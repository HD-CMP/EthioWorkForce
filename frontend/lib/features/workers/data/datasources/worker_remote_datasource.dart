import 'package:dio/dio.dart';
import '../../domain/entities/worker.dart';
import '../../../../core/network/dio_client.dart';

class WorkerRemoteDataSource {
  late final Dio _dio;

  WorkerRemoteDataSource() {
    _initDio();
  }

  Future<void> _initDio() async {
    _dio = await DioClient.createDio();
  }

  Future<List<Worker>> getWorkers({String? siteId, String? workType, bool? isActive}) async {
    await _initDio();
    
    final queryParams = <String, dynamic>{};
    if (siteId != null) queryParams['site_id'] = siteId;
    if (workType != null) queryParams['work_type'] = workType;
    if (isActive != null) queryParams['is_active'] = isActive;

    final response = await _dio.get('/workers', queryParameters: queryParams);
    
    return (response.data as List)
        .map((json) => Worker.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Worker> getWorkerById(int id) async {
    await _initDio();
    final response = await _dio.get('/workers/$id');
    return Worker.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Worker> createWorker(Worker worker) async {
    await _initDio();
    final response = await _dio.post('/workers', data: worker.toJson());
    return Worker.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Worker> updateWorker(Worker worker) async {
    await _initDio();
    final response = await _dio.put('/workers/${worker.id}', data: worker.toJson());
    return Worker.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWorker(int id) async {
    await _initDio();
    await _dio.delete('/workers/$id');
  }

  Future<String> generateWorkerQRCode(int workerId) async {
    await _initDio();
    final response = await _dio.get('/workers/$workerId/qr-code');
    return response.data['qr_data'] as String;
  }

  Future<List<Worker>> searchWorkers(String query) async {
    await _initDio();
    final response = await _dio.get('/workers/search', queryParameters: {'q': query});
    
    return (response.data as List)
        .map((json) => Worker.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
