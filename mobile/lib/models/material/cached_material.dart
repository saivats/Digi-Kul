import 'package:isar/isar.dart';

part 'cached_material.g.dart';

@collection
class CachedMaterial {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverId;

  late String title;
  late String fileName;
  late String fileType;
  late int fileSizeBytes;
  late String cohortId;
  late String uploadedBy;
  late DateTime uploadedAt;
  bool isDownloaded = false;
  String? localFilePath;
  DateTime? cachedAt;

  @ignore
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
