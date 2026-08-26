import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckyboss_jobseeker/main.dart';

void main() {
  testWidgets('LuckyBoss Job Seeker App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LuckyBossJobSeekerApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}