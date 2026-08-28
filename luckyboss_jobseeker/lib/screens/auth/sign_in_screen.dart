import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import '../../widgets/phone_number_field.dart';
import 'email_sign_in_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

/// Candidate sign-in.
///
/// The mobile number is the whole screen. Everything else — email, the demo,
/// creating an account — sits below a divider as a secondary route. That order
/// is deliberate: candidates in SG/MY/IN reach for their phone number first,
/// and the previous Mobile/Email toggle put a decision in front of them before
/// they could type anything.
///
/// OTP itself is gated behind [AuthService.phoneOtpAvailable] until Firebase is
/// configured, so the primary action states plainly that it is not switched on
/// yet rather than failing after the number is entered. Google sign-in is
/// deliberately absent: it needs the same Firebase setup, and a dead button is
/// worse than no button.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _e164 = '';
  PhoneFormat _format = PhoneFormat.all.first;
  final _phoneKey = GlobalKey<PhoneNumberFieldState>();

  bool _busy = false;
  String? _error;

  // ---------------------------------------------------------------------------

  Future<void> _continueWithPhone() async {
    final field = _phoneKey.currentState;
    if (field == null || !field.isComplete) {
      setState(() => _error =
          'Enter your ${_format.digitCount}-digit ${_format.name} mobile number.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await AuthService.sendPhoneOtp(fullPhoneNumber: _e164);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!result.success) {
      setState(() => _error = result.message);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(phoneNumber: _e164),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: LuckyBossBrandLogo(height: 40)),
                  const SizedBox(height: 36),
                  Text(
                    'Sign in',
                    style: AppTheme.serifTitle(fontSize: 30, color: AppTheme.inkOf(context)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get job updates and recruiter calls on your mobile.',
                    style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
                  ),
                  const SizedBox(height: 30),
                  ..._mobileFields(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _errorBanner(_error!),
                  ],
                  const SizedBox(height: 22),
                  _primaryButton(),
                  const SizedBox(height: 22),
                  _divider(),
                  const SizedBox(height: 18),
                  _secondaryButton(
                    icon: Icons.mail_outline,
                    label: 'Continue with email',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmailSignInScreen()),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _registerLink(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _mobileFields() => [
        Text('Mobile number',
            style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.inkMutedOf(context))),
        const SizedBox(height: 8),
        PhoneNumberField(
          key: _phoneKey,
          enabled: !_busy,
          onChanged: (v) => _e164 = v,
          onCountryChanged: (f) => setState(() => _format = f),
          onSubmitted: _continueWithPhone,
        ),
        const SizedBox(height: 10),
        Text(
          "We'll text you a 6-digit verification code.",
          style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkFaintOf(context)),
        ),
      ];

  Widget _errorBanner(String message) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppTheme.signalClosedWash,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 17, color: AppTheme.signalClosed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTheme.sansMedium(fontSize: 13, color: AppTheme.signalClosed),
              ),
            ),
          ],
        ),
      );

  Widget _primaryButton() => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _busy ? null : _continueWithPhone,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryFillOf(context),
            foregroundColor: AppTheme.onPrimaryFillOf(context),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              : Text('Get OTP',
                  style: AppTheme.sansBold(fontSize: 15.5, color: AppTheme.onInkOf(context))),
        ),
      );

  /// Shared style for the routes below the divider. Uniform weight keeps email
  /// and the demo reading as alternatives to each other, not to the phone field.
  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: _busy ? null : onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).dividerColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppTheme.signalSource),
              const SizedBox(width: 10),
              Flexible(
                child: Text(label,
                    style: AppTheme.sansBold(fontSize: 15, color: AppTheme.inkOf(context)),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );

  Widget _divider() => Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or',
                style: AppTheme.sansRegular(fontSize: 12.5, color: AppTheme.inkFaintOf(context))),
          ),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      );

  Widget _registerLink() => Center(
        child: GestureDetector(
          onTap: _busy
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
          child: RichText(
            text: TextSpan(
              text: 'New to Lucky Boss? ',
              style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.inkMutedOf(context)),
              children: [
                TextSpan(
                  text: 'Create an account',
                  style: AppTheme.sansBold(fontSize: 14, color: AppTheme.signalSource),
                ),
              ],
            ),
          ),
        ),
      );
}
