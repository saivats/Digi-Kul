// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttendanceDto _$AttendanceDtoFromJson(Map<String, dynamic> json) {
  return _AttendanceDto.fromJson(json);
}

/// @nodoc
mixin _$AttendanceDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'lecture_id')
  String get lectureId => throw _privateConstructorUsedError;
  @JsonKey(name: 'lecture_title')
  String get lectureTitle => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'lecture_date')
  DateTime get lectureDate => throw _privateConstructorUsedError;

  /// Serializes this AttendanceDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttendanceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendanceDtoCopyWith<AttendanceDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceDtoCopyWith<$Res> {
  factory $AttendanceDtoCopyWith(
          AttendanceDto value, $Res Function(AttendanceDto) then) =
      _$AttendanceDtoCopyWithImpl<$Res, AttendanceDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'lecture_id') String lectureId,
      @JsonKey(name: 'lecture_title') String lectureTitle,
      String status,
      @JsonKey(name: 'lecture_date') DateTime lectureDate});
}

/// @nodoc
class _$AttendanceDtoCopyWithImpl<$Res, $Val extends AttendanceDto>
    implements $AttendanceDtoCopyWith<$Res> {
  _$AttendanceDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendanceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lectureId = null,
    Object? lectureTitle = null,
    Object? status = null,
    Object? lectureDate = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lectureId: null == lectureId
          ? _value.lectureId
          : lectureId // ignore: cast_nullable_to_non_nullable
              as String,
      lectureTitle: null == lectureTitle
          ? _value.lectureTitle
          : lectureTitle // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      lectureDate: null == lectureDate
          ? _value.lectureDate
          : lectureDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceDtoImplCopyWith<$Res>
    implements $AttendanceDtoCopyWith<$Res> {
  factory _$$AttendanceDtoImplCopyWith(
          _$AttendanceDtoImpl value, $Res Function(_$AttendanceDtoImpl) then) =
      __$$AttendanceDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'lecture_id') String lectureId,
      @JsonKey(name: 'lecture_title') String lectureTitle,
      String status,
      @JsonKey(name: 'lecture_date') DateTime lectureDate});
}

/// @nodoc
class __$$AttendanceDtoImplCopyWithImpl<$Res>
    extends _$AttendanceDtoCopyWithImpl<$Res, _$AttendanceDtoImpl>
    implements _$$AttendanceDtoImplCopyWith<$Res> {
  __$$AttendanceDtoImplCopyWithImpl(
      _$AttendanceDtoImpl _value, $Res Function(_$AttendanceDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendanceDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lectureId = null,
    Object? lectureTitle = null,
    Object? status = null,
    Object? lectureDate = null,
  }) {
    return _then(_$AttendanceDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lectureId: null == lectureId
          ? _value.lectureId
          : lectureId // ignore: cast_nullable_to_non_nullable
              as String,
      lectureTitle: null == lectureTitle
          ? _value.lectureTitle
          : lectureTitle // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      lectureDate: null == lectureDate
          ? _value.lectureDate
          : lectureDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceDtoImpl extends _AttendanceDto {
  const _$AttendanceDtoImpl(
      {required this.id,
      @JsonKey(name: 'lecture_id') required this.lectureId,
      @JsonKey(name: 'lecture_title') this.lectureTitle = '',
      this.status = 'absent',
      @JsonKey(name: 'lecture_date') required this.lectureDate})
      : super._();

  factory _$AttendanceDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'lecture_id')
  final String lectureId;
  @override
  @JsonKey(name: 'lecture_title')
  final String lectureTitle;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'lecture_date')
  final DateTime lectureDate;

  @override
  String toString() {
    return 'AttendanceDto(id: $id, lectureId: $lectureId, lectureTitle: $lectureTitle, status: $status, lectureDate: $lectureDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lectureId, lectureId) ||
                other.lectureId == lectureId) &&
            (identical(other.lectureTitle, lectureTitle) ||
                other.lectureTitle == lectureTitle) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lectureDate, lectureDate) ||
                other.lectureDate == lectureDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, lectureId, lectureTitle, status, lectureDate);

  /// Create a copy of AttendanceDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceDtoImplCopyWith<_$AttendanceDtoImpl> get copyWith =>
      __$$AttendanceDtoImplCopyWithImpl<_$AttendanceDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceDtoImplToJson(
      this,
    );
  }
}

abstract class _AttendanceDto extends AttendanceDto {
  const factory _AttendanceDto(
          {required final String id,
          @JsonKey(name: 'lecture_id') required final String lectureId,
          @JsonKey(name: 'lecture_title') final String lectureTitle,
          final String status,
          @JsonKey(name: 'lecture_date') required final DateTime lectureDate}) =
      _$AttendanceDtoImpl;
  const _AttendanceDto._() : super._();

  factory _AttendanceDto.fromJson(Map<String, dynamic> json) =
      _$AttendanceDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'lecture_id')
  String get lectureId;
  @override
  @JsonKey(name: 'lecture_title')
  String get lectureTitle;
  @override
  String get status;
  @override
  @JsonKey(name: 'lecture_date')
  DateTime get lectureDate;

  /// Create a copy of AttendanceDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendanceDtoImplCopyWith<_$AttendanceDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
