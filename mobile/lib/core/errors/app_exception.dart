enum ExceptionType {
  network,
  auth,
  cache,
  server,
  timeout,
  unknown,
}

sealed class AppException implements Exception {
  const AppException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  final String message;
  final ExceptionType type;
  final int? statusCode;
  final Object? originalError;

  @override
  String toString() => 'AppException($type): $message';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.originalError,
  }) : super(type: ExceptionType.network);
}

class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication failed. Please log in again.',
    super.statusCode,
    super.originalError,
  }) : super(type: ExceptionType.auth);
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Failed to access local data.',
    super.originalError,
  }) : super(type: ExceptionType.cache);
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Something went wrong on the server.',
    super.statusCode,
    super.originalError,
  }) : super(type: ExceptionType.server);
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out. Please try again.',
    super.originalError,
  }) : super(type: ExceptionType.timeout);
}
