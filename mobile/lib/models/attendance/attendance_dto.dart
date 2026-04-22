import 'package:freezed_annotation/freezed_annotation.dart';

import 'cached_attendance.dart';

part 'attendance_dto.freezed.dart';
part 'attendance_dto.g.dart';

@freezed
class AttendanceDto with _$AttendanceDto {
  const AttendanceDto._();

  const factory AttendanceDto({
    required String id,
    @JsonKey(name: 'lecture_id') required String lectureId,
    @JsonKey(name: 'lecture_title') @Default('') String lectureTitle,
    @Default('absent') String status,
    @JsonKey(name: 'lecture_date') required DateTime lectureDate,
  }) = _AttendanceDto;

  factory AttendanceDto.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDtoFromJson(json);

  factory AttendanceDto.fromCached(CachedAttendance cached) => AttendanceDto(
        id: cached.serverId,
        lectureId: cached.lectureId,
        lectureTitle: cached.lectureTitle,
        status: cached.status,
        lectureDate: cached.lectureDate,
      );

  bool get isPresent => status == 'present' || status == 'late';

  CachedAttendance toCached() {
    return CachedAttendance()
      ..serverId = id
      ..lectureId = lectureId
      ..lectureTitle = lectureTitle
      ..status = status
      ..lectureDate = lectureDate
      ..cachedAt = DateTime.now();
  }
}
