// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lecture_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LectureDto _$LectureDtoFromJson(Map<String, dynamic> json) {
  return _LectureDto.fromJson(json);
}

/// @nodoc
mixin _$LectureDto {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'scheduled_time')
  DateTime get scheduledTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_minutes')
  int get durationMinutes => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'cohort_id')
  String get cohortId => throw _privateConstructorUsedError;
  @JsonKey(name: 'teacher_name')
  String get teacherName => throw _privateConstructorUsedError;
  @JsonKey(name: 'recording_id')
  String? get recordingId => throw _privateConstructorUsedError;
  @JsonKey(name: 'session_id')
  String? get sessionId => throw _privateConstructorUsedError;

  /// Serializes this LectureDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LectureDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LectureDtoCopyWith<LectureDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LectureDtoCopyWith<$Res> {
  factory $LectureDtoCopyWith(
          LectureDto value, $Res Function(LectureDto) then) =
      _$LectureDtoCopyWithImpl<$Res, LectureDto>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      @JsonKey(name: 'scheduled_time') DateTime scheduledTime,
      @JsonKey(name: 'duration_minutes') int durationMinutes,
      String status,
      @JsonKey(name: 'cohort_id') String cohortId,
      @JsonKey(name: 'teacher_name') String teacherName,
      @JsonKey(name: 'recording_id') String? recordingId,
      @JsonKey(name: 'session_id') String? sessionId});
}

/// @nodoc
class _$LectureDtoCopyWithImpl<$Res, $Val extends LectureDto>
    implements $LectureDtoCopyWith<$Res> {
  _$LectureDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LectureDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? scheduledTime = null,
    Object? durationMinutes = null,
    Object? status = null,
    Object? cohortId = null,
    Object? teacherName = null,
    Object? recordingId = freezed,
    Object? sessionId = freezed,
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
      scheduledTime: null == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      cohortId: null == cohortId
          ? _value.cohortId
          : cohortId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherName: null == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String,
      recordingId: freezed == recordingId
          ? _value.recordingId
          : recordingId // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LectureDtoImplCopyWith<$Res>
    implements $LectureDtoCopyWith<$Res> {
  factory _$$LectureDtoImplCopyWith(
          _$LectureDtoImpl value, $Res Function(_$LectureDtoImpl) then) =
      __$$LectureDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      @JsonKey(name: 'scheduled_time') DateTime scheduledTime,
      @JsonKey(name: 'duration_minutes') int durationMinutes,
      String status,
      @JsonKey(name: 'cohort_id') String cohortId,
      @JsonKey(name: 'teacher_name') String teacherName,
      @JsonKey(name: 'recording_id') String? recordingId,
      @JsonKey(name: 'session_id') String? sessionId});
}

/// @nodoc
class __$$LectureDtoImplCopyWithImpl<$Res>
    extends _$LectureDtoCopyWithImpl<$Res, _$LectureDtoImpl>
    implements _$$LectureDtoImplCopyWith<$Res> {
  __$$LectureDtoImplCopyWithImpl(
      _$LectureDtoImpl _value, $Res Function(_$LectureDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of LectureDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? scheduledTime = null,
    Object? durationMinutes = null,
    Object? status = null,
    Object? cohortId = null,
    Object? teacherName = null,
    Object? recordingId = freezed,
    Object? sessionId = freezed,
  }) {
    return _then(_$LectureDtoImpl(
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
      scheduledTime: null == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      cohortId: null == cohortId
          ? _value.cohortId
          : cohortId // ignore: cast_nullable_to_non_nullable
              as String,
      teacherName: null == teacherName
          ? _value.teacherName
          : teacherName // ignore: cast_nullable_to_non_nullable
              as String,
      recordingId: freezed == recordingId
          ? _value.recordingId
          : recordingId // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LectureDtoImpl extends _LectureDto {
  const _$LectureDtoImpl(
      {required this.id,
      required this.title,
      this.description = '',
      @JsonKey(name: 'scheduled_time') required this.scheduledTime,
      @JsonKey(name: 'duration_minutes') this.durationMinutes = 60,
      this.status = 'scheduled',
      @JsonKey(name: 'cohort_id') this.cohortId = '',
      @JsonKey(name: 'teacher_name') this.teacherName = '',
      @JsonKey(name: 'recording_id') this.recordingId,
      @JsonKey(name: 'session_id') this.sessionId})
      : super._();

  factory _$LectureDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$LectureDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'scheduled_time')
  final DateTime scheduledTime;
  @override
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'cohort_id')
  final String cohortId;
  @override
  @JsonKey(name: 'teacher_name')
  final String teacherName;
  @override
  @JsonKey(name: 'recording_id')
  final String? recordingId;
  @override
  @JsonKey(name: 'session_id')
  final String? sessionId;

  @override
  String toString() {
    return 'LectureDto(id: $id, title: $title, description: $description, scheduledTime: $scheduledTime, durationMinutes: $durationMinutes, status: $status, cohortId: $cohortId, teacherName: $teacherName, recordingId: $recordingId, sessionId: $sessionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LectureDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.cohortId, cohortId) ||
                other.cohortId == cohortId) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.recordingId, recordingId) ||
                other.recordingId == recordingId) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      scheduledTime,
      durationMinutes,
      status,
      cohortId,
      teacherName,
      recordingId,
      sessionId);

  /// Create a copy of LectureDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LectureDtoImplCopyWith<_$LectureDtoImpl> get copyWith =>
      __$$LectureDtoImplCopyWithImpl<_$LectureDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LectureDtoImplToJson(
      this,
    );
  }
}

abstract class _LectureDto extends LectureDto {
  const factory _LectureDto(
      {required final String id,
      required final String title,
      final String description,
      @JsonKey(name: 'scheduled_time') required final DateTime scheduledTime,
      @JsonKey(name: 'duration_minutes') final int durationMinutes,
      final String status,
      @JsonKey(name: 'cohort_id') final String cohortId,
      @JsonKey(name: 'teacher_name') final String teacherName,
      @JsonKey(name: 'recording_id') final String? recordingId,
      @JsonKey(name: 'session_id') final String? sessionId}) = _$LectureDtoImpl;
  const _LectureDto._() : super._();

  factory _LectureDto.fromJson(Map<String, dynamic> json) =
      _$LectureDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  @JsonKey(name: 'scheduled_time')
  DateTime get scheduledTime;
  @override
  @JsonKey(name: 'duration_minutes')
  int get durationMinutes;
  @override
  String get status;
  @override
  @JsonKey(name: 'cohort_id')
  String get cohortId;
  @override
  @JsonKey(name: 'teacher_name')
  String get teacherName;
  @override
  @JsonKey(name: 'recording_id')
  String? get recordingId;
  @override
  @JsonKey(name: 'session_id')
  String? get sessionId;

  /// Create a copy of LectureDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LectureDtoImplCopyWith<_$LectureDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
