import '../../domain/entities/payroll.dart';
import '../../domain/entities/payroll_item.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../datasources/payroll_remote_datasource.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  final PayrollRemoteDataSource remoteDataSource;

  PayrollRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Payroll>> getPayrolls({String? status, DateTime? month}) async {
    try {
      return await remoteDataSource.getPayrolls(status: status, month: month);
    } catch (e) {
      throw Exception('Failed to fetch payrolls: $e');
    }
  }

  @override
  Future<Payroll> getPayrollById(int id) async {
    try {
      return await remoteDataSource.getPayrollById(id);
    } catch (e) {
      throw Exception('Failed to fetch payroll: $e');
    }
  }

  @override
  Future<List<PayrollItem>> getPayrollItems(int payrollId) async {
    try {
      return await remoteDataSource.getPayrollItems(payrollId);
    } catch (e) {
      throw Exception('Failed to fetch payroll items: $e');
    }
  }

  @override
  Future<Payroll> createPayroll(Payroll payroll) async {
    try {
      return await remoteDataSource.createPayroll(payroll);
    } catch (e) {
      throw Exception('Failed to create payroll: $e');
    }
  }

  @override
  Future<Payroll> approvePayroll(int payrollId) async {
    try {
      return await remoteDataSource.approvePayroll(payrollId);
    } catch (e) {
      throw Exception('Failed to approve payroll: $e');
    }
  }

  @override
  Future<String> exportPayrollCBE(int payrollId) async {
    try {
      return await remoteDataSource.exportPayrollCBE(payrollId);
    } catch (e) {
      throw Exception('Failed to export CBE payroll: $e');
    }
  }

  @override
  Future<String> exportPayrollDashen(int payrollId) async {
    try {
      return await remoteDataSource.exportPayrollDashen(payrollId);
    } catch (e) {
      throw Exception('Failed to export Dashen payroll: $e');
    }
  }

  @override
  Future<String> exportPayrollAwash(int payrollId) async {
    try {
      return await remoteDataSource.exportPayrollAwash(payrollId);
    } catch (e) {
      throw Exception('Failed to export Awash payroll: $e');
    }
  }

  @override
  Future<String> exportPayrollTelebirr(int payrollId) async {
    try {
      return await remoteDataSource.exportPayrollTelebirr(payrollId);
    } catch (e) {
      throw Exception('Failed to export Telebirr payroll: $e');
    }
  }

  @override
  Future<String> exportPensionReport(int payrollId, String format) async {
    try {
      return await remoteDataSource.exportPensionReport(payrollId, format);
    } catch (e) {
      throw Exception('Failed to export pension report: $e');
    }
  }
}
