import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/launch_loader.dart';
import '../providers/job_seeker_provider.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';
import 'onboarding/profile_wizard_screen.dart';

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
        // Long enough to read one line. Auth and profile checks finish well before
    // this, so the wait is deliberate rather than the app being slow.
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final provider = Provider.of<JobSeekerProvider>(context, listen: false);
    final session = await AuthService.currentSession();
    final isProfileDone = await AuthService.isProfileComplete();

    if (!mounted) return;

    // Pull the stored profile before deciding where to send them. Without this
    // a returning candidate with a complete server-side profile was routed back
    // into the wizard and asked for everything again.
    if (session != null) {
      await provider.hydrateProfile();
      if (!mounted) return;
    }

    if (session != null && (isProfileDone || session.isDemo)) {
      // Returning candidate with a complete profile, or the demo account whose
      // profile is already seeded — straight into the app.
      await provider.checkAuthStatus();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (session != null && provider.profile.skills.isNotEmpty) {
      // Server had a usable profile even though this device had not recorded
      // the wizard as finished.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (session != null) {
      // Signed in but setup unfinished — resume the wizard where they left it.
      provider.setAuthenticated(true, phone: session.phone);
      provider.setDemoMode(session.isDemo);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Pass the real number or nothing at all. The placeholder that used
          // to sit here put a stranger's phone number on a candidate's setup
          // screen as though it were their own.
          builder: (_) => const ProfileWizardScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const LaunchLoader();
}