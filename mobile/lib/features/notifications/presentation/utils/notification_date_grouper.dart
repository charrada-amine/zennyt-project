import 'package:intl/intl.dart';
import '../../domain/entities/app_notification.dart';

class NotificationDateGroup {
  final String key;
  final List<AppNotification> notifications;

  const NotificationDateGroup({
    required this.key,
    required this.notifications,
  });

  bool get isToday => key == _todayKey;
  bool get isYesterday => key == _yesterdayKey;
}

const _todayKey = 'today';
const _yesterdayKey = 'yesterday';

String notificationDateGroupKey(DateTime createdAt) {
  final now = DateTime.now();
  final local = createdAt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return _todayKey;
  if (diff == 1) return _yesterdayKey;
  return date.toIso8601String().split('T').first;
}

String notificationDateGroupLabel(
  String key,
  String todayLabel,
  String yesterdayLabel,
  String localeName,
) {
  if (key == _todayKey) return todayLabel;
  if (key == _yesterdayKey) return yesterdayLabel;

  final date = DateTime.parse(key);
  return DateFormat('EEEE', localeName).format(date);
}

int _groupSortOrder(String key) {
  if (key == _todayKey) return 0;
  if (key == _yesterdayKey) return 1;
  return 2;
}

List<NotificationDateGroup> groupNotificationsByDate(
  List<AppNotification> notifications,
) {
  final grouped = <String, List<AppNotification>>{};

  for (final notification in notifications) {
    final key = notificationDateGroupKey(notification.createdAt);
    grouped.putIfAbsent(key, () => []).add(notification);
  }

  final entries = grouped.entries.toList()
    ..sort((a, b) {
      final order = _groupSortOrder(a.key).compareTo(_groupSortOrder(b.key));
      if (order != 0) return order;
      return DateTime.parse(b.key).compareTo(DateTime.parse(a.key));
    });

  return entries
      .map(
        (entry) => NotificationDateGroup(
          key: entry.key,
          notifications: entry.value,
        ),
      )
      .toList();
}
