import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../employer_main_navigation_screen.dart';

class EmployerLoginScreen extends StatefulWidget {
  const EmployerLoginScreen({super.key});

  @override
  State<EmployerLoginScreen> createState() => _EmployerLoginScreenState();
}

class _EmployerLoginScreenState extends State<EmployerLoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'employer@luckyboss.test');
  final TextEditingController _passwordController = TextEditingController(text: 'password');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both work email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      // Check valid employer credentials (matches web auth)
      if (email.toLowerCase() == 'employer@luckyboss.test' && password == 'password') {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployerMainNavigationScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'These credentials do not match our records. If your company is not registered yet, please register on the web portal.';
        });
      }
    });
  }

  void _fillDemoEmployer() {
    setState(() {
      _emailController.text = 'employer@luckyboss.test';
      _passwordController.text = 'password';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Employer Portal', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navy)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / Eyebrow
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.business, size: 14, color: AppTheme.emerald),
                          const SizedBox(width: 6),
                          Text(
                            'Corporate Recruiter Workspace',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.emerald),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Sign in to your account',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage corporate job postings, ATS pipelines, and candidate applications.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 24),

                  // Quick Demo Fill Shortcut
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPaper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚡ Quick Demo Sign In',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'employer@luckyboss.test',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.navy),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _fillDemoEmployer,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppTheme.borderLight),
                            ),
                          ),
                          child: Text(
                            'Auto-Fill',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emerald),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFB91C1C), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Email Field
                  Text(
                    'Work Email Address',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'recruiter@company.com',
                      prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppTheme.textMuted, size: 20),
                      fillColor: AppTheme.bgPaper,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.navy, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  Text(
                    'Password',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      fillColor: AppTheme.bgPaper,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.navy, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppTheme.navy,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              onChanged: (val) => setState(() => _rememberMe = val ?? true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.royalBlue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Sign In', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Register Company Web Link Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Are you an employer with an unregistered company?',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please open https://luckyboss.global/register/employer in browser to register your company.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                                backgroundColor: AppTheme.navy,
                              ),
                            );
                          },
                          child: Text(
                            'Register your company on the Web Portal →',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
