import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRemoteDatasource datasource;

  NotificationsBloc({required this.datasource})
      : super(const NotificationsInitial()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<FetchUnreadCountEvent>(_onFetchUnreadCount);
  }

  Future<void> _onFetchNotifications(
    FetchNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      final notifications = await datasource.getNotifications(
        unreadOnly: event.unreadOnly,
      );
      final unreadCount = await datasource.getUnreadCount();
      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError('Failed to fetch notifications: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await datasource.markAsRead(event.notificationIds);
      add(const FetchNotificationsEvent());
    } catch (e) {
      emit(NotificationsError('Failed to mark as read: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await datasource.markAllAsRead();
      add(const FetchNotificationsEvent());
    } catch (e) {
      emit(NotificationsError('Failed to mark all as read: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await datasource.deleteNotification(event.notificationId);
      add(const FetchNotificationsEvent());
    } catch (e) {
      emit(NotificationsError('Failed to delete notification: ${e.toString()}'));
    }
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCountEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final count = await datasource.getUnreadCount();
      if (state is NotificationsLoaded) {
        emit((state as NotificationsLoaded).copyWith(unreadCount: count));
      }
    } catch (e) {
      emit(NotificationsError('Failed to fetch unread count: ${e.toString()}'));
    }
  }
}
