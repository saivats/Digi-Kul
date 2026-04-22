// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaterialDtoImpl _$$MaterialDtoImplFromJson(Map<String, dynamic> json) =>
    _$MaterialDtoImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      fileName: json['file_name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'pdf',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      cohortId: json['cohort_id'] as String? ?? '',
      uploadedBy: json['uploaded_by'] as String? ?? '',
      uploadedAt: json['uploaded_at'] == null
          ? null
          : DateTime.parse(json['uploaded_at'] as String),
      downloadUrl: json['download_url'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localFilePath: json['localFilePath'] as String?,
    );

Map<String, dynamic> _$$MaterialDtoImplToJson(_$MaterialDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'file_name': instance.fileName,
      'file_type': instance.fileType,
      'file_size_bytes': instance.fileSizeBytes,
      'cohort_id': instance.cohortId,
      'uploaded_by': instance.uploadedBy,
      'uploaded_at': instance.uploadedAt?.toIso8601String(),
      'download_url': instance.downloadUrl,
      'isDownloaded': instance.isDownloaded,
      'localFilePath': instance.localFilePath,
    };
