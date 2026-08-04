import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_local_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsLocalDataSource local;
  NotificationsRepositoryImpl({required this.local});

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      return Right(await local.getNotifications());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
