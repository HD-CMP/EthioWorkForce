class PayrollItem {
  final int? id;
  final int payrollId;
  final int workerId;
  final String? workerName;
  final String? employeeId;
  final double basicSalary;
  final double? allowances;
  final double? overtimePay;
  final double grossSalary;
  final double? incomeTax;
  final double? pensionContribution;
  final double? otherDeductions;
  final double netSalary;
  final int? daysWorked;
  final double? hoursWorked;

  PayrollItem({
    this.id,
    required this.payrollId,
    required this.workerId,
    this.workerName,
    this.employeeId,
    required this.basicSalary,
    this.allowances,
    this.overtimePay,
    required this.grossSalary,
    this.incomeTax,
    this.pensionContribution,
    this.otherDeductions,
    required this.netSalary,
    this.daysWorked,
    this.hoursWorked,
  });

  factory PayrollItem.fromJson(Map<String, dynamic> json) {
    return PayrollItem(
      id: json['id'] as int?,
      payrollId: json['payroll_id'] as int,
      workerId: json['worker_id'] as int,
      workerName: json['worker_name'] as String?,
      employeeId: json['employee_id'] as String?,
      basicSalary: (json['basic_salary'] as num).toDouble(),
      allowances: (json['allowances'] as num?)?.toDouble(),
      overtimePay: (json['overtime_pay'] as num?)?.toDouble(),
      grossSalary: (json['gross_salary'] as num).toDouble(),
      incomeTax: (json['income_tax'] as num?)?.toDouble(),
      pensionContribution: (json['pension_contribution'] as num?)?.toDouble(),
      otherDeductions: (json['other_deductions'] as num?)?.toDouble(),
      netSalary: (json['net_salary'] as num).toDouble(),
      daysWorked: json['days_worked'] as int?,
      hoursWorked: (json['hours_worked'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'payroll_id': payrollId,
      'worker_id': workerId,
      'basic_salary': basicSalary,
      if (allowances != null) 'allowances': allowances,
      if (overtimePay != null) 'overtime_pay': overtimePay,
      'gross_salary': grossSalary,
      if (incomeTax != null) 'income_tax': incomeTax,
      if (pensionContribution != null) 'pension_contribution': pensionContribution,
      if (otherDeductions != null) 'other_deductions': otherDeductions,
      'net_salary': netSalary,
      if (daysWorked != null) 'days_worked': daysWorked,
      if (hoursWorked != null) 'hours_worked': hoursWorked,
    };
  }
}
