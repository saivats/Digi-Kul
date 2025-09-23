/// Application configuration and constants
class AppConfig {
  // API Configuration
  static const String defaultApiBaseUrl = 'http://192.168.29.104:5000';
  static const String apiVersion = 'v1';
  
  // Network Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // WebRTC Configuration
  static const Map<String, dynamic> rtcConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
  };
  
  // Socket.IO Configuration
  static const String socketNamespace = '/';
  static const bool autoConnect = false;
  static const Duration reconnectionDelay = Duration(seconds: 2);
  static const int maxReconnectionAttempts = 5;
  
  // Storage Configuration
  static const String hiveDatabaseName = 'digikul_db';
  static const String isarDatabaseName = 'digikul.isar';
  
  // Cache Configuration
  static const Duration cacheValidityDuration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Audio Configuration
  static const int audioQualityKbps = 64; // Low bandwidth optimized
  static const int audioSampleRate = 22050; // Reduced for bandwidth
  
  // File Download Configuration
  static const String downloadsFolder = 'digikul_downloads';
  static const int maxDownloadRetries = 3;
  static const Duration downloadTimeout = Duration(minutes: 10);
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Offline Configuration
  static const Duration offlineDataRetention = Duration(days: 30);
  static const int maxOfflineLectures = 10;
  
  // Security Configuration
  static const Duration sessionTimeout = Duration(hours: 8);
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = false; // Disabled for privacy
  static const bool enableCrashReporting = false; // Disabled for privacy
  
  // Environment Detection
  static bool get isDebug {
    var debug = false;
    assert(debug = true);
    return debug;
  }
  
  static bool get isProduction => !isDebug;
  
  // App Information
  static const String appName = 'Digi-Kul';
  static const String appDescription = 'Audio-first Educational Platform';
  static const String supportEmail = 'support@digikul.com';
  static const String privacyPolicyUrl = 'https://digikul.com/privacy';
  static const String termsOfServiceUrl = 'https://digikul.com/terms';
}

/// Environment-specific configuration
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment current = Environment.development;
  
  static String get apiBaseUrl {
    switch (current) {
      case Environment.development:
        return AppConfig.defaultApiBaseUrl;
      case Environment.staging:
        return 'https://staging-api.digikul.com';
      case Environment.production:
        return 'https://api.digikul.com';
    }
  }
  
  static String get socketUrl {
    switch (current) {
      case Environment.development:
        return AppConfig.defaultApiBaseUrl;
      case Environment.staging:
        return 'https://staging-api.digikul.com';
      case Environment.production:
        return 'https://api.digikul.com';
    }
  }
  
  static bool get enableLogging {
    switch (current) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }
}
