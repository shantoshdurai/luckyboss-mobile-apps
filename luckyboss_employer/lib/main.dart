import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/employer_provider.dart';
import 'screens/auth/employer_login_screen.dart';

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
        title: 'Lucky Boss Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
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
                  color: Colors.white,
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
        home: const EmployerLoginScreen(),
      ),
    );
  }
}