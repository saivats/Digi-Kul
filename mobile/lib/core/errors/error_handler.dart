import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'app_exception.dart';

class ErrorHandler {
  ErrorHandler._();

  static final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  static AppException handleDioError(DioException error) {
    _logger.e('DioException: ${error.type} — ${error.message}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: error);

      case DioExceptionType.connectionError:
        return NetworkException(originalError: error);

      case DioExceptionType.badResponse:
        return _handleStatusCode(
          error.response?.statusCode,
          error.response?.data,
          error,
        );

      case DioExceptionType.cancel:
        return const ServerException(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return ServerException(
          message: 'Certificate verification failed.',
          originalError: error,
        );

      case DioExceptionType.unknown:
        if (error.error != null &&
            error.error.toString().contains('SocketException')) {
          return NetworkException(originalError: error);
        }
        return ServerException(
          message: error.message ?? 'An unexpected error occurred.',
          originalError: error,
        );
    }
  }

  static AppException _handleStatusCode(
    int? statusCode,
    dynamic responseData,
    DioException error,
  ) {
    final serverMessage = _extractServerMessage(responseData);

    switch (statusCode) {
      case 400:
        return ServerException(
          message: serverMessage ?? 'Invalid request.',
          statusCode: 400,
          originalError: error,
        );
      case 401:
        return AuthException(
          message: serverMessage ?? 'Session expired. Please log in again.',
          statusCode: 401,
          originalError: error,
        );
      case 403:
        return AuthException(
          message: serverMessage ?? 'Access denied.',
          statusCode: 403,
          originalError: error,
        );
      case 404:
        return ServerException(
          message: serverMessage ?? 'Resource not found.',
          statusCode: 404,
          originalError: error,
        );
      case 409:
        return ServerException(
          message: serverMessage ?? 'Conflict — resource already exists.',
          statusCode: 409,
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: serverMessage ?? 'Server is temporarily unavailable.',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return ServerException(
          message: serverMessage ?? 'Something went wrong.',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  static String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['error'] as String? ?? data['message'] as String?;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  static String userFriendlyMessage(AppException exception) {
    return switch (exception) {
      NetworkException() =>
        'You appear to be offline. Showing cached data.',
      AuthException() =>
        'Your session has expired. Please log in again.',
      CacheException() =>
        'Could not load offline data. Please try again.',
      TimeoutException() =>
        'The server is taking too long. Please try again.',
      ServerException() => exception.message,
    };
  }
}
