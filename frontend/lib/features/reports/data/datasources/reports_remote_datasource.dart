import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ReportsRemoteDataSource {
  Dio? _dio;

  ReportsRemoteDataSource([Dio? dio]) : _dio = dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  /// Fetch executive dashboard KPI analytics
  Future<Map<String, dynamic>> getDashboardKpi({int? siteId}) async {
    final dio = await _getDio();
    final query = <String, dynamic>{};
    if (siteId != null) query['site_id'] = siteId;

    final response = await dio.get('/reports/dashboard', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  /// Fetch ERCA tax compliance schedule for a payroll
  Future<Map<String, dynamic>> getTaxComplianceReport(int payrollId) async {
    final dio = await _getDio();
    final response = await dio.get('/reports/tax-compliance/$payrollId');
    return response.data as Map<String, dynamic>;
  }

  /// Fetch workforce demographic & HR census
  Future<List<dynamic>> getWorkerCensus({int? siteId, int? workTypeId, String? status}) async {
    final dio = await _getDio();
    final query = <String, dynamic>{};
    if (siteId != null) query['site_id'] = siteId;
    if (workTypeId != null) query['work_type_id'] = workTypeId;
    if (status != null && status != 'all') query['status'] = status;

    final response = await dio.get('/reports/worker-census', queryParameters: query);
    return response.data as List<dynamic>;
  }

  /// Fetch attendance & overtime audit roster for a site and date range
  Future<Map<String, dynamic>> getAttendanceRoster({
    required int siteId,
    required String dateFrom,
    required String dateTo,
  }) async {
    final dio = await _getDio();
    final response = await dio.get('/reports/attendance-roster', queryParameters: {
      'site_id': siteId,
      'date_from': dateFrom,
      'date_to': dateTo,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Fetch all payroll runs for dropdown selection
  Future<List<dynamic>> getPayrolls({int? siteId}) async {
    final dio = await _getDio();
    final query = <String, dynamic>{};
    if (siteId != null) query['site_id'] = siteId;

    final response = await dio.get('/payroll/', queryParameters: query);
    return response.data as List<dynamic>;
  }

  /// Download binary report files (Excel or PDF) from the backend
  Future<List<int>> downloadReportBytes(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    final dio = await _getDio();
    final response = await dio.get(
      path,
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return List<int>.from(response.data);
  }
}
