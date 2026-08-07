import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/recruiter_job_offer.dart';
import '../../domain/entities/recruiter_test.dart';
import 'careers_local_datasource.dart';

/// Source distante de l'espace recruteur — appelle l'API Recruitment via Dio.
///
/// - `getJobOffers()` → `GET /recruiters/me/job-offers` (offres du recruteur courant).
/// - `getTests()`     → `GET /assessments/mine` (banque de tests du recruteur).
///
/// Le recruteur courant est identifié par le header `X-Dev-User` (Phase A) ou le
/// JWT (Phase B) — jamais passé dans la requête. Bascule le mode recruteur dans
/// l'UI pour que [DevIdentityInterceptor] envoie le bon UUID.
class CareersRemoteDataSource implements CareersLocalDataSource {
  final Dio dio;
  CareersRemoteDataSource(this.dio);

  @override
  Future<List<RecruiterJobOffer>> getJobOffers() async {
    try {
      final res = await dio.get(
        '/recruiters/me/job-offers',
        queryParameters: {'page': 0, 'size': 20},
      );
      final list = _asList(res.data);
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

  @override
  Future<List<RecruiterTest>> getTests() async {
    try {
      final res = await dio.get(
        '/assessments/mine',
        queryParameters: {'page': 0, 'size': 20},
      );
      final list = _asList(res.data);
      return list.map((a) {
        final m = a as Map<String, dynamic>;
        return RecruiterTest(
          id: m['id'] as String,
          name: m['title'] as String? ?? 'Test',
        );
      }).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Erreur réseau',
        statusCode: e.response?.statusCode,
      );
    }
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['content'] is List) return data['content'] as List;
    return const [];
  }

  RecruiterJobOffer _fromJobOffer(Map<String, dynamic> j) {
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
    final salary = (salaryMin != null || salaryMax != null)
        ? '${_num(salaryMin)}–${_num(salaryMax)} $currency'.trim()
        : '';

    final tags = <String>[
      if (j['fieldOfWork'] != null && (j['fieldOfWork'] as String).isNotEmpty)
        j['fieldOfWork'] as String,
      if (j['contractType'] != null) _pretty(j['contractType']),
    ];

    return RecruiterJobOffer(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      company: j['companyName'] as String? ?? '',
      location: location,
      salary: salary,
      tags: tags,
      postedAgo: _relative(j['postedAt'] as String?),
      // Non exposés par l'API aujourd'hui — défaut 0 (voir BACKEND_WIRING.md §5).
      candidates: 0,
      successRate: 0,
    );
  }

  String _num(Object? n) {
    if (n == null) return '';
    if (n is num && n == n.roundToDouble()) return n.toInt().toString();
    return n.toString();
  }

  String _pretty(Object e) => e
      .toString()
      .split('_')
      .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
      .join(' ');

  // Instant ISO-8601 -> "3 days ago" (approximatif, affichage seulement).
  String _relative(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 1) return '${d.inDays} day${d.inDays > 1 ? 's' : ''} ago';
    if (d.inHours >= 1) return '${d.inHours} hour${d.inHours > 1 ? 's' : ''} ago';
    if (d.inMinutes >= 1) {
      return '${d.inMinutes} minute${d.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'just now';
  }
}
