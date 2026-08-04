import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';

/// Écritures côté candidat liées aux candidatures.
///
/// Appelée directement depuis la page (action ponctuelle "Postuler"), sans bloc
/// dédié. L'identité du candidat vient du header `X-Dev-User` / JWT — jamais du
/// corps : `POST /applications` ne porte que `jobOfferId`.
class ApplicationsRemoteDataSource {
  final Dio dio;
  ApplicationsRemoteDataSource(this.dio);

  /// POST /applications — soumet une candidature à l'offre.
  ///
  /// Renvoie `true` si l'API a créé la candidature (201). Un doublon (4xx, déjà
  /// postulé) renvoie `false` sans lever — l'UI peut continuer vers le test.
  Future<bool> submit(String jobOfferId) async {
    try {
      await dio.post('/applications', data: {'jobOfferId': jobOfferId});
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      // 400/409 = déjà postulé ou règle métier — non bloquant pour le parcours.
      if (code >= 400 && code < 500) return false;
      throw ServerException(e.message ?? 'Erreur réseau', statusCode: code);
    }
  }
}
