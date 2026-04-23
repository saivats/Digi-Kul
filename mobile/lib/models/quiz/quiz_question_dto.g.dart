// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizQuestionDtoImpl _$$QuizQuestionDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$QuizQuestionDtoImpl(
      id: json['id'] as String,
      quizSetId: json['quiz_set_id'] as String,
      question: json['question'] as String,
      questionType: json['question_type'] as String? ?? 'mcq',
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswer: json['correct_answer'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$QuizQuestionDtoImplToJson(
        _$QuizQuestionDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quiz_set_id': instance.quizSetId,
      'question': instance.question,
      'question_type': instance.questionType,
      'options': instance.options,
      'correct_answer': instance.correctAnswer,
      'order_index': instance.orderIndex,
    };
