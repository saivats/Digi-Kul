/// API configuration — selected at BUILD time.
///
/// Pick an environment with `--dart-define=APP_ENV=dev|staging|prod`
/// (or a flavor that sets it). Release builds default to `prod`, everything
/// else to `dev`. Any base URL can still be overridden explicitly:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000            # Android emulator -> host
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.4:8000         # phone on LAN
///   flutter build apk --release                                            # -> prod URLs
///   flutter build apk --release --dart-define=APP_ENV=staging
///
/// TURN relay (recommended for mobile-data students — STUN alone gives no
/// audio behind carrier NAT):
///   --dart-define=TURN_URL=turn:turn.digikul.in:3478 \
///   --dart-define=TURN_USERNAME=digikul --dart-define=TURN_CREDENTIAL=secret
class ApiConstants {
  ApiConstants._();

  // ---------------------------------------------------------------------
  // Environments
  // ---------------------------------------------------------------------
  static const String _envFlag = String.fromEnvironment('APP_ENV');
  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  /// dev | staging | prod
  static const String environment =
      _envFlag != '' ? _envFlag : (_isRelease ? 'prod' : 'dev');

  static const bool isProd = environment == 'prod';
  static const bool isDev = environment == 'dev';

  // 10.0.2.2 is the Android emulator's alias for the host machine. On a
  // physical device pass API_BASE_URL explicitly (your machine's LAN IP).
  static const String devBaseUrl = 'http://10.0.2.2:8000';
  static const String stagingBaseUrl = 'https://staging-api.digikul.in';
  static const String prodBaseUrl = 'https://api.digikul.in';

  static const String _envBaseUrl = environment == 'prod'
      ? prodBaseUrl
      : environment == 'staging'
          ? stagingBaseUrl
          : devBaseUrl;

  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');
  static const String _socketOverride = String.fromEnvironment('SOCKET_URL');

  /// REST base URL (no trailing slash).
  static const String baseUrl = _apiOverride != '' ? _apiOverride : _envBaseUrl;

  /// Socket.IO origin. nginx proxies /socket.io/ on the same public origin
  /// as the API, so it defaults to [baseUrl].
  static const String socketUrl =
      _socketOverride != '' ? _socketOverride : baseUrl;

  /// Socket.IO handshake path (python-socketio default, matches nginx.conf).
  static const String socketPath = '/socket.io';

  // ---------------------------------------------------------------------
  // WebRTC
  // ---------------------------------------------------------------------
  static const String turnUrl = String.fromEnvironment('TURN_URL');
  static const String turnUsername = String.fromEnvironment('TURN_USERNAME');
  static const String turnCredential =
      String.fromEnvironment('TURN_CREDENTIAL');

  static const connectionTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------
  // Endpoints — every path below exists on the FastAPI backend
  // (backend/app/routers/*). Verified against /openapi.json.
  // ---------------------------------------------------------------------
  static const health = '/api/health';

  // auth.py
  static const login = '/api/auth/login';
  static const refresh = '/api/auth/refresh';
  static const registerStudent = '/api/auth/register/student';
  static const validateSession = '/api/auth/validate-session';
  static const logout = '/api/auth/logout';

  // public.py
  static const institutions = '/api/public/institutions';

  // student.py  (prefix is /api/students — plural)
  static const studentProfile = '/api/students/me';
  static const studentDashboard = '/api/students/dashboard';
  static const studentCohorts = '/api/students/cohorts';
  static const studentLectures = '/api/students/lectures';
  static const upcomingLectures = '/api/students/lectures/upcoming';
  static const liveLectures = '/api/students/lectures/live';
  static const studentMaterials = '/api/students/materials';
  static const studentRecordings = '/api/students/recordings';
  static const studentQuizzes = '/api/students/quizzes';
  static const quizAttempts = '/api/students/quiz-attempts';
  static const quizResponses = '/api/students/quiz-responses';
  static const quizHistory = '/api/students/quiz-history';
  static const attendance = '/api/students/attendance';
  static const fcmToken = '/api/students/fcm-token';

  static String quizQuestions(String quizSetId) =>
      '$studentQuizzes/$quizSetId/questions';

  static String quizAttemptQuestions(String attemptId) =>
      '$quizAttempts/$attemptId/questions';

  static String quizAttemptSubmit(String attemptId) =>
      '$quizAttempts/$attemptId/submit';

  static String quizResult(String attemptId) =>
      '$quizAttempts/$attemptId/result';

  // material.py — streams the uploaded file (bearer auth required)
  static String materialFile(String materialId) =>
      '/api/materials/$materialId/file';

  static String materialDownloadTracked(String materialId) =>
      '/api/materials/$materialId/download';
}
