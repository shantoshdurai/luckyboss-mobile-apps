import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/keyboard_dismisser.dart';
import 'core/theme/app_theme.dart';
import 'providers/employer_provider.dart';
import 'screens/auth/employer_login_screen.dart';
import 'screens/employer_main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LuckyBossEmployerApp());
}

class LuckyBossEmployerApp extends StatelessWidget {
  const LuckyBossEmployerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployerProvider()),
      ],
      child: MaterialApp(
        title: 'LuckyBoss Employer',
        debugShowCheckedModeBanner: false,
        // One observer instead of an unfocus call at every navigation point.
        // See KeyboardDismisser — fixing this per screen is how it kept coming
        // back.
        navigatorObservers: [KeyboardDismisser()],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          // A phone-shaped frame on a wide screen. The app is designed for a
          // handset, and stretching a 400px layout across a monitor makes it
          // look broken in review.
          final isDesktop = MediaQuery.of(context).size.width > 500;
          if (!isDesktop) return child!;

          return Scaffold(
            backgroundColor: const Color(0xFF14100C),
            body: Center(
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 420, maxHeight: 900),
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child!,
              ),
            ),
          );
        },
        home: const EmployerLaunchGate(),
      ),
    );
  }
}

/// Reads what is on the device before deciding which screen to show.
///
/// The app used to open straight onto the login form every launch, because
/// there was nothing to read — the provider held its state in memory alone. Now
/// a recruiter who signed in yesterday lands on their dashboard with their jobs
/// and their pipeline intact, which is the whole point of the app persisting
/// anything at all.
class EmployerLaunchGate extends StatefulWidget {
  const EmployerLaunchGate({super.key});

  @override
  State<EmployerLaunchGate> createState() => _EmployerLaunchGateState();
}

class _EmployerLaunchGateState extends State<EmployerLaunchGate> {
  bool _ready = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final provider = context.read<EmployerProvider>();
    await provider.hydrate();
    if (!mounted) return;

    // A stored company is what "signed in" means on a standalone build: it is
    // written only after a successful sign-in, and cleared on sign-out.
    setState(() {
      _signedIn = provider.company.email.isNotEmpty;
      if (_signedIn) provider.setAuthenticated(true);
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: AppTheme.paperOf(context),
        body: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _signedIn
        ? const EmployerMainNavigationScreen()
        : const EmployerLoginScreen();
  }
}
