class Cohort {
  final String id;
  final String name;
  final String description;
  final String subject;
  final String teacherId;
  final String code;
  final DateTime createdAt;
  final bool isActive;
  
  // Additional fields from API responses
  final String? teacherName;
  final DateTime? joinedAt;

  const Cohort({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.teacherId,
    required this.code,
    required this.createdAt,
    this.isActive = true,
    this.teacherName,
    this.joinedAt,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      code: json['code'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
      teacherName: json['teacher_name'],
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'teacher_id': teacherId,
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'teacher_name': teacherName,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }

  Cohort copyWith({
    String? id,
    String? name,
    String? description,
    String? subject,
    String? teacherId,
    String? code,
    DateTime? createdAt,
    bool? isActive,
    String? teacherName,
    DateTime? joinedAt,
  }) {
    return Cohort(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      teacherId: teacherId ?? this.teacherId,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      teacherName: teacherName ?? this.teacherName,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  // Computed properties for UI
  String get displayTeacherName => teacherName ?? 'Unknown Teacher';
  String get displayDescription => description.isNotEmpty ? description : 'No description available';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cohort && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Cohort{id: $id, name: $name, subject: $subject, teacherId: $teacherId}';
  }
}