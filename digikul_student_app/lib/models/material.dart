class MaterialItem {
  final String id;
  final String title;
  final String fileType;
  final double fileSizeMb;

  MaterialItem({
    required this.id,
    required this.title,
    required this.fileType,
    required this.fileSizeMb,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'],
      title: json['title'],
      fileType: json['file_type'],
      fileSizeMb: (json['file_size_mb'] ?? 0.0).toDouble(),
    );
  }
}