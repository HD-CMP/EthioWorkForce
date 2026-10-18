import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDatasource {
  final Dio dio;

  NotificationsRemoteDatasource(this.dio);

  Future<List<NotificationModel>> getNotifications({
    int skip = 0,
    int limit = 50,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (unreadOnly != null) {
        queryParams['unread_only'] = unreadOnly;
      }

      final response = await dio.get(
        '/notifications/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch notifications: ${e.message}');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get('/notifications/unread-count');
      return response.data['count'] as int;
    } on DioException catch (e) {
      throw Exception('Failed to fetch unread count: ${e.message}');
    }
  }

  Future<void> markAsRead(List<int> notificationIds) async {
    try {
      await dio.post(
        '/notifications/mark-read',
        data: {'notification_ids': notificationIds},
      );
    } on DioException catch (e) {
      throw Exception('Failed to mark as read: ${e.message}');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await dio.post('/notifications/mark-all-read');
    } on DioException catch (e) {
      throw Exception('Failed to mark all as read: ${e.message}');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await dio.delete('/notifications/$notificationId');
    } on DioException catch (e) {
      throw Exception('Failed to delete notification: ${e.message}');
    }
  }
}
