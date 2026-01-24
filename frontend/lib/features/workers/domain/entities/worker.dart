class Worker {
  final int? id;
  final String employeeId;
  final String fullName;
  final String? phoneNumber;
  final String workType;
  final int siteId;
  final String? siteName;
  final bool isActive;
  final String? bankAccountNumber;
  final String? tinNumber;
  final DateTime? hireDate;

  Worker({
    this.id,
    required this.employeeId,
    required this.fullName,
    this.phoneNumber,
    required this.workType,
    required this.siteId,
    this.siteName,
    this.isActive = true,
    this.bankAccountNumber,
    this.tinNumber,
    this.hireDate,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as int?,
      employeeId: json['employee_id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      workType: json['work_type'] as String,
      siteId: json['site_id'] as int,
      siteName: json['site_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      bankAccountNumber: json['bank_account_number'] as String?,
      tinNumber: json['tin_number'] as String?,
      hireDate: json['hire_date'] != null 
          ? DateTime.parse(json['hire_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'work_type': workType,
      'site_id': siteId,
      'is_active': isActive,
      if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
      if (tinNumber != null) 'tin_number': tinNumber,
      if (hireDate != null) 'hire_date': hireDate!.toIso8601String(),
    };
  }
}
