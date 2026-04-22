// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MaterialDto _$MaterialDtoFromJson(Map<String, dynamic> json) {
  return _MaterialDto.fromJson(json);
}

/// @nodoc
mixin _$MaterialDto {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_name')
  String get fileName => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_type')
  String get fileType => throw _privateConstructorUsedError;
  @JsonKey(name: 'file_size_bytes')
  int get fileSizeBytes => throw _privateConstructorUsedError;
  @JsonKey(name: 'cohort_id')
  String get cohortId => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploaded_by')
  String get uploadedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'uploaded_at')
  DateTime? get uploadedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'download_url')
  String? get downloadUrl => throw _privateConstructorUsedError;
  bool get isDownloaded => throw _privateConstructorUsedError;
  String? get localFilePath => throw _privateConstructorUsedError;

  /// Serializes this MaterialDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaterialDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaterialDtoCopyWith<MaterialDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaterialDtoCopyWith<$Res> {
  factory $MaterialDtoCopyWith(
          MaterialDto value, $Res Function(MaterialDto) then) =
      _$MaterialDtoCopyWithImpl<$Res, MaterialDto>;
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_type') String fileType,
      @JsonKey(name: 'file_size_bytes') int fileSizeBytes,
      @JsonKey(name: 'cohort_id') String cohortId,
      @JsonKey(name: 'uploaded_by') String uploadedBy,
      @JsonKey(name: 'uploaded_at') DateTime? uploadedAt,
      @JsonKey(name: 'download_url') String? downloadUrl,
      bool isDownloaded,
      String? localFilePath});
}

/// @nodoc
class _$MaterialDtoCopyWithImpl<$Res, $Val extends MaterialDto>
    implements $MaterialDtoCopyWith<$Res> {
  _$MaterialDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaterialDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? fileName = null,
    Object? fileType = null,
    Object? fileSizeBytes = null,
    Object? cohortId = null,
    Object? uploadedBy = null,
    Object? uploadedAt = freezed,
    Object? downloadUrl = freezed,
    Object? isDownloaded = null,
    Object? localFilePath = freezed,
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
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      fileSizeBytes: null == fileSizeBytes
          ? _value.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      cohortId: null == cohortId
          ? _value.cohortId
          : cohortId // ignore: cast_nullable_to_non_nullable
              as String,
      uploadedBy: null == uploadedBy
          ? _value.uploadedBy
          : uploadedBy // ignore: cast_nullable_to_non_nullable
              as String,
      uploadedAt: freezed == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      downloadUrl: freezed == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isDownloaded: null == isDownloaded
          ? _value.isDownloaded
          : isDownloaded // ignore: cast_nullable_to_non_nullable
              as bool,
      localFilePath: freezed == localFilePath
          ? _value.localFilePath
          : localFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MaterialDtoImplCopyWith<$Res>
    implements $MaterialDtoCopyWith<$Res> {
  factory _$$MaterialDtoImplCopyWith(
          _$MaterialDtoImpl value, $Res Function(_$MaterialDtoImpl) then) =
      __$$MaterialDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      @JsonKey(name: 'file_name') String fileName,
      @JsonKey(name: 'file_type') String fileType,
      @JsonKey(name: 'file_size_bytes') int fileSizeBytes,
      @JsonKey(name: 'cohort_id') String cohortId,
      @JsonKey(name: 'uploaded_by') String uploadedBy,
      @JsonKey(name: 'uploaded_at') DateTime? uploadedAt,
      @JsonKey(name: 'download_url') String? downloadUrl,
      bool isDownloaded,
      String? localFilePath});
}

/// @nodoc
class __$$MaterialDtoImplCopyWithImpl<$Res>
    extends _$MaterialDtoCopyWithImpl<$Res, _$MaterialDtoImpl>
    implements _$$MaterialDtoImplCopyWith<$Res> {
  __$$MaterialDtoImplCopyWithImpl(
      _$MaterialDtoImpl _value, $Res Function(_$MaterialDtoImpl) _then)
      : super(_value, _then);

  /// Create a copy of MaterialDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? fileName = null,
    Object? fileType = null,
    Object? fileSizeBytes = null,
    Object? cohortId = null,
    Object? uploadedBy = null,
    Object? uploadedAt = freezed,
    Object? downloadUrl = freezed,
    Object? isDownloaded = null,
    Object? localFilePath = freezed,
  }) {
    return _then(_$MaterialDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      fileSizeBytes: null == fileSizeBytes
          ? _value.fileSizeBytes
          : fileSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      cohortId: null == cohortId
          ? _value.cohortId
          : cohortId // ignore: cast_nullable_to_non_nullable
              as String,
      uploadedBy: null == uploadedBy
          ? _value.uploadedBy
          : uploadedBy // ignore: cast_nullable_to_non_nullable
              as String,
      uploadedAt: freezed == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      downloadUrl: freezed == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isDownloaded: null == isDownloaded
          ? _value.isDownloaded
          : isDownloaded // ignore: cast_nullable_to_non_nullable
              as bool,
      localFilePath: freezed == localFilePath
          ? _value.localFilePath
          : localFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MaterialDtoImpl extends _MaterialDto {
  const _$MaterialDtoImpl(
      {required this.id,
      required this.title,
      @JsonKey(name: 'file_name') this.fileName = '',
      @JsonKey(name: 'file_type') this.fileType = 'pdf',
      @JsonKey(name: 'file_size_bytes') this.fileSizeBytes = 0,
      @JsonKey(name: 'cohort_id') this.cohortId = '',
      @JsonKey(name: 'uploaded_by') this.uploadedBy = '',
      @JsonKey(name: 'uploaded_at') this.uploadedAt,
      @JsonKey(name: 'download_url') this.downloadUrl,
      this.isDownloaded = false,
      this.localFilePath})
      : super._();

  factory _$MaterialDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaterialDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey(name: 'file_name')
  final String fileName;
  @override
  @JsonKey(name: 'file_type')
  final String fileType;
  @override
  @JsonKey(name: 'file_size_bytes')
  final int fileSizeBytes;
  @override
  @JsonKey(name: 'cohort_id')
  final String cohortId;
  @override
  @JsonKey(name: 'uploaded_by')
  final String uploadedBy;
  @override
  @JsonKey(name: 'uploaded_at')
  final DateTime? uploadedAt;
  @override
  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  @override
  @JsonKey()
  final bool isDownloaded;
  @override
  final String? localFilePath;

  @override
  String toString() {
    return 'MaterialDto(id: $id, title: $title, fileName: $fileName, fileType: $fileType, fileSizeBytes: $fileSizeBytes, cohortId: $cohortId, uploadedBy: $uploadedBy, uploadedAt: $uploadedAt, downloadUrl: $downloadUrl, isDownloaded: $isDownloaded, localFilePath: $localFilePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaterialDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.fileSizeBytes, fileSizeBytes) ||
                other.fileSizeBytes == fileSizeBytes) &&
            (identical(other.cohortId, cohortId) ||
                other.cohortId == cohortId) &&
            (identical(other.uploadedBy, uploadedBy) ||
                other.uploadedBy == uploadedBy) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.isDownloaded, isDownloaded) ||
                other.isDownloaded == isDownloaded) &&
            (identical(other.localFilePath, localFilePath) ||
                other.localFilePath == localFilePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      fileName,
      fileType,
      fileSizeBytes,
      cohortId,
      uploadedBy,
      uploadedAt,
      downloadUrl,
      isDownloaded,
      localFilePath);

  /// Create a copy of MaterialDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaterialDtoImplCopyWith<_$MaterialDtoImpl> get copyWith =>
      __$$MaterialDtoImplCopyWithImpl<_$MaterialDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MaterialDtoImplToJson(
      this,
    );
  }
}

abstract class _MaterialDto extends MaterialDto {
  const factory _MaterialDto(
      {required final String id,
      required final String title,
      @JsonKey(name: 'file_name') final String fileName,
      @JsonKey(name: 'file_type') final String fileType,
      @JsonKey(name: 'file_size_bytes') final int fileSizeBytes,
      @JsonKey(name: 'cohort_id') final String cohortId,
      @JsonKey(name: 'uploaded_by') final String uploadedBy,
      @JsonKey(name: 'uploaded_at') final DateTime? uploadedAt,
      @JsonKey(name: 'download_url') final String? downloadUrl,
      final bool isDownloaded,
      final String? localFilePath}) = _$MaterialDtoImpl;
  const _MaterialDto._() : super._();

  factory _MaterialDto.fromJson(Map<String, dynamic> json) =
      _$MaterialDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  @JsonKey(name: 'file_name')
  String get fileName;
  @override
  @JsonKey(name: 'file_type')
  String get fileType;
  @override
  @JsonKey(name: 'file_size_bytes')
  int get fileSizeBytes;
  @override
  @JsonKey(name: 'cohort_id')
  String get cohortId;
  @override
  @JsonKey(name: 'uploaded_by')
  String get uploadedBy;
  @override
  @JsonKey(name: 'uploaded_at')
  DateTime? get uploadedAt;
  @override
  @JsonKey(name: 'download_url')
  String? get downloadUrl;
  @override
  bool get isDownloaded;
  @override
  String? get localFilePath;

  /// Create a copy of MaterialDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaterialDtoImplCopyWith<_$MaterialDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
