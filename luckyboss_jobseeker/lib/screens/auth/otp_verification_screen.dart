import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../providers/job_seeker_provider.dart';
import '../../widgets/lucky_boss_brand_logo.dart';
import '../main_navigation_screen.dart';
import '../onboarding/profile_setup_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // 4 individual digit controllers (Clean & Empty)
  final List<TextEditingController> _digitControllers = List.generate(
    4,
    (i) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (i) => FocusNode());

  int _resendSeconds = 45;
  Timer? _countdownTimer;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _resendSeconds = 45);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_resendSeconds > 0) {
          setState(() => _resendSeconds--);
        } else {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _digitControllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    final code = _currentOtp.trim();
    if (code.length != 4) {
      setState(() => _errorMsg = 'Please enter all 4 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final success = await FirebaseAuthService.verifyOtp(
      verificationId: widget.verificationId,
      smsCode: code,
      phoneNumber: widget.phoneNumber,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        final provider = Provider.of<JobSeekerProvider>(context, listen: false);
        provider.setAuthenticated(true, phone: widget.phoneNumber);

        final profileComplete = await FirebaseAuthService.isProfileComplete();

        if (mounted) {
          if (profileComplete) {
            await provider.checkAuthStatus();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileSetupScreen(phoneNumber: widget.phoneNumber),
              ),
              (route) => false,
            );
          }
        }
      } else {
        setState(() => _errorMsg = 'Invalid verification code. Please try 1234');
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == 4) {
          _verifyCode();
        }
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryNavy, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const LuckyBossBrandLogo(height: 34),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Verification', style: AppTheme.sansBold(fontSize: 11, color: AppTheme.primaryNavy)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter 4-digit OTP',
                style: GoogleFonts.cormorantGaramond(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Code sent to ',
                    style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  Text(
                    widget.phoneNumber,
                    style: AppTheme.sansBold(fontSize: 14, color: AppTheme.primaryNavy),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 4 Distinct Uniformly Sized PIN Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final isFilled = _digitControllers[index].text.isNotEmpty;
                  return Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isFilled ? AppTheme.emerald.withValues(alpha: 0.06) : AppTheme.bgPaper,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFilled ? AppTheme.emerald : AppTheme.borderMedium,
                        width: isFilled ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _digitControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: '–',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                        onChanged: (val) => _onDigitChanged(index, val),
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _errorMsg!,
                    style: AppTheme.sansMedium(fontSize: 12.5, color: Colors.redAccent),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Live Resend Code Countdown
              Center(
                child: _resendSeconds > 0
                    ? RichText(
                        text: TextSpan(
                          text: "Didn't receive code? ",
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Resend in 00:${_resendSeconds.toString().padLeft(2, '0')}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emeraldDark),
                            ),
                          ],
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () {
                          _startCountdown();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('A fresh 4-digit OTP has been sent via SMS.')),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.emeraldDark),
                        label: Text(
                          'Resend Code via SMS',
                          style: AppTheme.sansBold(fontSize: 13, color: AppTheme.emeraldDark),
                        ),
                      ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Verify & Continue', style: AppTheme.sansBold(fontSize: 15, color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}