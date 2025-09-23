import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digikul_student_app/models/user.dart';
import 'package:digikul_student_app/services/api_service_new.dart';

// Auth state
class AuthState {

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._apiService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  final ApiService _apiService;

  Future<void> _checkAuthStatus() async {
    if (_apiService.isAuthenticated) {
      state = state.copyWith(user: _apiService.currentUser);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final user = await _apiService.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _apiService.logout();
      state = const AuthState();
    } catch (e) {
      // Even if logout fails, clear the state
      state = const AuthState();
    }
  }

  void clearError() {
    state = state.copyWith();
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

// Helper providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
