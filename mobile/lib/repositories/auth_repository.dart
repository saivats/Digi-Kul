import 'package:logger/logger.dart';

import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../core/storage/preferences.dart';
import '../core/storage/secure_storage.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<bool> login({
    required String email,
    required String password,
    String? institutionId,
  }) async {
    try {
      final response = await _api.login(
        email: email,
        password: password,
        institutionId: institutionId,
      );

      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (!success) {
        throw AuthException(
          message: data['error'] as String? ?? 'Login failed.',
        );
      }

      final accessToken = data['access_token'] as String?;
      if (accessToken != null) {
        await SecureStorageService.saveAuthToken(accessToken);
      }

      final refreshToken = data['refresh_token'] as String?;
      if (refreshToken != null) {
        await SecureStorageService.saveRefreshToken(refreshToken);
      }

      final userId = data['user_id'] as String? ?? '';
      final userName = data['user_name'] as String? ?? '';
      final userEmail = data['user_email'] as String? ?? email;
      final responseInstitutionId = data['institution_id'] as String? ?? '';
      final cohortId = data['cohort_id'] as String?;

      await PreferencesService.saveStudentProfile(
        studentId: userId,
        studentName: userName,
        studentEmail: userEmail,
        institutionId: responseInstitutionId,
        cohortId: cohortId,
      );

      _logger.i('Login successful for $email');
      return true;
    } on AuthException {
      rethrow;
    } catch (e) {
      _logger.e('Login failed: $e');
      if (e is AppException) rethrow;
      throw const AuthException(message: 'Login failed. Please try again.');
    }
  }

  Future<bool> validateSession() async {
    try {
      final hasToken = await SecureStorageService.hasToken();
      if (!hasToken) return false;

      final response = await _api.validateSession();
      final data = response.data as Map<String, dynamic>;
      return data['valid'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      _logger.w('Logout API call failed, clearing local data anyway');
    } finally {
      await SecureStorageService.clearAuth();
      await PreferencesService.clearProfile();
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String institutionId,
    String? phone,
  }) async {
    try {
      final response = await _api.registerStudent(
        studentData: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'institution_id': institutionId,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (!success) {
        throw ServerException(
          message: data['error'] as String? ?? 'Registration failed.',
        );
      }

      _logger.i('Registration successful for $email');
      return true;
    } catch (e) {
      _logger.e('Registration failed: $e');
      if (e is AppException) rethrow;
      throw const ServerException(message: 'Registration failed.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchInstitutions() async {
    try {
      final response = await _api.getInstitutions();
      final data = response.data as Map<String, dynamic>;
      final institutions = (data['institutions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      await PreferencesService.cacheInstitutions(institutions);
      return institutions;
    } catch (_) {
      return PreferencesService.getCachedInstitutions();
    }
  }
}
