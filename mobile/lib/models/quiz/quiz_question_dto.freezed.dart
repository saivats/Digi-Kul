// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_question_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuizQuestionDto _$QuizQuestionDtoFromJson(Map<String, dynamic> json) {
  return _QuizQuestionDto.fromJson(json);
}

/// @nodoc
mixin _$QuizQuestionDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_set_id')
  String get quizSetId => throw _privateConstructorUsedError;
  String get question => throw _privateConstructorUsedError;
  @JsonKey(name: 'question_type')
  String get questionType => throw _privateConstructorUsedError;
  List<String> get options => throw _privateConstructorUsedError;
  @JsonKey(name: 'correct_answer')
  String? get correctAnswer => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_index')
  int get orderIndex => throw _privateConstructorUsedError;

  /// Serializes this QuizQuestionDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizQuestionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizQuestionDtoCopyWith<QuizQuestionDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizQuestionDtoCopyWith<$Res> {
  factory $QuizQuestionDtoCopyWith(
          QuizQuestionDto value, $Res Function(QuizQuestionDto) then) =
      _$QuizQuestionDtoCopyWithImpl<$Res, QuizQuestionDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quiz_set_id') String quizSetId,
      String question,
      @JsonKey(name: 'question_type') String questionType,
      List<String> options,
      @JsonKey(name: 'correct_answer') String? correctAnswer,
      @JsonKey(name: 'order_index') int orderIndex});
}

/// @nodoc
class _$QuizQuestionDtoCopyWithImpl<$Res, $Val extends QuizQuestionDto>
    implements $QuizQuestionDtoCopyWith<$Res> {
  _$QuizQuestionDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizQuestionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizSetId = null,
    Object? question = null,
    Object? questionType = null,
    Object? options = null,
    Object? correctAnswer = freezed,
    Object? orderIndex = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quizSetId: null == quizSetId
          ? _value.quizSetId
          : quizSetId // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      questionType: null == questionType
          ? _value.questionType
          : questionType // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<String>,
      correctAnswer: freezed == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuizQuestionDtoImplCopyWith<$Res>
    implements $QuizQuestionDtoCopyWith<$Res> {
  factory _$$QuizQuestionDtoImplCopyWith(_$QuizQuestionDtoImpl value,
          $Res Function(_$QuizQuestionDtoImpl) then) =
      __$$QuizQuestionDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quiz_set_id') String quizSetId,
      String question,
      @JsonKey(name: 'question_type') String questionType,
      List<String> options,
      @JsonKey(name: 'correct_answer') String? correctAnswer,
      @JsonKey(name: 'order_index') int orderIndex});
}

/// @nodoc
class __$$QuizQuestionDtoImplCopyWithImpl<$Res>
    extends _$QuizQuestionDtoCopyWithImpl<$Res, _$QuizQuestionDtoImpl>
    implements _$$QuizQuestionDtoImplCopyWith<$Res> {
  __$$QuizQuestionDtoImplCopyWithImpl(
      _$QuizQuestionDtoImpl _value, $Res Function(_$QuizQuestionDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuizQuestionDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizSetId = null,
    Object? question = null,
    Object? questionType = null,
    Object? options = null,
    Object? correctAnswer = freezed,
    Object? orderIndex = null,
  }) {
    return _then(_$QuizQuestionDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quizSetId: null == quizSetId
          ? _value.quizSetId
          : quizSetId // ignore: cast_nullable_to_non_nullable
              as String,
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      questionType: null == questionType
          ? _value.questionType
          : questionType // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<String>,
      correctAnswer: freezed == correctAnswer
          ? _value.correctAnswer
          : correctAnswer // ignore: cast_nullable_to_non_nullable
              as String?,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizQuestionDtoImpl implements _QuizQuestionDto {
  const _$QuizQuestionDtoImpl(
      {required this.id,
      @JsonKey(name: 'quiz_set_id') required this.quizSetId,
      required this.question,
      @JsonKey(name: 'question_type') this.questionType = 'mcq',
      required final List<String> options,
      @JsonKey(name: 'correct_answer') this.correctAnswer,
      @JsonKey(name: 'order_index') this.orderIndex = 0})
      : _options = options;

  factory _$QuizQuestionDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizQuestionDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'quiz_set_id')
  final String quizSetId;
  @override
  final String question;
  @override
  @JsonKey(name: 'question_type')
  final String questionType;
  final List<String> _options;
  @override
  List<String> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  @JsonKey(name: 'correct_answer')
  final String? correctAnswer;
  @override
  @JsonKey(name: 'order_index')
  final int orderIndex;

  @override
  String toString() {
    return 'QuizQuestionDto(id: $id, quizSetId: $quizSetId, question: $question, questionType: $questionType, options: $options, correctAnswer: $correctAnswer, orderIndex: $orderIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizQuestionDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quizSetId, quizSetId) ||
                other.quizSetId == quizSetId) &&
            (identical(other.question, question) ||
                other.question == question) &&
            (identical(other.questionType, questionType) ||
                other.questionType == questionType) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.correctAnswer, correctAnswer) ||
                other.correctAnswer == correctAnswer) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      quizSetId,
      question,
      questionType,
      const DeepCollectionEquality().hash(_options),
      correctAnswer,
      orderIndex);

  /// Create a copy of QuizQuestionDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizQuestionDtoImplCopyWith<_$QuizQuestionDtoImpl> get copyWith =>
      __$$QuizQuestionDtoImplCopyWithImpl<_$QuizQuestionDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizQuestionDtoImplToJson(
      this,
    );
  }
}

abstract class _QuizQuestionDto implements QuizQuestionDto {
  const factory _QuizQuestionDto(
          {required final String id,
          @JsonKey(name: 'quiz_set_id') required final String quizSetId,
          required final String question,
          @JsonKey(name: 'question_type') final String questionType,
          required final List<String> options,
          @JsonKey(name: 'correct_answer') final String? correctAnswer,
          @JsonKey(name: 'order_index') final int orderIndex}) =
      _$QuizQuestionDtoImpl;

  factory _QuizQuestionDto.fromJson(Map<String, dynamic> json) =
      _$QuizQuestionDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'quiz_set_id')
  String get quizSetId;
  @override
  String get question;
  @override
  @JsonKey(name: 'question_type')
  String get questionType;
  @override
  List<String> get options;
  @override
  @JsonKey(name: 'correct_answer')
  String? get correctAnswer;
  @override
  @JsonKey(name: 'order_index')
  int get orderIndex;

  /// Create a copy of QuizQuestionDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizQuestionDtoImplCopyWith<_$QuizQuestionDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
