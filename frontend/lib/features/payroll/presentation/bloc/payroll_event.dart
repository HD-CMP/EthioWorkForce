import 'package:equatable/equatable.dart';

abstract class PayrollEvent extends Equatable {
  const PayrollEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayrolls extends PayrollEvent {
  final String? status;
  final int? siteId;

  const LoadPayrolls({this.status, this.siteId});

  @override
  List<Object?> get props => [status, siteId];
}

class RefreshPayrolls extends PayrollEvent {
  final String? status;
  final int? siteId;

  const RefreshPayrolls({this.status, this.siteId});

  @override
  List<Object?> get props => [status, siteId];
}

class LoadPayrollDetails extends PayrollEvent {
  final int payrollId;

  const LoadPayrollDetails(this.payrollId);

  @override
  List<Object> get props => [payrollId];
}

class CreateAndCalculatePayroll extends PayrollEvent {
  final int siteId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? ethiopianMonth;
  final int? ethiopianYear;
  final int? workTypeId;
  final int? workPlaceId;

  const CreateAndCalculatePayroll({
    required this.siteId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    this.ethiopianMonth,
    this.ethiopianYear,
    this.workTypeId,
    this.workPlaceId,
  });

  @override
  List<Object?> get props => [siteId, periodType, periodStart, periodEnd, ethiopianMonth, ethiopianYear, workTypeId, workPlaceId];
}

class CalculatePayroll extends PayrollEvent {
  final int payrollId;

  const CalculatePayroll(this.payrollId);

  @override
  List<Object> get props => [payrollId];
}

class ApprovePayroll extends PayrollEvent {
  final int payrollId;

  const ApprovePayroll(this.payrollId);

  @override
  List<Object> get props => [payrollId];
}

class LoadPayrollWithItems extends PayrollEvent {
  final int payrollId;

  const LoadPayrollWithItems(this.payrollId);

  @override
  List<Object> get props => [payrollId];
}
