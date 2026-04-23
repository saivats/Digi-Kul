// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizResultDtoImpl _$$QuizResultDtoImplFromJson(Map<String, dynamic> json) =>
    _$QuizResultDtoImpl(
      attemptId: json['attempt_id'] as String,
      quizSetId: json['quiz_set_id'] as String,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      scorePercentage: (json['score_percentage'] as num?)?.toDouble() ?? 0.0,
      timeTakenSeconds: (json['time_taken_seconds'] as num?)?.toInt(),
      review: (json['review'] as List<dynamic>?)
              ?.map((e) => QuestionReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <QuestionReview>[],
    );

Map<String, dynamic> _$$QuizResultDtoImplToJson(_$QuizResultDtoImpl instance) =>
    <String, dynamic>{
      'attempt_id': instance.attemptId,
      'quiz_set_id': instance.quizSetId,
      'total_questions': instance.totalQuestions,
      'correct_answers': instance.correctAnswers,
      'score_percentage': instance.scorePercentage,
      'time_taken_seconds': instance.timeTakenSeconds,
      'review': instance.review,
    };

_$QuestionReviewImpl _$$QuestionReviewImplFromJson(Map<String, dynamic> json) =>
    _$QuestionReviewImpl(
      questionId: json['question_id'] as String,
      question: json['question'] as String,
      options:
          (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      selectedAnswer: json['selected_answer'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
    );

Map<String, dynamic> _$$QuestionReviewImplToJson(
        _$QuestionReviewImpl instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question': instance.question,
      'options': instance.options,
      'selected_answer': instance.selectedAnswer,
      'correct_answer': instance.correctAnswer,
      'is_correct': instance.isCorrect,
    };
