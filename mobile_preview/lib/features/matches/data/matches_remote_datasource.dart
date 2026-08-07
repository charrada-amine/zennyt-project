import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';

/// Un match mutuel (candidat ↔ offre/recruteur).
class MatchItem {
  final String id;
  final String jobOfferId;
  final String jobOfferTitle;
  final String status;
  final String? matchedAt;
  const MatchItem({
    required this.id,
    required this.jobOfferId,
    required this.jobOfferTitle,
    required this.status,
    this.matchedAt,
  });
}

/// Lecture des matches pour l'utilisateur courant.
///
/// L'endpoint dépend du rôle :
/// - candidat  → `GET /candidates/me/matches`
/// - recruteur → `GET /recruiters/me/matches`
///
/// L'identité vient du header `X-Dev-User` / JWT ; aucun id dans la requête.
class MatchesRemoteDataSource {
  final Dio dio;
  MatchesRemoteDataSource(this.dio);

  Future<List<MatchItem>> getMatches({required bool recruiter}) async {
    final path =
        recruiter ? '/recruiters/me/matches' : '/candidates/me/matches';
    try {
      final res = await dio.get(
        path,
        queryParameters: {'page': 0, 'size': 20},
      );
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map && data['content'] is List)
              ? data['content'] as List
              : const [];
      return list.map((m) {
        final j = m as Map<String, dynamic>;
        return MatchItem(
          id: j['id'] as String,
          jobOfferId: j['jobOfferId'] as String? ?? '',
          jobOfferTitle: j['jobOfferTitle'] as String? ?? 'Offre',
          status: j['status'] as String? ?? '',
          matchedAt: j['matchedAt'] as String?,
        );
      }).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
