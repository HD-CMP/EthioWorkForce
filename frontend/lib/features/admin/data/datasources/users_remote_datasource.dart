import 'package:dio/dio.dart';
import '../models/user_model.dart';

class UsersRemoteDatasource {
  final Dio dio;

  UsersRemoteDatasource(this.dio);

  Future<List<UserModel>> searchUsers(String query, {int? siteId}) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'limit': 10,
      };
      
      if (siteId != null) {
        queryParams['site_id'] = siteId;
      }

      final response = await dio.get(
        '/users/search',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to search users: ${e.message}');
    }
  }

  Future<UserModel> getUser(int userId) async {
    try {
      final response = await dio.get('/users/$userId');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get user: ${e.message}');
    }
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    try {
      await dio.post(
        '/users/$userId/reset-password',
        data: {'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to reset password: ${e.message}');
    }
  }
}
