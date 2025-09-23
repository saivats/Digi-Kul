import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:digikul_student_app/src/data/models/user.dart';
import 'package:digikul_student_app/src/data/repositories/auth_repository.dart';
import 'package:digikul_student_app/src/data/services/api_service.dart';
import 'package:digikul_student_app/src/data/services/offline_storage_service.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiService: ref.read(apiServiceProvider),
    storageService: ref.read(offlineStorageServiceProvider),
  );
});

// Service providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final offlineStorageServiceProvider = Provider<OfflineStorageService>((ref) {
  return OfflineStorageService();
});

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Current user provider
final currentUserProvider = Provider<UserSession?>((ref) {
  return ref.watch(authStateProvider).user;
});

// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

// Loading state provider
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});

// Error state provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});

/// Authentication state model
class AuthState {

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });
  final UserSession? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserSession? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() {
    return 'AuthState{user: ${user?.userName}, isLoading: $isLoading, error: $error, isInitialized: $isInitialized}';
  }
}

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {

  AuthNotifier(this._authRepository) 
      : _logger = Logger(),
        super(const AuthState()) {
    _initialize();
  }
  final AuthRepository _authRepository;
  final Logger _logger;

  /// Initialize authentication state
  Future<void> _initialize() async {
    try {
      // Check if user is already authenticated
      final session = _authRepository.getCurrentSession();
      if (session != null) {
        // Validate session with server
        final isValid = await _authRepository.validateSession();
        if (isValid) {
          final updatedSession = _authRepository.getCurrentSession();
          state = state.copyWith(
            user: updatedSession,
            isInitialized: true,
          );
          _logger.i('User session restored: ${updatedSession?.userName}');
        } else {
          // Session invalid, clear it
          await _authRepository.clearAuthData();
          state = state.copyWith(
            isInitialized: true,
            clearUser: true,
          );
          _logger.w('Stored session was invalid, cleared');
        }
      } else {
        state = state.copyWith(isInitialized: true);
        _logger.d('No stored session found');
      }
    } catch (e) {
      _logger.e('Error initializing auth state: $e');
      state = state.copyWith(
        error: 'Failed to initialize authentication',
        isInitialized: true,
        clearUser: true,
      );
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _logger.d('Attempting login for: $email');
      
      final session = await _authRepository.login(email, password);
      
      state = state.copyWith(
        user: session,
        isLoading: false,
        clearError: true,
      );
      
      _logger.i('Login successful: ${session.userName}');
      return true;
    } catch (e) {
      _logger.e('Login failed: $e');
      
      var errorMessage = 'Login failed';
      if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'Invalid email or password';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        clearUser: true,
      );
      
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      _logger.d('Logging out user: ${state.user?.userName}');
      
      await _authRepository.logout();
      
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        clearError: true,
      );
      
      _logger.i('Logout successful');
    } catch (e) {
      _logger.e('Logout error: $e');
      
      // Even if logout fails on server, clear local state
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        error: 'Logout completed with warnings',
      );
    }
  }

  /// Refresh current session
  Future<bool> refreshSession() async {
    if (state.isLoading || !state.isAuthenticated) return false;

    try {
      _logger.d('Refreshing session for: ${state.user?.userName}');
      
      final session = await _authRepository.refreshSession();
      if (session != null) {
        state = state.copyWith(user: session, clearError: true);
        _logger.d('Session refreshed successfully');
        return true;
      } else {
        // Session invalid, logout
        state = state.copyWith(clearUser: true, clearError: true);
        _logger.w('Session refresh failed, user logged out');
        return false;
      }
    } catch (e) {
      _logger.e('Session refresh error: $e');
      return false;
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    if (!state.isAuthenticated) return false;

    try {
      return await _authRepository.validateSession();
    } catch (e) {
      _logger.e('Session validation error: $e');
      return false;
    }
  }

  /// Clear authentication error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Force logout (without API call)
  void forceLogout() {
    _authRepository.clearAuthData();
    state = state.copyWith(
      clearUser: true,
      clearError: true,
      isLoading: false,
    );
    _logger.i('Force logout completed');
  }

  /// Check if authentication is required
  bool requiresAuthentication() {
    return !state.isAuthenticated || !state.isInitialized;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return state.user?.userId;
  }

  /// Get current user type
  String? getCurrentUserType() {
    return state.user?.userType;
  }

  /// Get current user name
  String? getCurrentUserName() {
    return state.user?.userName;
  }

  /// Check if current user is student
  bool isStudent() {
    return state.user?.isStudent ?? false;
  }

  /// Check if current user is teacher
  bool isTeacher() {
    return state.user?.isTeacher ?? false;
  }

  /// Check if current user is admin
  bool isAdmin() {
    return state.user?.isAdmin ?? false;
  }
}

/// Convenience providers for common auth checks
final requiresAuthProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return !authState.isAuthenticated || !authState.isInitialized;
});

final userTypeProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.userType;
});

final userNameProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.userName;
});

final isStudentProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isStudent ?? false;
});

final isTeacherProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isTeacher ?? false;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdmin ?? false;
});
