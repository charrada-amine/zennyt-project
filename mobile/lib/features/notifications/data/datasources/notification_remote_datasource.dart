import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/app_notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotificationModel>> getNotifications(String userId);

  Future<void> markAsRead(String id, String userId);

  Future<void> markAllAsRead(String userId);

  Future<void> createNotification(AppNotificationModel notification);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl(this.dio);

  @override
  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    try {
      final res = await dio.get(
        '/notifications',
      );
      final data = res.data;
      final List<dynamic> items = data is Map<String, dynamic>
          ? (data['content'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);
      return items
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> markAsRead(String id, String userId) async {
    try {
      await dio.post(
        '/notifications/$id/read',
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await dio.post(
        '/notifications/read-all',
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> createNotification(AppNotificationModel notification) async {
    try {
      await dio.post('/notifications', data: notification.toJson());
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
