import 'package:dio/dio.dart';
import '../../domain/entities/payroll.dart';
import '../../domain/entities/payroll_item.dart';
import '../../../../core/network/dio_client.dart';

class PayrollRemoteDataSource {
  late final Dio _dio;

  PayrollRemoteDataSource() {
    _initDio();
  }

  Future<void> _initDio() async {
    _dio = await DioClient.createDio();
  }

  Future<List<Payroll>> getPayrolls({String? status, DateTime? month}) async {
    await _initDio();
    
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (month != null) queryParams['month'] = month.toIso8601String().split('T')[0];

    final response = await _dio.get('/payrolls', queryParameters: queryParams);
    
    return (response.data as List)
        .map((json) => Payroll.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Payroll> getPayrollById(int id) async {
    await _initDio();
    final response = await _dio.get('/payrolls/$id');
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PayrollItem>> getPayrollItems(int payrollId) async {
    await _initDio();
    final response = await _dio.get('/payrolls/$payrollId/items');
    
    return (response.data as List)
        .map((json) => PayrollItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Payroll> createPayroll(Payroll payroll) async {
    await _initDio();
    final response = await _dio.post('/payrolls', data: payroll.toJson());
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Payroll> approvePayroll(int payrollId) async {
    await _initDio();
    final response = await _dio.post('/payrolls/$payrollId/approve');
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> exportPayrollCBE(int payrollId) async {
    await _initDio();
    final response = await _dio.get(
      '/reports/payroll/$payrollId/export/cbe',
      options: Options(responseType: ResponseType.bytes),
    );
    return 'CBE_Payroll_$payrollId.xlsx';
  }

  Future<String> exportPayrollDashen(int payrollId) async {
    await _initDio();
    final response = await _dio.get(
      '/reports/payroll/$payrollId/export/dashen',
      options: Options(responseType: ResponseType.bytes),
    );
    return 'Dashen_Payroll_$payrollId.xlsx';
  }

  Future<String> exportPayrollAwash(int payrollId) async {
    await _initDio();
    final response = await _dio.get(
      '/reports/payroll/$payrollId/export/awash',
      options: Options(responseType: ResponseType.bytes),
    );
    return 'Awash_Payroll_$payrollId.xlsx';
  }

  Future<String> exportPayrollTelebirr(int payrollId) async {
    await _initDio();
    final response = await _dio.get(
      '/reports/payroll/$payrollId/export/telebirr',
      options: Options(responseType: ResponseType.bytes),
    );
    return 'Telebirr_Payroll_$payrollId.csv';
  }

  Future<String> exportPensionReport(int payrollId, String format) async {
    await _initDio();
    final response = await _dio.get(
      '/reports/payroll/$payrollId/pension-declaration',
      queryParameters: {'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return 'Pension_Report_$payrollId.$format';
  }
}
