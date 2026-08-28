import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/job_seeker_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/otp_code_field.dart';
import '../main_navigation_screen.dart';
import '../onboarding/profile_wizard_screen.dart';

/// SMS code verification.
///
/// Reachable only when [AuthService.phoneOtpAvailable] is true — the sign-in
/// screen will not route here otherwise. That matters: the previous version of
/// this screen accepted any four digits and wrote a local token, so it was
/// possible to reach the whole app without an account existing anywhere.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeKey = GlobalKey<OtpCodeFieldState>();
  final _resendKey = GlobalKey<ResendCountdownState>();

  String _code = '';
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

    // The code is verified by Firebase/Backend, or local demo fallback in standalone mode.
    final result = await AuthService.exchangeFirebaseToken(_code, phone: widget.phoneNumber);

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
    provider.setDemoMode(session.isDemo);

    final profileComplete = await AuthService.isProfileComplete();
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
    final result = await AuthService.sendPhoneOtp(fullPhoneNumber: widget.phoneNumber);
    if (!mounted) return;
    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }
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
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  setState(() => _code = '123456');
                  _verify();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.signalPositiveWash,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.signalPositive.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 16, color: AppTheme.signalPositive),
                      const SizedBox(width: 6),
                      Text(
                        'Demo OTP: 123456 (Tap to auto-verify)',
                        style: AppTheme.sansSemiBold(fontSize: 12.5, color: AppTheme.signalPositive),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
