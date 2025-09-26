class Cohort {
  final String id;
  final String name;
  final String? description;
  final String subject;
  final String teacherId;
  final String code;
  final DateTime createdAt;
  final String? teacherName;

  Cohort({
    required this.id,
    required this.name,
    this.description,
    required this.subject,
    required this.teacherId,
    required this.code,
    required this.createdAt,
    this.teacherName,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      subject: json['subject'] as String,
      teacherId: json['teacher_id'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      teacherName: json['teacher_name'] as String? ?? 'Unknown Teacher',
    );
  }
}