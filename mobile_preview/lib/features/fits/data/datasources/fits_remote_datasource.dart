import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/fit_item.dart';
import '../models/fit_item_model.dart';
import 'fits_local_datasource.dart';

/// Source distante du deck Fits — appelle l'API Recruitment via Dio.
///
/// - `FitKind.jobOffer` (vue candidat) → `GET /job-offers` → [FitItemModel].
/// - `FitKind.professional` (vue recruteur) → pas d'endpoint de feed candidat
///   côté recrutement aujourd'hui : on renvoie une liste vide (voir
///   `BACKEND_WIRING.md` §5). Le *write* (swipe sur un candidat) existe, mais pas
///   la *liste* à afficher.
///
/// L'identité de l'appelant est portée par le header `X-Dev-User`
/// (`DevIdentityInterceptor`) en Phase A, ou par le JWT en Phase B — jamais dans
/// le corps de la requête.
class FitsRemoteDataSource implements FitsLocalDataSource {
  final Dio dio;
  FitsRemoteDataSource(this.dio);

  @override
  Future<List<FitItemModel>> getFits(FitKind kind) async {
    if (kind == FitKind.professional) {
      return const [];
    }
    try {
      final res = await dio.get(
        '/job-offers',
        queryParameters: {'page': 0, 'size': 20},
      );
      // GET /job-offers renvoie une liste nue (pas une Page Spring).
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map && data['content'] is List)
              ? data['content'] as List
              : const [];
      return list
          .map((j) => _fromJobOffer(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Mappe le `JobOfferResponse` du backend sur le [FitItemModel] existant.
  FitItemModel _fromJobOffer(Map<String, dynamic> j) {
    final city = j['locationCity'] as String?;
    final country = j['locationCountry'] as String?;
    final remote = j['locationRemote'] == true;
    final location = remote
        ? 'Remote'
        : [city, country]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');

    final salaryMin = j['salaryMin'];
    final salaryMax = j['salaryMax'];
    final currency = j['salaryCurrency'] as String? ?? '';
    String? salary;
    if (salaryMin != null || salaryMax != null) {
      salary = '${_num(salaryMin)}–${_num(salaryMax)} $currency'.trim();
    }

    final tags = <String>[
      if (j['experienceLevel'] != null) _pretty(j['experienceLevel']),
      if (j['contractType'] != null) _pretty(j['contractType']),
      if (j['workplaceType'] != null) _pretty(j['workplaceType']),
      if (j['openToInternational'] == true) 'International candidates welcome',
    ];

    final assessmentIds = (j['assessmentIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return FitItemModel(
      id: j['id'] as String,
      kind: FitKind.jobOffer,
      // Le % de fit est un appel séparé (GET /fit-scores) — laissé à 0 en Phase A.
      fitScore: 0,
      name: j['companyName'] as String? ?? '',
      imageUrl: '', // pas de logo côté backend ; FitCard a un fallback.
      role: j['title'] as String? ?? '',
      location: location,
      tags: tags,
      salary: salary,
      about: j['description'] as String?,
      assessmentIds: assessmentIds,
    );
  }

  /// POST /swipes — enregistre le swipe et retourne `true` si match détecté.
  @override
  Future<bool> recordSwipe({
    required String targetId,
    required String targetType,
    required String direction,
    String? jobOfferId,
  }) async {
    try {
      final body = <String, dynamic>{
        'targetId': targetId,
        'targetType': targetType,
        'direction': direction,
      };
      if (jobOfferId != null) body['jobOfferId'] = jobOfferId;

      final res = await dio.post('/swipes', data: body);
      final matched = res.data['matched'] as bool? ?? false;
      return matched;
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // 15000.0 -> "15000", 15000.5 -> "15000.5"
  String _num(Object? n) {
    if (n == null) return '';
    if (n is num && n == n.roundToDouble()) return n.toInt().toString();
    return n.toString();
  }

  // FULL_TIME -> "Full time", ON_SITE -> "On site"
  String _pretty(Object e) => e
      .toString()
      .split('_')
      .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
      .join(' ');
}
