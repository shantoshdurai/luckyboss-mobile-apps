import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_identity_service.dart';
import '../../widgets/otp_code_field.dart';
import '../main_navigation_screen.dart';
import '../onboarding/profile_wizard_screen.dart';

/// SMS code verification.
///
/// Reached only after Firebase has actually sent an SMS, which is what
/// [verificationId] represents. That matters: the previous version of this
/// screen accepted any four digits and wrote a local token, so it was possible
/// to reach the whole app without an account existing anywhere.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  /// Firebase's handle for the code it just sent. Pairs with the digits the
  /// candidate types; one is useless without the other.
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeKey = GlobalKey<OtpCodeFieldState>();
  final _resendKey = GlobalKey<ResendCountdownState>();

  String _code = '';
  /// Replaced on every resend — see [_resend].
  late String _verificationId = widget.verificationId;
  bool _busy = false;
  String? _error;

  static const int _codeLength = 6;

  Future<void> _verify() async {
    if (_code.length != _codeLength) {
      setState(() => _error = 'Enter the $_codeLength-digit code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    // Firebase checks the code against the one it actually sent. The previous
    // version passed the typed digits to exchangeFirebaseToken as though they
    // were an ID token, which is why any four digits used to work.
    final result = await AuthService.verifySmsCode(
      verificationId: _verificationId,
      smsCode: _code,
      phone: widget.phoneNumber,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      setState(() => _error = result.message);
      _codeKey.currentState?.clear();
      _codeKey.currentState?.focus();
      return;
    }

    final session = result.session!;
    final provider = context.read<JobSeekerProvider>();
    provider.setAuthenticated(true, phone: session.phone ?? widget.phoneNumber);

    // Pull the profile back down before deciding anything. signOut() wiped
    // the local copy, and the server is the only place it still exists.
    await provider.hydrateAfterSignIn();
    final profileComplete = provider.isProfileComplete;
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => profileComplete
            ? const MainNavigationScreen()
            : const ProfileWizardScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      // A resend produces a NEW verification id. Keeping the old one would make
      // the fresh code the candidate just received fail as "invalid".
      _verificationId =
          await AuthService.sendPhoneOtp(fullPhoneNumber: widget.phoneNumber);
    } on FirebaseIdentityException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      return;
    }
    if (!mounted) return;
    _codeKey.currentState?.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New code sent to ${widget.phoneNumber}.',
            style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.onInkOf(context))),
        backgroundColor: AppTheme.primaryFillOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the code',
                style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.inkOf(context)),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  text: 'We sent a $_codeLength-digit code to ',
                  style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
                  children: [
                    TextSpan(
                      text: widget.phoneNumber,
                      style: AppTheme.sansBold(fontSize: 14, color: AppTheme.inkOf(context)),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Wrong number?',
                  style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.signalSource),
                ),
              ),
              const SizedBox(height: 32),

              OtpCodeField(
                key: _codeKey,
                length: _codeLength,
                enabled: !_busy,
                hasError: _error != null,
                onChanged: (v) => setState(() {
                  _code = v;
                  if (_error != null) _error = null;
                }),
                onCompleted: (_) => _verify(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 15, color: AppTheme.signalClosed),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(_error!,
                          style: AppTheme.sansMedium(
                              fontSize: 13, color: AppTheme.signalClosed)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _busy || _code.length != _codeLength ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryFillOf(context),
                    foregroundColor: AppTheme.onPrimaryFillOf(context),
                    disabledBackgroundColor: AppTheme.inkFaintOf(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppTheme.onInkOf(context)),
                          ),
                        )
                      : Text('Verify',
                          style: AppTheme.sansBold(fontSize: 15.5, color: AppTheme.onInkOf(context))),
                ),
              ),
              const SizedBox(height: 22),
              ResendCountdown(
                key: _resendKey,
                enabled: !_busy,
                onResend: _resend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
