import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:digikul_student_app/models/user.dart';
import 'package:digikul_student_app/models/lecture.dart';
import 'package:digikul_student_app/models/cohort.dart';
import 'package:digikul_student_app/models/material.dart';
import 'package:digikul_student_app/models/poll.dart';
import 'package:digikul_student_app/models/quiz.dart';
import 'package:digikul_student_app/models/enrollment.dart';

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

class ApiService {
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging and error handling
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    // Add cookie interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_sessionCookie != null) {
          options.headers['Cookie'] = _sessionCookie!;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Extract session cookie from response
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final cookie = cookies.first;
          final index = cookie.indexOf(';');
          _sessionCookie = index == -1 ? cookie : cookie.substring(0, index);
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _sessionCookie = null;
          _currentUser = null;
        }
        handler.next(error);
      },
    ));
  }
  static const String _defaultBaseUrl = 'http://192.168.29.104:5000';
  
  late final Dio _dio;
  String? _sessionCookie;
  User? _currentUser;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  // Getters
  bool get isAuthenticated => _sessionCookie != null && _currentUser != null;
  User? get currentUser => _currentUser;
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
      return const NetworkException('Connection timeout. Please check your internet connection.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NetworkException('Unable to connect to server. Please check your internet connection.');
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      
      try {
        final data = response.data as Map<String, dynamic>;
        final message = data['error'] ?? data['message'] ?? 'Unknown server error';
        
        if (statusCode == 401) {
          return AuthenticationException(message);
        }
        
        return ServerException(message, statusCode);
      } catch (_) {
        return ServerException('Server error ($statusCode)', statusCode);
      }
    }

    return const ApiException('Unknown error occurred');
  }

  // Authentication APIs
  Future<User> login(String email, String password, {String userType = 'student'}) async {
    try {
      final response = await _dio.post('/api/login', data: {
        'email': email,
        'password': password,
        'user_type': userType,
      },);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Validate session to get user details
        final userDetails = await validateSession();
        if (userDetails != null) {
          _currentUser = User(
            id: userDetails['user_id'],
            name: userDetails['user_name'],
            email: userDetails['user_email'],
            institution: '', // Will be filled by profile API if needed
            createdAt: DateTime.now(),
          );
          return _currentUser!;
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
        await _dio.post('/api/logout');
      }
    } catch (_) {
      // Even if logout fails on server, clear local session
    } finally {
      _sessionCookie = null;
      _currentUser = null;
    }
  }

  Future<Map<String, dynamic>?> validateSession() async {
    try {
      final response = await _dio.get('/api/validate-session');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['valid'] == true) {
          return data;
        }
      }
      
      // Session invalid
      _sessionCookie = null;
      _currentUser = null;
      return null;
    } on DioException catch (_) {
      _sessionCookie = null;
      _currentUser = null;
      return null;
    }
  }

  // Lecture APIs
  Future<List<Lecture>> getAvailableLectures() async {
    try {
      final response = await _dio.get('/api/student/lectures/available');
      
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
      final response = await _dio.get('/api/student/enrolled_lectures');
      
      final data = response.data as Map<String, dynamic>;
      final lecturesJson = data['lectures'] as List;
      
      return lecturesJson
          .map((json) => Lecture.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Lecture> getLectureDetails(String lectureId) async {
    try {
      final response = await _dio.get('/api/lectures/$lectureId');
      
      final data = response.data as Map<String, dynamic>;
      return Lecture.fromJson(data['lecture'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> enrollInLecture(String lectureId) async {
    try {
      await _dio.post('/api/student/enroll', data: {
        'lecture_id': lectureId,
      },);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Cohort APIs
  Future<List<Cohort>> getStudentCohorts() async {
    try {
      final response = await _dio.get('/api/student/cohorts');
      
      final data = response.data as Map<String, dynamic>;
      final cohortsJson = data['cohorts'] as List;
      
      return cohortsJson
          .map((json) => Cohort.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> joinCohortByCode(String cohortCode) async {
    try {
      await _dio.post('/api/student/cohorts/join', data: {
        'cohort_code': cohortCode,
      },);
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
    return '$baseUrl/api/download/$materialId';
  }

  Future<void> downloadMaterial(String materialId, String savePath, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        '/api/download/$materialId',
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: _sessionCookie != null ? {'Cookie': _sessionCookie} : null,
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Poll APIs
  Future<List<Poll>> getStudentPolls() async {
    try {
      final response = await _dio.get('/api/student/polls');
      
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

  // Quiz APIs (if needed in the future)
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

  Future<void> submitQuizResponse(String quizId, String response) async {
    try {
      await _dio.post('/api/quizzes/$quizId/submit', data: {
        'response': response,
      },);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Network status check
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
