class AppConstants {
  AppConstants._();

  static const appName = 'Digi-Kul';
  static const appTagline = 'Digital Gurukul';

  static const maxRetryAttempts = 3;
  static const cacheExpirationMinutes = 5;
  static const backgroundRefreshHours = 4;
  static const maxQuizSyncAttempts = 5;

  static const bandwidthCheckIntervalSeconds = 10;
  static const handRaiseAutoLowerSeconds = 30;

  static const bandwidthFullThresholdKbps = 200;
  static const bandwidthAudioThresholdKbps = 30;
  static const rttFullThresholdMs = 300;
  static const rttAudioThresholdMs = 800;

  static const minTouchTargetSize = 48.0;
  static const minBodyTextSize = 14.0;

  static const attendanceWarningThreshold = 75.0;
}
