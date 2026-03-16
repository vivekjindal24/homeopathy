import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'app_exception.dart';

/// Centralised error mapping — converts raw exceptions to [AppException].
class ErrorHandler {
  ErrorHandler._();

  /// Map any caught [error] to an [AppException].
  static AppException map(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is sb.AuthException) {
      return AuthException(
        message: _friendlyAuthMessage(error.message),
        code: error.statusCode?.toString(),
        originalError: error,
      );
    }

    if (error is sb.PostgrestException) {
      if (error.code == '42501' || error.message.contains('permission')) {
        return PermissionException(
          message: 'You do not have permission to perform this action.',
          code: error.code,
          originalError: error,
        );
      }
      return ServerException(
        message: error.message,
        code: error.code,
        originalError: error,
      );
    }

    if (error is sb.StorageException) {
      return StorageException(
        message: error.message,
        originalError: error,
      );
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    if (!kIsWeb && error.toString().contains('SocketException')) {
      return const NetworkException(
        message: 'No internet connection. Please check your network.',
        code: 'NO_INTERNET',
      );
    }

    if (error is FormatException) {
      return ParseException(
        message: 'Unexpected data format received.',
        originalError: error,
      );
    }

    return ServerException(
      message: error?.toString() ?? 'An unexpected error occurred.',
      originalError: error,
    );
  }

  static AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Connection timed out. Please try again.',
          code: 'TIMEOUT',
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Unable to reach the server. Check your connection.',
          code: 'CONNECTION_ERROR',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return const AuthException(
            message: 'Session expired. Please log in again.',
            code: '401',
          );
        }
        if (statusCode == 403) {
          return const PermissionException(
            message: 'You do not have permission to perform this action.',
            code: '403',
          );
        }
        if (statusCode == 404) {
          return ServerException(
            message: 'Resource not found.',
            code: '404',
            statusCode: statusCode,
            originalError: error,
          );
        }
        return ServerException(
          message: 'Server error ($statusCode). Please try again.',
          code: '$statusCode',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return NetworkException(
          message: 'Network error. Please try again.',
          originalError: error,
        );
    }
  }

  static String _friendlyAuthMessage(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Please verify your email address first.';
    }
    if (raw.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('Token has expired')) {
      return 'Your session has expired. Please log in again.';
    }
    return raw;
  }
}

