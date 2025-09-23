import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:digikul_student_app/src/data/models/user.dart';
import 'package:digikul_student_app/src/data/repositories/auth_repository.dart';
import 'package:digikul_student_app/src/domain/providers/auth_provider.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthNotifier', () {
    late MockAuthRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be not authenticated', () {
      when(() => mockRepository.getCurrentSession()).thenReturn(null);
      when(() => mockRepository.validateSession()).thenAnswer((_) async => false);

      final authState = container.read(authStateProvider);

      expect(authState.isAuthenticated, false);
      expect(authState.user, null);
      expect(authState.isLoading, false);
    });

    test('login should update state on success', () async {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test User',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      when(() => mockRepository.login(any(), any()))
          .thenAnswer((_) async => testSession);

      final notifier = container.read(authStateProvider.notifier);
      final result = await notifier.login('test@example.com', 'password');

      expect(result, true);
      expect(container.read(authStateProvider).isAuthenticated, true);
      expect(container.read(authStateProvider).user?.userName, 'Test User');
      verify(() => mockRepository.login('test@example.com', 'password')).called(1);
    });

    test('login should handle errors properly', () async {
      when(() => mockRepository.login(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      final notifier = container.read(authStateProvider.notifier);
      final result = await notifier.login('test@example.com', 'wrong-password');

      expect(result, false);
      expect(container.read(authStateProvider).isAuthenticated, false);
      expect(container.read(authStateProvider).error, isNotNull);
    });

    test('logout should clear state', () async {
      // Setup initial authenticated state
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test User',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      when(() => mockRepository.login(any(), any()))
          .thenAnswer((_) async => testSession);
      when(() => mockRepository.logout()).thenAnswer((_) async {});

      final notifier = container.read(authStateProvider.notifier);
      
      // Login first
      await notifier.login('test@example.com', 'password');
      expect(container.read(authStateProvider).isAuthenticated, true);

      // Then logout
      await notifier.logout();
      
      expect(container.read(authStateProvider).isAuthenticated, false);
      expect(container.read(authStateProvider).user, null);
      verify(() => mockRepository.logout()).called(1);
    });

    test('validateSession should refresh user data', () async {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Updated User',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      when(() => mockRepository.validateSession()).thenAnswer((_) async => true);
      when(() => mockRepository.refreshSession()).thenAnswer((_) async => testSession);

      final notifier = container.read(authStateProvider.notifier);
      final result = await notifier.refreshSession();

      expect(result, true);
      verify(() => mockRepository.refreshSession()).called(1);
    });

    test('convenience providers should return correct values', () {
      final testSession = UserSession(
        userId: 'test-id',
        userType: 'student',
        userName: 'Test User',
        userEmail: 'test@example.com',
        loginTime: DateTime.now(),
      );

      when(() => mockRepository.getCurrentSession()).thenReturn(testSession);
      when(() => mockRepository.validateSession()).thenAnswer((_) async => true);

      // Manually set the state for testing convenience providers
      container.read(authStateProvider.notifier).state = 
          container.read(authStateProvider).copyWith(user: testSession);

      expect(container.read(currentUserProvider), testSession);
      expect(container.read(isAuthenticatedProvider), true);
      expect(container.read(isStudentProvider), true);
      expect(container.read(isTeacherProvider), false);
      expect(container.read(userNameProvider), 'Test User');
      expect(container.read(userTypeProvider), 'student');
    });
  });
}
