class Attendance {
  final int? id;
  final int workerId;
  final String? workerName;
  final String? employeeId;
  final int siteId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final String? remarks;

  Attendance({
    this.id,
    required this.workerId,
    this.workerName,
    this.employeeId,
    required this.siteId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.remarks,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int?,
      workerId: json['worker_id'] as int,
      workerName: json['worker_name'] as String?,
      employeeId: json['employee_id'] as String?,
      siteId: json['site_id'] as int,
      date: DateTime.parse(json['date'] as String),
      checkIn: json['check_in'] != null 
          ? DateTime.parse(json['check_in'] as String)
          : null,
      checkOut: json['check_out'] != null 
          ? DateTime.parse(json['check_out'] as String)
          : null,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'worker_id': workerId,
      'site_id': siteId,
      'date': date.toIso8601String(),
      if (checkIn != null) 'check_in': checkIn!.toIso8601String(),
      if (checkOut != null) 'check_out': checkOut!.toIso8601String(),
      'status': status,
      if (remarks != null) 'remarks': remarks,
    };
  }
}
