// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digikul_student_app/main.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DigiKulApp());

    // Verify that the Login Page is displayed.
    expect(find.text('Digi-Kul'), findsOneWidget);
    expect(find.text('Student Portal'), findsOneWidget);

    // Verify that the email and password fields are present.
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);

    // Verify the login button is present
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}