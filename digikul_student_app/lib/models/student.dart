class StudentStats {
  final int enrolledCourses;
  final int joinedCohorts;
  final double learningHours;

  StudentStats({
    required this.enrolledCourses,
    required this.joinedCohorts,
    required this.learningHours,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      enrolledCourses: json['enrolled_courses'] as int,
      joinedCohorts: json['joined_cohorts'] as int,
      learningHours: (json['learning_hours'] as num).toDouble(),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String email;
  final String institution;
  final DateTime createdAt;
  final StudentStats stats;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.institution,
    required this.createdAt,
    required this.stats,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      institution: json['institution'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      stats: StudentStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}