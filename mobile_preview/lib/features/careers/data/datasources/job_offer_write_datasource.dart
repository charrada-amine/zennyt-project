import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';

/// Écritures côté recruteur sur les offres d'emploi.
///
/// `create` poste l'offre (statut initial DRAFT côté backend) puis `activate`
/// la publie (PATCH status = ACTIVE) pour qu'elle apparaisse dans le deck Fits
/// des candidats. L'identité du recruteur vient du header `X-Dev-User` / JWT.
class JobOfferWriteDataSource {
  final Dio dio;
  JobOfferWriteDataSource(this.dio);

  /// POST /job-offers — crée l'offre. Renvoie son id.
  Future<String> create({
    required String title,
    required String description,
    required String contractType, // enum exact, ex. FULL_TIME
    required String workplaceType, // enum exact, ex. ON_SITE
    required String experienceLevel, // enum exact, ex. JUNIOR
    required String locationCity,
    required String locationCountry,
    required bool locationRemote,
  }) async {
    try {
      final res = await dio.post('/job-offers', data: {
        'title': title,
        'description': description,
        'contractType': contractType,
        'workplaceType': workplaceType,
        'experienceLevel': experienceLevel,
        'locationCity': locationCity,
        'locationCountry': locationCountry,
        'locationRemote': locationRemote,
      });
      final data = res.data as Map<String, dynamic>;
      return data['id'] as String;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// PATCH /job-offers/{id}/status — publie l'offre (ACTIVE).
  Future<void> activate(String id) async {
    try {
      await dio.patch('/job-offers/$id/status', data: {'status': 'ACTIVE'});
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
