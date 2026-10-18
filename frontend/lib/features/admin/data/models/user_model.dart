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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool? ?? true,
      siteId: json['site_id'] as int?,
      workPlaceId: json['work_place_id'] as int?,
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
    };
  }
}
