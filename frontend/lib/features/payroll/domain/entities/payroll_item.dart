class PayrollItem {
  final int? id;
  final int payrollId;
  final int workerId;
  final String? workerName;
  final String? employeeId;
  final int? workTypeId;
  final String? workTypeName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? phoneNumber;
  final double basicSalary;
  final double? allowances;
  final double? overtimePay;
  final double? allocatedOvertimePay;
  final double grossSalary;
  final double? incomeTax;
  final double? pensionContribution;
  final double? otherDeductions;
  final double netSalary;
  final int? daysWorked;
  final double? hoursWorked;
  final String? paymentPeriodStart;
  final String? paymentPeriodEnd;
  final int? paymentPeriodDays;
  final bool isProrated;
  final String? paymentPeriodType;
  final String? paymentPeriodDescription;
  final bool isPaid;
  final String? paymentDate;
  final int? paymentId;

  PayrollItem({
    this.id,
    required this.payrollId,
    required this.workerId,
    this.workerName,
    this.employeeId,
    this.workTypeId,
    this.workTypeName,
    this.bankName,
    this.bankAccountNumber,
    this.phoneNumber,
    required this.basicSalary,
    this.allowances,
    this.overtimePay,
    this.allocatedOvertimePay,
    required this.grossSalary,
    this.incomeTax,
    this.pensionContribution,
    this.otherDeductions,
    required this.netSalary,
    this.daysWorked,
    this.hoursWorked,
    this.paymentPeriodStart,
    this.paymentPeriodEnd,
    this.paymentPeriodDays,
    this.isProrated = false,
    this.paymentPeriodType,
    this.paymentPeriodDescription,
    this.isPaid = false,
    this.paymentDate,
    this.paymentId,
  });

  factory PayrollItem.fromJson(Map<String, dynamic> json) {
    return PayrollItem(
      id: json['id'] as int?,
      payrollId: json['payroll_id'] as int,
      workerId: json['worker_id'] as int,
      workerName: json['worker_name'] as String?,
      employeeId: json['employee_id'] as String?,
      workTypeId: json['work_type_id'] as int?,
      workTypeName: json['work_type_name'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      phoneNumber: json['phone_number'] as String?,
      basicSalary: ((json['basic_salary'] ?? json['base_salary']) as num).toDouble(),
      allowances: (json['allowances'] as num?)?.toDouble(),
      overtimePay: (json['overtime_pay'] as num?)?.toDouble(),
      allocatedOvertimePay: (json['allocated_overtime_pay'] as num?)?.toDouble(),
      grossSalary: (json['gross_salary'] as num).toDouble(),
      incomeTax: (json['income_tax'] as num?)?.toDouble(),
      pensionContribution: ((json['pension_contribution'] ?? json['employee_pension']) as num?)?.toDouble(),
      otherDeductions: (json['other_deductions'] as num?)?.toDouble(),
      netSalary: (json['net_salary'] as num).toDouble(),
      daysWorked: json['days_worked'] as int?,
      hoursWorked: (json['hours_worked'] as num?)?.toDouble(),
      paymentPeriodStart: json['payment_period_start'] as String?,
      paymentPeriodEnd: json['payment_period_end'] as String?,
      paymentPeriodDays: json['payment_period_days'] as int?,
      isProrated: json['is_prorated'] as bool? ?? false,
      paymentPeriodType: json['payment_period_type'] as String?,
      paymentPeriodDescription: json['payment_period_description'] as String?,
      isPaid: json['is_paid'] as bool? ?? false,
      paymentDate: json['payment_date'] as String?,
      paymentId: json['payment_id'] as int?,
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
      if (allocatedOvertimePay != null) 'allocated_overtime_pay': allocatedOvertimePay,
      'gross_salary': grossSalary,
      if (incomeTax != null) 'income_tax': incomeTax,
      if (pensionContribution != null) 'pension_contribution': pensionContribution,
      if (otherDeductions != null) 'other_deductions': otherDeductions,
      'net_salary': netSalary,
      if (daysWorked != null) 'days_worked': daysWorked,
      if (hoursWorked != null) 'hours_worked': hoursWorked,
    };
  }
  
  double get totalOvertimePay => (overtimePay ?? 0) + (allocatedOvertimePay ?? 0);
}
