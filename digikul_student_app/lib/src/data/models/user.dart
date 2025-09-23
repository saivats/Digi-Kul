import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Base User model representing common user fields
@JsonSerializable()
class User extends Equatable {

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.institution,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  final String id;
  final String name;
  final String email;
  final String institution;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  @JsonKey(name: 'is_active')
  final bool isActive;

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? institution,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      institution: institution ?? this.institution,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        institution,
        createdAt,
        lastLogin,
        isActive,
      ];

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, institution: $institution}';
  }
}

/// Student model extending User
@JsonSerializable()
class Student extends User {
  const Student({
    required super.id,
    required super.name,
    required super.email,
    required super.institution,
    required super.createdAt,
    super.lastLogin,
    super.isActive,
  });

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StudentToJson(this);

  @override
  Student copyWith({
    String? id,
    String? name,
    String? email,
    String? institution,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      institution: institution ?? this.institution,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Teacher model extending User with subject field
@JsonSerializable()
class Teacher extends User {

  const Teacher({
    required String id,
    required String name,
    required String email,
    required String institution,
    required this.subject,
    required DateTime createdAt,
    DateTime? lastLogin,
    bool isActive = true,
  }) : super(
          id: id,
          name: name,
          email: email,
          institution: institution,
          createdAt: createdAt,
          lastLogin: lastLogin,
          isActive: isActive,
        );

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
  final String subject;

  @override
  Map<String, dynamic> toJson() => _$TeacherToJson(this);

  @override
  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? institution,
    String? subject,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      institution: institution ?? this.institution,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        subject,
      ];

  @override
  String toString() {
    return 'Teacher{id: $id, name: $name, email: $email, subject: $subject}';
  }
}

/// Current user session information
@JsonSerializable()
class UserSession extends Equatable {

  const UserSession({
    required this.userId,
    required this.userType,
    required this.userName,
    required this.userEmail,
    this.sessionToken,
    required this.loginTime,
    this.lastActivity,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
  final String userId;
  final String userType;
  final String userName;
  final String userEmail;
  final String? sessionToken;
  final DateTime loginTime;
  final DateTime? lastActivity;

  Map<String, dynamic> toJson() => _$UserSessionToJson(this);

  UserSession copyWith({
    String? userId,
    String? userType,
    String? userName,
    String? userEmail,
    String? sessionToken,
    DateTime? loginTime,
    DateTime? lastActivity,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      sessionToken: sessionToken ?? this.sessionToken,
      loginTime: loginTime ?? this.loginTime,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  bool get isStudent => userType == 'student';
  bool get isTeacher => userType == 'teacher';
  bool get isAdmin => userType == 'admin';

  @override
  List<Object?> get props => [
        userId,
        userType,
        userName,
        userEmail,
        sessionToken,
        loginTime,
        lastActivity,
      ];

  @override
  String toString() {
    return 'UserSession{userId: $userId, userType: $userType, userName: $userName}';
  }
}
