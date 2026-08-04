import 'dart:convert';
import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../models/job_model.dart';

/// Source locale : cache Hive pour le mode offline-first.
abstract class JobLocalDataSource {
  Future<void> cacheJobs(List<JobModel> jobs);
  Future<List<JobModel>> getCachedJobs();
}

class JobLocalDataSourceImpl implements JobLocalDataSource {
  final Box box;
  JobLocalDataSourceImpl(this.box);

  static const _key = 'cached_jobs';

  @override
  Future<void> cacheJobs(List<JobModel> jobs) async {
    final encoded = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await box.put(_key, encoded);
  }

  @override
  Future<List<JobModel>> getCachedJobs() async {
    final raw = box.get(_key) as String?;
    if (raw == null) throw CacheException('Aucune offre en cache');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => JobModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
