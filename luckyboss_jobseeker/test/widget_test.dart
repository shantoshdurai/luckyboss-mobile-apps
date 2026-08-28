import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:luckyboss_jobseeker/providers/job_seeker_provider.dart';
import 'package:luckyboss_jobseeker/screens/main_navigation_screen.dart';

void main() {
  testWidgets('LuckyBoss Job Seeker Navigation and Tabs smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => JobSeekerProvider(),
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });
}