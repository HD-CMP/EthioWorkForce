import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/login_request.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final StorageService storageService = StorageService();

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
      if (e is DioException) {
        // Log but don't crash
        print('Login failed: ${e.response?.statusCode ?? e.type}');
      }
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearToken();
    await storageService.clearUserRole();
    await storageService.clearSelectedSiteId();
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = await localDataSource.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      
      // Validate the token by calling /users/me
      // If the token is expired or invalid, this will fail
      final dio = await DioClient.createDio();
      final response = await dio.get('/users/me');
      
      // If we get here, token is valid
      return response.statusCode == 200;
    } on DioException catch (e) {
      // Only clear token if server explicitly rejected it (401 Unauthorized)
      if (e.response?.statusCode == 401) {
        await localDataSource.clearToken();
        return false;
      }
      // Network error (no internet, timeout, etc.) — keep token, user stays logged in
      // This prevents offline users from being permanently locked out
      final token = await localDataSource.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      // Unknown error — preserve token if it exists (don't lock out offline users)
      final token = await localDataSource.getToken();
      return token != null && token.isNotEmpty;
    }
  }
}
