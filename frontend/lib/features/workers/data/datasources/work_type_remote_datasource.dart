import 'package:dio/dio.dart';

import '../../domain/entities/work_type.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

class WorkTypeRemoteDataSource {
  Dio? _dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      print('WorkType API DioException: ${e.type}, ${e.message}, ${e.response?.statusCode}');
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      if (e is ApiException) rethrow;
      print('WorkType API Unexpected error: $e');
      print('Stack trace: $stackTrace');
      throw ApiException(
        message: 'Unexpected error: $e',
        userMessage: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  Future<List<WorkType>> getWorkTypes({bool? isActive}) async {
    try {
      final dio = await _getDio();
      
      final queryParams = <String, dynamic>{};
      if (isActive != null) queryParams['is_active'] = isActive;

      print('🔍 Fetching work types with params: $queryParams');
      final response = await dio.get('/work-types', queryParameters: queryParams);
      print('✅ Work types response status: ${response.statusCode}');
      print('📦 Work types response data type: ${response.data.runtimeType}');
      print('📄 Work types response data: ${response.data}');
      
      // Handle null or empty response
      if (response.data == null) {
        print('⚠️ Response data is null - returning empty list');
        return [];
      }
      
      // Extract data from response
      final List<dynamic> data = response.data is List 
          ? response.data as List<dynamic>
          : (response.data['data'] ?? response.data['work_types'] ?? []) as List<dynamic>;
      
      print('📊 Extracted data list length: ${data.length}');
      
      // Empty list is valid - not an error!
      if (data.isEmpty) {
        print('✨ No work types found - returning empty list (NOT AN ERROR)');
        return <WorkType>[];
      }
      
      // Parse work types
      print('🔄 Parsing ${data.length} work types...');
      final workTypes = <WorkType>[];
      for (var i = 0; i < data.length; i++) {
        try {
          workTypes.add(WorkType.fromJson(data[i] as Map<String, dynamic>));
        } catch (e) {
          print('❌ Failed to parse work type at index $i: $e');
        }
      }
      print('✅ Successfully parsed ${workTypes.length} work types');
      return workTypes;
      
    } on DioException catch (e) {
      print('🔴 WorkType API DioException: ${e.type}, ${e.message}, Status: ${e.response?.statusCode}');
      print('Response body: ${e.response?.data}');
      throw ApiException.fromDioException(e);
    } catch (e, stackTrace) {
      if (e is ApiException) rethrow;
      print('💥 WorkType API Unexpected error: $e');
      print('Stack trace: $stackTrace');
      throw ApiException(
        message: 'Unexpected error: $e',
        userMessage: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  Future<WorkType> getWorkTypeById(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.get('/work-types/$id');
      return WorkType.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<WorkType> createWorkType(WorkType workType) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.post('/work-types', data: workType.toJson());
      return WorkType.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<WorkType> updateWorkType(WorkType workType) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.patch('/work-types/${workType.id}', data: workType.toJson());
      return WorkType.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteWorkType(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      await dio.delete('/work-types/$id');
    });
  }
}
