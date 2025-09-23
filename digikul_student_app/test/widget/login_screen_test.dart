import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:digikul_student_app/src/data/repositories/auth_repository.dart';
import 'package:digikul_student_app/src/domain/providers/auth_provider.dart';
import 'package:digikul_student_app/src/presentation/screens/auth/login_screen.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('should display login form elements', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify the presence of key UI elements
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Sign in to continue your learning journey'), findsOneWidget);
      
      // Check for form fields
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      
      // Check for buttons
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      
      // Check for remember me checkbox
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('should validate email field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the login button and tap it without entering email
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show email required validation
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('should validate password field', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter email but leave password empty
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      
      // Tap login button
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show password required validation
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      
      // Tap login button
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show invalid email validation
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate password length', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter valid email and short password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      
      // Tap login button
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show password length validation
      expect(find.text('Password must be at least 6 characters long'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find password field
      final passwordField = find.byType(TextFormField).last;
      
      // Initially password should be obscured
      final textFormField = tester.widget<TextFormField>(passwordField);
      expect(textFormField.obscureText, true);

      // Find and tap the visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);
      
      await tester.tap(visibilityButton);
      await tester.pump();

      // Now it should show the visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('should toggle remember me checkbox', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final checkbox = find.byType(Checkbox);
      
      // Initially unchecked
      Checkbox checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, false);

      // Tap checkbox
      await tester.tap(checkbox);
      await tester.pump();

      // Should be checked now
      checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, true);
    });

    testWidgets('should show loading state during login', (tester) async {
      // Mock the login to take some time
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 1), () => throw Exception('Test')));

      await tester.pumpWidget(createTestWidget());

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap login button
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should navigate to signup when Sign Up is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);

      // Note: In a real test, you would need to mock the router or use integration tests
      // to verify navigation. This test just verifies the button exists.
      await tester.tap(signUpButton);
      await tester.pump();
    });
  });
}
