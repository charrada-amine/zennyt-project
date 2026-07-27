import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications(
      String userId);

  Future<Either<Failure, void>> markAsRead(String id, String userId);

  Future<Either<Failure, void>> markAllAsRead(String userId);

  Future<Either<Failure, void>> createNotification(
      AppNotification notification);
}
