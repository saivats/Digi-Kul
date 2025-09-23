import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'package:digikul_student_app/src/core/config/app_config.dart';
import 'package:digikul_student_app/src/core/constants/app_constants.dart';
import 'package:digikul_student_app/src/data/models/user.dart';
import 'package:digikul_student_app/src/data/models/lecture.dart';
import 'package:digikul_student_app/src/data/models/cohort.dart';
import 'package:digikul_student_app/src/data/models/material.dart';
import 'package:digikul_student_app/src/data/models/poll.dart';
import 'package:digikul_student_app/src/data/models/quiz.dart';
import 'package:digikul_student_app/src/data/models/enrollment.dart';

/// Custom exceptions for API errors
class ApiException implements Exception {

  const ApiException(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class AuthenticationException extends ApiException {
  const AuthenticationException(super.message) : super(statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException(super.message, int statusCode) : super(statusCode: statusCode);
}

class ValidationException extends ApiException {
  const ValidationException(super.message) : super(statusCode: 400);
}

/// Main API service for all network operations
class ApiService {
  factory ApiService() => _instance;

  ApiService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );

    _initializeDio();
  }
  late final Dio _dio;
  late final Logger _logger;
  String? _sessionCookie;
  UserSession? _currentSession;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'DigiKul-Student-App/${AppConfig.isDebug ? 'debug' : 'release'}',
      },
      validateStatus: (status) => status != null && status < 500,
    ),);

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add session cookie if available
        if (_sessionCookie != null) {
          options.headers['Cookie'] = _sessionCookie;
        }

        // Add request ID for tracking
        options.headers['X-Request-ID'] = _generateRequestId();

        if (EnvironmentConfig.enableLogging) {
          _logger.d('Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            _logger.d('Request Data: ${options.data}');
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        // Extract and store session cookie
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final cookie = cookies.first;
          final index = cookie.indexOf(';');
          _sessionCookie = index == -1 ? cookie : cookie.substring(0, index);
        }

        if (EnvironmentConfig.enableLogging) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.uri}');
        }

        handler.next(response);
      },
      onError: (error, handler) {
        if (EnvironmentConfig.enableLogging) {
          _logger.e('Error: ${error.message}', error: error, stackTrace: error.stackTrace);
        }

        // Handle authentication errors
        if (error.response?.statusCode == 401) {
          _clearSession();
        }

        handler.next(error);
      },
    ),);

    // Logging interceptor for debug mode
    if (EnvironmentConfig.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) => _logger.d(obj.toString()),
      ),);
    }

    // Retry interceptor for network failures
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          try {
            final response = await _dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );
            handler.resolve(response);
            return;
          } catch (retryError) {
            // Retry failed, continue with original error
          }
        }
        handler.next(error);
      },
    ),);
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           (error.response?.statusCode != null && 
            error.response!.statusCode! >= 500 && 
            error.response!.statusCode! < 600);
  }

  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _clearSession() {
    _sessionCookie = null;
    _currentSession = null;
  }

  // Getters
  bool get isAuthenticated => _sessionCookie != null && _currentSession != null;
  UserSession? get currentSession => _currentSession;
  String get baseUrl => _dio.options.baseUrl;

  // Update base URL if needed
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  // Handle API errors
  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkException(AppConstants.networkErrorMessage);
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException('Unable to connect to server. Please check your internet connection.');
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      
      try {
        final data = response.data as Map<String, dynamic>;
        final message = data['error'] ?? data['message'] ?? AppConstants.serverErrorMessage;
        
        if (statusCode == 401) {
          return AuthenticationException(message);
        } else if (statusCode == 400) {
          return ValidationException(message);
        }
        
        return ServerException(message, statusCode);
      } catch (_) {
        return ServerException('Server error ($statusCode)', statusCode);
      }
    }

    return const ApiException(AppConstants.unknownErrorMessage);
  }

  // Authentication APIs
  Future<UserSession> login(String email, String password, {String userType = AppConstants.userTypeStudent}) async {
    try {
      final response = await _dio.post(AppConstants.loginEndpoint, data: {
        'email': email,
        'password': password,
        'user_type': userType,
      },);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Validate session to get user details
        final sessionData = await validateSession();
        if (sessionData != null) {
          _currentSession = UserSession.fromJson(sessionData);
          return _currentSession!;
        }
        
        throw const AuthenticationException('Failed to get user details after login');
      }
      
      throw const AuthenticationException('Invalid credentials');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      if (_sessionCookie != null) {
        await _dio.post(AppConstants.logoutEndpoint);
      }
    } catch (e) {
      _logger.w('Logout request failed: $e');
    } finally {
      _clearSession();
    }
  }

  Future<Map<String, dynamic>?> validateSession() async {
    try {
      final response = await _dio.get(AppConstants.validateSessionEndpoint);
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['valid'] == true) {
          return data;
        }
      }
      
      _clearSession();
      return null;
    } on DioException catch (_) {
      _clearSession();
      return null;
    }
  }

  // Lecture APIs
  Future<List<Lecture>> getAvailableLectures() async {
    try {
      final response = await _dio.get(AppConstants.availableLecturesEndpoint);
      
      final data = response.data as Map<String, dynamic>;
      final lecturesJson = data['lectures'] as List;
      
      return lecturesJson
          .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Lecture>> getEnrolledLectures() async {
    try {
      final response = await _dio.get(AppConstants.enrolledLecturesEndpoint);
      
      final data = response.data as Map<String, dynamic>;
      final lecturesJson = data['lectures'] as List;
      
      return lecturesJson
          .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<LectureDetails> getLectureDetails(String lectureId) async {
    try {
      final response = await _dio.get('/api/lectures/$lectureId');
      
      final data = response.data as Map<String, dynamic>;
      return LectureDetails.fromJson(data['lecture'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<EnrollmentResponse> enrollInLecture(String lectureId) async {
    try {
      final response = await _dio.post(AppConstants.enrollEndpoint, data: {
        'lecture_id': lectureId,
      },);

      final data = response.data as Map<String, dynamic>;
      return EnrollmentResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Cohort APIs
  Future<List<Cohort>> getStudentCohorts() async {
    try {
      final response = await _dio.get(AppConstants.studentCohortsEndpoint);
      
      final data = response.data as Map<String, dynamic>;
      final cohortsJson = data['cohorts'] as List;
      
      return cohortsJson
          .map((json) => Cohort.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CohortJoinResponse> joinCohortByCode(String cohortCode) async {
    try {
      final response = await _dio.post(AppConstants.joinCohortEndpoint, data: {
        'cohort_code': cohortCode,
      },);

      final data = response.data as Map<String, dynamic>;
      return CohortJoinResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Lecture>> getCohortLectures(String cohortId) async {
    try {
      final response = await _dio.get('/api/student/cohort/$cohortId/lectures');
      
      final data = response.data as Map<String, dynamic>;
      final lecturesJson = data['lectures'] as List;
      
      return lecturesJson
          .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Material APIs
  Future<List<MaterialItem>> getLectureMaterials(String lectureId) async {
    try {
      final response = await _dio.get('/api/student/lecture/$lectureId/materials');
      
      final data = response.data as Map<String, dynamic>;
      final materialsJson = data['materials'] as List;
      
      return materialsJson
          .map((json) => MaterialItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String getDownloadUrl(String materialId) {
    return '$baseUrl${AppConstants.downloadMaterialEndpoint}/$materialId';
  }

  Future<void> downloadMaterial(String materialId, String savePath, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        '${AppConstants.downloadMaterialEndpoint}/$materialId',
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: _sessionCookie != null ? {'Cookie': _sessionCookie} : null,
          receiveTimeout: AppConfig.downloadTimeout,
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Poll APIs
  Future<List<Poll>> getStudentPolls() async {
    try {
      final response = await _dio.get(AppConstants.studentPollsEndpoint);
      
      final data = response.data as Map<String, dynamic>;
      final pollsJson = data['polls'] as List;
      
      return pollsJson
          .map((json) => Poll.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Poll>> getLecturePolls(String lectureId) async {
    try {
      final response = await _dio.get('/api/lectures/$lectureId/polls');
      
      final data = response.data as Map<String, dynamic>;
      final pollsJson = data['polls'] as List;
      
      return pollsJson
          .map((json) => Poll.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> voteOnPoll(String pollId, String response) async {
    try {
      await _dio.post('/api/polls/$pollId/vote', data: {
        'response': response,
      },);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PollResults> getPollResults(String pollId) async {
    try {
      final response = await _dio.get('/api/polls/$pollId/results');
      
      final data = response.data as Map<String, dynamic>;
      return PollResults.fromJson(data['results'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Live Session APIs
  Future<String?> getActiveSessionId(String lectureId) async {
    try {
      final response = await _dio.get('/api/session/by_lecture/$lectureId');
      
      final data = response.data as Map<String, dynamic>;
      return data['session_id'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No active session
      }
      throw _handleError(e);
    }
  }

  // Quiz APIs
  Future<List<Quiz>> getLectureQuizzes(String lectureId) async {
    try {
      final response = await _dio.get('/api/lectures/$lectureId/quizzes');
      
      final data = response.data as Map<String, dynamic>;
      final quizzesJson = data['quizzes'] as List;
      
      return quizzesJson
          .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<QuizSubmissionResponse> submitQuizResponse(String quizId, String response) async {
    try {
      final result = await _dio.post('/api/quizzes/$quizId/submit', data: {
        'response': response,
      },);

      final data = result.data as Map<String, dynamic>;
      return QuizSubmissionResponse.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Health check
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        AppConstants.healthCheckEndpoint,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Generic API call method for extensibility
  Future<T> apiCall<T>(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final options = Options(
        method: method,
        headers: headers,
      );

      Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(endpoint, queryParameters: queryParameters, options: options);
        case 'POST':
          response = await _dio.post(endpoint, data: data, queryParameters: queryParameters, options: options);
        case 'PUT':
          response = await _dio.put(endpoint, data: data, queryParameters: queryParameters, options: options);
        case 'DELETE':
          response = await _dio.delete(endpoint, data: data, queryParameters: queryParameters, options: options);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (fromJson != null && response.data is Map<String, dynamic>) {
        return fromJson(response.data as Map<String, dynamic>);
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Dispose method for cleanup
  void dispose() {
    _dio.close();
  }
}
