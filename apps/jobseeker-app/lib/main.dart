import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/job_seeker_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LuckyBossJobSeekerApp());
}

class LuckyBossJobSeekerApp extends StatelessWidget {
  const LuckyBossJobSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobSeekerProvider()),
      ],
      child: Consumer<JobSeekerProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Lucky Boss',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
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
                      color: provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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
          );
        },
      ),
    );
  }
}