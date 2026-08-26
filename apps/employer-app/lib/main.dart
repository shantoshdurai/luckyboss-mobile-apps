import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: 'Lucky Boss — Employer Recruiter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const EmployerLoginScreen(),
      ),
    );
  }
}