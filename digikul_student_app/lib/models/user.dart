class User {
  final String id;
  final String name;
  final String email;
  final String institution;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.institution,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      institution: json['institution'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'institution': institution,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
    };
  }

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, institution: $institution}';
  }
}

class Teacher extends User {
  final String subject;

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

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      institution: json['institution'] ?? '',
      subject: json['subject'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
      isActive: json['is_active'] ?? true,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['subject'] = subject;
    return json;
  }

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
}
