class RegistrationRequest {
  final String username;
  final String? email;
  final String fullName;
  final String? phoneNumber;
  final String password;
  final String role;
  final String? preferredLanguage;
  final String? requestReason;
  final List<int>? siteIds;
  final List<int>? workPlaceIds;
  final int? workerId;

  RegistrationRequest({
    required this.username,
    this.email,
    required this.fullName,
    this.phoneNumber,
    required this.password,
    required this.role,
    this.preferredLanguage = 'en',
    this.requestReason,
    this.siteIds,
    this.workPlaceIds,
    this.workerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'password': password,
      'role': role,
      'preferred_language': preferredLanguage,
      'request_reason': requestReason,
      'site_ids': siteIds,
      'work_place_ids': workPlaceIds,
      'worker_id': workerId,
    };
  }
}

class RegistrationRequestResponse {
  final int id;
  final String username;
  final String? email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final int? approvedById;
  final String? approvalNotes;
  final List<int>? siteIds;
  final List<String>? siteNames;
  final int? workerId;

  RegistrationRequestResponse({
    required this.id,
    required this.username,
    this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.approvedById,
    this.approvalNotes,
    this.siteIds,
    this.siteNames,
    this.workerId,
  });

  factory RegistrationRequestResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationRequestResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      approvedById: json['approved_by_id'] as int?,
      approvalNotes: json['approval_notes'] as String?,
      siteIds: json['site_ids'] != null
          ? List<int>.from(json['site_ids'] as List)
          : null,
      siteNames: json['site_names'] != null
          ? List<String>.from(json['site_names'] as List)
          : null,
      workerId: json['worker_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'approved_by_id': approvedById,
      'approval_notes': approvalNotes,
      'site_ids': siteIds,
      'site_names': siteNames,
      'worker_id': workerId,
    };
  }
}


class RegistrationApproval {
  final int requestId;
  final bool approved;
  final String? approvalNotes;
  final List<int>? siteIds;
  final List<int>? workPlaceIds;
  final int? workerId;

  RegistrationApproval({
    required this.requestId,
    required this.approved,
    this.approvalNotes,
    this.siteIds,
    this.workPlaceIds,
    this.workerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'approved': approved,
      'approval_notes': approvalNotes,
      'site_ids': siteIds,
      'work_place_ids': workPlaceIds,
      'worker_id': workerId,
    };
  }
}
