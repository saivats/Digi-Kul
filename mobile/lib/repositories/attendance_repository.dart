import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/network/api_client.dart';
import '../models/attendance/attendance_dto.dart';
import '../models/attendance/attendance_summary.dart';
import '../models/attendance/cached_attendance.dart';
import '../models/common/api_response.dart';
import '../providers/core_providers.dart';

part 'attendance_repository.g.dart';

class AttendanceRepository {
  AttendanceRepository(this._api, this._isar);

  final ApiClient _api;
  final Isar _isar;
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<List<AttendanceDto>> getAttendance() async {
    final cached = await _isar.cachedAttendances.where().findAll();

    if (cached.isNotEmpty) {
      _refreshInBackground();
      return cached.map(AttendanceDto.fromCached).toList();
    }

    return _fetchAndCache();
  }

  Future<AttendanceSummary> getAttendanceSummary() async {
    final records = await getAttendance();
    return AttendanceSummary(records: records);
  }

  Future<List<AttendanceDto>> refresh() => _fetchAndCache();

  Future<List<AttendanceDto>> _fetchAndCache() async {
    try {
      final response = await _api.getAttendance();
      final apiResponse = ApiResponse.fromResponse(response);
      final records = apiResponse.parseList(AttendanceDto.fromJson);

      await _isar.writeTxn(() async {
        await _isar.cachedAttendances.clear();
        for (final record in records) {
          await _isar.cachedAttendances.put(record.toCached());
        }
      });

      return records;
    } catch (e) {
      _logger.e('Failed to fetch attendance: $e');
      final cached = await _isar.cachedAttendances.where().findAll();
      if (cached.isNotEmpty) {
        return cached.map(AttendanceDto.fromCached).toList();
      }
      rethrow;
    }
  }

  void _refreshInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _fetchAndCache();
      } catch (e) {
        _logger.w('Background attendance refresh failed: $e');
      }
    });
  }
}

@riverpod
AttendanceRepository attendanceRepository(Ref ref) {
  final api = ref.watch(apiClientProvider);
  final isar = ref.watch(isarProvider).requireValue;
  return AttendanceRepository(api, isar);
}

@riverpod
Future<List<AttendanceDto>> attendance(Ref ref) {
  return ref.watch(attendanceRepositoryProvider).getAttendance();
}

@riverpod
Future<AttendanceSummary> attendanceSummary(Ref ref) {
  return ref.watch(attendanceRepositoryProvider).getAttendanceSummary();
}
