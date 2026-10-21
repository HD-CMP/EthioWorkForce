enum PaymentMode {
  monthlySalary('monthly_salary', 'Monthly Salary'),
  dailyRate('daily_rate', 'Daily Rate'),
  pieceRate('piece_rate', 'Piece Rate'),
  hourlyRate('hourly_rate', 'Hourly Rate');

  final String value;
  final String displayName;
  const PaymentMode(this.value, this.displayName);

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => PaymentMode.dailyRate,
    );
  }
}

enum TaxRule {
  standardEmployee('standard_employee', 'Standard Employee (ERCA Progressive Tax)'),
  dailyCasual('daily_casual', 'Daily Casual / Tax Exempt (No Tax/Pension)');

  final String value;
  final String displayName;
  const TaxRule(this.value, this.displayName);

  static TaxRule fromString(String value) {
    return TaxRule.values.firstWhere(
      (rule) => rule.value == value,
      orElse: () => TaxRule.standardEmployee,
    );
  }
}

class WorkType {
  final int? id;
  final String name;
  final String code;
  final String? description;
  final PaymentMode paymentMode;
  final double baseRate;
  final int? paymentPeriodDays;
  final DateTime? paymentPeriodStartDate;
  final TaxRule taxRule;
  final bool overtimeEligible;
  final double? overtimeRatePerHour;
  final bool pensionEligible;
  final double? employeePensionRate;
  final double? employerPensionRate;
  final int hierarchyLevel;
  final int? parentWorkTypeId;
  final String? canManageLevels;
  final bool requiresSupervisor;
  final int? maxSubordinates;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkType({
    this.id,
    required this.name,
    required this.code,
    this.description,
    required this.paymentMode,
    required this.baseRate,
    this.paymentPeriodDays,
    this.paymentPeriodStartDate,
    this.taxRule = TaxRule.standardEmployee,
    this.overtimeEligible = false,
    this.overtimeRatePerHour,
    this.pensionEligible = true,
    this.employeePensionRate = 0.07,
    this.employerPensionRate = 0.11,
    this.hierarchyLevel = 5,
    this.parentWorkTypeId,
    this.canManageLevels,
    this.requiresSupervisor = true,
    this.maxSubordinates,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkType.fromJson(Map<String, dynamic> json) {
    // Helper function to parse numeric values that may come as String or num
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double? _parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return WorkType(
      id: json['id'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      paymentMode: PaymentMode.fromString(json['payment_mode'] as String),
      baseRate: _parseDouble(json['base_rate']),
      paymentPeriodDays: json['payment_period_days'] as int?,
      paymentPeriodStartDate: json['payment_period_start_date'] != null
          ? DateTime.parse(json['payment_period_start_date'] as String)
          : null,
      taxRule: TaxRule.fromString(json['tax_rule'] as String? ?? 'standard_employee'),
      overtimeEligible: json['overtime_eligible'] as bool? ?? false,
      overtimeRatePerHour: _parseNullableDouble(json['overtime_rate_per_hour']),
      pensionEligible: json['pension_eligible'] as bool? ?? true,
      employeePensionRate: _parseNullableDouble(json['employee_pension_rate']) ?? 0.07,
      employerPensionRate: _parseNullableDouble(json['employer_pension_rate']) ?? 0.11,
      hierarchyLevel: json['hierarchy_level'] as int? ?? 5,
      parentWorkTypeId: json['parent_work_type_id'] as int?,
      canManageLevels: json['can_manage_levels'] as String?,
      requiresSupervisor: json['requires_supervisor'] as bool? ?? true,
      maxSubordinates: json['max_subordinates'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      'payment_mode': paymentMode.value,
      'base_rate': baseRate,
      if (paymentPeriodDays != null) 'payment_period_days': paymentPeriodDays,
      if (paymentPeriodStartDate != null) 'payment_period_start_date': paymentPeriodStartDate!.toIso8601String().split('T')[0],
      'tax_rule': taxRule.value,
      'overtime_eligible': overtimeEligible,
      if (overtimeRatePerHour != null) 'overtime_rate_per_hour': overtimeRatePerHour,
      'pension_eligible': pensionEligible,
      if (employeePensionRate != null) 'employee_pension_rate': employeePensionRate,
      if (employerPensionRate != null) 'employer_pension_rate': employerPensionRate,
      'hierarchy_level': hierarchyLevel,
      if (parentWorkTypeId != null) 'parent_work_type_id': parentWorkTypeId,
      if (canManageLevels != null) 'can_manage_levels': canManageLevels,
      'requires_supervisor': requiresSupervisor,
      if (maxSubordinates != null) 'max_subordinates': maxSubordinates,
      'is_active': isActive,
    };
  }

  WorkType copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    PaymentMode? paymentMode,
    double? baseRate,
    int? paymentPeriodDays,
    DateTime? paymentPeriodStartDate,
    TaxRule? taxRule,
    bool? overtimeEligible,
    double? overtimeRatePerHour,
    bool? pensionEligible,
    double? employeePensionRate,
    double? employerPensionRate,
    int? hierarchyLevel,
    int? parentWorkTypeId,
    String? canManageLevels,
    bool? requiresSupervisor,
    int? maxSubordinates,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkType(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      paymentMode: paymentMode ?? this.paymentMode,
      baseRate: baseRate ?? this.baseRate,
      paymentPeriodDays: paymentPeriodDays ?? this.paymentPeriodDays,
      paymentPeriodStartDate: paymentPeriodStartDate ?? this.paymentPeriodStartDate,
      taxRule: taxRule ?? this.taxRule,
      overtimeEligible: overtimeEligible ?? this.overtimeEligible,
      overtimeRatePerHour: overtimeRatePerHour ?? this.overtimeRatePerHour,
      pensionEligible: pensionEligible ?? this.pensionEligible,
      employeePensionRate: employeePensionRate ?? this.employeePensionRate,
      employerPensionRate: employerPensionRate ?? this.employerPensionRate,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      parentWorkTypeId: parentWorkTypeId ?? this.parentWorkTypeId,
      canManageLevels: canManageLevels ?? this.canManageLevels,
      requiresSupervisor: requiresSupervisor ?? this.requiresSupervisor,
      maxSubordinates: maxSubordinates ?? this.maxSubordinates,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
