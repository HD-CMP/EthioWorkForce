import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/login_request.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/session_manager.dart';
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
      
      // Initialize active session tracking immediately
      SessionManager.recordActivity(syncNow: true);
      
      // Proactively fetch and cache the user's profile and role immediately
      try {
        final dio = await DioClient.createDio();
        final userResponse = await dio.get('/users/me');
        if (userResponse.statusCode == 200 && userResponse.data != null) {
          final userData = Map<String, dynamic>.from(userResponse.data as Map);
          await localDataSource.saveUserData(userData);
          if (userData['role'] != null) {
            await storageService.setUserRole(userData['role'].toString());
          }
        }
      } catch (_) {
        // If profile fetch fails (e.g. slow connection), token is still valid
      }
      
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
    SessionManager.stop();
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      // Security check: Has session expired due to inactivity?
      if (await SessionManager.isSessionExpired()) {
        await SessionManager.expireSession();
        return false;
      }

      final token = await localDataSource.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }
      
      // Validate the token by calling /users/me
      final dio = await DioClient.createDio();
      final response = await dio.get('/users/me');
      
      if (response.statusCode == 200 && response.data != null) {
        final userData = Map<String, dynamic>.from(response.data as Map);
        await localDataSource.saveUserData(userData);
        if (userData['role'] != null) {
          await storageService.setUserRole(userData['role'].toString());
        }
        SessionManager.recordActivity(syncNow: true);
        return true;
      }
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      // Only clear token if server explicitly rejected it (401 Unauthorized)
      if (e.response?.statusCode == 401) {
        await localDataSource.clearToken();
        return false;
      }
      // Network error (no internet, timeout, etc.) — check if token exists
      final token = await localDataSource.getToken();
      if (token != null && token.isNotEmpty) {
        SessionManager.recordActivity(syncNow: true);
        return true;
      }
      return false;
    } catch (e) {
      final token = await localDataSource.getToken();
      if (token != null && token.isNotEmpty) {
        SessionManager.recordActivity(syncNow: true);
        return true;
      }
      return false;
    }
  }
}
