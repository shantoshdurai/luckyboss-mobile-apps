import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/job_seeker_provider.dart';
import '../services/firebase_auth_service.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';
import 'onboarding/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    final isLoggedIn = await FirebaseAuthService.isLoggedIn();
    final isProfileDone = await FirebaseAuthService.isProfileComplete();

    if (!mounted) return;

    if (isLoggedIn && isProfileDone) {
      // Returning user with complete profile — go to main app
      await provider.checkAuthStatus();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (isLoggedIn && !isProfileDone) {
      // Authenticated but profile incomplete — resume setup wizard
      final phone = await FirebaseAuthService.getSavedPhone();
      provider.setAuthenticated(true, phone: phone);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(phoneNumber: phone ?? '+91 98765 43210'),
        ),
      );
    } else {
      // Not authenticated — show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lucky', style: GoogleFonts.cormorantGaramond(fontSize: 42, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  Text('Boss', style: GoogleFonts.cormorantGaramond(fontSize: 42, fontWeight: FontWeight.w800, color: const Color(0xFF0B1B3D))),
                ],
              ),
            ),
            const SizedBox(height: 44),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.emerald),
              ),
            ),
          ],
        ),
      ),
    );
  }
}