import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String? userMessage;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.userMessage,
    this.statusCode,
    this.originalError,
  });

  String get displayMessage => userMessage ?? message;

  @override
  String toString() => displayMessage;

  static ApiException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timeout',
          userMessage: 'Connection timed out. Please check your internet connection and try again.',
          originalError: error,
        );

      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Send timeout',
          userMessage: 'Request took too long to send. Please check your internet connection.',
          originalError: error,
        );

      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Receive timeout',
          userMessage: 'Server is taking too long to respond. Please try again later.',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        final errorMessage = error.error?.toString() ?? '';
        if (errorMessage.contains('offline mode')) {
          return ApiException(
            message: 'App is in offline mode',
            userMessage: 'You are in offline mode. Please disable offline mode in settings to access online features.',
            originalError: error,
          );
        }
        return ApiException(
          message: 'Request cancelled',
          userMessage: 'Request was cancelled. Please try again.',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Connection error',
          userMessage: 'Unable to connect to the server. Please check your internet connection.',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Bad certificate',
          userMessage: 'Security certificate error. Please contact support.',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        if (error.error?.toString().contains('SocketException') == true) {
          return ApiException(
            message: 'No internet connection',
            userMessage: 'No internet connection. Please check your network settings.',
            originalError: error,
          );
        }
        return ApiException(
          message: 'Unknown error',
          userMessage: 'An unexpected error occurred. Please try again.',
          originalError: error,
        );
    }
  }

  static ApiException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String userMessage;
    switch (statusCode) {
      case 400:
        userMessage = _extractErrorMessage(responseData) ?? 
            'Invalid request. Please check your input and try again.';
        break;
      case 401:
        userMessage = 'Authentication failed. Please log in again.';
        break;
      case 403:
        final errorDetail = _extractErrorMessage(responseData);
        if (errorDetail?.toLowerCase().contains('not authenticated') == true) {
          userMessage = 'Authentication required. Please log in to continue.';
        } else {
          userMessage = 'You don\'t have permission to perform this action.';
        }
        break;
      case 404:
        userMessage = 'The requested resource was not found.';
        break;
      case 409:
        userMessage = _extractErrorMessage(responseData) ?? 
            'A conflict occurred. This item may already exist.';
        break;
      case 422:
        userMessage = _extractErrorMessage(responseData) ?? 
            'Validation failed. Please check your input.';
        break;
      case 500:
        userMessage = 'Server error. Please try again later.';
        break;
      case 503:
        userMessage = 'Service is temporarily unavailable. Please try again later.';
        break;
      default:
        userMessage = _extractErrorMessage(responseData) ?? 
            'An error occurred. Please try again.';
    }

    return ApiException(
      message: 'HTTP $statusCode',
      userMessage: userMessage,
      statusCode: statusCode,
      originalError: error,
    );
  }

  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is Map) {
      return responseData['detail'] as String? ??
          responseData['message'] as String? ??
          responseData['error'] as String?;
    }

    if (responseData is String) {
      return responseData;
    }

    return null;
  }
}

class NetworkException extends ApiException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Network error',
          userMessage: 'No internet connection. Please check your network settings and try again.',
        );
}

class ServerException extends ApiException {
  ServerException({String? message})
      : super(
          message: message ?? 'Server error',
          userMessage: 'Server is experiencing issues. Please try again later.',
        );
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException({String? message, this.errors})
      : super(
          message: message ?? 'Validation error',
          userMessage: message ?? 'Please check your input and try again.',
        );
}
