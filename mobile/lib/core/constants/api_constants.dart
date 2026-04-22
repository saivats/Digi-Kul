class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const connectionTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  static const login = '/login';
  static const registerStudent = '/register/student';
  static const validateSession = '/validate-session';
  static const logout = '/logout';
  static const institutions = '/institutions';
  static const studentCohorts = '/student/cohorts';
  static const studentLectures = '/student/lectures';
  static const upcomingLectures = '/student/lectures/upcoming';
  static const studentMaterials = '/student/materials';
  static const studentQuizzes = '/student/quizzes';
  static const quizAttempts = '/student/quiz-attempts';
  static const quizResponses = '/student/quiz-responses';
  static const studentRecordings = '/student/recordings';
  static const studentDashboard = '/student/dashboard';
  static const studentProfile = '/student/profile';
  static const attendance = '/student/attendance';
  static const fcmToken = '/student/fcm-token';
}
