import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read.dart';
import '../../features/notifications/domain/usecases/create_notification.dart';
import '../../features/call/data/datasources/call_remote_datasource.dart';
import '../../features/call/data/repositories/call_repository_impl.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../../features/call/domain/usecases/get_call.dart';
import '../../features/call/domain/usecases/start_call.dart';
import '../../features/call/domain/usecases/end_call.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/datasources/message_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/data/repositories/message_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/repositories/message_repository.dart';
import '../../features/chat/domain/usecases/get_chats.dart';
import '../../features/chat/domain/usecases/get_messages.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/mark_conversation_read.dart';
import '../../features/home/data/datasources/post_remote_datasource.dart';
import '../../features/home/data/datasources/post_local_datasource.dart';
import '../../features/home/data/repositories/post_repository_impl.dart';
import '../../features/home/data/services/posts_cache_service.dart';
import '../../features/home/data/services/posts_sync_service.dart';
import '../../features/home/domain/repositories/post_repository.dart';
import '../../features/home/domain/usecases/get_posts.dart';
import '../../features/home/domain/usecases/create_post.dart';
import '../../features/home/domain/usecases/get_current_user.dart';
import '../../features/home/domain/usecases/get_user_post_preferences.dart';
import '../../features/home/domain/usecases/update_user_post_preferences.dart';
import '../../features/home/domain/usecases/like_post.dart';
import '../../features/home/domain/usecases/unlike_post.dart';
import '../../features/home/domain/usecases/add_comment.dart';
import '../../features/home/domain/usecases/get_comments_by_post.dart';
import '../../features/home/domain/usecases/upload_file.dart';
import '../../features/home/domain/usecases/vote_poll.dart';
import '../../features/help_center/data/datasources/help_chat_remote_datasource.dart';
import '../../features/help_center/data/repositories/help_chat_repository_impl.dart';
import '../../features/help_center/domain/repositories/help_chat_repository.dart';
import '../../features/help_center/domain/usecases/get_help_chats.dart';
import '../../features/help_center/domain/usecases/get_help_messages.dart';

final sl = GetIt.instance;

Future<void> initDependencies({required String apiBaseUrl}) async {
  const storage = FlutterSecureStorage();
  sl.registerSingleton<FlutterSecureStorage>(storage);
  sl.registerSingleton(DioClient.create(baseUrl: apiBaseUrl, storage: storage));
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));

  final jobsBox = await Hive.openBox('jobs_cache');
  sl.registerSingleton<Box>(jobsBox, instanceName: 'jobsBox');

  sl.registerSingleton<NotificationRemoteDataSource>(
    NotificationRemoteDataSourceImpl(sl()),
  );
  sl.registerSingleton<NotificationRepository>(
    NotificationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerSingleton(GetNotifications(sl()));
  sl.registerSingleton(MarkNotificationRead(sl()));
  sl.registerSingleton(MarkAllNotificationsRead(sl()));
  sl.registerSingleton(CreateNotification(sl()));

  sl.registerSingleton<CallRemoteDataSource>(CallRemoteDataSourceImpl(sl()));
  sl.registerSingleton<CallRepository>(
    CallRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerSingleton(GetCall(sl()));
  sl.registerSingleton(StartCall(sl()));
  sl.registerSingleton(EndCall(sl()));

  sl.registerSingleton<ConversationRemoteDataSource>(
    ConversationRemoteDataSourceImpl(sl()),
  );
  sl.registerSingleton<MessageRemoteDataSource>(
    MessageRemoteDataSourceImpl(sl()),
  );
  sl.registerSingleton<ConversationRepository>(
    ConversationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerSingleton<MessageRepository>(
    MessageRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerSingleton(GetConversations(sl()));
  sl.registerSingleton(GetMessages(sl()));
  sl.registerSingleton(SendMessage(sl()));
  sl.registerSingleton(MarkConversationRead(sl()));

  sl.registerSingleton<PostRemoteDataSource>(PostRemoteDataSourceImpl(sl()));

  final postsBox = await Hive.openBox('posts_cache');
  sl.registerSingleton<Box>(postsBox, instanceName: 'postsBox');

  final lastSyncBox = await Hive.openBox('last_sync');
  sl.registerSingleton<Box>(lastSyncBox, instanceName: 'lastSyncBox');

  sl.registerSingleton<PostLocalDataSource>(
    PostLocalDataSourceImpl(sl<Box>(instanceName: 'postsBox')),
  );

  sl.registerSingleton<PostsCacheService>(
    PostsCacheService(
      localDataSource: sl(),
      syncBox: sl<Box>(instanceName: 'lastSyncBox'),
    ),
  );

  sl.registerSingleton<PostRepository>(
    PostRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      cacheService: sl(),
    ),
  );

  sl.registerSingleton<PostsSyncService>(
    PostsSyncService(repository: sl()),
  );
  sl.registerSingleton(GetPosts(sl()));
  sl.registerSingleton(CreatePost(sl()));
  sl.registerSingleton(GetCurrentUser(sl()));
  sl.registerSingleton(GetUserPostPreferences(sl()));
  sl.registerSingleton(UpdateUserPostPreferences(sl()));
  sl.registerSingleton(LikePost(sl()));
  sl.registerSingleton(UnlikePost(sl()));
  sl.registerSingleton(AddComment(sl()));
  sl.registerSingleton(GetCommentsByPost(sl()));
  sl.registerSingleton(UploadFile(sl()));
  sl.registerSingleton(VotePoll(sl()));

  sl.registerSingleton<HelpChatRemoteDataSource>(
    HelpChatRemoteDataSourceImpl(sl()),
  );
  sl.registerSingleton<HelpChatRepository>(
    HelpChatRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerSingleton(GetHelpChats(sl()));
  sl.registerSingleton(GetHelpMessages(sl()));
}
