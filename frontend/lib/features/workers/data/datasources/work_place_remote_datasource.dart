import 'package:dio/dio.dart';

import '../../domain/entities/work_place.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

class WorkPlaceRemoteDataSource {
  Dio? _dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected error: $e',
        userMessage: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  Future<List<WorkPlace>> getWorkPlaces({int? siteId, bool? isActive}) async {
    try {
      final dio = await _getDio();
      
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await dio.get('/work-places', queryParameters: queryParams);
      
      if (response.data == null) {
        return [];
      }
      
      final List<dynamic> data = response.data is List 
          ? response.data as List<dynamic>
          : (response.data['data'] ?? response.data['work_places'] ?? []) as List<dynamic>;
      
      if (data.isEmpty) {
        return <WorkPlace>[];
      }
      
      final workPlaces = <WorkPlace>[];
      for (var item in data) {
        try {
          workPlaces.add(WorkPlace.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          print('Failed to parse work place: $e');
        }
      }
      return workPlaces;
      
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected error: $e',
        userMessage: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  Future<WorkPlace> getWorkPlaceById(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.get('/work-places/$id');
      return WorkPlace.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<WorkPlace> createWorkPlace(WorkPlace workPlace) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.post('/work-places', data: workPlace.toJson());
      return WorkPlace.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<WorkPlace> updateWorkPlace(WorkPlace workPlace) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.patch('/work-places/${workPlace.id}', data: workPlace.toJson());
      return WorkPlace.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteWorkPlace(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      await dio.delete('/work-places/$id');
    });
  }
}
