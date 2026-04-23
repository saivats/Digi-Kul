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

  static const login = '/api/auth/login';
  static const registerStudent = '/api/auth/register/student';
  static const validateSession = '/api/auth/validate-session';
  static const logout = '/api/auth/logout';
  static const institutions = '/api/public/institutions';
  static const studentCohorts = '/api/student/cohorts';
  static const studentLectures = '/api/student/lectures';
  static const upcomingLectures = '/api/student/lectures/upcoming';
  static const studentMaterials = '/api/student/materials';
  static const studentQuizzes = '/api/student/quizzes';
  static const quizAttempts = '/api/student/quiz-attempts';
  static const quizResponses = '/api/student/quiz-responses';
  static const studentRecordings = '/api/student/recordings';
  static const studentDashboard = '/api/student/dashboard';
  static const studentProfile = '/api/student/profile';
  static const attendance = '/api/student/attendance';
  static const fcmToken = '/api/student/fcm-token';

  static String quizQuestions(String quizSetId) =>
      '/api/student/quizzes/$quizSetId/questions';

  static String quizAttemptQuestions(String attemptId) =>
      '$quizAttempts/$attemptId/questions';

  static String quizAttemptSubmit(String attemptId) =>
      '$quizAttempts/$attemptId/submit';

  static String quizResult(String attemptId) =>
      '$quizAttempts/$attemptId/result';
}
