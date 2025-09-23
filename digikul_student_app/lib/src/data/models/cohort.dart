import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cohort.g.dart';

/// Cohort model representing a group of students and their associated content
@JsonSerializable()
class Cohort extends Equatable {

  const Cohort({
    required this.id,
    required this.name,
    this.description,
    required this.subject,
    required this.teacherId,
    required this.code,
    required this.createdAt,
    this.isActive = true,
    this.teacherName,
    this.joinedAt,
    this.studentCount,
    this.lectureCount,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) => _$CohortFromJson(json);
  final String id;
  final String name;
  final String? description;
  final String subject;
  @JsonKey(name: 'teacher_id')
  final String teacherId;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  // Additional fields from API responses
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  @JsonKey(name: 'joined_at')
  final DateTime? joinedAt;
  @JsonKey(name: 'student_count')
  final int? studentCount;
  @JsonKey(name: 'lecture_count')
  final int? lectureCount;

  Map<String, dynamic> toJson() => _$CohortToJson(this);

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
    int? studentCount,
    int? lectureCount,
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
      studentCount: studentCount ?? this.studentCount,
      lectureCount: lectureCount ?? this.lectureCount,
    );
  }

  /// Check if the student has joined this cohort
  bool get isJoined => joinedAt != null;

  /// Get formatted student count
  String get formattedStudentCount {
    if (studentCount == null) return '0 students';
    if (studentCount == 1) return '1 student';
    return '$studentCount students';
  }

  /// Get formatted lecture count
  String get formattedLectureCount {
    if (lectureCount == null) return '0 lectures';
    if (lectureCount == 1) return '1 lecture';
    return '$lectureCount lectures';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        subject,
        teacherId,
        code,
        createdAt,
        isActive,
        teacherName,
        joinedAt,
        studentCount,
        lectureCount,
      ];

  @override
  String toString() {
    return 'Cohort{id: $id, name: $name, code: $code, subject: $subject, teacher: $teacherName}';
  }
}

/// Cohort summary for list views
@JsonSerializable()
class CohortSummary extends Equatable {

  const CohortSummary({
    required this.id,
    required this.name,
    required this.subject,
    required this.code,
    this.teacherName,
    this.studentCount = 0,
    this.lectureCount = 0,
    this.isJoined = false,
  });

  factory CohortSummary.fromJson(Map<String, dynamic> json) =>
      _$CohortSummaryFromJson(json);

  factory CohortSummary.fromCohort(Cohort cohort) {
    return CohortSummary(
      id: cohort.id,
      name: cohort.name,
      subject: cohort.subject,
      code: cohort.code,
      teacherName: cohort.teacherName,
      studentCount: cohort.studentCount ?? 0,
      lectureCount: cohort.lectureCount ?? 0,
      isJoined: cohort.isJoined,
    );
  }
  final String id;
  final String name;
  final String subject;
  final String code;
  final String? teacherName;
  final int studentCount;
  final int lectureCount;
  final bool isJoined;

  Map<String, dynamic> toJson() => _$CohortSummaryToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        subject,
        code,
        teacherName,
        studentCount,
        lectureCount,
        isJoined,
      ];
}

/// Cohort details with additional information
@JsonSerializable()
class CohortDetails extends Cohort {

  const CohortDetails({
    required String id,
    required String name,
    String? description,
    required String subject,
    required String teacherId,
    required String code,
    required DateTime createdAt,
    bool isActive = true,
    String? teacherName,
    DateTime? joinedAt,
    int? studentCount,
    int? lectureCount,
    this.studentIds,
    this.lectureIds,
    this.recentLectures,
    this.lastActivity,
  }) : super(
          id: id,
          name: name,
          description: description,
          subject: subject,
          teacherId: teacherId,
          code: code,
          createdAt: createdAt,
          isActive: isActive,
          teacherName: teacherName,
          joinedAt: joinedAt,
          studentCount: studentCount,
          lectureCount: lectureCount,
        );

  factory CohortDetails.fromJson(Map<String, dynamic> json) =>
      _$CohortDetailsFromJson(json);
  final List<String>? studentIds;
  final List<String>? lectureIds;
  final List<String>? recentLectures;
  final DateTime? lastActivity;

  @override
  Map<String, dynamic> toJson() => _$CohortDetailsToJson(this);

  @override
  CohortDetails copyWith({
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
    int? studentCount,
    int? lectureCount,
    List<String>? studentIds,
    List<String>? lectureIds,
    List<String>? recentLectures,
    DateTime? lastActivity,
  }) {
    return CohortDetails(
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
      studentCount: studentCount ?? this.studentCount,
      lectureCount: lectureCount ?? this.lectureCount,
      studentIds: studentIds ?? this.studentIds,
      lectureIds: lectureIds ?? this.lectureIds,
      recentLectures: recentLectures ?? this.recentLectures,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        studentIds,
        lectureIds,
        recentLectures,
        lastActivity,
      ];
}

/// Model for joining a cohort by code
@JsonSerializable()
class CohortJoinRequest extends Equatable {

  const CohortJoinRequest({
    required this.cohortCode,
  });

  factory CohortJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$CohortJoinRequestFromJson(json);
  @JsonKey(name: 'cohort_code')
  final String cohortCode;

  Map<String, dynamic> toJson() => _$CohortJoinRequestToJson(this);

  @override
  List<Object?> get props => [cohortCode];
}

/// Response when joining a cohort
@JsonSerializable()
class CohortJoinResponse extends Equatable {

  const CohortJoinResponse({
    required this.success,
    required this.message,
    this.cohortId,
    this.cohortName,
  });

  factory CohortJoinResponse.fromJson(Map<String, dynamic> json) =>
      _$CohortJoinResponseFromJson(json);
  final bool success;
  final String message;
  final String? cohortId;
  final String? cohortName;

  Map<String, dynamic> toJson() => _$CohortJoinResponseToJson(this);

  @override
  List<Object?> get props => [success, message, cohortId, cohortName];
}
