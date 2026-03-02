import 'package:dartz/dartz.dart';

/// Base failure class — all domain errors extend this.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException[$code]: $message';
}

/// Authentication errors.
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Network / connectivity errors.
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Server-side errors (4xx / 5xx).
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
}

/// Data parsing / serialization errors.
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Supabase storage upload/download errors.
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Permission denied by RLS or role guard.
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Cache / local storage errors.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Convenience typedef for Either<AppException, T>.
typedef ResultEither<T> = Future<Either<AppException, T>>;

