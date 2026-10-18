import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotificationsEvent extends NotificationsEvent {
  final bool unreadOnly;

  const FetchNotificationsEvent({this.unreadOnly = false});

  @override
  List<Object?> get props => [unreadOnly];
}

class MarkAsReadEvent extends NotificationsEvent {
  final List<int> notificationIds;

  const MarkAsReadEvent(this.notificationIds);

  @override
  List<Object?> get props => [notificationIds];
}

class MarkAllAsReadEvent extends NotificationsEvent {
  const MarkAllAsReadEvent();
}

class DeleteNotificationEvent extends NotificationsEvent {
  final int notificationId;

  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class FetchUnreadCountEvent extends NotificationsEvent {
  const FetchUnreadCountEvent();
}
