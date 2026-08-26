import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckybossemployer/main.dart';

void main() {
  testWidgets('LuckyBoss Employer App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LuckyBossEmployerApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}