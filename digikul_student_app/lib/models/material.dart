class MaterialItem {
  final String id;
  final String title;
  final String fileName;
  final String lectureId;
  final String? description;
  final String? filePath;
  final String? compressedPath;
  final int? fileSize;
  final DateTime uploadedAt;
  final bool isActive;
  
  // Additional fields from API responses
  final String? downloadUrl;
  final String? lectureTitle;
  final String? teacherId;

  const MaterialItem({
    required this.id,
    required this.title,
    required this.fileName,
    required this.lectureId,
    this.description,
    this.filePath,
    this.compressedPath,
    this.fileSize,
    required this.uploadedAt,
    this.isActive = true,
    this.downloadUrl,
    this.lectureTitle,
    this.teacherId,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      fileName: json['file_name'] ?? '',
      lectureId: json['lecture_id'] ?? '',
      description: json['description'],
      filePath: json['file_path'],
      compressedPath: json['compressed_path'],
      fileSize: json['file_size'],
      uploadedAt: DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
      downloadUrl: json['download_url'],
      lectureTitle: json['lecture_title'],
      teacherId: json['teacher_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_name': fileName,
      'lecture_id': lectureId,
      'description': description,
      'file_path': filePath,
      'compressed_path': compressedPath,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
      'is_active': isActive,
      'download_url': downloadUrl,
      'lecture_title': lectureTitle,
      'teacher_id': teacherId,
    };
  }

  MaterialItem copyWith({
    String? id,
    String? title,
    String? fileName,
    String? lectureId,
    String? description,
    String? filePath,
    String? compressedPath,
    int? fileSize,
    DateTime? uploadedAt,
    bool? isActive,
    String? downloadUrl,
    String? lectureTitle,
    String? teacherId,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      lectureId: lectureId ?? this.lectureId,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      compressedPath: compressedPath ?? this.compressedPath,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isActive: isActive ?? this.isActive,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      lectureTitle: lectureTitle ?? this.lectureTitle,
      teacherId: teacherId ?? this.teacherId,
    );
  }

  // Computed properties for UI
  String get displayTitle => title.isNotEmpty ? title : fileName;
  String get displayDescription => description ?? 'No description available';
  String get fileExtension => fileName.split('.').last.toUpperCase();
  String get fileSizeFormatted => fileSize != null ? '${(fileSize! / 1024 / 1024).toStringAsFixed(2)} MB' : 'Unknown size';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MaterialItem{id: $id, title: $title, fileName: $fileName, lectureId: $lectureId}';
  }
}