class MaterialItem {
  final String id;
  final String lectureId;
  final String title;
  final String? description;
  final String fileType;
  final int fileSize;
  final String downloadUrl;

  MaterialItem({
    required this.id,
    required this.lectureId,
    required this.title,
    this.description,
    required this.fileType,
    required this.fileSize,
    required this.downloadUrl,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as String,
      lectureId: json['lecture_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      downloadUrl: json['download_url'] as String,
    );
  }
}