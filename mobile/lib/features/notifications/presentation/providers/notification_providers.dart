import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notification_read.dart';
import '../../domain/usecases/mark_all_notifications_read.dart';
import '../../domain/usecases/create_notification.dart';
import '../../domain/entities/app_notification.dart';

final getNotificationsUseCaseProvider = Provider<GetNotifications>((ref) {
  return sl();
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationRead>((ref) {
  return sl();
});

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsRead>((ref) {
  return sl();
});

final createNotificationUseCaseProvider = Provider<CreateNotification>((ref) {
  return sl();
});

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final usecase = ref.watch(getNotificationsUseCaseProvider);
  final result = await usecase(currentUser.id);
  return result.fold(
    (failure) => throw failure,
    (notifications) => notifications,
  );
});
