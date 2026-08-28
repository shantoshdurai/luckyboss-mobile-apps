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

  const AuthSession({
    required this.token,
    required this.name,
    required this.email,
    this.phone,
    this.isDemo = false,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'name': name,
        'email': email,
        'phone': phone,
        'is_demo': isDemo,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: j['phone'] as String?,
        isDemo: (j['is_demo'] ?? false) as bool,
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
/// Laravel and fails closed. There is no offline success path. If the server
/// is unreachable the user is told so and stays signed out.
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
  }) {
    return _post(
      '${ApiConfig.v1}/auth/login',
      {'email': email.trim(), 'password': password, 'app': 'seeker'},
      onInvalid: 'That email and password do not match an account.',
    );
  }

  /// Registers a new candidate via `POST /api/v1/auth/job-seekers/register`.
  ///
  /// [countryCode] is the 2-letter ISO code (SG / MY / IN) the server requires.
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String countryCode,
    required String password,
  }) {
    return _post(
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
  }

  /// Signs in to the seeded read-only demo candidate.
  ///
  /// This is a genuine account on the server, not a client-side bypass: a real
  /// Sanctum token, real seeded jobs and applications. The server marks it
  /// read-only and rejects writes, so the demo cannot mutate anything even if
  /// the client forgets to disable a button.
  static Future<AuthResult> loginDemo() async {
    final result = await _post(
      '${ApiConfig.v1}/auth/demo',
      const {},
      onInvalid: 'The demo account is not available on this server.',
    );
    if (!result.success || result.session == null) return result;
    final s = result.session!;
    return AuthResult.ok(AuthSession(
      token: s.token,
      name: s.name,
      email: s.email,
      phone: s.phone,
      isDemo: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // PHONE OTP — Firebase Phone Auth
  // ---------------------------------------------------------------------------

  /// Whether real phone OTP can run in this build.
  ///
  /// A build-time constant rather than a runtime setting, so a release build
  /// with OTP unfinished cannot be talked into taking a fake success path.
  static const bool phoneOtpAvailable =
      bool.fromEnvironment('FIREBASE_OTP_ENABLED');

  /// Requests an SMS code for [fullPhoneNumber] (E.164, e.g. +6591234567).
  ///
  /// Returns a failure while [phoneOtpAvailable] is false, and deliberately does
  /// NOT fall back to a locally generated code. An auth path that succeeds
  /// without the server is the exact defect this file exists to remove: a
  /// candidate who "signs in" with no account holds no Sanctum token, so every
  /// subsequent API call 401s and the app breaks in a far more confusing way
  /// than an honest "not available yet".
  ///
  /// All of the following must be true before this can succeed:
  ///   1. Blaze billing enabled on Firebase project `luckyboss-617d2`.
  ///   2. The Android `applicationId` and the package in google-services.json
  ///      must match. They currently do not — the app builds as
  ///      `com.userapp.luckyboss_jobseeker`; the config registers
  ///      `com.userapp.luckyboss`.
  ///   3. SHA-1 and SHA-256 signing fingerprints registered on the Firebase
  ///      Android app. `oauth_client` in google-services.json is empty, so
  ///      Play Integrity / reCAPTCHA verification cannot complete.
  ///   4. `firebase_core` + `firebase_auth` in pubspec, and the
  ///      `com.google.gms.google-services` Gradle plugin applied.
  ///   5. For Chrome testing, a Firebase *web* app config — google-services.json
  ///      is Android-only and does nothing on web.
  static Future<AuthResult> sendPhoneOtp({
    required String fullPhoneNumber,
  }) async {
    if (!phoneOtpAvailable) {
      return const AuthResult.fail(
        'SMS sign-in is not switched on yet. Use email and password, or try the demo.',
      );
    }
    // Firebase verifyPhoneNumber is wired here once the prerequisites above are
    // met; the resulting Firebase ID token is exchanged for a Sanctum token by
    // [exchangeFirebaseToken].
    return const AuthResult.fail('SMS sign-in is not available.');
  }

  /// Exchanges a verified Firebase ID token for a Laravel Sanctum token.
  ///
  /// The server re-verifies the token against Google's public keys. The client
  /// is never trusted to assert that verification happened.
  static Future<AuthResult> exchangeFirebaseToken(String idToken) {
    return _post(
      '${ApiConfig.v1}/auth/firebase',
      {'id_token': idToken},
      onInvalid: 'That verification could not be confirmed. Please try again.',
    );
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
      if (s != null) 'Authorization': 'Bearer ${s.token}',
    };
  }

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
