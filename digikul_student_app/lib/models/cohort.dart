class Cohort {
  final String id;
  final String name;
  final String description;
  final String teacherName;
  final String code;
  final String subject; // <-- ADD THIS LINE

  Cohort({
    required this.id,
    required this.name,
    required this.description,
    required this.teacherName,
    required this.code,
    required this.subject, // <-- AND THIS LINE
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] ?? '',
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? '',
      teacherName: json['teacher_name'] ?? 'Unknown Teacher',
      code: json['code'] ?? '',
      subject: json['subject'] ?? 'No Subject', // <-- AND THIS LINE
    );
  }
}