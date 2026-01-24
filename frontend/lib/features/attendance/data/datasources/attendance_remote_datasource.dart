import 'package:dio/dio.dart';
import '../../domain/entities/attendance.dart';
import '../../../../core/network/dio_client.dart';

class AttendanceRemoteDataSource {
  late final Dio _dio;

  AttendanceRemoteDataSource() {
    _initDio();
  }

  Future<void> _initDio() async {
    _dio = await DioClient.createDio();
  }

  Future<List<Attendance>> getAttendances({DateTime? date, int? siteId}) async {
    await _initDio();
    
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date.toIso8601String().split('T')[0];
    if (siteId != null) queryParams['site_id'] = siteId;

    final response = await _dio.get('/attendance', queryParameters: queryParams);
    
    return (response.data as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Attendance> markAttendance(int workerId, int siteId, String checkType) async {
    await _initDio();
    
    final response = await _dio.post('/attendance', data: {
      'worker_id': workerId,
      'site_id': siteId,
      'check_type': checkType,
    });
    
    return Attendance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Attendance> updateAttendance(int id, Attendance attendance) async {
    await _initDio();
    final response = await _dio.put('/attendance/$id', data: attendance.toJson());
    return Attendance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, int>> getAttendanceStats(DateTime date) async {
    await _initDio();
    
    final response = await _dio.get(
      '/attendance/stats',
      queryParameters: {'date': date.toIso8601String().split('T')[0]},
    );
    
    return Map<String, int>.from(response.data as Map);
  }

  Future<List<Attendance>> getWorkerAttendanceHistory(
    int workerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _initDio();
    
    final queryParams = <String, dynamic>{'worker_id': workerId};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await _dio.get('/attendance/history', queryParameters: queryParams);
    
    return (response.data as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
