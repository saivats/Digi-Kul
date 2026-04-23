import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class PreferencesService {
  PreferencesService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'PreferencesService not initialized. Call init() first.',
      );
    }
    return _prefs!;
  }

  static Future<void> saveStudentProfile({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String institutionId,
    String? cohortId,
    String? cohortName,
    String? institutionName,
  }) async {
    await _instance.setString(StorageKeys.studentId, studentId);
    await _instance.setString(StorageKeys.studentName, studentName);
    await _instance.setString(StorageKeys.studentEmail, studentEmail);
    await _instance.setString(StorageKeys.institutionId, institutionId);
    if (cohortId != null) {
      await _instance.setString(StorageKeys.cohortId, cohortId);
    }
    if (cohortName != null) {
      await _instance.setString(StorageKeys.cohortName, cohortName);
    }
    if (institutionName != null) {
      await _instance.setString(StorageKeys.institutionName, institutionName);
    }
  }

  static String? get studentId => _instance.getString(StorageKeys.studentId);
  static String? get studentName => _instance.getString(StorageKeys.studentName);
  static String? get studentEmail => _instance.getString(StorageKeys.studentEmail);
  static String? get institutionId => _instance.getString(StorageKeys.institutionId);
  static String? get cohortId => _instance.getString(StorageKeys.cohortId);
  static String? get institutionName =>
      _instance.getString(StorageKeys.institutionName);

  static bool get isDarkMode =>
      _instance.getBool(StorageKeys.themeMode) ?? false;

  static Future<void> setDarkMode(bool value) =>
      _instance.setBool(StorageKeys.themeMode, value);

  static bool get notificationsEnabled =>
      _instance.getBool(StorageKeys.notificationsEnabled) ?? true;

  static Future<void> setNotificationsEnabled(bool value) =>
      _instance.setBool(StorageKeys.notificationsEnabled, value);

  static Future<void> cacheInstitutions(List<Map<String, dynamic>> institutions) async {
    final encoded = jsonEncode(institutions);
    await _instance.setString(StorageKeys.cachedInstitutions, encoded);
  }

  static List<Map<String, dynamic>> getCachedInstitutions() {
    final encoded = _instance.getString(StorageKeys.cachedInstitutions);
    if (encoded == null) return [];
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  static String? get workerAuthToken =>
      _instance.getString(StorageKeys.workerAuthToken);

  static Future<void> setWorkerAuthToken(String token) =>
      _instance.setString(StorageKeys.workerAuthToken, token);

  static Future<void> clearWorkerAuthToken() =>
      _instance.remove(StorageKeys.workerAuthToken);

  static Future<void> clearProfile() async {
    await _instance.remove(StorageKeys.studentId);
    await _instance.remove(StorageKeys.studentName);
    await _instance.remove(StorageKeys.studentEmail);
    await _instance.remove(StorageKeys.institutionId);
    await _instance.remove(StorageKeys.cohortId);
    await _instance.remove(StorageKeys.cohortName);
    await _instance.remove(StorageKeys.institutionName);
  }
}
