import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  static Future<String?> getAuthToken() async {
    return _storage.read(key: StorageKeys.authToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  static Future<void> saveSessionCookie(String cookie) async {
    await _storage.write(key: StorageKeys.sessionCookie, value: cookie);
  }

  static Future<String?> getSessionCookie() async {
    return _storage.read(key: StorageKeys.sessionCookie);
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.sessionCookie);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> hasToken() async {
    final token = await getAuthToken();
    final cookie = await getSessionCookie();
    return (token != null && token.isNotEmpty) ||
        (cookie != null && cookie.isNotEmpty);
  }
}
