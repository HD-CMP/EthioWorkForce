import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/overtime.dart';
import '../../../../core/network/dio_client.dart';

class OvertimeRemoteDataSource {
  Dio? _dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  Future<List<Overtime>> getOvertimes({
    required int siteId,
    int? workerId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isVerified,
  }) async {
    final dio = await _getDio();
    
    final queryParams = <String, dynamic>{
      'site_id': siteId,
    };
    
    if (workerId != null) queryParams['worker_id'] = workerId;
    if (dateFrom != null) queryParams['date_from'] = DateFormat('yyyy-MM-dd').format(dateFrom);
    if (dateTo != null) queryParams['date_to'] = DateFormat('yyyy-MM-dd').format(dateTo);
    if (isVerified != null) queryParams['is_verified'] = isVerified;

    final response = await dio.get('/overtime/', queryParameters: queryParams);
    
    if (response.statusCode != 200) {
      final error = response.data is Map ? response.data['detail'] ?? 'Unknown error' : 'Unknown error';
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: error,
        type: DioExceptionType.badResponse,
      );
    }
    
    return (response.data as List)
        .map((json) => Overtime.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Overtime> createOvertime({
    required int workerId,
    required int siteId,
    required DateTime overtimeDate,
    required double hours,
    String? notes,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/overtime/', data: {
      'worker_id': workerId,
      'site_id': siteId,
      'overtime_date': DateFormat('yyyy-MM-dd').format(overtimeDate),
      'hours': hours,
      if (notes != null) 'notes': notes,
    });
    
    return Overtime.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createBulkOvertime({
    required int siteId,
    required DateTime overtimeDate,
    required Map<int, double> overtimeData,
    bool verify = false,
  }) async {
    final dio = await _getDio();
    
    final entries = overtimeData.entries
        .map((e) => {'worker_id': e.key, 'hours': e.value})
        .toList();
    
    final response = await dio.post('/overtime/bulk', data: {
      'site_id': siteId,
      'overtime_date': DateFormat('yyyy-MM-dd').format(overtimeDate),
      'entries': entries,
      'verify': verify,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMultiDayOvertime({
    required int workerId,
    required int siteId,
    required Map<DateTime, double> overtimeData,
    bool verify = false,
  }) async {
    final dio = await _getDio();
    
    final entries = overtimeData.entries
        .map((e) => {
              'overtime_date': DateFormat('yyyy-MM-dd').format(e.key),
              'hours': e.value,
            })
        .toList();
    
    final response = await dio.post('/overtime/multi-day', data: {
      'worker_id': workerId,
      'site_id': siteId,
      'entries': entries,
      'verify': verify,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Overtime> updateOvertime({
    required int id,
    double? hours,
    String? notes,
  }) async {
    final dio = await _getDio();
    
    final data = <String, dynamic>{};
    if (hours != null) data['hours'] = hours;
    if (notes != null) data['notes'] = notes;
    
    final response = await dio.patch('/overtime/$id', data: data);
    return Overtime.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteOvertime(int id) async {
    final dio = await _getDio();
    await dio.delete('/overtime/$id');
  }

  Future<Map<String, dynamic>> verifyOvertimes({
    required int siteId,
    required List<int> overtimeIds,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/overtime/verify', data: {
      'site_id': siteId,
      'overtime_ids': overtimeIds,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unverifyOvertimes({
    required int siteId,
    required List<int> overtimeIds,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/overtime/unverify', data: {
      'site_id': siteId,
      'overtime_ids': overtimeIds,
    });
    
    return response.data as Map<String, dynamic>;
  }
}
