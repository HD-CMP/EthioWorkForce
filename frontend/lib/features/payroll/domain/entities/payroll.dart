import '../../../../core/utils/ethiopian_calendar.dart';
import 'payroll_item.dart';

class Payroll {
  final int id;
  final String payrollCode;
  final int siteId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String? ethiopianMonth;
  final int? ethiopianYear;
  final double totalGrossAmount;
  final double totalDeductions;
  final double totalNetAmount;
  final double totalEmployerPension;
  final String status;
  final int? calculatedById;
  final int? approvedById;
  final DateTime? approvedAt;
  final String? notes;
  final int? workTypeId;
  final int? workPlaceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? hasMultiplePeriods;
  final int? periodTypesCount;
  final List<PayrollItem>? payrollItems;

  Payroll({
    required this.id,
    required this.payrollCode,
    required this.siteId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    this.ethiopianMonth,
    this.ethiopianYear,
    required this.totalGrossAmount,
    required this.totalDeductions,
    required this.totalNetAmount,
    required this.totalEmployerPension,
    required this.status,
    this.calculatedById,
    this.approvedById,
    this.approvedAt,
    this.notes,
    this.workTypeId,
    this.workPlaceId,
    required this.createdAt,
    required this.updatedAt,
    this.hasMultiplePeriods,
    this.periodTypesCount,
    this.payrollItems,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['id'] as int,
      payrollCode: json['payroll_code'] as String,
      siteId: json['site_id'] as int,
      periodType: json['period_type'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      ethiopianMonth: json['ethiopian_month'] as String?,
      ethiopianYear: json['ethiopian_year'] as int?,
      totalGrossAmount: _parseDecimal(json['total_gross_amount']),
      totalDeductions: _parseDecimal(json['total_deductions']),
      totalNetAmount: _parseDecimal(json['total_net_amount']),
      totalEmployerPension: _parseDecimal(json['total_employer_pension']),
      status: json['status'] as String,
      calculatedById: json['calculated_by_id'] as int?,
      approvedById: json['approved_by_id'] as int?,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      notes: json['notes'] as String?,
      workTypeId: json['work_type_id'] as int?,
      workPlaceId: json['work_place_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      hasMultiplePeriods: json['has_multiple_periods'] as bool?,
      periodTypesCount: json['period_types_count'] as int?,
      payrollItems: json['payroll_items'] != null
          ? (json['payroll_items'] as List<dynamic>)
              .map((e) => PayrollItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payroll_code': payrollCode,
      'site_id': siteId,
      'period_type': periodType,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      if (ethiopianMonth != null) 'ethiopian_month': ethiopianMonth,
      if (ethiopianYear != null) 'ethiopian_year': ethiopianYear,
      'total_gross_amount': totalGrossAmount,
      'total_deductions': totalDeductions,
      'total_net_amount': totalNetAmount,
      'total_employer_pension': totalEmployerPension,
      'status': status,
      if (calculatedById != null) 'calculated_by_id': calculatedById,
      if (approvedById != null) 'approved_by_id': approvedById,
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
      if (workTypeId != null) 'work_type_id': workTypeId,
      if (workPlaceId != null) 'work_place_id': workPlaceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (hasMultiplePeriods != null) 'has_multiple_periods': hasMultiplePeriods,
      if (periodTypesCount != null) 'period_types_count': periodTypesCount,
    };
  }

  String get formattedPeriod {
    final ethStart = EthiopianCalendar.fromGregorian(periodStart);
    final ethEnd = EthiopianCalendar.fromGregorian(periodEnd);
    
    final startFormatted = '${ethStart.month}/${ethStart.day}';
    final endFormatted = '${ethEnd.month}/${ethEnd.day}/${ethEnd.year}';
    return '$startFormatted-$endFormatted';
  }

  int get employeeCount {
    return payrollItems?.length ?? 0;
  }
}
