import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/payroll.dart';
import '../../domain/entities/payroll_item.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/file_saver.dart';

class PayrollRemoteDataSource {
  Dio? _dio;

  PayrollRemoteDataSource([Dio? dio]) : _dio = dio;

  Future<Dio> _getDio() async {
    _dio ??= await DioClient.createDio();
    return _dio!;
  }

  // ─── Core Payroll CRUD ───────────────────────────────────────────────────

  Future<List<Payroll>> getPayrolls({String? status, int? siteId}) async {
    final dio = await _getDio();
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (siteId != null) queryParams['site_id'] = siteId;

    final response = await dio.get('/payroll/', queryParameters: queryParams);
    return (response.data as List)
        .map((json) => Payroll.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Payroll> getPayrollById(int id) async {
    final dio = await _getDio();
    final response = await dio.get('/payroll/$id');
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PayrollItem>> getPayrollItems(int payrollId) async {
    final dio = await _getDio();
    final response = await dio.get('/payroll/$payrollId/items');
    return (response.data as List)
        .map((json) => PayrollItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Payroll> createPayroll(Payroll payroll) async {
    final dio = await _getDio();
    String periodType = payroll.periodType;
    if (periodType == 'biweekly') {
      periodType = 'bi_weekly';
    } else if (periodType == 'daily') {
      periodType = 'custom';
    }

    final response = await dio.post('/payroll/', data: {
      'site_id': payroll.siteId,
      'period_type': periodType,
      'period_start': DateFormat('yyyy-MM-dd').format(payroll.periodStart),
      'period_end': DateFormat('yyyy-MM-dd').format(payroll.periodEnd),
      if (payroll.ethiopianMonth != null) 'ethiopian_month': payroll.ethiopianMonth,
      if (payroll.ethiopianYear != null) 'ethiopian_year': payroll.ethiopianYear,
      if (payroll.workTypeId != null) 'work_type_id': payroll.workTypeId,
    });
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Payroll> calculatePayroll(int payrollId) async {
    final dio = await _getDio();
    final response = await dio.post('/payroll/calculate', data: {'payroll_id': payrollId});
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Approval, Locking & Payment Status Lifecycle ─────────────────────────

  Future<Payroll> approvePayroll(int payrollId, {String? notes}) async {
    final dio = await _getDio();
    final response = await dio.post('/payroll/approve', data: {
      'payroll_id': payrollId,
      if (notes != null) 'notes': notes,
    });
    return Payroll.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> lockPayroll(int payrollId) async {
    final dio = await _getDio();
    final response = await dio.post('/payroll/$payrollId/lock');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markPaymentStatus({
    required int payrollId,
    required int itemId,
    required bool isPaid,
  }) async {
    final dio = await _getDio();
    final response = await dio.post(
      '/payroll/$payrollId/items/$itemId/mark-paid',
      queryParameters: {'is_paid': isPaid},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPayrollPeriodBreakdown(int payrollId) async {
    final dio = await _getDio();
    final response = await dio.get('/payroll/$payrollId/period-breakdown');
    return response.data as Map<String, dynamic>;
  }

  // ─── Real Enterprise Bank & Statutory File Exports ────────────────────────

  Future<String> exportPayrollCBE(int payrollId) async {
    final dio = await _getDio();
    final filename = 'CBE_Payroll_PAY-$payrollId.xlsx';
    final response = await dio.get(
      '/reports/payroll/$payrollId/export/cbe',
      options: Options(responseType: ResponseType.bytes),
    );
    await FileSaver.saveAndOpenFile(List<int>.from(response.data), filename);
    return filename;
  }

  Future<String> exportPayrollDashen(int payrollId) async {
    final dio = await _getDio();
    final filename = 'Dashen_Payroll_PAY-$payrollId.xlsx';
    final response = await dio.get(
      '/reports/payroll/$payrollId/export/dashen',
      options: Options(responseType: ResponseType.bytes),
    );
    await FileSaver.saveAndOpenFile(List<int>.from(response.data), filename);
    return filename;
  }

  Future<String> exportPayrollAwash(int payrollId) async {
    final dio = await _getDio();
    final filename = 'Awash_Payroll_PAY-$payrollId.xlsx';
    final response = await dio.get(
      '/reports/payroll/$payrollId/export/awash',
      options: Options(responseType: ResponseType.bytes),
    );
    await FileSaver.saveAndOpenFile(List<int>.from(response.data), filename);
    return filename;
  }

  Future<String> exportPayrollTelebirr(int payrollId) async {
    final dio = await _getDio();
    final filename = 'Telebirr_Payroll_PAY-$payrollId.csv';
    final response = await dio.get(
      '/reports/payroll/$payrollId/export/telebirr',
      options: Options(responseType: ResponseType.bytes),
    );
    await FileSaver.saveAndOpenFile(List<int>.from(response.data), filename);
    return filename;
  }

  Future<String> exportCashPaymentSheet(int payrollId) async {
    final dio = await _getDio();
    final filename = 'Cash_Payment_Sheet_PAY-$payrollId.xlsx';
    final response = await dio.get(
      '/reports/payroll/$payrollId/export/cash-sheet',
      options: Options(responseType: ResponseType.bytes),
    );
    await FileSaver.saveAndOpenFile(List<int>.from(response.data), filename);
    return filename;
  }

  Future<String> exportPensionReport(
    int payrollId,
    String format, {
    String organizationName = 'EthioWorkforce Enterprise',
    String tinNumber = '0012345678',
  }) async {
    final dio = await _getDio();
    final ext = format.toLowerCase() == 'pdf' ? 'pdf' : 'xlsx';
    final filename = 'Pension_Declaration_PAY-$payrollId.$ext';
    final response = await dio.get(
      '/reports/payroll/$payrollId/pension-declaration/$ext',
      queryParameters: {
        'organization_name': organizationName,
        'tin_number': tinNumber,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    await FileSaver.saveAndOpenFile(List<int>.from(response.data), filename);
    return filename;
  }
}
