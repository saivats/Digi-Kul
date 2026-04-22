import 'package:freezed_annotation/freezed_annotation.dart';

import 'cached_material.dart';

part 'material_dto.freezed.dart';
part 'material_dto.g.dart';

@freezed
class MaterialDto with _$MaterialDto {
  const MaterialDto._();

  const factory MaterialDto({
    required String id,
    required String title,
    @JsonKey(name: 'file_name') @Default('') String fileName,
    @JsonKey(name: 'file_type') @Default('pdf') String fileType,
    @JsonKey(name: 'file_size_bytes') @Default(0) int fileSizeBytes,
    @JsonKey(name: 'cohort_id') @Default('') String cohortId,
    @JsonKey(name: 'uploaded_by') @Default('') String uploadedBy,
    @JsonKey(name: 'uploaded_at') DateTime? uploadedAt,
    @JsonKey(name: 'download_url') String? downloadUrl,
    @Default(false) bool isDownloaded,
    String? localFilePath,
  }) = _MaterialDto;

  factory MaterialDto.fromJson(Map<String, dynamic> json) =>
      _$MaterialDtoFromJson(json);

  factory MaterialDto.fromCached(CachedMaterial cached) => MaterialDto(
        id: cached.serverId,
        title: cached.title,
        fileName: cached.fileName,
        fileType: cached.fileType,
        fileSizeBytes: cached.fileSizeBytes,
        cohortId: cached.cohortId,
        uploadedBy: cached.uploadedBy,
        uploadedAt: cached.uploadedAt,
        isDownloaded: cached.isDownloaded,
        localFilePath: cached.localFilePath,
      );

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  CachedMaterial toCached() {
    return CachedMaterial()
      ..serverId = id
      ..title = title
      ..fileName = fileName
      ..fileType = fileType
      ..fileSizeBytes = fileSizeBytes
      ..cohortId = cohortId
      ..uploadedBy = uploadedBy
      ..uploadedAt = uploadedAt ?? DateTime.now()
      ..isDownloaded = isDownloaded
      ..localFilePath = localFilePath
      ..cachedAt = DateTime.now();
  }
}
