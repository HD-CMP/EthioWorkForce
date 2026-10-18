class Site {
  final int? id;
  final String name;
  final String code;
  final String? description;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final int? siteAdminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Site({
    this.id,
    required this.name,
    required this.code,
    this.description,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.siteAdminId,
    this.createdAt,
    this.updatedAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    // Helper to parse double that may come as String
    double? _parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Site(
      id: json['id'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      locationAddress: json['location_address'] as String?,
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
      isActive: json['is_active'] as bool? ?? true,
      siteAdminId: json['site_admin_id'] as int?,
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
      if (locationAddress != null) 'location_address': locationAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_active': isActive,
      if (siteAdminId != null) 'site_admin_id': siteAdminId,
    };
  }

  Site copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    String? locationAddress,
    double? latitude,
    double? longitude,
    bool? isActive,
    int? siteAdminId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      siteAdminId: siteAdminId ?? this.siteAdminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
