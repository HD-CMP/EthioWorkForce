class UserModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final int? siteId;
  final int? workPlaceId;
  final int? workerId;
  final String? employeeId;
  final int? hierarchyLevel;
  final String? workTypeName;
  final bool? hasUserAccount;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    this.siteId,
    this.workPlaceId,
    this.workerId,
    this.employeeId,
    this.hierarchyLevel,
    this.workTypeName,
    this.hasUserAccount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? json['employee_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'Worker',
      isActive: json['is_active'] as bool? ?? true,
      siteId: json['site_id'] as int?,
      workPlaceId: json['work_place_id'] as int?,
      workerId: json['worker_id'] as int? ?? json['id'] as int?,
      employeeId: json['employee_id'] as String?,
      hierarchyLevel: json['hierarchy_level'] as int?,
      workTypeName: json['work_type_name'] as String? ?? json['role'] as String?,
      hasUserAccount: json['has_user_account'] as bool?,
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
      'is_active': isActive,
      'site_id': siteId,
      'work_place_id': workPlaceId,
      'worker_id': workerId,
      'employee_id': employeeId,
      'hierarchy_level': hierarchyLevel,
      'work_type_name': workTypeName,
      'has_user_account': hasUserAccount,
    };
  }
}
