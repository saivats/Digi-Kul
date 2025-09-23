import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:digikul_student_app/main.dart' as app;
import 'package:digikul_student_app/src/data/models/user.dart';
import 'package:digikul_student_app/src/data/repositories/auth_repository.dart';
import 'package:digikul_student_app/src/domain/providers/auth_provider.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    testWidgets('complete login flow', (tester) async {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test Student',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      // Mock successful login
      when(() => mockAuthRepository.getCurrentSession()).thenReturn(null);
      when(() => mockAuthRepository.validateSession()).thenAnswer((_) async => false);
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) async => testSession);

      // Start the app with mocked dependencies
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const app.DigiKulApp(),
        ),
      );

      // Wait for splash screen to complete
      await tester.pumpAndSettle();

      // Should be on login screen since not authenticated
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should navigate to dashboard after successful login
      expect(find.text('Welcome, Test Student'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget); // Bottom nav item

      // Verify login was called with correct parameters
      verify(() => mockAuthRepository.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('login with invalid credentials shows error', (tester) async {
      // Mock failed login
      when(() => mockAuthRepository.getCurrentSession()).thenReturn(null);
      when(() => mockAuthRepository.validateSession()).thenAnswer((_) async => false);
      when(() => mockAuthRepository.login(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      // Start the app with mocked dependencies
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const app.DigiKulApp(),
        ),
      );

      // Wait for splash screen to complete
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrongpassword',
      );

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Login failed'), findsOneWidget);

      // Should still be on login screen
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('logout flow', (tester) async {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test Student',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      // Mock authenticated state
      when(() => mockAuthRepository.getCurrentSession()).thenReturn(testSession);
      when(() => mockAuthRepository.validateSession()).thenAnswer((_) async => true);
      when(() => mockAuthRepository.logout()).thenAnswer((_) async {});

      // Start the app with mocked dependencies
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const app.DigiKulApp(),
        ),
      );

      // Wait for splash screen and navigation to dashboard
      await tester.pumpAndSettle();

      // Should be on dashboard
      expect(find.text('Welcome, Test Student'), findsOneWidget);

      // Tap on profile menu
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm logout in dialog
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // Should navigate back to login screen
      expect(find.text('Welcome Back!'), findsOneWidget);

      // Verify logout was called
      verify(() => mockAuthRepository.logout()).called(1);
    });

    testWidgets('session validation on app start', (tester) async {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test Student',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      // Mock existing session that is valid
      when(() => mockAuthRepository.getCurrentSession()).thenReturn(testSession);
      when(() => mockAuthRepository.validateSession()).thenAnswer((_) async => true);

      // Start the app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const app.DigiKulApp(),
        ),
      );

      // Wait for splash screen and session validation
      await tester.pumpAndSettle();

      // Should navigate directly to dashboard since session is valid
      expect(find.text('Welcome, Test Student'), findsOneWidget);

      // Verify session validation was called
      verify(() => mockAuthRepository.validateSession()).called(1);
    });

    testWidgets('invalid session redirects to login', (tester) async {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test Student',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      // Mock existing session that is invalid
      when(() => mockAuthRepository.getCurrentSession()).thenReturn(testSession);
      when(() => mockAuthRepository.validateSession()).thenAnswer((_) async => false);
      when(() => mockAuthRepository.clearAuthData()).thenAnswer((_) async {});

      // Start the app
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
          child: const app.DigiKulApp(),
        ),
      );

      // Wait for splash screen and session validation
      await tester.pumpAndSettle();

      // Should redirect to login screen since session is invalid
      expect(find.text('Welcome Back!'), findsOneWidget);

      // Verify session validation was called
      verify(() => mockAuthRepository.validateSession()).called(1);
    });
  });
}
