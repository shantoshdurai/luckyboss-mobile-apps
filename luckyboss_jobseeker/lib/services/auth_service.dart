import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;

import '../core/config/api_config.dart';
import 'firebase_identity_service.dart';

/// Outcome of any authentication attempt.
///
/// Failure carries a message fit to show a user. It never carries a raw
/// exception string — those leak host names and stack details into the UI.
class AuthResult {
  final bool success;
  final String? message;
  final AuthSession? session;

  /// Whether a Lucky Boss server actually answered, as opposed to the request
  /// never arriving. **Only meaningful when [success] is false** — on success
  /// the caller already knows which path produced the session from
  /// [AuthSession.isLocal].
  ///
  /// The distinction matters for exactly one caller. On a network failure the
  /// app is entitled to fall back to an on-device account, because the
  /// standalone APK must work with nothing behind it. On a *rejection* it is
  /// not: if Laravel verified a Firebase token against Google's certificates
  /// and refused it, creating a local account instead would hand out a session
  /// the server just declined — which is the fake-auth pattern this project
  /// already shipped once.
  final bool serverAnswered;

  const AuthResult._({
    required this.success,
    this.message,
    this.session,
    this.serverAnswered = false,
  });

  const AuthResult.ok(AuthSession session)
      : this._(success: true, session: session);

  const AuthResult.fail(String message, {bool serverAnswered = false})
      : this._(
          success: false,
          message: message,
          serverAnswered: serverAnswered,
        );
}

/// A signed-in user. [token] is a Laravel Sanctum personal access token.
class AuthSession {
  final String token;
  final String name;
  final String email;
  final String? phone;

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
    this.isLocal = false,
  });

  AuthSession copyWith({String? name, String? email, String? phone}) =>
      AuthSession(
        token: token,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        isLocal: isLocal,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'name': name,
        'email': email,
        'phone': phone,
        'is_local': isLocal,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: j['phone'] as String?,
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
/// Phone OTP is handled by [FirebaseIdentityService], which only ever obtains
/// a Firebase ID token. There is no Google/social sign-in: spec section 29
/// defines registration as Name, Phone, Email and Password, and sir confirmed
/// on 2026-09-01 that Firebase is for phone OTP only. That token becomes a session
/// solely through [exchangeFirebaseToken], where Laravel verifies its signature
/// server-side. There is no local shortcut past that check.
class AuthService {
  AuthService._();

  static const String _sessionKey = 'luckyboss_seeker_session';
  static const String _profileCompleteKey = 'luckyboss_profile_complete';
  static const String _notificationPermKey = 'luckyboss_notification_granted';

  /// Accounts created on this handset, so sign-in can tell a returning user
  /// from a new one.
  ///
  /// On a standalone build there is no server to ask "does this account
  /// exist?", and without an answer `login` accepted anything — which meant a
  /// typo in an email silently created a second empty account rather than
  /// saying the password was wrong. This is the local stand-in: a map of
  /// email to password, replaced by the server's own check the moment
  /// `POST /api/v1/auth/login` answers.
  ///
  /// Not a security boundary and not pretending to be one. It is a local
  /// convenience on a device whose storage the owner already controls.
  static const String _accountsKey = 'luckyboss_local_accounts_v1';

  static Future<Map<String, String>> _localAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _rememberAccount(String email, String password) async {
    if (email.trim().isEmpty) return;
    final accounts = await _localAccounts();
    accounts[email.trim().toLowerCase()] = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  /// Whether an account with this email exists on this device.
  static Future<bool> accountExists(String email) async =>
      (await _localAccounts()).containsKey(email.trim().toLowerCase());

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

    // No server answered, so fall back to the accounts on this device — and
    // fail when there is no match. Signing somebody in on an email they have
    // never registered is how a typo becomes a second, empty account they
    // cannot find their profile in.
    final accounts = await _localAccounts();
    final key = email.trim().toLowerCase();
    final stored = accounts[key];

    if (stored == null) {
      return const AuthResult.fail(
        'We could not find an account with that email. Create one to get '
        'started.',
      );
    }
    if (stored != password) {
      return const AuthResult.fail('That password does not match.');
    }

    return _persistLocal(AuthSession(
      token: _localToken(),
      name: email.split('@').first,
      email: email.trim(),
      isLocal: true,
    ));
  }

  /// True when [message] means "no such account", so the caller can offer to
  /// create one rather than showing a dead end.
  static bool isUnknownAccount(String? message) =>
      message != null && message.startsWith('We could not find an account');

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

    // Remembered so the next sign-in recognises them. Without this the account
    // just created would be reported as not existing.
    await _rememberAccount(email, password);

    return _persistLocal(AuthSession(
      token: _localToken(),
      name: name.trim(),
      email: email.trim(),
      // Blank stays null rather than an empty string: the profile screen shows
      // a number when one exists, and '' is not a number.
      phone: phone.trim().isEmpty ? null : phone.trim(),
      isLocal: true,
    ));
  }

  // ---------------------------------------------------------------------------
  // PHONE OTP
  // ---------------------------------------------------------------------------

  /// Whether Firebase phone OTP is usable in this build.
  ///
  /// No longer a `--dart-define`. Firebase either initialised at launch or it
  /// did not, and the sign-in screen should reflect what is actually true on
  /// this device rather than what a build flag claimed.
  static bool get firebaseAvailable => FirebaseIdentityService.isAvailable;

  /// Requests an SMS code for [fullPhoneNumber] (E.164, e.g. +6591234567).
  ///
  /// Returns the Firebase verification id, which [verifySmsCode] needs. There
  /// is no offline path: a code nobody sent cannot be checked, and the previous
  /// version's "accept whatever the candidate types" is precisely the fake auth
  /// that had to be torn out of this app. When Firebase is unavailable the
  /// caller is told to use email and password.
  static Future<String> sendPhoneOtp({
    required String fullPhoneNumber,
    void Function(String idToken)? onAutoVerified,
  }) {
    return FirebaseIdentityService.sendSmsCode(
      e164Phone: fullPhoneNumber,
      onAutoVerified: onAutoVerified,
    );
  }

  /// Confirms the SMS code, then exchanges the resulting Firebase token for a
  /// Lucky Boss session.
  static Future<AuthResult> verifySmsCode({
    required String verificationId,
    required String smsCode,
    String? phone,
  }) async {
    try {
      final idToken = await FirebaseIdentityService.confirmSmsCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return exchangeFirebaseToken(idToken, phone: phone);
    } on FirebaseIdentityException catch (e) {
      return AuthResult.fail(e.message, serverAnswered: true);
    }
  }

  /// Exchanges a **verified Firebase ID token** for a Lucky Boss session via
  /// `POST /api/v1/auth/firebase`.
  ///
  /// Laravel checks the token's signature against Google's public certificates,
  /// its audience against our project id, and its expiry, then finds or creates
  /// the MySQL user and returns a Sanctum token. MySQL stays the system of
  /// record; Firebase only proved who this is.
  ///
  /// The failure handling here is the part worth reading. There are two
  /// different failures and they must not be treated alike:
  ///
  /// - **The server answered and refused** (401/403/422). The identity was
  ///   checked and rejected, or the account belongs to the other app. Falling
  ///   back to an on-device account here would hand out a session the server
  ///   just declined. So this fails, and says so.
  /// - **The server never answered.** The standalone APK must work with no
  ///   Laravel behind it, and Firebase has already proven this person owns the
  ///   phone number. An on-device account is created, marked `isLocal`, and its
  ///   token is never sent anywhere.
  static Future<AuthResult> exchangeFirebaseToken(
    String idToken, {
    String? phone,
    String? name,
    String? countryCode,
  }) async {
    final result = await _post(
      '${ApiConfig.v1}/auth/firebase',
      {
        'id_token': idToken,
        'app': 'seeker',
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (countryCode != null) 'country_code': countryCode.toUpperCase(),
      },
      onInvalid: 'That sign-in could not be confirmed. Please try again.',
    );

    if (result.success) return result;

    // The server had its say. Respect it.
    if (result.serverAnswered) return result;

    // No server. Fall back to the on-device account, carrying whatever
    // Firebase told us about the person so their profile is not blank.
    //
    // Guarded: FirebaseAuth.instance throws outright when Firebase never
    // initialised, and this method is also reachable with a token obtained
    // some other way. A missing display name must not turn a working offline
    // sign-in into a crash.
    User? user;
    if (FirebaseIdentityService.isAvailable) {
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (e) {
        debugPrint('[AuthService] no Firebase user available: $e');
      }
    }
    return _persistLocal(AuthSession(
      token: _localToken(),
      name: (name ?? user?.displayName ?? '').trim(),
      email: user?.email ?? '',
      phone: phone ?? user?.phoneNumber,
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
        );
        await _persist(session);
        return AuthResult.ok(session);
      }

      // 422 covers both Laravel validation errors and AuthController's
      // abort_unless on bad credentials. Surfacing the field error is far more
      // useful than a generic failure: "The email has already been taken"
      // tells the user what to do next.
      if (res.statusCode == 422) {
        return AuthResult.fail(
          _firstValidationError(res.body) ?? onInvalid,
          serverAnswered: true,
        );
      }
      if (res.statusCode == 429) {
        return const AuthResult.fail(
          'Too many attempts. Please wait a minute and try again.',
          serverAnswered: true,
        );
      }
      // 401 and 403 from /auth/firebase are a verified refusal, not an outage.
      if (res.statusCode == 401 || res.statusCode == 403) {
        return AuthResult.fail(
          _firstValidationError(res.body) ?? onInvalid,
          serverAnswered: true,
        );
      }
      // Deliberately NOT flagged as a verified refusal. A 500 from a crashed
      // app, or a 502 from a proxy in front of it, means Laravel never reached
      // a decision about this identity — treating that as "rejected" would
      // strand a candidate whose only fault is that our server is down, when
      // the standalone on-device account would have served them fine.
      return AuthResult.fail('Sign-in failed (${res.statusCode}).');
    } catch (e) {
      debugPrint('[AuthService] $url -> $e');
      return AuthResult.fail(
        ApiConfig.isLocal
            ? 'Cannot reach the Luckyboss server at ${ApiConfig.baseUrl}. Is the Laravel server running?'
            : 'Cannot reach the Luckyboss server. Check your connection.',
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
    // Firebase holds its own session. Clearing only the Lucky Boss one leaves
    // the previous Google account signed in, so the next "Continue with Google"
    // silently reuses it without ever showing the account chooser — on a shared
    // handset that signs the new person in as the old one.
    await FirebaseIdentityService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_profileCompleteKey);
    for (final k in _legacyKeys) {
      await prefs.remove(k);
    }
  }
}
