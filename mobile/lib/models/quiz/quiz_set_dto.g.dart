// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_set_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizSetDtoImpl _$$QuizSetDtoImplFromJson(Map<String, dynamic> json) =>
    _$QuizSetDtoImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      cohortId: json['cohort_id'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      timeLimitSeconds: (json['time_limit_seconds'] as num?)?.toInt(),
      showCorrectAnswers: json['show_correct_answers'] as bool? ?? true,
      availableFrom: DateTime.parse(json['available_from'] as String),
      availableUntil: json['available_until'] == null
          ? null
          : DateTime.parse(json['available_until'] as String),
      status: json['status'] as String? ?? 'available',
      isInProgress: json['isInProgress'] as bool? ?? false,
    );

Map<String, dynamic> _$$QuizSetDtoImplToJson(_$QuizSetDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'cohort_id': instance.cohortId,
      'question_count': instance.questionCount,
      'time_limit_seconds': instance.timeLimitSeconds,
      'show_correct_answers': instance.showCorrectAnswers,
      'available_from': instance.availableFrom.toIso8601String(),
      'available_until': instance.availableUntil?.toIso8601String(),
      'status': instance.status,
      'isInProgress': instance.isInProgress,
    };
