class Enrollment {

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.lectureId,
    required this.enrolledAt,
    this.isActive = true,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      lectureId: json['lecture_id'] ?? '',
      enrolledAt: DateTime.tryParse(json['enrolled_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String studentId;
  final String lectureId;
  final DateTime enrolledAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'lecture_id': lectureId,
      'enrolled_at': enrolledAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enrollment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Enrollment{id: $id, studentId: $studentId, lectureId: $lectureId}';
  }
}