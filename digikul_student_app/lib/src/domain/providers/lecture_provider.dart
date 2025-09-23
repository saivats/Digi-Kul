import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/models/lecture.dart';
import '../../data/models/enrollment.dart';
import '../../data/repositories/lecture_repository.dart';
import 'auth_provider.dart';

// Repository provider
final lectureRepositoryProvider = Provider<LectureRepository>((ref) {
  return LectureRepository();
});

// Available lectures provider
final availableLecturesProvider = StateNotifierProvider<AvailableLecturesNotifier, AsyncValue<List<Lecture>>>((ref) {
  return AvailableLecturesNotifier(ref.read(lectureRepositoryProvider));
});

// Enrolled lectures provider
final enrolledLecturesProvider = StateNotifierProvider<EnrolledLecturesNotifier, AsyncValue<List<Lecture>>>((ref) {
  return EnrolledLecturesNotifier(ref.read(lectureRepositoryProvider));
});

// Live lectures provider
final liveLecturesProvider = FutureProvider<List<Lecture>>((ref) async {
  final repository = ref.read(lectureRepositoryProvider);
  return repository.getLiveLectures();
});

// Upcoming lectures provider
final upcomingLecturesProvider = FutureProvider<List<Lecture>>((ref) async {
  final repository = ref.read(lectureRepositoryProvider);
  return repository.getUpcomingLectures();
});

// Completed lectures provider
final completedLecturesProvider = FutureProvider<List<Lecture>>((ref) async {
  final repository = ref.read(lectureRepositoryProvider);
  return repository.getCompletedLectures();
});

// Lecture statistics provider
final lectureStatisticsProvider = FutureProvider<LectureStatistics>((ref) async {
  final repository = ref.read(lectureRepositoryProvider);
  return repository.getLectureStatistics();
});

// Individual lecture provider
final lectureProvider = FutureProvider.family<LectureDetails, String>((ref, lectureId) async {
  final repository = ref.read(lectureRepositoryProvider);
  return repository.getLectureDetails(lectureId);
});

// Active session provider
final activeSessionProvider = FutureProvider.family<String?, String>((ref, lectureId) async {
  final repository = ref.read(lectureRepositoryProvider);
  return repository.getActiveSessionId(lectureId);
});

// Search lectures provider
final searchLecturesProvider = FutureProvider.family<List<Lecture>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  
  final repository = ref.read(lectureRepositoryProvider);
  return repository.searchLectures(query);
});

/// Available lectures state notifier
class AvailableLecturesNotifier extends StateNotifier<AsyncValue<List<Lecture>>> {
  final LectureRepository _repository;
  final Logger _logger;

  AvailableLecturesNotifier(this._repository)
      : _logger = Logger(),
        super(const AsyncValue.loading()) {
    _loadLectures();
  }

  Future<void> _loadLectures() async {
    try {
      _logger.d('Loading available lectures');
      final lectures = await _repository.getAvailableLectures();
      state = AsyncValue.data(lectures);
      _logger.i('Loaded ${lectures.length} available lectures');
    } catch (e, stack) {
      _logger.e('Error loading available lectures: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      _logger.d('Refreshing available lectures');
      final lectures = await _repository.getAvailableLectures(forceRefresh: true);
      state = AsyncValue.data(lectures);
      _logger.i('Refreshed ${lectures.length} available lectures');
    } catch (e, stack) {
      _logger.e('Error refreshing available lectures: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  List<Lecture> get lectures {
    return state.when(
      data: (lectures) => lectures,
      loading: () => [],
      error: (_, __) => [],
    );
  }

  bool get isLoading {
    return state.when(
      data: (_) => false,
      loading: () => true,
      error: (_, __) => false,
    );
  }

  String? get error {
    return state.when(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error.toString(),
    );
  }
}

/// Enrolled lectures state notifier
class EnrolledLecturesNotifier extends StateNotifier<AsyncValue<List<Lecture>>> {
  final LectureRepository _repository;
  final Logger _logger;

  EnrolledLecturesNotifier(this._repository)
      : _logger = Logger(),
        super(const AsyncValue.loading()) {
    _loadLectures();
  }

  Future<void> _loadLectures() async {
    try {
      _logger.d('Loading enrolled lectures');
      final lectures = await _repository.getEnrolledLectures();
      state = AsyncValue.data(lectures);
      _logger.i('Loaded ${lectures.length} enrolled lectures');
    } catch (e, stack) {
      _logger.e('Error loading enrolled lectures: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      _logger.d('Refreshing enrolled lectures');
      final lectures = await _repository.getEnrolledLectures(forceRefresh: true);
      state = AsyncValue.data(lectures);
      _logger.i('Refreshed ${lectures.length} enrolled lectures');
    } catch (e, stack) {
      _logger.e('Error refreshing enrolled lectures: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  List<Lecture> get lectures {
    return state.when(
      data: (lectures) => lectures,
      loading: () => [],
      error: (_, __) => [],
    );
  }

  bool get isLoading {
    return state.when(
      data: (_) => false,
      loading: () => true,
      error: (_, __) => false,
    );
  }

  String? get error {
    return state.when(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error.toString(),
    );
  }
}

/// Enrollment state notifier
final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, EnrollmentState>((ref) {
  return EnrollmentNotifier(
    ref.read(lectureRepositoryProvider),
    ref,
  );
});

class EnrollmentState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const EnrollmentState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  EnrollmentState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return EnrollmentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class EnrollmentNotifier extends StateNotifier<EnrollmentState> {
  final LectureRepository _repository;
  final Ref _ref;
  final Logger _logger;

  EnrollmentNotifier(this._repository, this._ref)
      : _logger = Logger(),
        super(const EnrollmentState());

  Future<bool> enrollInLecture(String lectureId) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      _logger.d('Enrolling in lecture: $lectureId');
      
      final response = await _repository.enrollInLecture(lectureId);
      
      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: response.message,
        );
        
        // Refresh enrolled lectures
        _ref.read(enrolledLecturesProvider.notifier).refresh();
        
        _logger.i('Successfully enrolled in lecture: $lectureId');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      _logger.e('Error enrolling in lecture: $e');
      
      String errorMessage = 'Failed to enroll in lecture';
      if (e.toString().contains('already enrolled')) {
        errorMessage = 'You are already enrolled in this lecture';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

/// Lecture filter provider
final lectureFilterProvider = StateProvider<LectureFilter>((ref) {
  return const LectureFilter();
});

class LectureFilter {
  final String? subject;
  final String? teacherId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final LectureSortOption sortBy;
  final bool ascending;

  const LectureFilter({
    this.subject,
    this.teacherId,
    this.fromDate,
    this.toDate,
    this.sortBy = LectureSortOption.scheduledTime,
    this.ascending = true,
  });

  LectureFilter copyWith({
    String? subject,
    String? teacherId,
    DateTime? fromDate,
    DateTime? toDate,
    LectureSortOption? sortBy,
    bool? ascending,
    bool clearSubject = false,
    bool clearTeacher = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) {
    return LectureFilter(
      subject: clearSubject ? null : (subject ?? this.subject),
      teacherId: clearTeacher ? null : (teacherId ?? this.teacherId),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

enum LectureSortOption {
  scheduledTime,
  title,
  teacherName,
  duration,
  createdAt,
}

/// Filtered lectures provider
final filteredLecturesProvider = Provider<List<Lecture>>((ref) {
  final lectures = ref.watch(availableLecturesProvider).value ?? [];
  final filter = ref.watch(lectureFilterProvider);
  
  List<Lecture> filtered = lectures.where((lecture) {
    // Apply filters
    if (filter.teacherId != null && lecture.teacherId != filter.teacherId) {
      return false;
    }
    
    if (filter.fromDate != null && lecture.scheduledTime.isBefore(filter.fromDate!)) {
      return false;
    }
    
    if (filter.toDate != null && lecture.scheduledTime.isAfter(filter.toDate!)) {
      return false;
    }
    
    return true;
  }).toList();
  
  // Apply sorting
  filtered.sort((a, b) {
    int comparison = 0;
    
    switch (filter.sortBy) {
      case LectureSortOption.scheduledTime:
        comparison = a.scheduledTime.compareTo(b.scheduledTime);
        break;
      case LectureSortOption.title:
        comparison = a.title.compareTo(b.title);
        break;
      case LectureSortOption.teacherName:
        comparison = (a.teacherName ?? '').compareTo(b.teacherName ?? '');
        break;
      case LectureSortOption.duration:
        comparison = a.duration.compareTo(b.duration);
        break;
      case LectureSortOption.createdAt:
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
    }
    
    return filter.ascending ? comparison : -comparison;
  });
  
  return filtered;
});
