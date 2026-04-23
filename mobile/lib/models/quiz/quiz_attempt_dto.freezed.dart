// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_attempt_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuizAttemptDto _$QuizAttemptDtoFromJson(Map<String, dynamic> json) {
  return _QuizAttemptDto.fromJson(json);
}

/// @nodoc
mixin _$QuizAttemptDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'quiz_set_id')
  String get quizSetId => throw _privateConstructorUsedError;
  @JsonKey(name: 'student_id')
  String get studentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'started_at')
  DateTime get startedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'submitted_at')
  DateTime? get submittedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this QuizAttemptDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuizAttemptDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuizAttemptDtoCopyWith<QuizAttemptDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuizAttemptDtoCopyWith<$Res> {
  factory $QuizAttemptDtoCopyWith(
          QuizAttemptDto value, $Res Function(QuizAttemptDto) then) =
      _$QuizAttemptDtoCopyWithImpl<$Res, QuizAttemptDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quiz_set_id') String quizSetId,
      @JsonKey(name: 'student_id') String studentId,
      @JsonKey(name: 'started_at') DateTime startedAt,
      @JsonKey(name: 'submitted_at') DateTime? submittedAt,
      String status});
}

/// @nodoc
class _$QuizAttemptDtoCopyWithImpl<$Res, $Val extends QuizAttemptDto>
    implements $QuizAttemptDtoCopyWith<$Res> {
  _$QuizAttemptDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuizAttemptDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizSetId = null,
    Object? studentId = null,
    Object? startedAt = null,
    Object? submittedAt = freezed,
    Object? status = null,
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
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuizAttemptDtoImplCopyWith<$Res>
    implements $QuizAttemptDtoCopyWith<$Res> {
  factory _$$QuizAttemptDtoImplCopyWith(_$QuizAttemptDtoImpl value,
          $Res Function(_$QuizAttemptDtoImpl) then) =
      __$$QuizAttemptDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quiz_set_id') String quizSetId,
      @JsonKey(name: 'student_id') String studentId,
      @JsonKey(name: 'started_at') DateTime startedAt,
      @JsonKey(name: 'submitted_at') DateTime? submittedAt,
      String status});
}

/// @nodoc
class __$$QuizAttemptDtoImplCopyWithImpl<$Res>
    extends _$QuizAttemptDtoCopyWithImpl<$Res, _$QuizAttemptDtoImpl>
    implements _$$QuizAttemptDtoImplCopyWith<$Res> {
  __$$QuizAttemptDtoImplCopyWithImpl(
      _$QuizAttemptDtoImpl _value, $Res Function(_$QuizAttemptDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of QuizAttemptDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? quizSetId = null,
    Object? studentId = null,
    Object? startedAt = null,
    Object? submittedAt = freezed,
    Object? status = null,
  }) {
    return _then(_$QuizAttemptDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      quizSetId: null == quizSetId
          ? _value.quizSetId
          : quizSetId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      submittedAt: freezed == submittedAt
          ? _value.submittedAt
          : submittedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuizAttemptDtoImpl implements _QuizAttemptDto {
  const _$QuizAttemptDtoImpl(
      {required this.id,
      @JsonKey(name: 'quiz_set_id') required this.quizSetId,
      @JsonKey(name: 'student_id') required this.studentId,
      @JsonKey(name: 'started_at') required this.startedAt,
      @JsonKey(name: 'submitted_at') this.submittedAt,
      this.status = 'in_progress'});

  factory _$QuizAttemptDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuizAttemptDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'quiz_set_id')
  final String quizSetId;
  @override
  @JsonKey(name: 'student_id')
  final String studentId;
  @override
  @JsonKey(name: 'started_at')
  final DateTime startedAt;
  @override
  @JsonKey(name: 'submitted_at')
  final DateTime? submittedAt;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'QuizAttemptDto(id: $id, quizSetId: $quizSetId, studentId: $studentId, startedAt: $startedAt, submittedAt: $submittedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuizAttemptDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.quizSetId, quizSetId) ||
                other.quizSetId == quizSetId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, quizSetId, studentId, startedAt, submittedAt, status);

  /// Create a copy of QuizAttemptDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuizAttemptDtoImplCopyWith<_$QuizAttemptDtoImpl> get copyWith =>
      __$$QuizAttemptDtoImplCopyWithImpl<_$QuizAttemptDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuizAttemptDtoImplToJson(
      this,
    );
  }
}

abstract class _QuizAttemptDto implements QuizAttemptDto {
  const factory _QuizAttemptDto(
      {required final String id,
      @JsonKey(name: 'quiz_set_id') required final String quizSetId,
      @JsonKey(name: 'student_id') required final String studentId,
      @JsonKey(name: 'started_at') required final DateTime startedAt,
      @JsonKey(name: 'submitted_at') final DateTime? submittedAt,
      final String status}) = _$QuizAttemptDtoImpl;

  factory _QuizAttemptDto.fromJson(Map<String, dynamic> json) =
      _$QuizAttemptDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'quiz_set_id')
  String get quizSetId;
  @override
  @JsonKey(name: 'student_id')
  String get studentId;
  @override
  @JsonKey(name: 'started_at')
  DateTime get startedAt;
  @override
  @JsonKey(name: 'submitted_at')
  DateTime? get submittedAt;
  @override
  String get status;

  /// Create a copy of QuizAttemptDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuizAttemptDtoImplCopyWith<_$QuizAttemptDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
