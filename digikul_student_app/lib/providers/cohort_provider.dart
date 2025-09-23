import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digikul_student_app/models/cohort.dart';
import 'package:digikul_student_app/models/lecture.dart';
import 'package:digikul_student_app/services/api_service_new.dart';
import 'package:digikul_student_app/providers/auth_provider.dart';

// Cohorts state
class CohortsState {

  const CohortsState({
    this.studentCohorts = const [],
    this.cohortLectures = const {},
    this.isLoading = false,
    this.error,
  });
  final List<Cohort> studentCohorts;
  final Map<String, List<Lecture>> cohortLectures;
  final bool isLoading;
  final String? error;

  CohortsState copyWith({
    List<Cohort>? studentCohorts,
    Map<String, List<Lecture>>? cohortLectures,
    bool? isLoading,
    String? error,
  }) {
    return CohortsState(
      studentCohorts: studentCohorts ?? this.studentCohorts,
      cohortLectures: cohortLectures ?? this.cohortLectures,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Lecture> getLectures(String cohortId) {
    return cohortLectures[cohortId] ?? [];
  }
}

// Cohorts notifier
class CohortsNotifier extends StateNotifier<CohortsState> {
  CohortsNotifier(this._apiService) : super(const CohortsState());

  final ApiService _apiService;

  Future<void> loadStudentCohorts() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final cohorts = await _apiService.getStudentCohorts();
      state = state.copyWith(
        studentCohorts: cohorts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadCohortLectures(String cohortId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final lectures = await _apiService.getCohortLectures(cohortId);
      final updatedLectures = Map<String, List<Lecture>>.from(state.cohortLectures);
      updatedLectures[cohortId] = lectures;
      
      state = state.copyWith(
        cohortLectures: updatedLectures,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> joinCohortByCode(String cohortCode) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _apiService.joinCohortByCode(cohortCode);
      // Refresh cohorts list after joining
      await loadStudentCohorts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith();
  }
}

// Providers
final cohortsProvider = StateNotifierProvider<CohortsNotifier, CohortsState>((ref) {
  return CohortsNotifier(ref.read(apiServiceProvider));
});

// Helper providers
final studentCohortsProvider = Provider<List<Cohort>>((ref) {
  return ref.watch(cohortsProvider).studentCohorts;
});

final cohortLecturesProvider = Provider.family<List<Lecture>, String>((ref, cohortId) {
  return ref.watch(cohortsProvider).getLectures(cohortId);
});

// Get cohort by ID
final cohortByIdProvider = Provider.family<Cohort?, String>((ref, cohortId) {
  final cohorts = ref.watch(studentCohortsProvider);
  try {
    return cohorts.firstWhere((cohort) => cohort.id == cohortId);
  } catch (_) {
    return null;
  }
});
