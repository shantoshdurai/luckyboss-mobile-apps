import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/keyboard_dismisser.dart';
import 'core/theme/app_theme.dart';
import 'providers/job_seeker_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_identity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Awaited rather than fired and forgotten: the sign-in screen asks whether
  // Google and phone sign-in are available, and a race there would show the
  // buttons disabled on a build where they work perfectly.
  //
  // This never throws. A missing or wrong Firebase config leaves
  // FirebaseIdentityService.isAvailable false and the app falls back to email
  // and password, which is the whole point of initialising it here rather than
  // lazily at the first tap.
  await FirebaseIdentityService.initialise();
  runApp(const LuckyBossJobSeekerApp());
}

/// Lets a mouse drag a horizontal list.
///
/// Flutter's default scroll behaviour only accepts touch and stylus for drags —
/// on web a mouse can scroll vertically with the wheel but cannot grab a
/// horizontal strip at all, so the profile boost cards, the category strip and
/// the filter chips all appeared frozen. Adding mouse and trackpad to
/// dragDevices is the supported fix and applies everywhere at once.
class _DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class LuckyBossJobSeekerApp extends StatelessWidget {
  const LuckyBossJobSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobSeekerProvider()),
        // Loaded eagerly so the very first frame already respects the stored
        // preference — deferring it makes the app flash light before going dark.
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
        title: 'Luckyboss',
        debugShowCheckedModeBanner: false,
        // One observer instead of an unfocus call at every navigation point.
        // See KeyboardDismisser — fixing this per screen is how it kept coming
        // back.
        navigatorObservers: [KeyboardDismisser()],
        scrollBehavior: _DragScrollBehavior(),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.mode,
        builder: (context, child) {
          final isDesktop = MediaQuery.of(context).size.width > 500;
          if (!isDesktop) return child!;

          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 900),
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
        home: const SplashScreen(),
        ),
      ),
    );
  }
}