import '../models/app_notification_model.dart';
import '../../domain/entities/app_notification.dart';

/// Source mockée pour les notifications.
abstract class NotificationMockDataSource {
  Future<List<AppNotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String id, String userId);
  Future<void> markAllAsRead(String userId);
  Future<void> createNotification(AppNotificationModel notification);
}

class NotificationMockDataSourceImpl implements NotificationMockDataSource {
  final List<AppNotificationModel> _notifications = [
    AppNotificationModel(
      id: '1',
      userId: 'current-user',
      title: 'New Job Opportunity',
      subtitle:
          'Oracle is interested in your profile and has sent you a job offer for the position...',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.newJob,
      isRead: false,
      contactName: 'Kristin Watson',
      chatId: '2',
    ),
    AppNotificationModel(
      id: '2',
      userId: 'current-user',
      title: 'Interest Confirmed',
      subtitle: 'You have been followed by Emily Ms.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.interestConfirmed,
      isRead: false,
      contactName: 'Emily Ms.',
    ),
    AppNotificationModel(
      id: '3',
      userId: 'current-user',
      title: 'New Comment on Your Post',
      subtitle: 'Emily Marine commented your last p...',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 12)),
      type: NotificationType.newComment,
      isRead: true,
      contactName: 'Emily Marine',
    ),
    AppNotificationModel(
      id: '4',
      userId: 'current-user',
      title: 'New Like on Your Post',
      subtitle: 'Emily Marine liked your last post',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
      type: NotificationType.newLike,
      isRead: true,
      contactName: 'Emily Marine',
    ),
    AppNotificationModel(
      id: '5',
      userId: 'current-user',
      title: 'Recommended Training',
      subtitle: 'Explore Udemy UX/UI Design courses',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.recommendedTraining,
      isRead: true,
    ),
    AppNotificationModel(
      id: '6',
      userId: 'current-user',
      title: 'Application rejected',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.applicationRejected,
      isRead: true,
    ),
    AppNotificationModel(
      id: '7',
      userId: 'current-user',
      title: 'Congratulations! The Google recruiter received your profile',
      subtitle: 'You\'ll receive an email explaining t...',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      type: NotificationType.newJob,
      isRead: true,
    ),
    AppNotificationModel(
      id: '8',
      userId: 'current-user',
      title: 'Application Approved',
      subtitle: 'Your application for the Financial Me...',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      type: NotificationType.applicationApproved,
      isRead: true,
    ),
    AppNotificationModel(
      id: '9',
      userId: 'current-user',
      title: 'Identity Verification completed successfully !',
      subtitle: 'Congratulations! Identity verificati...',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      type: NotificationType.identityVerificationSuccess,
      isRead: true,
    ),
  ];

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_notifications);
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> createNotification(AppNotificationModel notification) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notifications.add(notification);
  }
}
