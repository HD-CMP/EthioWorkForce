class WorkPlace {
  final int? id;
  final String name;
  final String code;
  final String? description;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final int parentSiteId;
  final int? supervisorId;
  final String? supervisorName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkPlace({
    this.id,
    required this.name,
    required this.code,
    this.description,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.parentSiteId,
    this.supervisorId,
    this.supervisorName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkPlace.fromJson(Map<String, dynamic> json) {
    double? _parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return WorkPlace(
      id: json['id'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      locationAddress: json['location_address'] as String?,
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
      parentSiteId: json['parent_site_id'] as int,
      supervisorId: json['supervisor_id'] as int?,
      supervisorName: json['supervisor_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
      'parent_site_id': parentSiteId,
      if (supervisorId != null) 'supervisor_id': supervisorId,
      'is_active': isActive,
    };
  }

  WorkPlace copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    String? locationAddress,
    double? latitude,
    double? longitude,
    int? parentSiteId,
    int? supervisorId,
    String? supervisorName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      parentSiteId: parentSiteId ?? this.parentSiteId,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisorName: supervisorName ?? this.supervisorName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
