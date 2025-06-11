import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habitfit_new/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HabitFitApp());

    // Since the counter widget no longer exists in HabitFitApp,
    // you can either remove this test or write a new one for login/dashboard.
    // Here's a dummy test just to ensure the app runs and shows login:
    expect(find.text('Login to HabitFit'), findsOneWidget);
  });
}
