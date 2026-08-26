import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/job_seeker_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation_screen.dart';

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
      child: MaterialApp(
        title: 'Lucky Boss — Job Seeker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}