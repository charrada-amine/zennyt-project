import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../../features/jobs/data/datasources/job_local_datasource.dart';
import '../../features/jobs/data/datasources/job_remote_datasource.dart';
import '../../features/jobs/data/repositories/job_repository_impl.dart';
import '../../features/jobs/domain/repositories/job_repository.dart';
import '../../features/jobs/domain/usecases/get_jobs.dart';
import '../../features/jobs/presentation/bloc/job_list_bloc.dart';

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
  sl.registerSingleton(DioClient.create(baseUrl: apiBaseUrl, storage: storage));
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

  // Les autres features (auth, profile, chat...) s'enregistrent ici sur le même modèle.
}
