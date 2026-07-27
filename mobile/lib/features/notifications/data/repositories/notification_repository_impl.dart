import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/app_notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications(
      String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getNotifications(userId);
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAsRead(id, userId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllAsRead(userId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> createNotification(
      AppNotification notification) async {
    if (await networkInfo.isConnected) {
      try {
        final model = AppNotificationModel(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          subtitle: notification.subtitle,
          createdAt: notification.createdAt,
          type: notification.type,
          isRead: notification.isRead,
          contactName: notification.contactName,
          contactInitials: notification.contactInitials,
          actionUrl: notification.actionUrl,
          chatId: notification.chatId,
        );
        await remoteDataSource.createNotification(model);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
