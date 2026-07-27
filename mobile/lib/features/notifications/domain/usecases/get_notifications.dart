import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications implements UseCase<List<AppNotification>, String> {
  final NotificationRepository repository;
  GetNotifications(this.repository);

  @override
  Future<Either<Failure, List<AppNotification>>> call(String userId) {
    return repository.getNotifications(userId);
  }
}
