class RoleModel {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final bool isSystemRole;
  final bool isActive;
  final DateTime createdAt;

  RoleModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.isSystemRole,
    required this.isActive,
    required this.createdAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      isSystemRole: json['is_system_role'] as bool,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'is_system_role': isSystemRole,
      'is_active': isActive,
    };
  }
}

class RoleCreateUpdate {
  final String name;
  final String displayName;
  final String? description;
  final bool isActive;

  RoleCreateUpdate({
    required this.name,
    required this.displayName,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      if (description != null) 'description': description,
      'is_active': isActive,
    };
  }
}
