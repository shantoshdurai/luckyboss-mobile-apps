import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

/// LUCKY BOSS — EMPLOYER AUTHENTICATION
///
/// Before this existed the employer portal had no server authentication of any
/// kind. `EmployerLoginScreen._submit` compared the typed email against a
/// company record stored on the handset and, if they matched, set
/// `provider.setAuthenticated(true)`. No password was ever checked against
/// anything, no token was ever issued, and a `TODO` in that method noted that
/// `POST /api/v1/auth/login` should be called "once an employer login route
/// exists". That route has existed all along.
///
/// What this class adds: a real round trip to Laravel and a real Sanctum
/// token, stored and attached to employer API calls, so the candidate pipeline
/// and vacancy endpoints stop being unauthenticated guesses.
///
/// No Firebase here at all. Spec section 29 defines registration as Name,
/// Phone, Email and Password, and sir confirmed on 2026-09-01 that Firebase is
/// for candidate phone OTP only — employers sign in with email and password
/// against Laravel.
///
/// The seeker app's `AuthService` is the sibling of this class. They are
/// deliberately separate rather than shared: the two apps issue role-scoped
/// tokens (`employer` vs `job-seeker`) and must not be able to hand each other
/// a session. The `app` discriminator below is what enforces that server-side.
class EmployerAuthService {
  EmployerAuthService._();

  static const String _sessionKey = 'luckyboss_employer_session';
  static const Duration _timeout = Duration(seconds: 15);

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // SIGN-IN
  // ---------------------------------------------------------------------------

  /// Email + password against `POST /api/v1/auth/login` with `app: employer`.
  ///
  /// The role scoping matters: a job seeker's credentials are refused here by
  /// Laravel rather than granted an employer session, because `AuthController`
  /// checks `hasRole('employer')` before issuing the token.
  static Future<EmployerAuthResult> login({
    required String email,
    required String password,
  }) {
    return _post(
      '${ApiConfig.v1}/auth/login',
      {
        'email': email.trim().toLowerCase(),
        'password': password,
        'app': 'employer',
      },
      onInvalid: 'That email and password do not match an employer account.',
    );
  }

  /// Registers a company via `POST /api/v1/auth/employers/register`.
  static Future<EmployerAuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String countryCode,
    required String password,
    required String companyName,
  }) {
    return _post(
      '${ApiConfig.v1}/auth/employers/register',
      {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'country_code': countryCode.toUpperCase(),
        'password': password,
        'company_name': companyName.trim(),
      },
      onInvalid: 'Check the details above and try again.',
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSPORT
  // ---------------------------------------------------------------------------

  static Future<EmployerAuthResult> _post(
    String url,
    Map<String, dynamic> body, {
    required String onInvalid,
  }) async {
    try {
      final res = await http
          .post(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          return EmployerAuthResult.fail('The server did not return a session.');
        }
        final user = (data['user'] as Map<String, dynamic>?) ?? const {};
        final company = data['company'] as Map<String, dynamic>?;

        final session = EmployerSession(
          token: token,
          name: (user['name'] ?? '') as String,
          email: (user['email'] ?? '') as String,
          phone: user['phone'] as String?,
          companyName: (company?['name'] ?? '') as String,
          isNewAccount: (data['is_new_user'] ?? false) as bool,
        );
        await _persist(session);
        return EmployerAuthResult.ok(session);
      }

      if (res.statusCode == 422 ||
          res.statusCode == 401 ||
          res.statusCode == 403) {
        return EmployerAuthResult.fail(
          _firstValidationError(res.body) ?? onInvalid,
        );
      }
      if (res.statusCode == 429) {
        return EmployerAuthResult.fail(
          'Too many attempts. Please wait a minute and try again.',
        );
      }
      return EmployerAuthResult.fail('Sign-in failed (${res.statusCode}).');
    } catch (e) {
      debugPrint('[EmployerAuth] $url -> $e');
      return EmployerAuthResult.fail(
        ApiConfig.isLocal
            ? 'Cannot reach the Luckyboss server at ${ApiConfig.baseUrl}. Is the Laravel server running?'
            : 'Cannot reach the Luckyboss server. Check your connection.',
        unreachable: true,
      );
    }
  }

  static String? _firstValidationError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      final message = data['message'] as String?;
      if (message != null && message.trim().isNotEmpty) return message;
    } catch (_) {
      // Non-JSON body; the caller's default is used.
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // SESSION
  // ---------------------------------------------------------------------------

  static Future<void> _persist(EmployerSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  static Future<EmployerSession?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return EmployerSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  static Future<bool> isLoggedIn() async => (await currentSession()) != null;

  /// Bearer header for authenticated employer calls. Omits the header when
  /// signed out so the server returns a clean 401 rather than parsing nothing.
  static Future<Map<String, String>> authHeaders() async {
    final s = await currentSession();
    return {
      'Accept': 'application/json',
      if (s != null) 'Authorization': 'Bearer ${s.token}',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

}

/// A signed-in employer. [token] is a Laravel Sanctum token scoped to the
/// `employer` role.
class EmployerSession {
  final String token;
  final String name;
  final String email;
  final String? phone;
  final String companyName;

  /// True when Laravel created this account during the sign-in that produced
  /// the session, so the UI can route to company setup instead of a dashboard
  /// with nothing in it.
  final bool isNewAccount;

  const EmployerSession({
    required this.token,
    required this.name,
    required this.email,
    this.phone,
    this.companyName = '',
    this.isNewAccount = false,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'name': name,
        'email': email,
        'phone': phone,
        'company_name': companyName,
        'is_new_account': isNewAccount,
      };

  factory EmployerSession.fromJson(Map<String, dynamic> j) => EmployerSession(
        token: j['token'] as String,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: j['phone'] as String?,
        companyName: (j['company_name'] ?? '') as String,
        isNewAccount: (j['is_new_account'] ?? false) as bool,
      );
}

/// Outcome of an employer sign-in attempt.
class EmployerAuthResult {
  final bool success;
  final String? message;
  final EmployerSession? session;

  /// True when the request never reached a server, as opposed to being
  /// refused by one. The login screen uses this to decide whether it may fall
  /// back to the existing on-device company check.
  final bool unreachable;

  const EmployerAuthResult._({
    required this.success,
    this.message,
    this.session,
    this.unreachable = false,
  });

  const EmployerAuthResult.ok(EmployerSession session)
      : this._(success: true, session: session);

  const EmployerAuthResult.fail(String message, {bool unreachable = false})
      : this._(success: false, message: message, unreachable: unreachable);
}
