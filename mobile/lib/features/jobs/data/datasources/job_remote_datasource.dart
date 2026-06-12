import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/job_filter.dart';
import '../models/job_model.dart';

/// Source distante : appelle l'API Recruitment via Dio.
/// Lève des [ServerException] que le Repository convertit en Failure.
abstract class JobRemoteDataSource {
  Future<List<JobModel>> getJobs({required JobFilter filter, required int page, required int size});
  Future<JobModel> getJobDetail(String jobId);
}

class JobRemoteDataSourceImpl implements JobRemoteDataSource {
  final Dio dio;
  JobRemoteDataSourceImpl(this.dio);

  @override
  Future<List<JobModel>> getJobs({required JobFilter filter, required int page, required int size}) async {
    try {
      final res = await dio.get('/jobs', queryParameters: {
        if (filter.query != null) 'q': filter.query,
        if (filter.location != null) 'location': filter.location,
        if (filter.contractType != null) 'contractType': filter.contractType,
        if (filter.remoteAllowed != null) 'remoteAllowed': filter.remoteAllowed,
        'page': page,
        'size': size,
      });
      final content = (res.data['content'] as List<dynamic>);
      return content.map((e) => JobModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Erreur serveur', statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<JobModel> getJobDetail(String jobId) async {
    try {
      final res = await dio.get('/jobs/$jobId');
      return JobModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Erreur serveur', statusCode: e.response?.statusCode);
    }
  }
}
