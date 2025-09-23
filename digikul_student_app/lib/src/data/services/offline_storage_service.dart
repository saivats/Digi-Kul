import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../models/user.dart';
import '../models/lecture.dart';
import '../models/cohort.dart';
import '../models/material.dart';
import '../models/poll.dart';
import '../models/quiz.dart';
import '../models/enrollment.dart';

/// Offline storage service using Hive for caching and offline functionality
class OfflineStorageService {
  late Logger _logger;
  
  // Hive boxes
  Box<String>? _userBox;
  Box<String>? _lecturesBox;
  Box<String>? _cohortsBox;
  Box<String>? _materialsBox;
  Box<String>? _pollsBox;
  Box<String>? _settingsBox;
  Box<String>? _cacheBox;
  
  bool _isInitialized = false;

  // Singleton pattern
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;

  OfflineStorageService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }

  bool get isInitialized => _isInitialized;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('Offline storage already initialized');
      return;
    }

    try {
      // Initialize Hive
      await Hive.initFlutter(AppConfig.hiveDatabaseName);
      
      // Open all boxes
      await _openBoxes();
      
      // Clean up old data
      await _cleanupOldData();
      
      _isInitialized = true;
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Offline storage initialized successfully');
      }
    } catch (e) {
      _logger.e('Failed to initialize offline storage: $e');
      rethrow;
    }
  }

  Future<void> _openBoxes() async {
    try {
      _userBox = await Hive.openBox<String>(AppConstants.userBox);
      _lecturesBox = await Hive.openBox<String>(AppConstants.lecturesBox);
      _cohortsBox = await Hive.openBox<String>(AppConstants.cohortsBox);
      _materialsBox = await Hive.openBox<String>(AppConstants.materialsBox);
      _pollsBox = await Hive.openBox<String>(AppConstants.pollsBox);
      _settingsBox = await Hive.openBox<String>(AppConstants.settingsBox);
      _cacheBox = await Hive.openBox<String>(AppConstants.cacheBox);
    } catch (e) {
      _logger.e('Failed to open Hive boxes: $e');
      rethrow;
    }
  }

  Future<void> _cleanupOldData() async {
    try {
      final now = DateTime.now();
      
      // Clean up cache entries older than retention period
      final cacheKeys = _cacheBox!.keys.toList();
      for (final key in cacheKeys) {
        final data = _getCachedData(key.toString());
        if (data != null) {
          final timestamp = DateTime.tryParse(data['timestamp'] ?? '');
          if (timestamp != null && 
              now.difference(timestamp) > AppConfig.offlineDataRetention) {
            await _cacheBox!.delete(key);
          }
        }
      }
      
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Cleaned up old cached data');
      }
    } catch (e) {
      _logger.e('Error cleaning up old data: $e');
    }
  }

  // User data methods
  Future<void> saveUserSession(UserSession session) async {
    _ensureInitialized();
    try {
      await _userBox!.put(AppConstants.userDataKey, jsonEncode(session.toJson()));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved user session');
      }
    } catch (e) {
      _logger.e('Failed to save user session: $e');
      rethrow;
    }
  }

  UserSession? getUserSession() {
    _ensureInitialized();
    try {
      final data = _userBox!.get(AppConstants.userDataKey);
      if (data != null) {
        return UserSession.fromJson(jsonDecode(data));
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get user session: $e');
      return null;
    }
  }

  Future<void> clearUserSession() async {
    _ensureInitialized();
    try {
      await _userBox!.delete(AppConstants.userDataKey);
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Cleared user session');
      }
    } catch (e) {
      _logger.e('Failed to clear user session: $e');
    }
  }

  // Lecture data methods
  Future<void> saveLectures(List<Lecture> lectures) async {
    _ensureInitialized();
    try {
      final data = {
        'lectures': lectures.map((l) => l.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _lecturesBox!.put('available_lectures', jsonEncode(data));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved ${lectures.length} lectures');
      }
    } catch (e) {
      _logger.e('Failed to save lectures: $e');
      rethrow;
    }
  }

  List<Lecture> getCachedLectures() {
    _ensureInitialized();
    try {
      final data = _getCachedData('available_lectures', box: _lecturesBox);
      if (data != null) {
        final lecturesJson = data['lectures'] as List;
        return lecturesJson
            .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Failed to get cached lectures: $e');
      return [];
    }
  }

  Future<void> saveEnrolledLectures(List<Lecture> lectures) async {
    _ensureInitialized();
    try {
      final data = {
        'lectures': lectures.map((l) => l.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _lecturesBox!.put('enrolled_lectures', jsonEncode(data));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved ${lectures.length} enrolled lectures');
      }
    } catch (e) {
      _logger.e('Failed to save enrolled lectures: $e');
      rethrow;
    }
  }

  List<Lecture> getCachedEnrolledLectures() {
    _ensureInitialized();
    try {
      final data = _getCachedData('enrolled_lectures', box: _lecturesBox);
      if (data != null) {
        final lecturesJson = data['lectures'] as List;
        return lecturesJson
            .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Failed to get cached enrolled lectures: $e');
      return [];
    }
  }

  // Cohort data methods
  Future<void> saveCohorts(List<Cohort> cohorts) async {
    _ensureInitialized();
    try {
      final data = {
        'cohorts': cohorts.map((c) => c.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _cohortsBox!.put('student_cohorts', jsonEncode(data));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved ${cohorts.length} cohorts');
      }
    } catch (e) {
      _logger.e('Failed to save cohorts: $e');
      rethrow;
    }
  }

  List<Cohort> getCachedCohorts() {
    _ensureInitialized();
    try {
      final data = _getCachedData('student_cohorts', box: _cohortsBox);
      if (data != null) {
        final cohortsJson = data['cohorts'] as List;
        return cohortsJson
            .map((json) => Cohort.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Failed to get cached cohorts: $e');
      return [];
    }
  }

  // Material data methods
  Future<void> saveLectureMaterials(String lectureId, List<MaterialItem> materials) async {
    _ensureInitialized();
    try {
      final data = {
        'materials': materials.map((m) => m.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _materialsBox!.put('lecture_${lectureId}_materials', jsonEncode(data));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved ${materials.length} materials for lecture $lectureId');
      }
    } catch (e) {
      _logger.e('Failed to save lecture materials: $e');
      rethrow;
    }
  }

  List<MaterialItem> getCachedLectureMaterials(String lectureId) {
    _ensureInitialized();
    try {
      final data = _getCachedData('lecture_${lectureId}_materials', box: _materialsBox);
      if (data != null) {
        final materialsJson = data['materials'] as List;
        return materialsJson
            .map((json) => MaterialItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Failed to get cached lecture materials: $e');
      return [];
    }
  }

  // Downloaded materials tracking
  Future<void> markMaterialAsDownloaded(String materialId, String localPath) async {
    _ensureInitialized();
    try {
      final downloadedMaterials = getDownloadedMaterials();
      downloadedMaterials[materialId] = {
        'local_path': localPath,
        'downloaded_at': DateTime.now().toIso8601String(),
      };
      
      await _materialsBox!.put(
        AppConstants.downloadedLecturesKey,
        jsonEncode(downloadedMaterials),
      );
      
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Marked material $materialId as downloaded');
      }
    } catch (e) {
      _logger.e('Failed to mark material as downloaded: $e');
    }
  }

  Map<String, dynamic> getDownloadedMaterials() {
    _ensureInitialized();
    try {
      final data = _materialsBox!.get(AppConstants.downloadedLecturesKey);
      if (data != null) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
      return {};
    } catch (e) {
      _logger.e('Failed to get downloaded materials: $e');
      return {};
    }
  }

  bool isMaterialDownloaded(String materialId) {
    final downloadedMaterials = getDownloadedMaterials();
    return downloadedMaterials.containsKey(materialId);
  }

  String? getMaterialLocalPath(String materialId) {
    final downloadedMaterials = getDownloadedMaterials();
    return downloadedMaterials[materialId]?['local_path'];
  }

  // Poll data methods
  Future<void> savePolls(List<Poll> polls) async {
    _ensureInitialized();
    try {
      final data = {
        'polls': polls.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _pollsBox!.put('student_polls', jsonEncode(data));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved ${polls.length} polls');
      }
    } catch (e) {
      _logger.e('Failed to save polls: $e');
      rethrow;
    }
  }

  List<Poll> getCachedPolls() {
    _ensureInitialized();
    try {
      final data = _getCachedData('student_polls', box: _pollsBox);
      if (data != null) {
        final pollsJson = data['polls'] as List;
        return pollsJson
            .map((json) => Poll.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Failed to get cached polls: $e');
      return [];
    }
  }

  // Settings methods
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    try {
      await _settingsBox!.put(key, jsonEncode(value));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Saved setting: $key');
      }
    } catch (e) {
      _logger.e('Failed to save setting $key: $e');
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    try {
      final data = _settingsBox!.get(key);
      if (data != null) {
        return jsonDecode(data) as T;
      }
      return defaultValue;
    } catch (e) {
      _logger.e('Failed to get setting $key: $e');
      return defaultValue;
    }
  }

  // Generic cache methods
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    _ensureInitialized();
    try {
      final cacheData = {
        ...data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _cacheBox!.put(key, jsonEncode(cacheData));
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Cached data: $key');
      }
    } catch (e) {
      _logger.e('Failed to cache data $key: $e');
    }
  }

  Map<String, dynamic>? _getCachedData(String key, {Box<String>? box}) {
    _ensureInitialized();
    try {
      final targetBox = box ?? _cacheBox!;
      final data = targetBox.get(key);
      if (data != null) {
        final parsedData = jsonDecode(data) as Map<String, dynamic>;
        final timestamp = DateTime.tryParse(parsedData['timestamp'] ?? '');
        
        // Check if data is still valid
        if (timestamp != null) {
          final age = DateTime.now().difference(timestamp);
          if (age <= AppConfig.cacheValidityDuration) {
            return parsedData;
          } else {
            // Data expired, remove it
            targetBox.delete(key);
          }
        }
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get cached data $key: $e');
      return null;
    }
  }

  // Sync status methods
  Future<void> updateLastSyncTime() async {
    _ensureInitialized();
    await saveSetting(AppConstants.lastSyncTimeKey, DateTime.now().toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = getSetting<String>(AppConstants.lastSyncTimeKey);
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }

  bool needsSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;
    
    final timeSinceSync = DateTime.now().difference(lastSync);
    return timeSinceSync > AppConfig.cacheValidityDuration;
  }

  // Storage info methods
  Future<StorageInfo> getStorageInfo() async {
    _ensureInitialized();
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final totalSpace = await _getTotalSpace(directory.path);
      final freeSpace = await _getFreeSpace(directory.path);
      final usedSpace = totalSpace - freeSpace;
      
      // Calculate cache size
      int cacheSize = 0;
      for (final box in [_userBox, _lecturesBox, _cohortsBox, _materialsBox, _pollsBox, _settingsBox, _cacheBox]) {
        if (box != null) {
          cacheSize += await _getBoxSize(box);
        }
      }
      
      return StorageInfo(
        totalSpace: totalSpace,
        freeSpace: freeSpace,
        usedSpace: usedSpace,
        cacheSize: cacheSize,
      );
    } catch (e) {
      _logger.e('Failed to get storage info: $e');
      return StorageInfo(totalSpace: 0, freeSpace: 0, usedSpace: 0, cacheSize: 0);
    }
  }

  Future<int> _getTotalSpace(String path) async {
    // This is a simplified implementation
    // In a real app, you might use platform-specific code
    return 1024 * 1024 * 1024; // 1GB placeholder
  }

  Future<int> _getFreeSpace(String path) async {
    // This is a simplified implementation
    return 512 * 1024 * 1024; // 512MB placeholder
  }

  Future<int> _getBoxSize(Box<String> box) async {
    int size = 0;
    for (final value in box.values) {
      size += value.length * 2; // Rough estimate (UTF-16)
    }
    return size;
  }

  // Clear cache methods
  Future<void> clearAllCache() async {
    _ensureInitialized();
    try {
      await _cacheBox!.clear();
      await _lecturesBox!.clear();
      await _cohortsBox!.clear();
      await _materialsBox!.clear();
      await _pollsBox!.clear();
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Cleared all cached data');
      }
    } catch (e) {
      _logger.e('Failed to clear cache: $e');
    }
  }

  Future<void> clearExpiredCache() async {
    _ensureInitialized();
    await _cleanupOldData();
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Offline storage service not initialized');
    }
  }

  /// Dispose and close all boxes
  Future<void> dispose() async {
    try {
      await _userBox?.close();
      await _lecturesBox?.close();
      await _cohortsBox?.close();
      await _materialsBox?.close();
      await _pollsBox?.close();
      await _settingsBox?.close();
      await _cacheBox?.close();
      
      _isInitialized = false;
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Offline storage service disposed');
      }
    } catch (e) {
      _logger.e('Error disposing offline storage: $e');
    }
  }
}

/// Storage information model
class StorageInfo {
  final int totalSpace;
  final int freeSpace;
  final int usedSpace;
  final int cacheSize;

  const StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
    required this.cacheSize,
  });

  String get formattedTotalSpace => _formatBytes(totalSpace);
  String get formattedFreeSpace => _formatBytes(freeSpace);
  String get formattedUsedSpace => _formatBytes(usedSpace);
  String get formattedCacheSize => _formatBytes(cacheSize);

  double get usedPercentage => totalSpace > 0 ? (usedSpace / totalSpace) * 100 : 0;
  double get cachePercentage => totalSpace > 0 ? (cacheSize / totalSpace) * 100 : 0;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
