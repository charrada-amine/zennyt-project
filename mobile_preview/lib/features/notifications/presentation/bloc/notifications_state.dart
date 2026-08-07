part of 'notifications_bloc.dart';

enum NotifStatus { initial, loading, ready, error }

class NotificationsState extends Equatable {
  final NotifStatus status;
  final List<AppNotification> items;
  final String message;

  const NotificationsState({
    this.status = NotifStatus.initial,
    this.items = const [],
    this.message = '',
  });

  List<AppNotification> get today =>
      items.where((n) => n.group == NotifGroup.today).toList();
  List<AppNotification> get yesterday =>
      items.where((n) => n.group == NotifGroup.yesterday).toList();
  int get unreadToday => today.where((n) => !n.read).length;

  NotificationsState copyWith({
    NotifStatus? status,
    List<AppNotification>? items,
    String? message,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, items, message];
}
