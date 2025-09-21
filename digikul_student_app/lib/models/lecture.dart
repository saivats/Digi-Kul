class Lecture {
  final String id;
  final String title;
  final String description;
  final String teacherName;
  final String scheduledTime;
  final int duration;
  final bool sessionActive;

  Lecture({
    required this.id,
    required this.title,
    required this.description,
    required this.teacherName,
    required this.scheduledTime,
    required this.duration,
    required this.sessionActive,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      teacherName: json['teacher_name'] ?? 'Unknown Teacher',
      scheduledTime: json['scheduled_time'] ?? '',
      duration: json['duration'] ?? 0,
      sessionActive: json['session_active'] ?? false,
    );
  }
}