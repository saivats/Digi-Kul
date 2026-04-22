// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceDtoImpl _$$AttendanceDtoImplFromJson(Map<String, dynamic> json) =>
    _$AttendanceDtoImpl(
      id: json['id'] as String,
      lectureId: json['lecture_id'] as String,
      lectureTitle: json['lecture_title'] as String? ?? '',
      status: json['status'] as String? ?? 'absent',
      lectureDate: DateTime.parse(json['lecture_date'] as String),
    );

Map<String, dynamic> _$$AttendanceDtoImplToJson(_$AttendanceDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lecture_id': instance.lectureId,
      'lecture_title': instance.lectureTitle,
      'status': instance.status,
      'lecture_date': instance.lectureDate.toIso8601String(),
    };
