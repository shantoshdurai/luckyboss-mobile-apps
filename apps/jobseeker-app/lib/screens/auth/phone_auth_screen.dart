import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_data.dart';
import '../../services/firebase_auth_service.dart';
import 'otp_verification_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  String _selectedCountryCode = '+91'; // Pre-selected India
  final TextEditingController _phoneController = TextEditingController(text: '98765-43210');
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.replaceAll('-', '').replaceAll(' ', '').trim();
    if (rawPhone.isEmpty || rawPhone.length < 8) {
      setState(() => _errorMsg = 'Please enter a valid mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final formattedPhone = rawPhone.length >= 10
        ? '${rawPhone.substring(0, 5)}-${rawPhone.substring(5)}'
        : rawPhone;
    final fullNumber = '$_selectedCountryCode $formattedPhone';

    await FirebaseAuthService.sendOtp(
      fullPhoneNumber: fullNumber,
      onCodeSent: (verifId) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: verifId,
                phoneNumber: fullNumber,
              ),
            ),
          );
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMsg = err;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Candidate Login', style: AppTheme.sansBold(fontSize: 17, color: AppTheme.primaryNavy)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your mobile number',
                style: AppTheme.serifTitle(fontSize: 28, color: AppTheme.primaryNavy),
              ),
              const SizedBox(height: 8),
              Text(
                'We will send a 4-digit verification code to authenticate your candidate workspace.',
                style: AppTheme.sansRegular(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Phone Row with Country Dropdown & Centered Hyphen Format (98765-43210)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgPaper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryNavy),
                        items: AppData.countries.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['phone'],
                            child: Row(
                              children: [
                                Text(c['flag']!, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  '${c['code']} (${c['phone']})',
                                  style: AppTheme.sansBold(fontSize: 13, color: AppTheme.primaryNavy),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCountryCode = val);
                        },
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: AppTheme.borderMedium,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _PhoneHyphenInputFormatter(),
                        ],
                        style: AppTheme.sansBold(fontSize: 17, color: AppTheme.textPrimary, letterSpacing: 0.8),
                        decoration: const InputDecoration(
                          hintText: '98765-43210',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(_errorMsg!, style: AppTheme.sansMedium(fontSize: 12, color: Colors.red)),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Code'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'By continuing, you agree to Lucky Boss Terms & Privacy Policy.',
                  style: AppTheme.sansRegular(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formatter that automatically places a '-' between 5th and 6th digits: 98765-43210
class _PhoneHyphenInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll('-', '');
    if (digitsOnly.length > 10) {
      return oldValue;
    }

    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 5) {
        formatted += '-';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}