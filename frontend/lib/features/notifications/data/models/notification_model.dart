class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum NotificationType {
  registrationRequest,
  registrationApproved,
  registrationRejected,
  workerAdded,
  attendanceMarked,
  payrollProcessed,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.registrationRequest:
        return 'registration_request';
      case NotificationType.registrationApproved:
        return 'registration_approved';
      case NotificationType.registrationRejected:
        return 'registration_rejected';
      case NotificationType.workerAdded:
        return 'worker_added';
      case NotificationType.attendanceMarked:
        return 'attendance_marked';
      case NotificationType.payrollProcessed:
        return 'payroll_processed';
      case NotificationType.general:
        return 'general';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'registration_request':
        return NotificationType.registrationRequest;
      case 'registration_approved':
        return NotificationType.registrationApproved;
      case 'registration_rejected':
        return NotificationType.registrationRejected;
      case 'worker_added':
        return NotificationType.workerAdded;
      case 'attendance_marked':
        return NotificationType.attendanceMarked;
      case 'payroll_processed':
        return NotificationType.payrollProcessed;
      default:
        return NotificationType.general;
    }
  }
}
