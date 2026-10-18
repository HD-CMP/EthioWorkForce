import '../entities/payroll.dart';
import '../entities/payroll_item.dart';

abstract class PayrollRepository {
  Future<List<Payroll>> getPayrolls({String? status, int? siteId});
  Future<Payroll> getPayrollById(int id);
  Future<List<PayrollItem>> getPayrollItems(int payrollId);
  Future<Payroll> createPayroll(Payroll payroll);
  Future<Payroll> calculatePayroll(int payrollId);
  Future<Payroll> approvePayroll(int payrollId, {String? notes});
  Future<Map<String, dynamic>> lockPayroll(int payrollId);
  Future<String> exportPayrollCBE(int payrollId);
  Future<String> exportPayrollDashen(int payrollId);
  Future<String> exportPayrollAwash(int payrollId);
  Future<String> exportPayrollTelebirr(int payrollId);
  Future<String> exportCashPaymentSheet(int payrollId);
  Future<String> exportPensionReport(int payrollId, String format);
}
