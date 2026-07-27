import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class CreateNotification implements UseCase<void, AppNotification> {
  final NotificationRepository repository;
  CreateNotification(this.repository);

  @override
  Future<Either<Failure, void>> call(AppNotification params) {
    return repository.createNotification(params);
  }
}
