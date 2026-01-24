import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
