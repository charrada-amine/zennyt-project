import '../../domain/entities/app_notification.dart';

abstract class NotificationsLocalDataSource {
  Future<List<AppNotification>> getNotifications();
}

/// Mock — reproduit les notifications de la maquette.
class NotificationsMockDataSource implements NotificationsLocalDataSource {
  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const [
      AppNotification(
          id: 'n1',
          type: NotifType.jobOpportunity,
          title: 'New Job Opportunity',
          subtitle: 'Oracle is interested in your profile and has sent you a job offer.',
          time: '13:45',
          group: NotifGroup.today),
      AppNotification(
          id: 'n2',
          type: NotifType.interestConfirmed,
          title: 'Interest Confirmed',
          subtitle: 'You have been followed by Emily Marine.',
          time: '12:45',
          group: NotifGroup.today),
      AppNotification(
          id: 'n3',
          type: NotifType.identityRequired,
          title: 'Identity verification required',
          subtitle: 'The recruiter requested a face-matching identity check.',
          time: '12:30',
          group: NotifGroup.today),
      AppNotification(
          id: 'n4',
          type: NotifType.comment,
          title: 'New Comment on Your Post',
          subtitle: 'Emily Marine commented your last post.',
          time: '12:45',
          read: true,
          group: NotifGroup.yesterday),
      AppNotification(
          id: 'n5',
          type: NotifType.like,
          title: 'New Like on Your Post',
          subtitle: 'Emily Marine liked your last post.',
          time: '12:45',
          read: true,
          group: NotifGroup.yesterday),
      AppNotification(
          id: 'n6',
          type: NotifType.training,
          title: 'Recommended Training',
          subtitle: 'Explore Udemy UX/UI Design courses.',
          time: '12:45',
          read: true,
          group: NotifGroup.yesterday),
      AppNotification(
          id: 'n7',
          type: NotifType.applicationRejected,
          title: 'Application rejected',
          subtitle: 'Your application for the UX/UI Designer position.',
          time: '02:00',
          read: true,
          group: NotifGroup.yesterday),
    ];
  }
}
