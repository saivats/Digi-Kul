import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

import '../network/api_client.dart';

/// Registers the device's FCM token with the backend
/// (POST /api/students/fcm-token). Silently no-ops when Firebase is not
/// configured for this build, so login never depends on it.
class PushService {
  PushService._();

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  static Future<void> registerTokenIfAvailable(ApiClient api) async {
    try {
      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 8));
      if (token == null || token.isEmpty) return;
      await api.registerFcmToken(
        token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      _logger.i('FCM token registered');
    } catch (e) {
      _logger.w('FCM token registration skipped: $e');
    }
  }
}
