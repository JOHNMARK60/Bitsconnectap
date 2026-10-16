import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bits_mobile_app/app/routes.dart';

void main() {
  testWidgets('BITS app starts on the public landing flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.landing,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BITSConnect'), findsWidgets);
    expect(find.text('v2.0.0+5'), findsOneWidget);
  });

  testWidgets('/login shows the CampusHub landing page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('BITSConnect'), findsWidgets);
    expect(
      find.text('Manage your campus smarter with BITSConnect'),
      findsOneWidget,
    );
    expect(find.text('Welcome to BITSConnect'), findsNothing);
  });

  testWidgets('landing CTA opens login form modal', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 5000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Login to Portal'));
    await tester.pumpAndSettle();

    expect(find.text('Login Portal'), findsOneWidget);
    expect(find.text('Access your BITSConnect dashboard.'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'student@bits-edu.com'),
      findsOneWidget,
    );
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(
      find.text("Don't have an account? Contact Administration"),
      findsOneWidget,
    );
    expect(find.text('BITSConnect'), findsWidgets);
    expect(find.text('Welcome to BITSConnect'), findsNothing);
  });
}
