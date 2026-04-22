import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/network/api_client.dart';
import '../models/common/api_response.dart';
import '../models/lecture/cached_lecture.dart';
import '../models/lecture/lecture_dto.dart';
import '../providers/core_providers.dart';

part 'lecture_repository.g.dart';

class LectureRepository {
  LectureRepository(this._api, this._isar);

  final ApiClient _api;
  final Isar _isar;
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<List<LectureDto>> getLectures() async {
    final cached = await _isar.cachedLectures.where().findAll();

    if (cached.isNotEmpty) {
      _refreshInBackground();
      return cached.map(LectureDto.fromCached).toList();
    }

    return _fetchAndCache();
  }

  Future<List<LectureDto>> getUpcomingLectures() async {
    final now = DateTime.now();
    final cached = await _isar.cachedLectures
        .filter()
        .statusEqualTo('scheduled')
        .and()
        .scheduledTimeGreaterThan(now)
        .sortByScheduledTime()
        .findAll();

    if (cached.isNotEmpty) {
      _refreshInBackground();
      return cached.map(LectureDto.fromCached).toList();
    }

    final all = await _fetchAndCache();
    return all.where((l) => l.isUpcoming).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<LectureDto?> getLiveLecture() async {
    final cached = await _isar.cachedLectures
        .filter()
        .statusEqualTo('live')
        .findFirst();

    _refreshInBackground();
    return cached != null ? LectureDto.fromCached(cached) : null;
  }

  Future<List<LectureDto>> refresh() => _fetchAndCache();

  Future<List<LectureDto>> _fetchAndCache() async {
    try {
      final response = await _api.getLectures();
      final apiResponse = ApiResponse.fromResponse(response);
      final lectures = apiResponse.parseList(LectureDto.fromJson);

      await _isar.writeTxn(() async {
        await _isar.cachedLectures.clear();
        for (final lecture in lectures) {
          await _isar.cachedLectures.put(lecture.toCached());
        }
      });

      return lectures;
    } catch (e) {
      _logger.e('Failed to fetch lectures: $e');
      final cached = await _isar.cachedLectures.where().findAll();
      if (cached.isNotEmpty) return cached.map(LectureDto.fromCached).toList();
      rethrow;
    }
  }

  void _refreshInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _fetchAndCache();
      } catch (e) {
        _logger.w('Background lecture refresh failed: $e');
      }
    });
  }
}

@riverpod
LectureRepository lectureRepository(Ref ref) {
  final api = ref.watch(apiClientProvider);
  final isar = ref.watch(isarProvider).requireValue;
  return LectureRepository(api, isar);
}

@riverpod
Future<List<LectureDto>> lectures(Ref ref) {
  return ref.watch(lectureRepositoryProvider).getLectures();
}

@riverpod
Future<List<LectureDto>> upcomingLectures(Ref ref) {
  return ref.watch(lectureRepositoryProvider).getUpcomingLectures();
}

@riverpod
Future<LectureDto?> liveLecture(Ref ref) {
  return ref.watch(lectureRepositoryProvider).getLiveLecture();
}
