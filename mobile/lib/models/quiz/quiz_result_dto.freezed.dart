// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuizResultDto _$QuizResultDtoFromJson(Map<String, dynamic> json) {
  return _QuizResultDto.fromJson(json);
}

/// @nodoc
mixin _$QuizResultDto {
  @JsonKey(name: 'attempt_id')
  String get attemptId => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_set_id')
  String get quizSetId => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_questions')
  int get totalQuestions => throw _privateConstructorUsedError;
  @JsonKey(name: 'correct_answers')
  int get correctAnswers => throw _privateConstructorUsedError;
  @JsonKey(name: 'score_percentage')
  double get scorePercentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_taken_seconds')
  int? get timeTakenSeconds => throw _privateConstructorUsedError;
  List<QuestionReview> get review => throw _privateConstructorUsedError;

  /// Serializes this QuizResultDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizResultDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizResultDtoCopyWith<QuizResultDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizResultDtoCopyWith<$Res> {
  factory $QuizResultDtoCopyWith(
          QuizResultDto value, $Res Function(QuizResultDto) then) =
      _$QuizResultDtoCopyWithImpl<$Res, QuizResultDto>;
  @useResult
  $Res call(
      {@JsonKey(name: 'attempt_id') String attemptId,
      @JsonKey(name: 'quiz_set_id') String quizSetId,
      @JsonKey(name: 'total_questions') int totalQuestions,
      @JsonKey(name: 'correct_answers') int correctAnswers,
      @JsonKey(name: 'score_percentage') double scorePercentage,
      @JsonKey(name: 'time_taken_seconds') int? timeTakenSeconds,
      List<QuestionReview> review});
}

/// @nodoc
class _$QuizResultDtoCopyWithImpl<$Res, $Val extends QuizResultDto>
    implements $QuizResultDtoCopyWith<$Res> {
  _$QuizResultDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizResultDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attemptId = null,
    Object? quizSetId = null,
    Object? totalQuestions = null,
    Object? correctAnswers = null,
    Object? scorePercentage = null,
    Object? timeTakenSeconds = freezed,
    Object? review = null,
  }) {
    return _then(_value.copyWith(
      attemptId: null == attemptId
          ? _value.attemptId
          : attemptId // ignore: cast_nullable_to_non_nullable
              as String,
      quizSetId: null == quizSetId
          ? _value.quizSetId
          : quizSetId // ignore: cast_nullable_to_non_nullable
              as String,
      totalQuestions: null == totalQuestions
          ? _value.totalQuestions
          : totalQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      correctAnswers: null == correctAnswers
          ? _value.correctAnswers
          : correctAnswers // ignore: cast_nullable_to_non_nullable
              as int,
      scorePercentage: null == scorePercentage
          ? _value.scorePercentage
          : scorePercentage // ignore: cast_nullable_to_non_nullable
              as double,
      timeTakenSeconds: freezed == timeTakenSeconds
          ? _value.timeTakenSeconds
          : timeTakenSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      review: null == review
          ? _value.review
          : review // ignore: cast_nullable_to_non_nullable
              as List<QuestionReview>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuizResultDtoImplCopyWith<$Res>
    implements $QuizResultDtoCopyWith<$Res> {
  factory _$$QuizResultDtoImplCopyWith(
          _$QuizResultDtoImpl value, $Res Function(_$QuizResultDtoImpl) then) =
      __$$QuizResultDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'attempt_id') String attemptId,
      @JsonKey(name: 'quiz_set_id') String quizSetId,
      @JsonKey(name: 'total_questions') int totalQuestions,
      @JsonKey(name: 'correct_answers') int correctAnswers,
      @JsonKey(name: 'score_percentage') double scorePercentage,
      @JsonKey(name: 'time_taken_seconds') int? timeTakenSeconds,
      List<QuestionReview> review});
}

/// @nodoc
class __$$QuizResultDtoImplCopyWithImpl<$Res>
    extends _$QuizResultDtoCopyWithImpl<$Res, _$QuizResultDtoImpl>
    implements _$$QuizResultDtoImplCopyWith<$Res> {
  __$$QuizResultDtoImplCopyWithImpl(
      _$QuizResultDtoImpl _value, $Res Function(_$QuizResultDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuizResultDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attemptId = null,
    Object? quizSetId = null,
    Object? totalQuestions = null,
    Object? correctAnswers = null,
    Object? scorePercentage = null,
    Object? timeTakenSeconds = freezed,
    Object? review = null,
  }) {
    return _then(_$QuizResultDtoImpl(
      attemptId: null == attemptId
          ? _value.attemptId
          : attemptId // ignore: cast_nullable_to_non_nullable
              as String,
      quizSetId: null == quizSetId
          ? _value.quizSetId
          : quizSetId // ignore: cast_nullable_to_non_nullable
              as String,
      totalQuestions: null == totalQuestions
          ? _value.totalQuestions
          : totalQuestions // ignore: cast_nullable_to_non_nullable
              as int,
      correctAnswers: null == correctAnswers
          ? _value.correctAnswers
          : correctAnswers // ignore: cast_nullable_to_non_nullable
              as int,
      scorePercentage: null == scorePercentage
          ? _value.scorePercentage
          : scorePercentage // ignore: cast_nullable_to_non_nullable
              as double,
      timeTakenSeconds: freezed == timeTakenSeconds
          ? _value.timeTakenSeconds
          : timeTakenSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      review: null == review
          ? _value._review
          : review // ignore: cast_nullable_to_non_nullable
              as List<QuestionReview>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizResultDtoImpl implements _QuizResultDto {
  const _$QuizResultDtoImpl(
      {@JsonKey(name: 'attempt_id') required this.attemptId,
      @JsonKey(name: 'quiz_set_id') required this.quizSetId,
      @JsonKey(name: 'total_questions') this.totalQuestions = 0,
      @JsonKey(name: 'correct_answers') this.correctAnswers = 0,
      @JsonKey(name: 'score_percentage') this.scorePercentage = 0.0,
      @JsonKey(name: 'time_taken_seconds') this.timeTakenSeconds,
      final List<QuestionReview> review = const <QuestionReview>[]})
      : _review = review;

  factory _$QuizResultDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizResultDtoImplFromJson(json);

  @override
  @JsonKey(name: 'attempt_id')
  final String attemptId;
  @override
  @JsonKey(name: 'quiz_set_id')
  final String quizSetId;
  @override
  @JsonKey(name: 'total_questions')
  final int totalQuestions;
  @override
  @JsonKey(name: 'correct_answers')
  final int correctAnswers;
  @override
  @JsonKey(name: 'score_percentage')
  final double scorePercentage;
  @override
  @JsonKey(name: 'time_taken_seconds')
  final int? timeTakenSeconds;
  final List<QuestionReview> _review;
  @override
  @JsonKey()
  List<QuestionReview> get review {
    if (_review is EqualUnmodifiableListView) return _review;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_review);
  }

  @override
  String toString() {
    return 'QuizResultDto(attemptId: $attemptId, quizSetId: $quizSetId, totalQuestions: $totalQuestions, correctAnswers: $correctAnswers, scorePercentage: $scorePercentage, timeTakenSeconds: $timeTakenSeconds, review: $review)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizResultDtoImpl &&
            (identical(other.attemptId, attemptId) ||
                other.attemptId == attemptId) &&
            (identical(other.quizSetId, quizSetId) ||
                other.quizSetId == quizSetId) &&
            (identical(other.totalQuestions, totalQuestions) ||
                other.totalQuestions == totalQuestions) &&
            (identical(other.correctAnswers, correctAnswers) ||
                other.correctAnswers == correctAnswers) &&
            (identical(other.scorePercentage, scorePercentage) ||
                other.scorePercentage == scorePercentage) &&
            (identical(other.timeTakenSeconds, timeTakenSeconds) ||
                other.timeTakenSeconds == timeTakenSeconds) &&
            const DeepCollectionEquality().equals(other._review, _review));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      attemptId,
      quizSetId,
      totalQuestions,
      correctAnswers,
      scorePercentage,
      timeTakenSeconds,
      const DeepCollectionEquality().hash(_review));

  /// Create a copy of QuizResultDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizResultDtoImplCopyWith<_$QuizResultDtoImpl> get copyWith =>
      __$$QuizResultDtoImplCopyWithImpl<_$QuizResultDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizResultDtoImplToJson(
      this,
    );
  }
}

abstract class _QuizResultDto implements QuizResultDto {
  const factory _QuizResultDto(
      {@JsonKey(name: 'attempt_id') required final String attemptId,
      @JsonKey(name: 'quiz_set_id') required final String quizSetId,
      @JsonKey(name: 'total_questions') final int totalQuestions,
      @JsonKey(name: 'correct_answers') final int correctAnswers,
      @JsonKey(name: 'score_percentage') final double scorePercentage,
      @JsonKey(name: 'time_taken_seconds') final int? timeTakenSeconds,
      final List<QuestionReview> review}) = _$QuizResultDtoImpl;

  factory _QuizResultDto.fromJson(Map<String, dynamic> json) =
      _$QuizResultDtoImpl.fromJson;

  @override
  @JsonKey(name: 'attempt_id')
  String get attemptId;
  @override
  @JsonKey(name: 'quiz_set_id')
  String get quizSetId;
  @override
  @JsonKey(name: 'total_questions')
  int get totalQuestions;
  @override
  @JsonKey(name: 'correct_answers')
  int get correctAnswers;
  @override
  @JsonKey(name: 'score_percentage')
  double get scorePercentage;
  @override
  @JsonKey(name: 'time_taken_seconds')
  int? get timeTakenSeconds;
  @override
  List<QuestionReview> get review;

  /// Create a copy of QuizResultDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizResultDtoImplCopyWith<_$QuizResultDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuestionReview _$QuestionReviewFromJson(Map<String, dynamic> json) {
  return _QuestionReview.fromJson(json);
}

/// @nodoc
mixin _$QuestionReview {
  @JsonKey(name: 'question_id')
  String get questionId => throw _privateConstructorUsedError;
  String get question => throw _privateConstructorUsedError;
  List<String> get options => throw _privateConstructorUsedError;
  @JsonKey(name: 'selected_answer')
  String? get selectedAnswer => throw _privateConstructorUsedError;
  @JsonKey(name: 'correct_answer')
  String? get correctAnswer => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_correct')
  bool get isCorrect => throw _privateConstructorUsedError;

  /// Serializes this QuestionReview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestionReviewCopyWith<QuestionReview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionReviewCopyWith<$Res> {
  factory $QuestionReviewCopyWith(
          QuestionReview value, $Res Function(QuestionReview) then) =
      _$QuestionReviewCopyWithImpl<$Res, QuestionReview>;
  @useResult
  $Res call(
      {@JsonKey(name: 'question_id') String questionId,
      String question,
      List<String> options,
      @JsonKey(name: 'selected_answer') String? selectedAnswer,
      @JsonKey(name: 'correct_answer') String? correctAnswer,
      @JsonKey(name: 'is_correct') bool isCorrect});
}

/// @nodoc
class _$QuestionReviewCopyWithImpl<$Res, $Val extends QuestionReview>
    implements $QuestionReviewCopyWith<$Res> {
  _$QuestionReviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? question = null,
    Object? options = null,
    Object? selectedAnswer = freezed,
    Object? correctAnswer = freezed,
    Object? isCorrect = null,
  }) {
    return _then(_value.copyWith(
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedAnswer: freezed == selectedAnswer
          ? _value.selectedAnswer
          : selectedAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      correctAnswer: freezed == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestionReviewImplCopyWith<$Res>
    implements $QuestionReviewCopyWith<$Res> {
  factory _$$QuestionReviewImplCopyWith(_$QuestionReviewImpl value,
          $Res Function(_$QuestionReviewImpl) then) =
      __$$QuestionReviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'question_id') String questionId,
      String question,
      List<String> options,
      @JsonKey(name: 'selected_answer') String? selectedAnswer,
      @JsonKey(name: 'correct_answer') String? correctAnswer,
      @JsonKey(name: 'is_correct') bool isCorrect});
}

/// @nodoc
class __$$QuestionReviewImplCopyWithImpl<$Res>
    extends _$QuestionReviewCopyWithImpl<$Res, _$QuestionReviewImpl>
    implements _$$QuestionReviewImplCopyWith<$Res> {
  __$$QuestionReviewImplCopyWithImpl(
      _$QuestionReviewImpl _value, $Res Function(_$QuestionReviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? question = null,
    Object? options = null,
    Object? selectedAnswer = freezed,
    Object? correctAnswer = freezed,
    Object? isCorrect = null,
  }) {
    return _then(_$QuestionReviewImpl(
      questionId: null == questionId
          ? _value.questionId
          : questionId // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedAnswer: freezed == selectedAnswer
          ? _value.selectedAnswer
          : selectedAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      correctAnswer: freezed == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      isCorrect: null == isCorrect
          ? _value.isCorrect
          : isCorrect // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestionReviewImpl implements _QuestionReview {
  const _$QuestionReviewImpl(
      {@JsonKey(name: 'question_id') required this.questionId,
      required this.question,
      required final List<String> options,
      @JsonKey(name: 'selected_answer') this.selectedAnswer,
      @JsonKey(name: 'correct_answer') this.correctAnswer,
      @JsonKey(name: 'is_correct') this.isCorrect = false})
      : _options = options;

  factory _$QuestionReviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestionReviewImplFromJson(json);

  @override
  @JsonKey(name: 'question_id')
  final String questionId;
  @override
  final String question;
  final List<String> _options;
  @override
  List<String> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  @JsonKey(name: 'selected_answer')
  final String? selectedAnswer;
  @override
  @JsonKey(name: 'correct_answer')
  final String? correctAnswer;
  @override
  @JsonKey(name: 'is_correct')
  final bool isCorrect;

  @override
  String toString() {
    return 'QuestionReview(questionId: $questionId, question: $question, options: $options, selectedAnswer: $selectedAnswer, correctAnswer: $correctAnswer, isCorrect: $isCorrect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionReviewImpl &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.question, question) ||
                other.question == question) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.selectedAnswer, selectedAnswer) ||
                other.selectedAnswer == selectedAnswer) &&
            (identical(other.correctAnswer, correctAnswer) ||
                other.correctAnswer == correctAnswer) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      questionId,
      question,
      const DeepCollectionEquality().hash(_options),
      selectedAnswer,
      correctAnswer,
      isCorrect);

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionReviewImplCopyWith<_$QuestionReviewImpl> get copyWith =>
      __$$QuestionReviewImplCopyWithImpl<_$QuestionReviewImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestionReviewImplToJson(
      this,
    );
  }
}

abstract class _QuestionReview implements QuestionReview {
  const factory _QuestionReview(
          {@JsonKey(name: 'question_id') required final String questionId,
          required final String question,
          required final List<String> options,
          @JsonKey(name: 'selected_answer') final String? selectedAnswer,
          @JsonKey(name: 'correct_answer') final String? correctAnswer,
          @JsonKey(name: 'is_correct') final bool isCorrect}) =
      _$QuestionReviewImpl;

  factory _QuestionReview.fromJson(Map<String, dynamic> json) =
      _$QuestionReviewImpl.fromJson;

  @override
  @JsonKey(name: 'question_id')
  String get questionId;
  @override
  String get question;
  @override
  List<String> get options;
  @override
  @JsonKey(name: 'selected_answer')
  String? get selectedAnswer;
  @override
  @JsonKey(name: 'correct_answer')
  String? get correctAnswer;
  @override
  @JsonKey(name: 'is_correct')
  bool get isCorrect;

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionReviewImplCopyWith<_$QuestionReviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
