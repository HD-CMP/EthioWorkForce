import 'package:dio/dio.dart';
import '../models/role_model.dart';

class RolesRemoteDatasource {
  final Dio dio;

  RolesRemoteDatasource(this.dio);

  Future<List<RoleModel>> getRoles({bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isActive != null) {
        queryParams['is_active'] = isActive;
      }

      final response = await dio.get(
        '/roles/',
        queryParameters: queryParams,
      );

      if (response.data is! List) {
        final errorDetail = response.data is Map ? (response.data['detail'] ?? response.data.toString()) : response.data.toString();
        throw Exception('API returned error: $errorDetail');
      }

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => RoleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMessage = e.response?.data is Map 
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception('Failed to fetch roles: $errorMessage');
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  Future<RoleModel> createRole(RoleCreateUpdate role) async {
    try {
      final response = await dio.post(
        '/roles/',
        data: role.toJson(),
      );

      return RoleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to create role: ${e.message}');
    }
  }

  Future<RoleModel> updateRole(int roleId, Map<String, dynamic> updates) async {
    try {
      final response = await dio.patch(
        '/roles/$roleId',
        data: updates,
      );

      return RoleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to update role: ${e.message}');
    }
  }

  Future<void> deleteRole(int roleId) async {
    try {
      await dio.delete('/roles/$roleId');
    } on DioException catch (e) {
      throw Exception('Failed to delete role: ${e.message}');
    }
  }
}
