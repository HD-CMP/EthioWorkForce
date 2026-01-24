class Payroll {
  final int? id;
  final String payrollCode;
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String status;
  final double? totalGrossSalary;
  final double? totalNetSalary;
  final int? employeeCount;
  final DateTime? approvedAt;
  final int? approvedBy;

  Payroll({
    this.id,
    required this.payrollCode,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.totalGrossSalary,
    this.totalNetSalary,
    this.employeeCount,
    this.approvedAt,
    this.approvedBy,
  });

  factory Payroll.fromJson(Map<String, dynamic> json) {
    return Payroll(
      id: json['id'] as int?,
      payrollCode: json['payroll_code'] as String,
      period: json['period'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      status: json['status'] as String,
      totalGrossSalary: (json['total_gross_salary'] as num?)?.toDouble(),
      totalNetSalary: (json['total_net_salary'] as num?)?.toDouble(),
      employeeCount: json['employee_count'] as int?,
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'payroll_code': payrollCode,
      'period': period,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'status': status,
      if (totalGrossSalary != null) 'total_gross_salary': totalGrossSalary,
      if (totalNetSalary != null) 'total_net_salary': totalNetSalary,
      if (employeeCount != null) 'employee_count': employeeCount,
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      if (approvedBy != null) 'approved_by': approvedBy,
    };
  }
}
