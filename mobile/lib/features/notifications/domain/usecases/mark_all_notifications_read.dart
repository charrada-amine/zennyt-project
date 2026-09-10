import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkAllNotificationsRead implements UseCase<void, String> {
  final NotificationRepository repository;
  MarkAllNotificationsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(String userId) {
    return repository.markAllAsRead(userId);
  }
}
