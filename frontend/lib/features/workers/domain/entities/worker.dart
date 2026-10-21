class Worker {
  final int? id;
  final String employeeId;
  final String fullName;
  final String? phoneNumber;
  final String? workType;
  final int? workTypeId;
  final int siteId;
  final String? siteName;
  final int? workPlaceId;
  final String? workPlaceName;
  final String? workPlaceSupervisorName;
  final String? status;
  final String? bankName;
  final String? bankAccountNumber;
  final String? tinNumber;
  final DateTime? hireDate;
  final double? overtimeHours;
  final double? overtimeRatePerHour;
  final int? supervisorId;
  final String? supervisorName;
  final int? paymentPeriodDays;
  final double? baseSalary;
  final int? hierarchyLevel;
  final String? idCardUrl;
  final String? photoUrl;

  bool get isActive => status == null || status == 'active';
  bool get hasIdDocument => idCardUrl != null && idCardUrl!.isNotEmpty;
  
  double get totalOvertimePayment => (overtimeHours ?? 0.0) * (overtimeRatePerHour ?? 0.0);

  Worker({
    this.id,
    required this.employeeId,
    required this.fullName,
    this.phoneNumber,
    this.workType,
    this.workTypeId,
    required this.siteId,
    this.siteName,
    this.workPlaceId,
    this.workPlaceName,
    this.workPlaceSupervisorName,
    this.status,
    this.bankName,
    this.bankAccountNumber,
    this.tinNumber,
    this.hireDate,
    this.overtimeHours,
    this.overtimeRatePerHour,
    this.supervisorId,
    this.supervisorName,
    this.paymentPeriodDays,
    this.baseSalary,
    this.hierarchyLevel,
    this.idCardUrl,
    this.photoUrl,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    double? _parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return (parsed == null || parsed == 0.0) ? null : parsed;
      }
      return null;
    }

    return Worker(
      id: json['id'] as int?,
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      workType: json['work_type'] as String?,
      workTypeId: json['work_type_id'] as int?,
      siteId: json['site_id'] as int,
      siteName: json['site_name'] as String?,
      workPlaceId: json['work_place_id'] as int?,
      workPlaceName: json['work_place_name'] as String?,
      workPlaceSupervisorName: json['work_place_supervisor_name'] as String?,
      status: json['status'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      tinNumber: json['tin_number'] as String? ?? json['national_id'] as String?,
      hireDate: json['hire_date'] != null 
          ? DateTime.parse(json['hire_date'] as String)
          : null,
      overtimeHours: _parseNullableDouble(json['overtime_hours']),
      overtimeRatePerHour: _parseNullableDouble(json['overtime_rate_per_hour']),
      supervisorId: json['supervisor_id'] as int?,
      supervisorName: json['supervisor_name'] as String?,
      paymentPeriodDays: json['payment_period_days'] as int?,
      baseSalary: _parseNullableDouble(json['base_salary']),
      hierarchyLevel: json['hierarchy_level'] as int?,
      idCardUrl: json['id_card_url'] as String? ?? json['photo_url'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (workTypeId != null) 'work_type_id': workTypeId,
      'site_id': siteId,
      if (workPlaceId != null) 'work_place_id': workPlaceId,
      if (status != null) 'status': status,
      if (bankName != null) 'bank_name': bankName,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (tinNumber != null) ...{
        'tin_number': tinNumber,
        'national_id': tinNumber,
      },
      'hire_date': (hireDate ?? DateTime.now()).toIso8601String().split('T')[0],
      'overtime_hours': overtimeHours ?? 0,
      'overtime_rate_per_hour': overtimeRatePerHour ?? 0,
      if (supervisorId != null) 'supervisor_id': supervisorId,
      if (supervisorName != null) 'supervisor_name': supervisorName,
      if (paymentPeriodDays != null) 'payment_period_days': paymentPeriodDays,
      if (baseSalary != null) 'base_salary': baseSalary,
      if (hierarchyLevel != null) 'hierarchy_level': hierarchyLevel,
      if (idCardUrl != null) 'id_card_url': idCardUrl,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}
