import 'package:freezed_annotation/freezed_annotation.dart';

import 'cached_lecture.dart';

part 'lecture_dto.freezed.dart';
part 'lecture_dto.g.dart';

@freezed
class LectureDto with _$LectureDto {
  const LectureDto._();

  const factory LectureDto({
    required String id,
    required String title,
    @Default('') String description,
    @JsonKey(name: 'scheduled_time') required DateTime scheduledTime,
    @JsonKey(name: 'duration_minutes') @Default(60) int durationMinutes,
    @Default('scheduled') String status,
    @JsonKey(name: 'cohort_id') @Default('') String cohortId,
    @JsonKey(name: 'teacher_name') @Default('') String teacherName,
    @JsonKey(name: 'recording_id') String? recordingId,
    @JsonKey(name: 'session_id') String? sessionId,
  }) = _LectureDto;

  factory LectureDto.fromJson(Map<String, dynamic> json) =>
      _$LectureDtoFromJson(json);

  factory LectureDto.fromCached(CachedLecture cached) => LectureDto(
        id: cached.serverId,
        title: cached.title,
        description: cached.description,
        scheduledTime: cached.scheduledTime,
        durationMinutes: cached.durationMinutes,
        status: cached.status,
        cohortId: cached.cohortId,
        teacherName: cached.teacherName,
        recordingId: cached.recordingId,
      );

  bool get isLive => status == 'live';

  bool get isUpcoming =>
      status == 'scheduled' && scheduledTime.isAfter(DateTime.now());

  bool get isPast => status == 'ended';

  Duration get timeUntilStart => scheduledTime.difference(DateTime.now());

  CachedLecture toCached() {
    return CachedLecture()
      ..serverId = id
      ..title = title
      ..description = description
      ..scheduledTime = scheduledTime
      ..durationMinutes = durationMinutes
      ..status = status
      ..cohortId = cohortId
      ..teacherName = teacherName
      ..recordingId = recordingId
      ..cachedAt = DateTime.now();
  }
}
