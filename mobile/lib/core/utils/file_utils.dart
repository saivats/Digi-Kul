import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  FileUtils._();

  static Future<String> get appDocumentsPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String> get materialsPath async {
    final base = await appDocumentsPath;
    final dir = Directory('$base/materials');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String fileTypeIcon(String fileType) {
    final lower = fileType.toLowerCase();
    if (lower.contains('pdf')) return 'pdf';
    if (lower.contains('audio') || lower.contains('mp3') || lower.contains('wav')) {
      return 'audio';
    }
    if (lower.contains('image') || lower.contains('jpg') || lower.contains('png')) {
      return 'image';
    }
    if (lower.contains('video') || lower.contains('mp4')) return 'video';
    if (lower.contains('doc') || lower.contains('word')) return 'doc';
    if (lower.contains('ppt') || lower.contains('presentation')) return 'ppt';
    if (lower.contains('xls') || lower.contains('sheet')) return 'xls';
    return 'file';
  }

  static Future<int> calculateDirectorySize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  static Future<void> deleteAllDownloads() async {
    final path = await materialsPath;
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }
}
