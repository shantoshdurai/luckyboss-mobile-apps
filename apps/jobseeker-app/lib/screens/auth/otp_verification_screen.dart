import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../providers/job_seeker_provider.dart';
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
  // 4 individual digit controllers
  final List<TextEditingController> _digitControllers = List.generate(
    4,
    (i) => TextEditingController(text: ['1', '2', '3', '4'][i]),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (i) => FocusNode());

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
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

        // Check if profile is already completed
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Verification', style: AppTheme.sansBold(fontSize: 17, color: AppTheme.primaryNavy)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter 4-digit OTP',
                style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.primaryNavy),
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
                        width: isFilled ? 2 : 1.2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppTheme.emerald.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: TextField(
                        controller: _digitControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onChanged: (val) => _onDigitChanged(index, val),
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Text(_errorMsg!, style: AppTheme.sansMedium(fontSize: 12.5, color: Colors.red)),
              ],

              const SizedBox(height: 32),

              // Resend Countdown
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't receive code? ", style: AppTheme.sansRegular(fontSize: 13.5, color: AppTheme.textSecondary)),
                    Text('Resend in 00:45', style: AppTheme.sansBold(fontSize: 13.5, color: AppTheme.emeraldDark)),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}