// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lecture_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LectureDtoImpl _$$LectureDtoImplFromJson(Map<String, dynamic> json) =>
    _$LectureDtoImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      status: json['status'] as String? ?? 'scheduled',
      cohortId: json['cohort_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? '',
      recordingId: json['recording_id'] as String?,
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$$LectureDtoImplToJson(_$LectureDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'scheduled_time': instance.scheduledTime.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'status': instance.status,
      'cohort_id': instance.cohortId,
      'teacher_name': instance.teacherName,
      'recording_id': instance.recordingId,
      'session_id': instance.sessionId,
    };
