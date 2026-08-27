import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:luckybossemployer/providers/employer_provider.dart';
import 'package:luckybossemployer/screens/employer_main_navigation_screen.dart';

void main() {
  testWidgets('Employer Main Navigation and Tabs render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EmployerProvider(),
        child: const MaterialApp(
          home: EmployerMainNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EmployerMainNavigationScreen), findsOneWidget);
  });
}