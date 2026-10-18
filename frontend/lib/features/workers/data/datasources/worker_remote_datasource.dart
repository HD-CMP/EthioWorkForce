import 'package:dio/dio.dart';
import '../../domain/entities/worker.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';

class WorkerRemoteDataSource {
  Dio? _dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    } else if (data is Map) {
      return (data['data'] ?? data['workers'] ?? data['items'] ?? []) as List;
    } else {
      throw ApiException(
        message: 'Unexpected response format',
        userMessage: 'Received unexpected data from server. Please try again.',
      );
    }
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

  Future<List<Worker>> getWorkers({int? siteId, int? workTypeId, String? status}) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      
      final queryParams = <String, dynamic>{};
      if (siteId != null) queryParams['site_id'] = siteId;
      if (workTypeId != null) queryParams['work_type_id'] = workTypeId;
      if (status != null) queryParams['status'] = status;

      final response = await dio.get('/workers', queryParameters: queryParams);
      
      return _extractList(response.data)
          .map((json) => Worker.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Worker> getWorkerById(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.get('/workers/$id');
      return Worker.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Worker> createWorker(Worker worker) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.post('/workers', data: worker.toJson());
      return Worker.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Worker> updateWorker(Worker worker) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.patch('/workers/${worker.id}', data: worker.toJson());
      return Worker.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteWorker(int id) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      await dio.delete('/workers/$id');
    });
  }

  Future<String> generateWorkerQRCode(int workerId) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.get('/workers/$workerId/qr-code');
      return response.data['qr_data'] as String;
    });
  }

  Future<List<Worker>> searchWorkers(String query) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final response = await dio.get('/workers/search', queryParameters: {'q': query});
      
      return _extractList(response.data)
          .map((json) => Worker.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Map<String, dynamic>> checkEmployeeIdAvailability({
    required String employeeId,
    required int siteId,
    required int workTypeId,
    int? excludeWorkerId,
  }) async {
    return _handleRequest(() async {
      final dio = await _getDio();
      final queryParams = {
        'employee_id': employeeId,
        'site_id': siteId,
        'work_type_id': workTypeId,
      };
      if (excludeWorkerId != null) {
        queryParams['exclude_worker_id'] = excludeWorkerId;
      }
      
      final response = await dio.get('/workers/check-employee-id', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    });
  }
}
