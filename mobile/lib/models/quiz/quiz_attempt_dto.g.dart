// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_attempt_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizAttemptDtoImpl _$$QuizAttemptDtoImplFromJson(Map<String, dynamic> json) =>
    _$QuizAttemptDtoImpl(
      id: json['id'] as String,
      quizSetId: json['quiz_set_id'] as String,
      studentId: json['student_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.parse(json['submitted_at'] as String),
      status: json['status'] as String? ?? 'in_progress',
    );

Map<String, dynamic> _$$QuizAttemptDtoImplToJson(
        _$QuizAttemptDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quiz_set_id': instance.quizSetId,
      'student_id': instance.studentId,
      'started_at': instance.startedAt.toIso8601String(),
      'submitted_at': instance.submittedAt?.toIso8601String(),
      'status': instance.status,
    };
