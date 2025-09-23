import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'material.g.dart';

/// Material model representing educational content files
@JsonSerializable()
class MaterialItem extends Equatable {
  final String id;
  @JsonKey(name: 'lecture_id')
  final String lectureId;
  final String title;
  final String? description;
  @JsonKey(name: 'file_path')
  final String filePath;
  @JsonKey(name: 'compressed_path')
  final String compressedPath;
  @JsonKey(name: 'file_size')
  final int fileSize;
  @JsonKey(name: 'file_type')
  final String fileType;
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional fields from API responses
  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  @JsonKey(name: 'file_size_mb')
  final double? fileSizeMb;
  
  // Local download information
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localPath;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isDownloaded;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTime? downloadedAt;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final DownloadStatus downloadStatus;

  const MaterialItem({
    required this.id,
    required this.lectureId,
    required this.title,
    this.description,
    required this.filePath,
    required this.compressedPath,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
    this.isActive = true,
    this.downloadUrl,
    this.fileSizeMb,
    this.localPath,
    this.isDownloaded = false,
    this.downloadedAt,
    this.downloadStatus = DownloadStatus.notDownloaded,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) =>
      _$MaterialItemFromJson(json);

  Map<String, dynamic> toJson() => _$MaterialItemToJson(this);

  MaterialItem copyWith({
    String? id,
    String? lectureId,
    String? title,
    String? description,
    String? filePath,
    String? compressedPath,
    int? fileSize,
    String? fileType,
    DateTime? uploadedAt,
    bool? isActive,
    String? downloadUrl,
    double? fileSizeMb,
    String? localPath,
    bool? isDownloaded,
    DateTime? downloadedAt,
    DownloadStatus? downloadStatus,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      compressedPath: compressedPath ?? this.compressedPath,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isActive: isActive ?? this.isActive,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      downloadStatus: downloadStatus ?? this.downloadStatus,
    );
  }

  /// Get file extension
  String get fileExtension {
    final parts = title.split('.');
    return parts.length > 1 ? '.${parts.last.toLowerCase()}' : '';
  }

  /// Check if file is an audio file
  bool get isAudio => fileType == 'audio' || _audioExtensions.contains(fileExtension);

  /// Check if file is an image file
  bool get isImage => fileType == 'image' || _imageExtensions.contains(fileExtension);

  /// Check if file is a document file
  bool get isDocument => fileType == 'document' || _documentExtensions.contains(fileExtension);

  /// Check if file is a video file
  bool get isVideo => fileType == 'video' || _videoExtensions.contains(fileExtension);

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSizeMb != null) {
      if (fileSizeMb! < 1) {
        return '${(fileSizeMb! * 1024).toStringAsFixed(0)} KB';
      }
      return '${fileSizeMb!.toStringAsFixed(1)} MB';
    }
    
    final sizeInMb = fileSize / (1024 * 1024);
    if (sizeInMb < 1) {
      return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeInMb.toStringAsFixed(1)} MB';
  }

  /// Get material icon based on file type
  String get iconName {
    if (isAudio) return 'audio_file';
    if (isImage) return 'image';
    if (isVideo) return 'video_file';
    if (fileExtension == '.pdf') return 'picture_as_pdf';
    if (_wordExtensions.contains(fileExtension)) return 'description';
    if (_presentationExtensions.contains(fileExtension)) return 'slideshow';
    return 'insert_drive_file';
  }

  /// Check if file can be previewed in app
  bool get canPreview {
    return isImage || fileExtension == '.pdf';
  }

  /// Check if file can be played in app
  bool get canPlay {
    return isAudio || isVideo;
  }

  static const List<String> _audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
  static const List<String> _imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
  static const List<String> _documentExtensions = ['.pdf', '.doc', '.docx', '.txt', '.rtf'];
  static const List<String> _videoExtensions = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv'];
  static const List<String> _wordExtensions = ['.doc', '.docx', '.txt', '.rtf'];
  static const List<String> _presentationExtensions = ['.ppt', '.pptx', '.odp'];

  @override
  List<Object?> get props => [
        id,
        lectureId,
        title,
        description,
        filePath,
        compressedPath,
        fileSize,
        fileType,
        uploadedAt,
        isActive,
        downloadUrl,
        fileSizeMb,
        localPath,
        isDownloaded,
        downloadedAt,
        downloadStatus,
      ];

  @override
  String toString() {
    return 'MaterialItem{id: $id, title: $title, type: $fileType, size: $formattedFileSize}';
  }
}

/// Download status enumeration
enum DownloadStatus {
  notDownloaded,
  pending,
  downloading,
  completed,
  failed,
  paused,
}

/// Download progress information
@JsonSerializable()
class DownloadProgress extends Equatable {
  final String materialId;
  final int received;
  final int total;
  final double progress;
  final DownloadStatus status;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const DownloadProgress({
    required this.materialId,
    required this.received,
    required this.total,
    required this.progress,
    required this.status,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  factory DownloadProgress.fromJson(Map<String, dynamic> json) =>
      _$DownloadProgressFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadProgressToJson(this);

  DownloadProgress copyWith({
    String? materialId,
    int? received,
    int? total,
    double? progress,
    DownloadStatus? status,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DownloadProgress(
      materialId: materialId ?? this.materialId,
      received: received ?? this.received,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Get formatted download progress
  String get formattedProgress {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  /// Get formatted received size
  String get formattedReceived {
    final sizeInMb = received / (1024 * 1024);
    if (sizeInMb < 1) {
      return '${(received / 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeInMb.toStringAsFixed(1)} MB';
  }

  /// Get formatted total size
  String get formattedTotal {
    final sizeInMb = total / (1024 * 1024);
    if (sizeInMb < 1) {
      return '${(total / 1024).toStringAsFixed(0)} KB';
    }
    return '${sizeInMb.toStringAsFixed(1)} MB';
  }

  /// Get download speed if applicable
  String? get downloadSpeed {
    if (startedAt == null || status != DownloadStatus.downloading) {
      return null;
    }
    
    final duration = DateTime.now().difference(startedAt!);
    if (duration.inSeconds == 0) return null;
    
    final bytesPerSecond = received / duration.inSeconds;
    final kbPerSecond = bytesPerSecond / 1024;
    
    if (kbPerSecond < 1024) {
      return '${kbPerSecond.toStringAsFixed(0)} KB/s';
    }
    
    final mbPerSecond = kbPerSecond / 1024;
    return '${mbPerSecond.toStringAsFixed(1)} MB/s';
  }

  @override
  List<Object?> get props => [
        materialId,
        received,
        total,
        progress,
        status,
        error,
        startedAt,
        completedAt,
      ];
}

/// Material download request
@JsonSerializable()
class MaterialDownloadRequest extends Equatable {
  @JsonKey(name: 'material_id')
  final String materialId;
  @JsonKey(name: 'save_path')
  final String savePath;

  const MaterialDownloadRequest({
    required this.materialId,
    required this.savePath,
  });

  factory MaterialDownloadRequest.fromJson(Map<String, dynamic> json) =>
      _$MaterialDownloadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MaterialDownloadRequestToJson(this);

  @override
  List<Object?> get props => [materialId, savePath];
}
