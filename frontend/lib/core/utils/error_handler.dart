import 'package:dio/dio.dart';

class ApiError {
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? details;
  final int? statusCode;

  ApiError({
    required this.message,
    this.errorCode,
    this.details,
    this.statusCode,
  });

  bool get isDuplicateRequest => errorCode == 'DUPLICATE_REQUEST';
  bool get isPasswordRequired => errorCode == 'PASSWORD_REQUIRED';
  bool get isEmailExists => errorCode == 'EMAIL_EXISTS';
  bool get isPermissionDenied => errorCode == 'PERMISSION_DENIED';
}

class ErrorHandler {
  static ApiError extractError(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    }
    
    return ApiError(
      message: error.toString().replaceAll('Exception: ', ''),
    );
  }

  static ApiError _handleDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      
      if (detail is Map<String, dynamic>) {
        return ApiError(
          message: detail['message'] ?? 'An error occurred',
          errorCode: detail['error_code'],
          details: detail,
          statusCode: statusCode,
        );
      } else if (detail is String) {
        return ApiError(
          message: detail,
          statusCode: statusCode,
        );
      }
    }

    return ApiError(
      message: _getDefaultErrorMessage(statusCode, e),
      statusCode: statusCode,
    );
  }

  static String _getDefaultErrorMessage(int? statusCode, DioException e) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'A conflict occurred. The resource may already exist.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return 'Connection timeout. Please check your internet connection or backend server status.';
        }
        if (e.type == DioExceptionType.connectionError) {
          return 'Cannot connect to server. Please verify:\n'
                 '• Backend server is running\n'
                 '• Network connection is active\n'
                 '• Backend URL is configured correctly in Settings';
        }
        return e.message ?? 'An unexpected error occurred';
    }
  }

  static String getUserFriendlyMessage(ApiError error) {
    if (error.isDuplicateRequest) {
      final username = error.details?['username'] ?? 'this user';
      return 'A registration request for "$username" is already pending approval.';
    }
    
    if (error.isPasswordRequired) {
      return 'Password is required for new user registration (minimum 6 characters).';
    }
    
    if (error.isEmailExists) {
      return 'This email address is already registered.';
    }
    
    if (error.isPermissionDenied) {
      return error.message;
    }
    
    return error.message;
  }
}
