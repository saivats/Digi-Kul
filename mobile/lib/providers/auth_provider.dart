import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/core_providers.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepository) : super(const AuthState());

  final AuthRepository _authRepository;
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    final isValid = await _authRepository.validateSession();
    state = state.copyWith(
      status: isValid ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login({
    required String email,
    required String password,
    String? institutionId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authRepository.login(
        email: email,
        password: password,
        institutionId: institutionId,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      _logger.e('Auth login error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
