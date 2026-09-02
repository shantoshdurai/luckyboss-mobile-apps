import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/launch_loader.dart';
import '../providers/job_seeker_provider.dart';
import '../services/auth_service.dart';
import '../services/profile_sync_service.dart';
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
    final isProfileDone = await ProfileSyncService.isCompleteOnServer();

    if (!mounted) return;

    // Read the device copy before deciding where to send them. This is the
    // only source on a standalone install, and it has to happen before the
    // routing below — a returning candidate whose profile has not been loaded
    // yet looks exactly like a brand new one and gets sent back through the
    // whole wizard.
    await provider.hydrateFromDevice();
    if (!mounted) return;

    // The job catalogue, before the feed is ever built. Loading it lazily from
    // the feed screen means a candidate reaches the home tab and watches an
    // empty list fill in, which reads as "no jobs" for as long as it lasts.
    await provider.loadJobs();
    if (!mounted) return;

    // Then let the server fill in anything it knows that the device does not.
    // Never the other way round: what the candidate last typed on this handset
    // is newer than whatever was last pushed.
    if (session != null) {
      // Guarded on purpose. Everything below this point is what actually gets
      // the candidate off the splash screen, and a single bad field in a
      // server payload must never be able to strand them there. A failed
      // hydrate means "we did not learn anything new", not "stop".
      try {
        await provider.hydrateProfile();
      } catch (e) {
        debugPrint('[Splash] profile hydrate failed, continuing: $e');
      }
      if (!mounted) return;
    }

    if (session != null && isProfileDone) {
      // Returning candidate with a complete profile — straight into the app.
      await provider.checkAuthStatus();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (session != null && provider.profile.skills.isNotEmpty) {
      // Server or local storage had a usable profile with skills
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (session != null) {
      // Signed in but setup unfinished — resume the wizard
      provider.setAuthenticated(true, phone: session.phone);
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