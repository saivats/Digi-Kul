import 'package:digikul_student_app/src/core/constants/app_constants.dart';
import 'package:digikul_student_app/src/data/models/user.dart';
import 'package:digikul_student_app/src/data/services/api_service.dart';
import 'package:digikul_student_app/src/data/services/offline_storage_service.dart';

/// Repository for authentication-related operations
class AuthRepository {

  AuthRepository({
    ApiService? apiService,
    OfflineStorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? OfflineStorageService();
  final ApiService _apiService;
  final OfflineStorageService _storageService;

  /// Login with email and password
  Future<UserSession> login(String email, String password) async {
    try {
      final session = await _apiService.login(
        email,
        password,
      );
      
      // Save session locally
      await _storageService.saveUserSession(session);
      
      return session;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      // Always clear local session, even if API call fails
      await _storageService.clearUserSession();
    }
  }

  /// Get current user session
  UserSession? getCurrentSession() {
    return _storageService.getUserSession();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    final session = getCurrentSession();
    return session != null && _apiService.isAuthenticated;
  }

  /// Validate current session with server
  Future<bool> validateSession() async {
    try {
      final sessionData = await _apiService.validateSession();
      if (sessionData != null) {
        final session = UserSession.fromJson(sessionData);
        await _storageService.saveUserSession(session);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Refresh session if needed
  Future<UserSession?> refreshSession() async {
    try {
      if (!isAuthenticated()) {
        return null;
      }

      final sessionData = await _apiService.validateSession();
      if (sessionData != null) {
        final session = UserSession.fromJson(sessionData);
        await _storageService.saveUserSession(session);
        return session;
      }
      
      // Session invalid, clear local data
      await _storageService.clearUserSession();
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await _storageService.clearUserSession();
  }
}
