import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/lecture.dart';
import '../models/enrollment.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

/// Repository for lecture-related operations
class LectureRepository {
  final ApiService _apiService;
  final OfflineStorageService _storageService;
  final Connectivity _connectivity;

  LectureRepository({
    ApiService? apiService,
    OfflineStorageService? storageService,
    Connectivity? connectivity,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? OfflineStorageService(),
        _connectivity = connectivity ?? Connectivity();

  /// Get available lectures (with offline fallback)
  Future<List<Lecture>> getAvailableLectures({bool forceRefresh = false}) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline && (forceRefresh || _storageService.needsSync())) {
        // Fetch from API
        final lectures = await _apiService.getAvailableLectures();
        
        // Cache the results
        await _storageService.saveLectures(lectures);
        await _storageService.updateLastSyncTime();
        
        return lectures;
      } else {
        // Return cached data
        return _storageService.getCachedLectures();
      }
    } catch (e) {
      // Fallback to cached data on error
      final cachedLectures = _storageService.getCachedLectures();
      if (cachedLectures.isNotEmpty) {
        return cachedLectures;
      }
      rethrow;
    }
  }

  /// Get enrolled lectures (with offline fallback)
  Future<List<Lecture>> getEnrolledLectures({bool forceRefresh = false}) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline && (forceRefresh || _storageService.needsSync())) {
        // Fetch from API
        final lectures = await _apiService.getEnrolledLectures();
        
        // Cache the results
        await _storageService.saveEnrolledLectures(lectures);
        await _storageService.updateLastSyncTime();
        
        return lectures;
      } else {
        // Return cached data
        return _storageService.getCachedEnrolledLectures();
      }
    } catch (e) {
      // Fallback to cached data on error
      final cachedLectures = _storageService.getCachedEnrolledLectures();
      if (cachedLectures.isNotEmpty) {
        return cachedLectures;
      }
      rethrow;
    }
  }

  /// Get lecture details
  Future<LectureDetails> getLectureDetails(String lectureId) async {
    try {
      return await _apiService.getLectureDetails(lectureId);
    } catch (e) {
      // Could implement caching for lecture details here
      rethrow;
    }
  }

  /// Enroll in a lecture
  Future<EnrollmentResponse> enrollInLecture(String lectureId) async {
    try {
      final response = await _apiService.enrollInLecture(lectureId);
      
      // Refresh enrolled lectures after successful enrollment
      if (response.success) {
        await getEnrolledLectures(forceRefresh: true);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get active session ID for a lecture
  Future<String?> getActiveSessionId(String lectureId) async {
    try {
      return await _apiService.getActiveSessionId(lectureId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a lecture is currently live
  Future<bool> isLectureActive(String lectureId) async {
    try {
      final sessionId = await getActiveSessionId(lectureId);
      return sessionId != null;
    } catch (e) {
      return false;
    }
  }

  /// Get upcoming lectures from enrolled lectures
  Future<List<Lecture>> getUpcomingLectures() async {
    try {
      final enrolledLectures = await getEnrolledLectures();
      final now = DateTime.now();
      
      return enrolledLectures
          .where((lecture) => lecture.scheduledTime.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    } catch (e) {
      rethrow;
    }
  }

  /// Get live lectures from enrolled lectures
  Future<List<Lecture>> getLiveLectures() async {
    try {
      final enrolledLectures = await getEnrolledLectures();
      final now = DateTime.now();
      
      final liveLectures = <Lecture>[];
      
      for (final lecture in enrolledLectures) {
        final endTime = lecture.scheduledTime.add(Duration(minutes: lecture.duration));
        final isInTimeRange = now.isAfter(lecture.scheduledTime) && now.isBefore(endTime);
        
        if (isInTimeRange) {
          // Check if session is actually active
          final isActive = await isLectureActive(lecture.id);
          if (isActive) {
            liveLectures.add(lecture.copyWith(sessionActive: true));
          }
        }
      }
      
      return liveLectures;
    } catch (e) {
      rethrow;
    }
  }

  /// Get completed lectures from enrolled lectures
  Future<List<Lecture>> getCompletedLectures() async {
    try {
      final enrolledLectures = await getEnrolledLectures();
      final now = DateTime.now();
      
      return enrolledLectures
          .where((lecture) {
            final endTime = lecture.scheduledTime.add(Duration(minutes: lecture.duration));
            return now.isAfter(endTime);
          })
          .toList()
        ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    } catch (e) {
      rethrow;
    }
  }

  /// Search lectures by title or teacher name
  Future<List<Lecture>> searchLectures(String query) async {
    try {
      final lectures = await getAvailableLectures();
      final lowercaseQuery = query.toLowerCase();
      
      return lectures
          .where((lecture) =>
              lecture.title.toLowerCase().contains(lowercaseQuery) ||
              (lecture.teacherName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (lecture.description?.toLowerCase().contains(lowercaseQuery) ?? false))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Filter lectures by subject or teacher
  Future<List<Lecture>> filterLectures({
    String? subject,
    String? teacherId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final lectures = await getAvailableLectures();
      
      return lectures.where((lecture) {
        // Subject filter (if available in lecture data)
        if (subject != null && subject.isNotEmpty) {
          // This would need to be implemented based on how subject data is available
          // For now, we'll skip this filter
        }
        
        // Teacher filter
        if (teacherId != null && lecture.teacherId != teacherId) {
          return false;
        }
        
        // Date range filter
        if (fromDate != null && lecture.scheduledTime.isBefore(fromDate)) {
          return false;
        }
        
        if (toDate != null && lecture.scheduledTime.isAfter(toDate)) {
          return false;
        }
        
        return true;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get lecture statistics for dashboard
  Future<LectureStatistics> getLectureStatistics() async {
    try {
      final enrolledLectures = await getEnrolledLectures();
      final now = DateTime.now();
      
      int upcoming = 0;
      int live = 0;
      int completed = 0;
      
      for (final lecture in enrolledLectures) {
        final endTime = lecture.scheduledTime.add(Duration(minutes: lecture.duration));
        
        if (now.isBefore(lecture.scheduledTime)) {
          upcoming++;
        } else if (now.isAfter(lecture.scheduledTime) && now.isBefore(endTime)) {
          // Check if actually live
          final isActive = await isLectureActive(lecture.id);
          if (isActive) {
            live++;
          } else {
            completed++;
          }
        } else {
          completed++;
        }
      }
      
      return LectureStatistics(
        totalEnrolled: enrolledLectures.length,
        upcoming: upcoming,
        live: live,
        completed: completed,
      );
    } catch (e) {
      return const LectureStatistics(
        totalEnrolled: 0,
        upcoming: 0,
        live: 0,
        completed: 0,
      );
    }
  }

  /// Clear cached lecture data
  Future<void> clearCache() async {
    // This would clear specific lecture cache
    // Implementation depends on how the storage service is structured
  }

  /// Refresh all lecture data
  Future<void> refreshAll() async {
    await Future.wait([
      getAvailableLectures(forceRefresh: true),
      getEnrolledLectures(forceRefresh: true),
    ]);
  }
}

/// Lecture statistics model
class LectureStatistics {
  final int totalEnrolled;
  final int upcoming;
  final int live;
  final int completed;

  const LectureStatistics({
    required this.totalEnrolled,
    required this.upcoming,
    required this.live,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'total_enrolled': totalEnrolled,
        'upcoming': upcoming,
        'live': live,
        'completed': completed,
      };
}
