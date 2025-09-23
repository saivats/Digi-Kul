import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/cohort.dart';
import '../models/lecture.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

/// Repository for cohort-related operations
class CohortRepository {
  final ApiService _apiService;
  final OfflineStorageService _storageService;
  final Connectivity _connectivity;

  CohortRepository({
    ApiService? apiService,
    OfflineStorageService? storageService,
    Connectivity? connectivity,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? OfflineStorageService(),
        _connectivity = connectivity ?? Connectivity();

  /// Get student's cohorts (with offline fallback)
  Future<List<Cohort>> getStudentCohorts({bool forceRefresh = false}) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline && (forceRefresh || _storageService.needsSync())) {
        // Fetch from API
        final cohorts = await _apiService.getStudentCohorts();
        
        // Cache the results
        await _storageService.saveCohorts(cohorts);
        await _storageService.updateLastSyncTime();
        
        return cohorts;
      } else {
        // Return cached data
        return _storageService.getCachedCohorts();
      }
    } catch (e) {
      // Fallback to cached data on error
      final cachedCohorts = _storageService.getCachedCohorts();
      if (cachedCohorts.isNotEmpty) {
        return cachedCohorts;
      }
      rethrow;
    }
  }

  /// Join a cohort by code
  Future<CohortJoinResponse> joinCohortByCode(String cohortCode) async {
    try {
      final response = await _apiService.joinCohortByCode(cohortCode);
      
      // Refresh cohorts after successful join
      if (response.success) {
        await getStudentCohorts(forceRefresh: true);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get lectures for a specific cohort
  Future<List<Lecture>> getCohortLectures(String cohortId) async {
    try {
      return await _apiService.getCohortLectures(cohortId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get cohort details by ID
  Future<Cohort?> getCohortById(String cohortId) async {
    try {
      final cohorts = await getStudentCohorts();
      return cohorts.firstWhere(
        (cohort) => cohort.id == cohortId,
        orElse: () => throw Exception('Cohort not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search cohorts by name or subject
  Future<List<Cohort>> searchCohorts(String query) async {
    try {
      final cohorts = await getStudentCohorts();
      final lowercaseQuery = query.toLowerCase();
      
      return cohorts
          .where((cohort) =>
              cohort.name.toLowerCase().contains(lowercaseQuery) ||
              cohort.subject.toLowerCase().contains(lowercaseQuery) ||
              (cohort.teacherName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (cohort.description?.toLowerCase().contains(lowercaseQuery) ?? false))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Filter cohorts by subject
  Future<List<Cohort>> filterCohortsBySubject(String subject) async {
    try {
      final cohorts = await getStudentCohorts();
      return cohorts
          .where((cohort) => 
              cohort.subject.toLowerCase() == subject.toLowerCase())
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get cohorts grouped by subject
  Future<Map<String, List<Cohort>>> getCohortsGroupedBySubject() async {
    try {
      final cohorts = await getStudentCohorts();
      final groupedCohorts = <String, List<Cohort>>{};
      
      for (final cohort in cohorts) {
        if (!groupedCohorts.containsKey(cohort.subject)) {
          groupedCohorts[cohort.subject] = [];
        }
        groupedCohorts[cohort.subject]!.add(cohort);
      }
      
      return groupedCohorts;
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent cohort activity
  Future<List<CohortActivity>> getRecentCohortActivity() async {
    try {
      final cohorts = await getStudentCohorts();
      final activities = <CohortActivity>[];
      
      for (final cohort in cohorts) {
        try {
          final lectures = await getCohortLectures(cohort.id);
          
          // Get recent lectures (last 7 days)
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          
          final recentLectures = lectures
              .where((lecture) => lecture.scheduledTime.isAfter(weekAgo))
              .toList();
          
          if (recentLectures.isNotEmpty) {
            activities.add(CohortActivity(
              cohortId: cohort.id,
              cohortName: cohort.name,
              activityType: CohortActivityType.newLectures,
              activityCount: recentLectures.length,
              lastActivity: recentLectures
                  .map((l) => l.scheduledTime)
                  .reduce((a, b) => a.isAfter(b) ? a : b),
            ));
          }
        } catch (e) {
          // Skip this cohort if we can't get its lectures
          continue;
        }
      }
      
      // Sort by most recent activity
      activities.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      
      return activities;
    } catch (e) {
      return [];
    }
  }

  /// Get cohort statistics
  Future<CohortStatistics> getCohortStatistics() async {
    try {
      final cohorts = await getStudentCohorts();
      final subjects = cohorts.map((c) => c.subject).toSet();
      
      int totalLectures = 0;
      for (final cohort in cohorts) {
        try {
          final lectures = await getCohortLectures(cohort.id);
          totalLectures += lectures.length;
        } catch (e) {
          // Skip if can't get lectures for this cohort
        }
      }
      
      return CohortStatistics(
        totalCohorts: cohorts.length,
        totalSubjects: subjects.length,
        totalLectures: totalLectures,
        subjects: subjects.toList(),
      );
    } catch (e) {
      return const CohortStatistics(
        totalCohorts: 0,
        totalSubjects: 0,
        totalLectures: 0,
        subjects: [],
      );
    }
  }

  /// Validate cohort code format
  bool isValidCohortCode(String code) {
    // Basic validation - should be 6-8 alphanumeric characters
    final regex = RegExp(r'^[A-Z0-9]{6,8}$');
    return regex.hasMatch(code.toUpperCase());
  }

  /// Clear cached cohort data
  Future<void> clearCache() async {
    // Implementation would depend on storage service structure
  }

  /// Refresh all cohort data
  Future<void> refreshAll() async {
    await getStudentCohorts(forceRefresh: true);
  }
}

/// Cohort activity model
class CohortActivity {
  final String cohortId;
  final String cohortName;
  final CohortActivityType activityType;
  final int activityCount;
  final DateTime lastActivity;

  const CohortActivity({
    required this.cohortId,
    required this.cohortName,
    required this.activityType,
    required this.activityCount,
    required this.lastActivity,
  });

  String get description {
    switch (activityType) {
      case CohortActivityType.newLectures:
        return activityCount == 1
            ? '1 new lecture'
            : '$activityCount new lectures';
      case CohortActivityType.newMaterials:
        return activityCount == 1
            ? '1 new material'
            : '$activityCount new materials';
      case CohortActivityType.newPolls:
        return activityCount == 1
            ? '1 new poll'
            : '$activityCount new polls';
    }
  }
}

enum CohortActivityType {
  newLectures,
  newMaterials,
  newPolls,
}

/// Cohort statistics model
class CohortStatistics {
  final int totalCohorts;
  final int totalSubjects;
  final int totalLectures;
  final List<String> subjects;

  const CohortStatistics({
    required this.totalCohorts,
    required this.totalSubjects,
    required this.totalLectures,
    required this.subjects,
  });

  Map<String, dynamic> toJson() => {
        'total_cohorts': totalCohorts,
        'total_subjects': totalSubjects,
        'total_lectures': totalLectures,
        'subjects': subjects,
      };
}
