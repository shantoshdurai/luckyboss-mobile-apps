import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/config/firebase_options.dart';

/// LUCKY BOSS — FIREBASE IDENTITY
///
/// Deliberately **not** named `FirebaseAuthService`. A class by that name used
/// to exist in this app, contained no Firebase, contacted no server, accepted
/// any four digits as a valid OTP for any phone number, and wrote itself a
/// "token" made from a millisecond timestamp. The name is left burnt so nobody
/// confuses the two.
///
/// WHAT THIS CLASS DOES AND DOES NOT DO
///
/// It obtains a Firebase ID token for a **phone number**, and nothing else.
/// Google/social sign-in is deliberately absent: the functional specification
/// (section 29) defines registration as Name, Phone, Email and Password, and
/// sir confirmed on 2026-09-01 that Firebase is for phone OTP only. Email
/// sign-in goes to Laravel, not to Firebase.
///
/// It never creates a Lucky Boss session, never writes to storage, and never decides that somebody is
/// signed in. The ID token it returns is worthless on its own — it becomes a
/// session only when [AuthService.exchangeFirebaseToken] posts it to
/// `POST /api/v1/auth/firebase` and Laravel verifies the signature against
/// Google's public certificates. That verification is the security boundary.
/// Anything this class believes about the user is a client-side claim.
///
/// MySQL remains the system of record. Firebase answers one question — "is this
/// really the owner of this phone number?" — and stores nothing about the
/// candidate.
class FirebaseIdentityService {
  FirebaseIdentityService._();

  /// Whether [initialise] completed. When false, every method below fails
  /// closed with a message rather than throwing from deep inside the SDK.
  static bool _ready = false;

  static bool get isAvailable => _ready;

  /// Why Firebase is unavailable, for the sign-in screen to show. Null when
  /// initialisation succeeded.
  static String? _unavailableReason;

  static String? get unavailableReason => _unavailableReason;

  /// Called once from `main()` before `runApp`.
  ///
  /// Failure is not fatal. The app must keep working with email + password and
  /// with the on-device standalone account, so a missing or wrong Firebase
  /// config degrades the sign-in screen rather than preventing launch.
  static Future<void> initialise() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
      _unavailableReason = null;
    } catch (e) {
      _ready = false;
      _unavailableReason = _readableInitError(e);
      debugPrint('[FirebaseIdentity] init failed: $e');
    }
  }

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // PHONE / OTP
  // ---------------------------------------------------------------------------

  /// Requests an SMS code for [e164Phone] (e.g. +6591234567).
  ///
  /// Returns the verification id needed by [confirmSmsCode]. On Android the SMS
  /// is sometimes auto-retrieved by the OS, in which case [onAutoVerified]
  /// fires with a finished ID token and the code screen should be skipped
  /// entirely rather than asking for digits the user never has to read.
  ///
  /// Requires, in the Firebase console: Blaze billing, the Phone provider
  /// enabled, and the app's SHA-1 registered for Play Integrity. Missing any of
  /// these produces a specific message from [_readableSignInError] instead of a
  /// silent failure.
  static Future<String> sendSmsCode({
    required String e164Phone,
    void Function(String idToken)? onAutoVerified,
  }) async {
    _assertReady();

    if (kIsWeb) {
      // Web phone auth needs a reCAPTCHA verifier attached to a DOM element,
      // which this app has no host for. Stated plainly rather than failing
      // with an SDK error nobody can act on.
      throw const FirebaseIdentityException(
        'Phone sign-in is not available in the browser. Please use the Android '
        'app, or sign in with your email and password.',
      );
    }

    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (onAutoVerified == null) return;
        try {
          final result = await _auth.signInWithCredential(credential);
          final token = await result.user?.getIdToken();
          if (token != null) onAutoVerified(token);
        } catch (e) {
          debugPrint('[FirebaseIdentity] auto-verify: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(
            FirebaseIdentityException(_readableSignInError(e)),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  /// Exchanges the [smsCode] the candidate typed for a Firebase ID token.
  ///
  /// A wrong code throws here, at Firebase, which is the whole point: the old
  /// fake service accepted any four digits because nothing was ever checked.
  static Future<String> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    _assertReady();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(credential);
      final token = await result.user?.getIdToken();
      if (token == null) {
        throw const FirebaseIdentityException(
          'That verification did not complete. Please try again.',
        );
      }
      return token;
    } on FirebaseAuthException catch (e) {
      throw FirebaseIdentityException(_readableSignInError(e));
    }
  }

  // ---------------------------------------------------------------------------

  /// Signs out of Firebase. Called alongside `AuthService.logout()` — clearing
  /// the Lucky Boss session while leaving the Firebase session live leaves the
  /// previous phone number verified, so the next sign-in can skip the SMS step
  /// for somebody else's handset.
  static Future<void> signOut() async {
    if (!_ready) return;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[FirebaseIdentity] sign-out: $e');
    }
  }

  static void _assertReady() {
    if (!_ready) {
      throw FirebaseIdentityException(
        _unavailableReason ?? 'Firebase sign-in is not available in this build.',
      );
    }
  }

  static String _readableInitError(Object e) {
    final text = e.toString();
    if (text.contains('invalid-api-key') || text.contains('API key not valid')) {
      return 'The Firebase configuration for this build is not valid. The '
          'project owner needs to supply a current google-services.json.';
    }
    return 'Firebase sign-in is unavailable. You can still sign in with email '
        'and password.';
  }

  /// Maps Firebase error codes to something a candidate can act on — and, for
  /// the two codes our unconfigured project actually produces, says exactly
  /// what is missing so this is not debugged from scratch again.
  static String _readableSignInError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'That code is not correct. Check the SMS and try again.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'That code has expired. Request a new one.';
      case 'invalid-phone-number':
        return 'That phone number does not look right. Include your country code.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'The SMS limit for today has been reached. Please try another '
            'sign-in method.';
      case 'billing-not-enabled':
        return 'Phone sign-in is not switched on for this project yet.';
      case 'quota-exceeded-sms':
        // Spark projects get 10 SMS/day. Retrying will not help today.
        return 'The SMS limit for today has been reached. Please sign in with your '
            'email and password.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        // Two very different console problems share this one code, and the
        // difference cost a whole debugging session:
        //
        //  1. the Phone provider is switched off, or
        //  2. the provider is on, but the candidate's COUNTRY is not on the
        //     SMS region allowlist (Authentication -> Settings -> SMS region
        //     policy). Firebase's REST error says so explicitly — "SMS unable
        //     to be sent until this region enabled by the app developer" — but
        //     the Android SDK collapses it to this same code.
        //
        // The message names both, so the next person does not assume the
        // provider is off when it is really the region.
        return 'Phone sign-in is not available for your country yet. Please '
            'use email and password for now.';
      case 'configuration-not-found':
      case 'app-not-authorized':
      case 'missing-client-identifier':
        // The empty `oauth_client` in google-services.json. No amount of client
        // code fixes this; the SHA-1 has to be registered in the console.
        return 'This app is not yet registered for phone sign-in. Please use '
            'email and password for now.';
      default:
        debugPrint('[FirebaseIdentity] unmapped code: ${e.code} ${e.message}');
        return 'Sign-in could not be completed. Please try again.';
    }
  }
}

/// A sign-in failure carrying a message fit to show a user. Never wraps a raw
/// SDK string — those leak project ids and internal endpoints into the UI.
class FirebaseIdentityException implements Exception {
  final String message;

  const FirebaseIdentityException(this.message);

  @override
  String toString() => message;
}
