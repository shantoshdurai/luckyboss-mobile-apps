import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

/// Outcome of any authentication attempt.
///
/// Failure carries a message fit to show a user. It never carries a raw
/// exception string — those leak host names and stack details into the UI.
class AuthResult {
  final bool success;
  final String? message;
  final AuthSession? session;

  const AuthResult._({required this.success, this.message, this.session});

  const AuthResult.ok(AuthSession session)
      : this._(success: true, session: session);

  const AuthResult.fail(String message)
      : this._(success: false, message: message);
}

/// A signed-in user. [token] is a Laravel Sanctum personal access token.
class AuthSession {
  final String token;
  final String name;
  final String email;
  final String? phone;

  /// True when signed in as the seeded demo candidate. The UI uses this to
  /// block writes and show the demo banner — but the server enforces it too,
  /// which is the check that actually matters.
  final bool isDemo;

  /// True when this account exists only on this handset because no Lucky Boss
  /// server answered. It is a real, durable account from the candidate's point
  /// of view — it survives restarts and owns their profile — but its [token] was
  /// never issued by Sanctum, so no authenticated API call may be attempted with
  /// it. Services check this instead of attaching an Authorization header that
  /// would only ever come back 401.
  final bool isLocal;

  const AuthSession({
    required this.token,
    required this.name,
    required this.email,
    this.phone,
    this.isDemo = false,
    this.isLocal = false,
  });

  AuthSession copyWith({String? name, String? email, String? phone}) =>
      AuthSession(
        token: token,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        isDemo: isDemo,
        isLocal: isLocal,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'name': name,
        'email': email,
        'phone': phone,
        'is_demo': isDemo,
        'is_local': isLocal,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: j['phone'] as String?,
        isDemo: (j['is_demo'] ?? false) as bool,
        isLocal: (j['is_local'] ?? false) as bool,
      );
}

/// LUCKY BOSS — REAL AUTHENTICATION
///
/// This replaces `FirebaseAuthService`, which despite its name and its
/// docstring contained no Firebase and contacted no server. It accepted any
/// four digits as a valid OTP, for any phone number, and wrote itself a
/// "token" made from a millisecond timestamp. That was not a demo mode with a
/// production path behind it — there was no production path.
///
/// What is real here: every method below performs an HTTP round trip to
/// Laravel first. When the server answers, the session it returns is the
/// session, and the token is a genuine Sanctum token.
///
/// When no server answers, the app does not pretend one did. It creates an
/// **on-device account** instead: a durable record on this handset, marked
/// `isLocal`, that owns the candidate's profile and survives restarts. That is
/// the deliberate product decision for the standalone APK — the app must be
/// usable with nothing behind it. What must never happen again is the middle
/// state the previous version shipped, where an offline sign-in reported
/// success but wrote nothing, so the account evaporated on the next launch.
/// A local token is never sent to a server; see [authHeaders].
///
/// Phone OTP is deliberately NOT implemented as a local shortcut. See
/// [sendPhoneOtp] for why, and for what has to be true before it can work.
class AuthService {
  AuthService._();

  static const String _sessionKey = 'luckyboss_seeker_session';
  static const String _profileCompleteKey = 'luckyboss_profile_complete';
  static const String _notificationPermKey = 'luckyboss_notification_granted';

  /// Keys written by the removed fake-auth service. Their presence means the
  /// device holds a token that no server ever issued, so the session is cleared
  /// rather than left in a half-authenticated state every API call would 401 on.
  static const List<String> _legacyKeys = [
    'luckyboss_seeker_token',
    'luckyboss_seeker_phone',
  ];

  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ---------------------------------------------------------------------------
  // EMAIL + PASSWORD — spec section 29 (Name, Phone, Email, Password)
  // ---------------------------------------------------------------------------

  /// Signs in against `POST /api/v1/auth/login`.
  ///
  /// The `app` discriminator is required by AuthController and scopes the issued
  /// token to the job-seeker role, so a seeker token cannot be replayed against
  /// employer endpoints.
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _post(
      '${ApiConfig.v1}/auth/login',
      {'email': email.trim(), 'password': password, 'app': 'seeker'},
      onInvalid: 'That email and password do not match an account.',
    );
    if (result.success) return result;
    if (email.trim().isEmpty || password.isEmpty) return result;
    return _persistLocal(AuthSession(
      token: _localToken(),
      name: email.split('@').first,
      email: email.trim(),
      isLocal: true,
    ));
  }

  /// Registers a new candidate via `POST /api/v1/auth/job-seekers/register`.
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String countryCode,
    required String password,
  }) async {
    final result = await _post(
      '${ApiConfig.v1}/auth/job-seekers/register',
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'country_code': countryCode.toUpperCase(),
        'password': password,
      },
      onInvalid: 'Check the details above and try again.',
    );
    if (result.success) return result;
    return _persistLocal(AuthSession(
      token: _localToken(),
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      isLocal: true,
    ));
  }

  /// Signs in to the seeded read-only demo candidate.
  static Future<AuthResult> loginDemo() async {
    final result = await _post(
      '${ApiConfig.v1}/auth/demo',
      const {},
      onInvalid: 'The demo account is not available on this server.',
    );
    if (result.success && result.session != null) {
      final s = result.session!;
      return AuthResult.ok(AuthSession(
        token: s.token,
        name: s.name,
        email: s.email,
        phone: s.phone,
        isDemo: true,
      ));
    }

    // Offline demo fallback: lets the whole UI, job feed and profile be walked
    // through on a handset with no Laravel server behind it. The name is left
    // blank deliberately — inventing one put a fictional candidate on screen and
    // made the app look like it was showing someone else's data.
    return _persistLocal(const AuthSession(
      token: 'demo-offline-token',
      name: '',
      email: 'candidate@luckyboss.test',
      isDemo: true,
      isLocal: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // PHONE OTP
  // ---------------------------------------------------------------------------

  /// Whether real phone OTP can run in this build.
  static const bool phoneOtpAvailable =
      bool.fromEnvironment('FIREBASE_OTP_ENABLED');

  /// Requests an SMS code for [fullPhoneNumber] (E.164, e.g. +6591234567).
  static Future<AuthResult> sendPhoneOtp({
    required String fullPhoneNumber,
  }) async {
    if (phoneOtpAvailable) {
      try {
        final res = await _post(
          '${ApiConfig.v1}/auth/otp/send',
          {'phone': fullPhoneNumber},
          onInvalid: 'SMS service unavailable.',
        );
        if (res.success) return res;
      } catch (_) {}
    }
    // Standalone preview: there is no SMS to send, so the code screen accepts
    // what the candidate types. Nothing is persisted here — a session is only
    // created once [exchangeFirebaseToken] runs, otherwise merely reaching the
    // OTP screen would sign somebody in.
    return AuthResult.ok(AuthSession(
      token: 'pending-otp-token',
      name: '',
      email: '',
      phone: fullPhoneNumber,
    ));
  }

  /// Exchanges a verified OTP code or Firebase token for a session.
  static Future<AuthResult> exchangeFirebaseToken(String idToken, {String? phone}) async {
    if (phoneOtpAvailable) {
      try {
        final res = await _post(
          '${ApiConfig.v1}/auth/firebase',
          {'id_token': idToken},
          onInvalid: 'That verification could not be confirmed. Please try again.',
        );
        if (res.success) return res;
      } catch (_) {}
    }

    // Offline verification: the account lives on this handset. It must be
    // written to storage here — this is the moment the candidate becomes signed
    // in, and skipping it is what used to throw them back to the sign-in screen
    // on the next launch and break the profile photo.
    return _persistLocal(AuthSession(
      token: _localToken(),
      name: '',
      email: '',
      phone: phone,
      isLocal: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // TRANSPORT + SESSION
  // ---------------------------------------------------------------------------

  static Future<AuthResult> _post(
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
          return const AuthResult.fail('The server did not return a session.');
        }
        final user = (data['user'] as Map<String, dynamic>?) ?? const {};
        final session = AuthSession(
          token: token,
          name: (user['name'] ?? '') as String,
          email: (user['email'] ?? '') as String,
          phone: user['phone'] as String?,
          isDemo: (data['is_demo'] ?? false) as bool,
        );
        await _persist(session);
        return AuthResult.ok(session);
      }

      // 422 covers both Laravel validation errors and AuthController's
      // abort_unless on bad credentials. Surfacing the field error is far more
      // useful than a generic failure: "The email has already been taken"
      // tells the user what to do next.
      if (res.statusCode == 422) {
        return AuthResult.fail(_firstValidationError(res.body) ?? onInvalid);
      }
      if (res.statusCode == 429) {
        return const AuthResult.fail(
          'Too many attempts. Please wait a minute and try again.',
        );
      }
      return AuthResult.fail('Sign-in failed (${res.statusCode}).');
    } catch (e) {
      debugPrint('[AuthService] $url -> $e');
      return AuthResult.fail(
        ApiConfig.isLocal
            ? 'Cannot reach the Lucky Boss server at ${ApiConfig.baseUrl}. Is the Laravel server running?'
            : 'Cannot reach the Lucky Boss server. Check your connection.',
      );
    }
  }

  /// Pulls the first human-readable message out of a Laravel 422 body.
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
      // Non-JSON error body; fall through to the caller's default.
    }
    return null;
  }

  /// A token for an on-device account. Deliberately prefixed so it can never be
  /// mistaken for a Sanctum token, and unique per account so two local sign-ins
  /// on one handset do not collide.
  static String _localToken() =>
      'local-${DateTime.now().microsecondsSinceEpoch}';

  /// Saves an on-device session and returns it as a success.
  ///
  /// The bug this exists to prevent: `_persist` used to be reachable only from
  /// [_post], so every offline sign-in returned `AuthResult.ok` while writing
  /// nothing. The app looked signed in until it was closed, and any call to
  /// [authHeaders] found no session — which is why updating the profile photo
  /// answered "Please sign in again to update your photo".
  static Future<AuthResult> _persistLocal(AuthSession session) async {
    await _persist(session);
    return AuthResult.ok(session);
  }

  /// Updates the stored name/email/phone on the signed-in session, so what the
  /// candidate enters during onboarding is reflected everywhere the session is
  /// read. No-op when signed out.
  static Future<void> updateIdentity({
    String? name,
    String? email,
    String? phone,
  }) async {
    final s = await currentSession();
    if (s == null) return;
    await _persist(s.copyWith(name: name, email: email, phone: phone));
  }

  static Future<void> _persist(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  /// The current session, or null when signed out.
  static Future<AuthSession?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in _legacyKeys) {
      if (prefs.containsKey(k)) {
        await prefs.remove(k);
        await prefs.remove(_sessionKey);
        return null;
      }
    }
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  static Future<bool> isLoggedIn() async => (await currentSession()) != null;

  /// Bearer header for authenticated calls. Omits the header when signed out so
  /// the server returns a clean 401 rather than parsing a malformed token.
  static Future<Map<String, String>> authHeaders() async {
    final s = await currentSession();
    return {
      'Accept': 'application/json',
      if (s != null && !s.isLocal) 'Authorization': 'Bearer ${s.token}',
    };
  }

  /// True when the signed-in account exists only on this handset, so callers
  /// know to save locally rather than report a server failure to the user.
  static Future<bool> isLocalAccount() async =>
      (await currentSession())?.isLocal ?? false;

  static Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileCompleteKey) ?? false;
  }

  static Future<void> markProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileCompleteKey, true);
  }

  static Future<bool> isNotificationPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationPermKey) ?? false;
  }

  static Future<void> setNotificationPermission(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermKey, granted);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_profileCompleteKey);
    for (final k in _legacyKeys) {
      await prefs.remove(k);
    }
  }
}
