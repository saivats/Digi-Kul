class Lecture {
  final String id;
  final String teacherId;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final int duration;
  final DateTime createdAt;
  final bool sessionActive;
  final String? teacherName;

  Lecture({
    required this.id,
    required this.teacherId,
    required this.title,
    this.description,
    required this.scheduledTime,
    required this.duration,
    required this.createdAt,
    this.sessionActive = false,
    this.teacherName,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      duration: json['duration'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      sessionActive: json['session_active'] ?? false,
      teacherName: json['teacher_name'] as String?,
    );
  }
}