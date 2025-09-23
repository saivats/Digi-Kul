import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lecture.dart';
import '../models/material.dart';
import '../services/api_service_new.dart';
import 'auth_provider.dart';

// Lectures state
class LecturesState {
  final List<Lecture> availableLectures;
  final List<Lecture> enrolledLectures;
  final bool isLoading;
  final String? error;

  const LecturesState({
    this.availableLectures = const [],
    this.enrolledLectures = const [],
    this.isLoading = false,
    this.error,
  });

  LecturesState copyWith({
    List<Lecture>? availableLectures,
    List<Lecture>? enrolledLectures,
    bool? isLoading,
    String? error,
  }) {
    return LecturesState(
      availableLectures: availableLectures ?? this.availableLectures,
      enrolledLectures: enrolledLectures ?? this.enrolledLectures,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Lectures notifier
class LecturesNotifier extends StateNotifier<LecturesState> {
  LecturesNotifier(this._apiService) : super(const LecturesState());

  final ApiService _apiService;

  Future<void> loadAvailableLectures() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final lectures = await _apiService.getAvailableLectures();
      state = state.copyWith(
        availableLectures: lectures,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadEnrolledLectures() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final lectures = await _apiService.getEnrolledLectures();
      state = state.copyWith(
        enrolledLectures: lectures,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> enrollInLecture(String lectureId) async {
    try {
      await _apiService.enrollInLecture(lectureId);
      // Refresh both lists after enrollment
      await Future.wait([
        loadAvailableLectures(),
        loadEnrolledLectures(),
      ]);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<String?> getActiveSessionId(String lectureId) async {
    try {
      return await _apiService.getActiveSessionId(lectureId);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Materials state
class MaterialsState {
  final Map<String, List<MaterialItem>> lectureMaterials;
  final bool isLoading;
  final String? error;

  const MaterialsState({
    this.lectureMaterials = const {},
    this.isLoading = false,
    this.error,
  });

  MaterialsState copyWith({
    Map<String, List<MaterialItem>>? lectureMaterials,
    bool? isLoading,
    String? error,
  }) {
    return MaterialsState(
      lectureMaterials: lectureMaterials ?? this.lectureMaterials,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<MaterialItem> getMaterials(String lectureId) {
    return lectureMaterials[lectureId] ?? [];
  }
}

// Materials notifier
class MaterialsNotifier extends StateNotifier<MaterialsState> {
  MaterialsNotifier(this._apiService) : super(const MaterialsState());

  final ApiService _apiService;

  Future<void> loadLectureMaterials(String lectureId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final materials = await _apiService.getLectureMaterials(lectureId);
      final updatedMaterials = Map<String, List<MaterialItem>>.from(state.lectureMaterials);
      updatedMaterials[lectureId] = materials;
      
      state = state.copyWith(
        lectureMaterials: updatedMaterials,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String getDownloadUrl(String materialId) {
    return _apiService.getDownloadUrl(materialId);
  }

  Future<void> downloadMaterial(
    String materialId,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await _apiService.downloadMaterial(
        materialId,
        savePath,
        onReceiveProgress: onProgress,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final lecturesProvider = StateNotifierProvider<LecturesNotifier, LecturesState>((ref) {
  return LecturesNotifier(ref.read(apiServiceProvider));
});

final materialsProvider = StateNotifierProvider<MaterialsNotifier, MaterialsState>((ref) {
  return MaterialsNotifier(ref.read(apiServiceProvider));
});

// Helper providers
final availableLecturesProvider = Provider<List<Lecture>>((ref) {
  return ref.watch(lecturesProvider).availableLectures;
});

final enrolledLecturesProvider = Provider<List<Lecture>>((ref) {
  return ref.watch(lecturesProvider).enrolledLectures;
});

final upcomingLecturesProvider = Provider<List<Lecture>>((ref) {
  final enrolled = ref.watch(enrolledLecturesProvider);
  final now = DateTime.now();
  
  return enrolled
      .where((lecture) => lecture.scheduledAt.isAfter(now))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
});

final liveLecturesProvider = Provider<List<Lecture>>((ref) {
  final enrolled = ref.watch(enrolledLecturesProvider);
  
  return enrolled.where((lecture) => lecture.isLive).toList();
});

// Lecture materials provider
final lectureMaterialsProvider = Provider.family<List<MaterialItem>, String>((ref, lectureId) {
  return ref.watch(materialsProvider).getMaterials(lectureId);
});
