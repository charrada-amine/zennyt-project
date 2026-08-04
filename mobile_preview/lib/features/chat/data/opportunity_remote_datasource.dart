import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';

/// Flux "offre d'opportunité" (recruteur → candidat) branché sur l'API.
///
/// Le contexte chat (Engagement) n'a pas de backend : on reconstitue donc le
/// parcours réel côté recrutement. Comme un seul client joue les deux rôles en
/// dev, chaque appel fixe explicitement son identité via `X-Dev-User`
/// (le [DevIdentityInterceptor] ne l'écrase pas s'il est déjà présent) :
/// - l'envoi de l'offre est fait par le recruteur,
/// - la confirmation / l'OTP / le rejet par le candidat.
///
/// L'OTP est accepté tel quel par le backend dev (validation déléguée à un
/// service externe stubé), donc n'importe quel code à 6 chiffres finalise.
class OpportunityRemoteDataSource {
  final Dio dio;
  OpportunityRemoteDataSource(this.dio);

  static const _recruiter = '11111111-1111-1111-1111-111111111111';
  static const _candidate = '22222222-2222-2222-2222-222222222222';
  // Offre de démo semée par DevDataSeeder (OFFER_1).
  static const _demoOffer = 'a0000000-0000-0000-0000-000000000001';

  Options _as(String uuid) => Options(headers: {'X-Dev-User': uuid});

  /// Recruteur envoie l'offre, candidat confirme puis vérifie l'OTP.
  /// Renvoie le statut final (`CONFIRMED`).
  Future<String> confirm({String? jobOfferId, String otpCode = '745558'}) async {
    final offer = jobOfferId ?? _demoOffer;
    try {
      final sent = await dio.post(
        '/job-opportunity-offers',
        data: {'candidateId': _candidate, 'jobOfferId': offer},
        options: _as(_recruiter),
      );
      final id = sent.data['id'] as String;
      await dio.post('/job-opportunity-offers/$id/confirm', options: _as(_candidate));
      final res = await dio.post(
        '/job-opportunity-offers/$id/verify-otp',
        data: {'otpCode': otpCode},
        options: _as(_candidate),
      );
      return res.data['status'] as String? ?? 'CONFIRMED';
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Recruteur envoie l'offre, candidat la rejette. Renvoie `REJECTED`.
  Future<String> reject({String? jobOfferId}) async {
    final offer = jobOfferId ?? _demoOffer;
    try {
      final sent = await dio.post(
        '/job-opportunity-offers',
        data: {'candidateId': _candidate, 'jobOfferId': offer},
        options: _as(_recruiter),
      );
      final id = sent.data['id'] as String;
      final res =
          await dio.post('/job-opportunity-offers/$id/reject', options: _as(_candidate));
      return res.data['status'] as String? ?? 'REJECTED';
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
