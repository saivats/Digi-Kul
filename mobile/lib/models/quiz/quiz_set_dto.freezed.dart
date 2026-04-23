// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_set_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuizSetDto _$QuizSetDtoFromJson(Map<String, dynamic> json) {
  return _QuizSetDto.fromJson(json);
}

/// @nodoc
mixin _$QuizSetDto {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'cohort_id')
  String get cohortId => throw _privateConstructorUsedError;
  @JsonKey(name: 'question_count')
  int get questionCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_limit_seconds')
  int? get timeLimitSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'show_correct_answers')
  bool get showCorrectAnswers => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_from')
  DateTime get availableFrom => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_until')
  DateTime? get availableUntil => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  bool get isInProgress => throw _privateConstructorUsedError;

  /// Serializes this QuizSetDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizSetDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizSetDtoCopyWith<QuizSetDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizSetDtoCopyWith<$Res> {
  factory $QuizSetDtoCopyWith(
          QuizSetDto value, $Res Function(QuizSetDto) then) =
      _$QuizSetDtoCopyWithImpl<$Res, QuizSetDto>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      @JsonKey(name: 'cohort_id') String cohortId,
      @JsonKey(name: 'question_count') int questionCount,
      @JsonKey(name: 'time_limit_seconds') int? timeLimitSeconds,
      @JsonKey(name: 'show_correct_answers') bool showCorrectAnswers,
      @JsonKey(name: 'available_from') DateTime availableFrom,
      @JsonKey(name: 'available_until') DateTime? availableUntil,
      String status,
      bool isInProgress});
}

/// @nodoc
class _$QuizSetDtoCopyWithImpl<$Res, $Val extends QuizSetDto>
    implements $QuizSetDtoCopyWith<$Res> {
  _$QuizSetDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizSetDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? cohortId = null,
    Object? questionCount = null,
    Object? timeLimitSeconds = freezed,
    Object? showCorrectAnswers = null,
    Object? availableFrom = null,
    Object? availableUntil = freezed,
    Object? status = null,
    Object? isInProgress = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cohortId: null == cohortId
          ? _value.cohortId
          : cohortId // ignore: cast_nullable_to_non_nullable
              as String,
      questionCount: null == questionCount
          ? _value.questionCount
          : questionCount // ignore: cast_nullable_to_non_nullable
              as int,
      timeLimitSeconds: freezed == timeLimitSeconds
          ? _value.timeLimitSeconds
          : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      showCorrectAnswers: null == showCorrectAnswers
          ? _value.showCorrectAnswers
          : showCorrectAnswers // ignore: cast_nullable_to_non_nullable
              as bool,
      availableFrom: null == availableFrom
          ? _value.availableFrom
          : availableFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      availableUntil: freezed == availableUntil
          ? _value.availableUntil
          : availableUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      isInProgress: null == isInProgress
          ? _value.isInProgress
          : isInProgress // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuizSetDtoImplCopyWith<$Res>
    implements $QuizSetDtoCopyWith<$Res> {
  factory _$$QuizSetDtoImplCopyWith(
          _$QuizSetDtoImpl value, $Res Function(_$QuizSetDtoImpl) then) =
      __$$QuizSetDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      @JsonKey(name: 'cohort_id') String cohortId,
      @JsonKey(name: 'question_count') int questionCount,
      @JsonKey(name: 'time_limit_seconds') int? timeLimitSeconds,
      @JsonKey(name: 'show_correct_answers') bool showCorrectAnswers,
      @JsonKey(name: 'available_from') DateTime availableFrom,
      @JsonKey(name: 'available_until') DateTime? availableUntil,
      String status,
      bool isInProgress});
}

/// @nodoc
class __$$QuizSetDtoImplCopyWithImpl<$Res>
    extends _$QuizSetDtoCopyWithImpl<$Res, _$QuizSetDtoImpl>
    implements _$$QuizSetDtoImplCopyWith<$Res> {
  __$$QuizSetDtoImplCopyWithImpl(
      _$QuizSetDtoImpl _value, $Res Function(_$QuizSetDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuizSetDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? cohortId = null,
    Object? questionCount = null,
    Object? timeLimitSeconds = freezed,
    Object? showCorrectAnswers = null,
    Object? availableFrom = null,
    Object? availableUntil = freezed,
    Object? status = null,
    Object? isInProgress = null,
  }) {
    return _then(_$QuizSetDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      cohortId: null == cohortId
          ? _value.cohortId
          : cohortId // ignore: cast_nullable_to_non_nullable
              as String,
      questionCount: null == questionCount
          ? _value.questionCount
          : questionCount // ignore: cast_nullable_to_non_nullable
              as int,
      timeLimitSeconds: freezed == timeLimitSeconds
          ? _value.timeLimitSeconds
          : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      showCorrectAnswers: null == showCorrectAnswers
          ? _value.showCorrectAnswers
          : showCorrectAnswers // ignore: cast_nullable_to_non_nullable
              as bool,
      availableFrom: null == availableFrom
          ? _value.availableFrom
          : availableFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      availableUntil: freezed == availableUntil
          ? _value.availableUntil
          : availableUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      isInProgress: null == isInProgress
          ? _value.isInProgress
          : isInProgress // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizSetDtoImpl extends _QuizSetDto {
  const _$QuizSetDtoImpl(
      {required this.id,
      required this.title,
      this.description = '',
      @JsonKey(name: 'cohort_id') this.cohortId = '',
      @JsonKey(name: 'question_count') this.questionCount = 0,
      @JsonKey(name: 'time_limit_seconds') this.timeLimitSeconds,
      @JsonKey(name: 'show_correct_answers') this.showCorrectAnswers = true,
      @JsonKey(name: 'available_from') required this.availableFrom,
      @JsonKey(name: 'available_until') this.availableUntil,
      this.status = 'available',
      this.isInProgress = false})
      : super._();

  factory _$QuizSetDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizSetDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'cohort_id')
  final String cohortId;
  @override
  @JsonKey(name: 'question_count')
  final int questionCount;
  @override
  @JsonKey(name: 'time_limit_seconds')
  final int? timeLimitSeconds;
  @override
  @JsonKey(name: 'show_correct_answers')
  final bool showCorrectAnswers;
  @override
  @JsonKey(name: 'available_from')
  final DateTime availableFrom;
  @override
  @JsonKey(name: 'available_until')
  final DateTime? availableUntil;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final bool isInProgress;

  @override
  String toString() {
    return 'QuizSetDto(id: $id, title: $title, description: $description, cohortId: $cohortId, questionCount: $questionCount, timeLimitSeconds: $timeLimitSeconds, showCorrectAnswers: $showCorrectAnswers, availableFrom: $availableFrom, availableUntil: $availableUntil, status: $status, isInProgress: $isInProgress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizSetDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.cohortId, cohortId) ||
                other.cohortId == cohortId) &&
            (identical(other.questionCount, questionCount) ||
                other.questionCount == questionCount) &&
            (identical(other.timeLimitSeconds, timeLimitSeconds) ||
                other.timeLimitSeconds == timeLimitSeconds) &&
            (identical(other.showCorrectAnswers, showCorrectAnswers) ||
                other.showCorrectAnswers == showCorrectAnswers) &&
            (identical(other.availableFrom, availableFrom) ||
                other.availableFrom == availableFrom) &&
            (identical(other.availableUntil, availableUntil) ||
                other.availableUntil == availableUntil) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isInProgress, isInProgress) ||
                other.isInProgress == isInProgress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      cohortId,
      questionCount,
      timeLimitSeconds,
      showCorrectAnswers,
      availableFrom,
      availableUntil,
      status,
      isInProgress);

  /// Create a copy of QuizSetDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizSetDtoImplCopyWith<_$QuizSetDtoImpl> get copyWith =>
      __$$QuizSetDtoImplCopyWithImpl<_$QuizSetDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizSetDtoImplToJson(
      this,
    );
  }
}

abstract class _QuizSetDto extends QuizSetDto {
  const factory _QuizSetDto(
      {required final String id,
      required final String title,
      final String description,
      @JsonKey(name: 'cohort_id') final String cohortId,
      @JsonKey(name: 'question_count') final int questionCount,
      @JsonKey(name: 'time_limit_seconds') final int? timeLimitSeconds,
      @JsonKey(name: 'show_correct_answers') final bool showCorrectAnswers,
      @JsonKey(name: 'available_from') required final DateTime availableFrom,
      @JsonKey(name: 'available_until') final DateTime? availableUntil,
      final String status,
      final bool isInProgress}) = _$QuizSetDtoImpl;
  const _QuizSetDto._() : super._();

  factory _QuizSetDto.fromJson(Map<String, dynamic> json) =
      _$QuizSetDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  @JsonKey(name: 'cohort_id')
  String get cohortId;
  @override
  @JsonKey(name: 'question_count')
  int get questionCount;
  @override
  @JsonKey(name: 'time_limit_seconds')
  int? get timeLimitSeconds;
  @override
  @JsonKey(name: 'show_correct_answers')
  bool get showCorrectAnswers;
  @override
  @JsonKey(name: 'available_from')
  DateTime get availableFrom;
  @override
  @JsonKey(name: 'available_until')
  DateTime? get availableUntil;
  @override
  String get status;
  @override
  bool get isInProgress;

  /// Create a copy of QuizSetDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizSetDtoImplCopyWith<_$QuizSetDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
