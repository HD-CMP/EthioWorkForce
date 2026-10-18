import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/attendance.dart';
import '../../../../core/network/dio_client.dart';

class AttendanceRemoteDataSource {
  Dio? _dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  Future<List<Attendance>> getAttendances({
    int? siteId,
    int? workerId,
    DateTime? dateFrom,
    DateTime? dateTo,
    DateTime? startDate,
    DateTime? endDate,
    bool? isVerified,
    int skip = 0,
    int limit = 100,
  }) async {
    final dio = await _getDio();
    
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    
    if (siteId != null) queryParams['site_id'] = siteId;
    if (workerId != null) queryParams['worker_id'] = workerId;
    if (dateFrom != null) queryParams['date_from'] = DateFormat('yyyy-MM-dd').format(dateFrom);
    if (dateTo != null) queryParams['date_to'] = DateFormat('yyyy-MM-dd').format(dateTo);
    if (startDate != null) queryParams['date_from'] = DateFormat('yyyy-MM-dd').format(startDate);
    if (endDate != null) queryParams['date_to'] = DateFormat('yyyy-MM-dd').format(endDate);
    if (isVerified != null) queryParams['is_verified'] = isVerified;

    final response = await dio.get('/attendance/', queryParameters: queryParams);
    
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
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Attendance> getAttendance(int id) async {
    final dio = await _getDio();
    final response = await dio.get('/attendance/$id');
    return Attendance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Attendance> createAttendance({
    required int workerId,
    required int siteId,
    required DateTime attendanceDate,
    String? checkInTime,
    String? checkOutTime,
    required String status,
    required String method,
    int regularHours = 8,
    double overtimeHours = 0.0,
    String? notes,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/', data: {
      'worker_id': workerId,
      'site_id': siteId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(attendanceDate),
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      'status': status,
      'method': method,
      'regular_hours': regularHours,
      'overtime_hours': overtimeHours,
      if (notes != null) 'notes': notes,
    });
    
    return Attendance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Attendance>> createBulkAttendance({
    required int siteId,
    required DateTime attendanceDate,
    required List<int> workerIds,
    String method = 'manual_entry',
    String status = 'present',
    String? checkInTime,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/bulk', data: {
      'site_id': siteId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(attendanceDate),
      'worker_ids': workerIds,
      'method': method,
      'status': status,
      if (checkInTime != null) 'check_in_time': checkInTime,
    });
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = response.data is Map ? response.data['detail'] ?? 'Unknown error' : 'Unknown error';
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: error,
        type: DioExceptionType.badResponse,
      );
    }
    
    return (response.data as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Attendance>> createMultiDayAttendance({
    required int workerId,
    required int siteId,
    required List<DateTime> attendanceDates,
    String method = 'manual_entry',
    String status = 'present',
    String? checkInTime,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/multi-day', data: {
      'worker_id': workerId,
      'site_id': siteId,
      'attendance_dates': attendanceDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
      'method': method,
      'status': status,
      if (checkInTime != null) 'check_in_time': checkInTime,
    });
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = response.data is Map ? response.data['detail'] ?? 'Unknown error' : 'Unknown error';
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: error,
        type: DioExceptionType.badResponse,
      );
    }
    
    return (response.data as List)
        .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Attendance> updateAttendance({
    required int id,
    String? checkInTime,
    String? checkOutTime,
    String? status,
    int? regularHours,
    double? overtimeHours,
    String? overrideReason,
    String? notes,
  }) async {
    final dio = await _getDio();
    
    final data = <String, dynamic>{};
    if (checkInTime != null) data['check_in_time'] = checkInTime.isEmpty ? null : checkInTime;
    if (checkOutTime != null) data['check_out_time'] = checkOutTime.isEmpty ? null : checkOutTime;
    if (status != null) data['status'] = status;
    if (regularHours != null) data['regular_hours'] = regularHours;
    if (overtimeHours != null) data['overtime_hours'] = overtimeHours;
    if (overrideReason != null) data['override_reason'] = overrideReason;
    if (notes != null) data['notes'] = notes;
    
    final response = await dio.patch('/attendance/$id', data: data);
    return Attendance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> verifyAttendances({
    required List<int> attendanceIds,
    String? overrideReason,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/verify', data: {
      'attendance_ids': attendanceIds,
      if (overrideReason != null) 'override_reason': overrideReason,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unverifyAttendances({
    required List<int> attendanceIds,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/unverify', data: {
      'attendance_ids': attendanceIds,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> lockAttendances({
    required List<int> attendanceIds,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/lock', data: {
      'attendance_ids': attendanceIds,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlockAttendances({
    required List<int> attendanceIds,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/unlock', data: {
      'attendance_ids': attendanceIds,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyMultiDayAttendance({
    required int workerId,
    required int siteId,
    required List<DateTime> attendanceDates,
    String? overrideReason,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/verify-multi-day', data: {
      'worker_id': workerId,
      'site_id': siteId,
      'attendance_dates': attendanceDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
      if (overrideReason != null) 'override_reason': overrideReason,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStatistics({
    required int siteId,
    required DateTime dateFrom,
    DateTime? dateTo,
  }) async {
    final dio = await _getDio();
    
    final queryParams = <String, dynamic>{
      'site_id': siteId,
      'date_from': DateFormat('yyyy-MM-dd').format(dateFrom),
    };
    
    if (dateTo != null) {
      queryParams['date_to'] = DateFormat('yyyy-MM-dd').format(dateTo);
    }
    
    final response = await dio.get('/attendance/statistics', queryParameters: queryParams);
    
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAttendance(int id) async {
    final dio = await _getDio();
    await dio.delete('/attendance/$id');
  }

  Future<Map<String, dynamic>> bulkUpdateOvertime({
    required int siteId,
    required DateTime date,
    required List<Map<String, dynamic>> overtimeEntries,
    bool verify = false,
  }) async {
    final dio = await _getDio();
    
    final response = await dio.post('/attendance/overtime/bulk-update', data: {
      'site_id': siteId,
      'attendance_date': DateFormat('yyyy-MM-dd').format(date),
      'overtime_entries': overtimeEntries,
      'verify': verify,
    });
    
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getWorkerPaymentPeriod({
    required int workerId,
    DateTime? referenceDate,
  }) async {
    final dio = await _getDio();
    
    final queryParams = <String, dynamic>{};
    if (referenceDate != null) {
      queryParams['reference_date'] = DateFormat('yyyy-MM-dd').format(referenceDate);
    }
    
    final response = await dio.get(
      '/payment-periods/worker/$workerId',
      queryParameters: queryParams,
    );
    
    return response.data as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> getCurrentPaymentPeriod(int siteId) async {
    final dio = await _getDio();
    
    final response = await dio.get('/payment-periods/current/$siteId');
    
    return response.data as Map<String, dynamic>?;
  }
}
