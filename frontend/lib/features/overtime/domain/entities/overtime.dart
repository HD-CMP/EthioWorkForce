class Overtime {
  final int? id;
  final int workerId;
  final String? workerName;
  final String? employeeId;
  final int siteId;
  final DateTime overtimeDate;
  final double hours;
  final bool isVerified;
  final int? verifiedById;
  final DateTime? verifiedAt;
  final bool isLocked;
  final String? notes;
  final int? ethiopianYear;
  final int? ethiopianMonth;
  final int? ethiopianDay;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Overtime({
    this.id,
    required this.workerId,
    this.workerName,
    this.employeeId,
    required this.siteId,
    required this.overtimeDate,
    required this.hours,
    this.isVerified = false,
    this.verifiedById,
    this.verifiedAt,
    this.isLocked = false,
    this.notes,
    this.ethiopianYear,
    this.ethiopianMonth,
    this.ethiopianDay,
    this.createdAt,
    this.updatedAt,
  });

  factory Overtime.fromJson(Map<String, dynamic> json) {
    return Overtime(
      id: json['id'] as int?,
      workerId: json['worker_id'] as int,
      workerName: json['worker_name'] as String?,
      employeeId: json['employee_id'] as String?,
      siteId: json['site_id'] as int,
      overtimeDate: DateTime.parse(json['overtime_date'] as String),
      hours: (json['hours'] as num).toDouble(),
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedById: json['verified_by_id'] as int?,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      isLocked: json['is_locked'] as bool? ?? false,
      notes: json['notes'] as String?,
      ethiopianYear: json['ethiopian_date_year'] as int?,
      ethiopianMonth: json['ethiopian_date_month'] as int?,
      ethiopianDay: json['ethiopian_date_day'] as int?,
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
      'id': id,
      'worker_id': workerId,
      'worker_name': workerName,
      'employee_id': employeeId,
      'site_id': siteId,
      'overtime_date': overtimeDate.toIso8601String().split('T')[0],
      'hours': hours,
      'is_verified': isVerified,
      'verified_by_id': verifiedById,
      'verified_at': verifiedAt?.toIso8601String(),
      'is_locked': isLocked,
      'notes': notes,
      'ethiopian_date_year': ethiopianYear,
      'ethiopian_date_month': ethiopianMonth,
      'ethiopian_date_day': ethiopianDay,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Overtime copyWith({
    int? id,
    int? workerId,
    String? workerName,
    String? employeeId,
    int? siteId,
    DateTime? overtimeDate,
    double? hours,
    bool? isVerified,
    int? verifiedById,
    DateTime? verifiedAt,
    bool? isLocked,
    String? notes,
    int? ethiopianYear,
    int? ethiopianMonth,
    int? ethiopianDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Overtime(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      employeeId: employeeId ?? this.employeeId,
      siteId: siteId ?? this.siteId,
      overtimeDate: overtimeDate ?? this.overtimeDate,
      hours: hours ?? this.hours,
      isVerified: isVerified ?? this.isVerified,
      verifiedById: verifiedById ?? this.verifiedById,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isLocked: isLocked ?? this.isLocked,
      notes: notes ?? this.notes,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      ethiopianMonth: ethiopianMonth ?? this.ethiopianMonth,
      ethiopianDay: ethiopianDay ?? this.ethiopianDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
