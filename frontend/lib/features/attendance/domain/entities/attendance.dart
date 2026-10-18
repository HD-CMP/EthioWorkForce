class Attendance {
  final int? id;
  final int workerId;
  final String? workerName;
  final String? employeeId;
  final int siteId;
  final DateTime attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String status;
  final String method;
  final int regularHours;
  final double overtimeHours;
  final bool isVerified;
  final int? verifiedById;
  final DateTime? verifiedAt;
  final bool isOvertimeVerified;
  final int? overtimeVerifiedById;
  final DateTime? overtimeVerifiedAt;
  final String? overrideReason;
  final String? notes;
  final int? ethiopianYear;
  final int? ethiopianMonth;
  final int? ethiopianDay;
  final bool isLocked;
  final bool isOvertimeLocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attendance({
    this.id,
    required this.workerId,
    this.workerName,
    this.employeeId,
    required this.siteId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    required this.method,
    this.regularHours = 8,
    this.overtimeHours = 0,
    this.isVerified = false,
    this.verifiedById,
    this.verifiedAt,
    this.isOvertimeVerified = false,
    this.overtimeVerifiedById,
    this.overtimeVerifiedAt,
    this.overrideReason,
    this.notes,
    this.ethiopianYear,
    this.ethiopianMonth,
    this.ethiopianDay,
    this.isLocked = false,
    this.isOvertimeLocked = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int?,
      workerId: json['worker_id'] as int,
      workerName: json['worker_name'] as String?,
      employeeId: json['employee_id'] as String?,
      siteId: json['site_id'] as int,
      attendanceDate: DateTime.parse(json['attendance_date'] as String),
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      status: json['status'] as String,
      method: json['method'] as String,
      regularHours: json['regular_hours'] as int? ?? 8,
      overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedById: json['verified_by_id'] as int?,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      isOvertimeVerified: json['is_overtime_verified'] as bool? ?? false,
      overtimeVerifiedById: json['overtime_verified_by_id'] as int?,
      overtimeVerifiedAt: json['overtime_verified_at'] != null 
          ? DateTime.parse(json['overtime_verified_at'] as String)
          : null,
      overrideReason: json['override_reason'] as String?,
      notes: json['notes'] as String?,
      ethiopianYear: json['ethiopian_date_year'] as int?,
      ethiopianMonth: json['ethiopian_date_month'] as int?,
      ethiopianDay: json['ethiopian_date_day'] as int?,
      isLocked: json['is_locked'] as bool? ?? false,
      isOvertimeLocked: json['is_overtime_locked'] as bool? ?? false,
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
      'worker_id': workerId,
      'site_id': siteId,
      'attendance_date': attendanceDate.toIso8601String().split('T')[0],
      if (checkInTime != null) 'check_in_time': checkInTime,
      if (checkOutTime != null) 'check_out_time': checkOutTime,
      'status': status,
      'method': method,
      'regular_hours': regularHours,
      'overtime_hours': overtimeHours,
      if (notes != null) 'notes': notes,
    };
  }

  Attendance copyWith({
    int? id,
    int? workerId,
    String? workerName,
    String? employeeId,
    int? siteId,
    DateTime? attendanceDate,
    String? checkInTime,
    String? checkOutTime,
    String? status,
    String? method,
    int? regularHours,
    double? overtimeHours,
    bool? isVerified,
    int? verifiedById,
    DateTime? verifiedAt,
    bool? isOvertimeVerified,
    int? overtimeVerifiedById,
    DateTime? overtimeVerifiedAt,
    String? overrideReason,
    String? notes,
    int? ethiopianYear,
    int? ethiopianMonth,
    int? ethiopianDay,
    bool? isLocked,
    bool? isOvertimeLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      employeeId: employeeId ?? this.employeeId,
      siteId: siteId ?? this.siteId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      method: method ?? this.method,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      isVerified: isVerified ?? this.isVerified,
      verifiedById: verifiedById ?? this.verifiedById,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isOvertimeVerified: isOvertimeVerified ?? this.isOvertimeVerified,
      overtimeVerifiedById: overtimeVerifiedById ?? this.overtimeVerifiedById,
      overtimeVerifiedAt: overtimeVerifiedAt ?? this.overtimeVerifiedAt,
      overrideReason: overrideReason ?? this.overrideReason,
      notes: notes ?? this.notes,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
      ethiopianDay: ethiopianDay ?? this.ethiopianDay,
      isLocked: isLocked ?? this.isLocked,
      isOvertimeLocked: isOvertimeLocked ?? this.isOvertimeLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedEthiopianDate {
    if (ethiopianYear == null || ethiopianMonth == null || ethiopianDay == null) {
      return '';
    }
    final months = [
      'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
      'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜን'
    ];
    final monthName = ethiopianMonth! >= 1 && ethiopianMonth! <= 13 
        ? months[ethiopianMonth! - 1] 
        : '';
    return '$monthName $ethiopianDay, $ethiopianYear';
  }
}
