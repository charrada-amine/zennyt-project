import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/dio_client.dart';
import '../network/dev_identity_interceptor.dart';
import '../network/network_info.dart';
import '../../features/jobs/data/datasources/job_local_datasource.dart';
import '../../features/jobs/data/datasources/job_remote_datasource.dart';
import '../../features/jobs/data/repositories/job_repository_impl.dart';
import '../../features/jobs/domain/repositories/job_repository.dart';
import '../../features/jobs/domain/usecases/get_jobs.dart';
import '../../features/jobs/presentation/bloc/job_list_bloc.dart';
import '../../features/home/data/datasources/feed_local_datasource.dart';
import '../../features/home/data/repositories/feed_repository_impl.dart';
import '../../features/home/domain/repositories/feed_repository.dart';
import '../../features/home/domain/usecases/get_feed.dart';
import '../../features/home/presentation/bloc/feed_bloc.dart';
import '../../features/search/data/datasources/search_local_datasource.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/search_suggestions.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/fits/data/datasources/fits_local_datasource.dart';
import '../../features/fits/data/datasources/fits_remote_datasource.dart';
import '../../features/fits/data/repositories/fits_repository_impl.dart';
import '../../features/fits/domain/repositories/fits_repository.dart';
import '../../features/fits/domain/usecases/get_fits.dart';
import '../../features/fits/domain/usecases/record_swipe.dart';
import '../../features/fits/presentation/bloc/fits_bloc.dart';
import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/chat/data/datasources/chat_local_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/get_chats.dart';
import '../../features/chat/domain/usecases/get_messages.dart';
import '../../features/chat/presentation/bloc/chat_list_bloc.dart';
import '../../features/chat/presentation/bloc/conversation_bloc.dart';
import '../../features/careers/data/datasources/careers_local_datasource.dart';
import '../../features/careers/data/datasources/careers_remote_datasource.dart';
import '../../features/careers/data/repositories/careers_repository_impl.dart';
import '../../features/careers/domain/repositories/careers_repository.dart';
import '../../features/careers/domain/usecases/get_my_job_offers.dart';
import '../../features/careers/domain/usecases/get_my_tests.dart';
import '../../features/careers/data/datasources/job_offer_write_datasource.dart';
import '../../features/careers/presentation/bloc/careers_bloc.dart';
import '../../features/applications/data/applications_remote_datasource.dart';
import '../../features/assessment/data/assessment_remote_datasource.dart';
import '../../features/matches/data/matches_remote_datasource.dart';
import '../../features/chat/data/opportunity_remote_datasource.dart';

final sl = GetIt.instance;

/// Enregistre toutes les dépendances. Appelé une fois au démarrage.
///
/// Convention de durée de vie :
/// - singletons : clients réseau, datasources, repositories (sans état mutable)
/// - factory : BLoCs (un nouvel état par écran)
Future<void> initDependencies({required String apiBaseUrl}) async {
  // ───── Core ─────
  const storage = FlutterSecureStorage();
  sl.registerSingleton<FlutterSecureStorage>(storage);
  final dio = DioClient.create(baseUrl: apiBaseUrl, storage: storage);
  // Phase A : simule l'identité (candidat/recruteur) via le header X-Dev-User
  // selon le mode courant. À retirer après la fusion du contexte Identity.
  dio.interceptors.add(DevIdentityInterceptor());
  sl.registerSingleton<Dio>(dio);
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));

  final jobsBox = await Hive.openBox('jobs_cache');
  sl.registerSingleton<Box>(jobsBox, instanceName: 'jobsBox');

  // ───── Feature : jobs ─────
  sl.registerSingleton<JobRemoteDataSource>(JobRemoteDataSourceImpl(sl()));
  sl.registerSingleton<JobLocalDataSource>(
      JobLocalDataSourceImpl(sl<Box>(instanceName: 'jobsBox')));
  sl.registerSingleton<JobRepository>(JobRepositoryImpl(
    remote: sl(),
    local: sl(),
    networkInfo: sl(),
  ));
  sl.registerSingleton(GetJobs(sl()));
  // BLoC en factory : une instance neuve par écran
  sl.registerFactory(() => JobListBloc(getJobs: sl()));

  // ───── Feature : home (fil d'actualité, données mock) ─────
  sl.registerSingleton<FeedLocalDataSource>(FeedMockDataSource());
  sl.registerSingleton<FeedRepository>(FeedRepositoryImpl(local: sl()));
  sl.registerSingleton(GetFeed(sl()));
  sl.registerFactory(() => FeedBloc(getFeed: sl()));

  // ───── Feature : search (offres / pros, données mock) ─────
  sl.registerSingleton<SearchLocalDataSource>(SearchMockDataSource());
  sl.registerSingleton<SearchRepository>(SearchRepositoryImpl(local: sl()));
  sl.registerSingleton(SearchSuggestions(sl()));
  sl.registerFactory(() => SearchBloc(searchSuggestions: sl()));

  // ───── Feature : fits (deck swipe — offres réelles via GET /job-offers) ─────
  // Onglet "Offres" = backend ; onglet "Professionnels" = vide (pas d'endpoint).
  sl.registerSingleton<FitsLocalDataSource>(FitsRemoteDataSource(sl<Dio>()));
  sl.registerSingleton<FitsRepository>(FitsRepositoryImpl(local: sl()));
  sl.registerSingleton(GetFits(sl()));
  sl.registerSingleton(RecordSwipe(sl()));
  sl.registerFactory(() => FitsBloc(getFits: sl(), recordSwipe: sl()));

  // ───── Feature : notifications (mock) ─────
  sl.registerSingleton<NotificationsLocalDataSource>(NotificationsMockDataSource());
  sl.registerSingleton<NotificationsRepository>(
      NotificationsRepositoryImpl(local: sl()));
  sl.registerSingleton(GetNotifications(sl()));
  sl.registerFactory(() => NotificationsBloc(getNotifications: sl()));

  // ───── Feature : chat (mock) ─────
  sl.registerSingleton<ChatLocalDataSource>(ChatMockDataSource());
  sl.registerSingleton<ChatRepository>(ChatRepositoryImpl(local: sl()));
  sl.registerSingleton(GetChats(sl()));
  sl.registerSingleton(GetMessages(sl()));
  sl.registerFactory(() => ChatListBloc(getChats: sl()));
  sl.registerFactory(() => ConversationBloc(getMessages: sl()));

  // ───── Feature : careers (recruteur — offres & tests réels) ─────
  // GET /recruiters/me/job-offers + GET /assessments/mine (header X-Dev-User).
  sl.registerSingleton<CareersLocalDataSource>(CareersRemoteDataSource(sl<Dio>()));
  sl.registerSingleton<CareersRepository>(CareersRepositoryImpl(local: sl()));
  sl.registerSingleton(GetMyTests(sl()));
  sl.registerSingleton(GetMyJobOffers(sl()));
  sl.registerFactory(() => CareersBloc(getMyTests: sl(), getMyJobOffers: sl()));

  // ───── Écritures du flux recrutement (appelées directement depuis les pages) ─────
  // Candidat : postuler + soumettre une tentative. Recruteur : créer offre/test.
  // Lecture : matches (candidat ou recruteur selon le mode).
  sl.registerSingleton(ApplicationsRemoteDataSource(sl<Dio>()));
  sl.registerSingleton(AssessmentRemoteDataSource(sl<Dio>()));
  sl.registerSingleton(JobOfferWriteDataSource(sl<Dio>()));
  sl.registerSingleton(MatchesRemoteDataSource(sl<Dio>()));
  sl.registerSingleton(OpportunityRemoteDataSource(sl<Dio>()));

  // Les autres features (auth, profile...) s'enregistrent ici sur le même modèle.
}
