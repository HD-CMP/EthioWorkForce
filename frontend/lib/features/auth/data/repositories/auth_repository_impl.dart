import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/login_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<bool> login(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await remoteDataSource.login(request);
      
      await localDataSource.saveToken(response.accessToken);
      
      return true;
    } catch (e) {
      // Detailed error logging for debugging
      if (e is DioException) {
        print('❌ Login Failed - Type: ${e.type}');
        print('❌ Request: ${e.requestOptions.method} ${e.requestOptions.uri}');
        print('❌ Status: ${e.response?.statusCode ?? "No response"}');
        print('❌ Message: ${e.response?.data ?? e.message}');
        
        // Network errors
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          print('❌ Network timeout - Check internet connection');
        } else if (e.type == DioExceptionType.connectionError) {
          print('❌ Connection error - Cannot reach server at ${e.requestOptions.uri.host}');
        }
      } else {
        print('❌ Unexpected error: $e');
      }
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }
}
