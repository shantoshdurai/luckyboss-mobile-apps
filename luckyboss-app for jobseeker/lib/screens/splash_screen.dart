import 'package:flutter/material.dart';
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
      backgroundColor: AppTheme.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppTheme.emerald, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'Lucky Boss',
              style: AppTheme.serifTitle(fontSize: 32, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Executive Career Network',
              style: AppTheme.sansMedium(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 36),
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