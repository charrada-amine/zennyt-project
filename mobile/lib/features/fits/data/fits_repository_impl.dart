import 'package:dio/dio.dart';
import 'package:zennyt/core/network/page_items.dart';

import '../../../core/error/api_exception.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../jobs/domain/entities/job.dart';
import '../domain/entities/candidate_profile.dart';
import '../domain/entities/match_entity.dart';
import '../domain/entities/swipe_result.dart';
import '../domain/repositories/fits_repository.dart';

/// [FitsRepository] backed by Dio, talking to the integrated recruitment API.
///
/// Maps the merged backend's responses onto the REC-04 UI entities so the
/// original Fits screens render unchanged.
class FitsRepositoryImpl implements FitsRepository {
  FitsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<JobOffer>> getCandidateDeck() {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/job-offers/matching-deck');
      final content = res.data!['content'] as List<dynamic>;
      return content
          .map((e) => _jobOfferFromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<JobOffer>> getMyActiveOffers() {
    return _guard(() async {
      final res = await _dio.get<Object>(
        '/recruiters/me/job-offers',
        queryParameters: {'status': 'ACTIVE', 'size': 100},
      );
      return pageItems(res.data).map(_jobOfferFromJson).toList();
    });
  }

  @override
  Future<List<CandidateProfile>> getCandidateFeed(String jobOfferId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/recruiters/me/candidate-feed',
        queryParameters: {'jobOfferId': jobOfferId, 'size': 50},
      );
      final content = res.data!['content'] as List<dynamic>;
      return content
          .map((e) => _candidateFromFeedJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<CandidateProfile>> searchCandidates({String? query, String? location}) {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/candidates/search', queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (location != null && location.trim().isNotEmpty) 'location': location.trim(),
      });
      return res.data!
          .map((e) => _candidateFromSearchJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<CandidateProfile>> getCandidateMatchingDeck(String jobOfferId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/job-offers/$jobOfferId/candidates/matching-deck',
      );
      final content = res.data!['content'] as List<dynamic>;
      return content
          .map((e) => _candidateFromDeckJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  static CandidateProfile _candidateFromDeckJson(Map<String, dynamic> json) {
    final fullName = (json['fullName'] as String?)?.trim() ?? '';
    final spaceIndex = fullName.indexOf(' ');
    final firstName = spaceIndex == -1 ? fullName : fullName.substring(0, spaceIndex);
    final lastName = spaceIndex == -1 ? '' : fullName.substring(spaceIndex + 1);
    return CandidateProfile(
      user: AppUser(
        id: json['id']?.toString() ?? '',
        firstName: firstName.isEmpty ? 'Candidate' : firstName,
        lastName: lastName,
        email: '',
        profileImageUrl: json['avatarUrl'] as String?,
      ),
      targetRole: json['headline'] as String? ?? '',
      seniority: '',
      fitScore: 0,
      location: '',
      softSkillsLevel: '—',
      hardSkills: const {},
      partialData: false,
      contractTypes: const [],
      isImmediate: false,
    );
  }

  CandidateProfile _candidateFromSearchJson(Map<String, dynamic> json) {
    final fullName = (json['fullName'] as String?)?.trim() ?? '';
    final parts = fullName.isEmpty ? const <String>[] : fullName.split(' ');
    final first = parts.isEmpty ? 'Candidate' : parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final city = json['city'] as String?;
    final country = json['country'] as String?;
    final location = [city, country]
        .where((v) => v != null && v.isNotEmpty)
        .join(', ');
    final contract = json['contractTypePreference'] as String?;
    return CandidateProfile(
      user: AppUser(
        id: json['id']?.toString() ?? '',
        firstName: first,
        lastName: last,
        email: '',
        profileImageUrl: json['avatarUrl'] as String?,
      ),
      targetRole: json['lookingFor'] as String? ?? '',
      seniority: '',
      fitScore: 0,
      location: location,
      softSkillsLevel: '',
      hardSkills: const {},
      partialData: false,
      contractTypes: contract != null ? [contract] : const [],
      isImmediate: false,
    );
  }

  @override
  Future<SwipeResult> swipe({
    required String targetId,
    required SwipeTargetType targetType,
    required String jobOfferId,
    required SwipeDirection direction,
  }) {
    return _guard(() async {
      // Candidate swiping an offer vs recruiter swiping a candidate live on
      // different contract routes (both are "an offer's swipes", side-specific).
      final path = targetType == SwipeTargetType.candidate
          ? '/job-offers/$jobOfferId/candidates/$targetId/swipes'
          : '/job-offers/$jobOfferId/swipes';
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'direction': direction.value},
      );
      final data = res.data ?? const {};
      final match = data['match'] as Map<String, dynamic>?;
      return SwipeResult(
        swipeId: data['swipeId']?.toString() ?? '',
        direction: direction,
        matched: data['matched'] as bool? ?? false,
        matchId: match?['id']?.toString() ?? data['matchId']?.toString(),
      );
    });
  }

  @override
  Future<void> undoSwipe({
    required String jobOfferId,
    required SwipeTargetType targetType,
    required String targetId,
  }) {
    return _guard(() {
      final path = targetType == SwipeTargetType.candidate
          ? '/job-offers/$jobOfferId/candidates/$targetId/swipes/me'
          : '/job-offers/$jobOfferId/swipes/me';
      return _dio.delete<void>(path);
    });
  }

  @override
  Future<List<MatchEntity>> getCandidateMatches() {
    return _guard(() async {
      final res = await _dio.get<Object>(
        '/candidates/me/matches',
        queryParameters: {'size': 100},
      );
      return pageItems(res.data).map(_matchFromJson).toList();
    });
  }

  @override
  Future<List<MatchEntity>> getRecruiterMatches({required String jobOfferId}) {
    return _guard(() async {
      final res = await _dio.get<Object>(
        '/job-offers/$jobOfferId/matches',
        queryParameters: {'size': 100},
      );
      return pageItems(res.data)
          .map((json) => _matchFromJson(json, jobOfferId: jobOfferId))
          .toList();
    });
  }

  // --- mappers -------------------------------------------------------------

  static JobOffer _jobOfferFromJson(Map<String, dynamic> json) => JobOffer(
        id: json['id'] as String,
        recruiterId: json['recruiterId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        companyName: json['companyName'] as String? ?? '',
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        remote: json['remote'] as bool? ?? false,
        salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
        salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? '',
        contractType: ContractType.fromString(json['contractType'] as String? ?? ''),
        workplaceType: WorkplaceType.fromString(json['workplaceType'] as String? ?? ''),
        experienceLevel:
            ExperienceLevel.fromString(json['experienceLevel'] as String? ?? ''),
        fieldOfWork: json['fieldOfWork'] as String? ?? '',
        description: json['description'] as String? ?? '',
        responsibilities: json['responsibilities'] as String? ?? '',
        minimumQualifications: json['minimumQualifications'] as String? ?? '',
        preferredQualifications: json['preferredQualifications'] as String? ?? '',
        whatWeOffer: json['whatWeOffer'] as String? ?? '',
        howToApply: json['howToApply'] as String? ?? '',
        companyInfo: json['companyInfo'] as String? ?? '',
        assessmentId: json['assessmentId'] as String?,
        jobPositionId: json['jobPositionId'] as String?,
        openToInternational: json['openToInternational'] as bool? ?? false,
        status: JobStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
        postedAt: json['postedAt'] != null
            ? DateTime.tryParse(json['postedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        // F17 (FITSCORE_REMEDIATION.md §3 index F17): the candidate's Fit Score
        // for this offer — this mapper only ever backs candidate-facing calls
        // (getCandidateDeck/getMyActiveOffers), so it's populated when present.
        fitScore: (json['fitScore'] as num?)?.toInt(),
        hardSkillsAlert: HardSkillsAlertLevel.fromString(json['hardSkillsAlert'] as String?),
      );

  /// The merged backend's candidate feed (`CandidateFeedItem`, contract §…)
  /// carries the fit score, an aggregate soft-skills score, `targetRole` and
  /// a nested `location` object — not flat `city`/`country` keys, and no
  /// `avatarUrl` field (candidate photo isn't projected into Recruitment
  /// yet). Per-module soft-skill details aren't exposed either (see F10,
  /// PLAN_FITSCORE_V3 D5), so section shows one qualitative level derived
  /// from the aggregate instead of three fabricated identical rows.
  static CandidateProfile _candidateFromFeedJson(Map<String, dynamic> json) {
    final fullName = json['fullName'] as String? ?? '';
    final spaceIndex = fullName.indexOf(' ');
    final firstName = spaceIndex == -1 ? fullName : fullName.substring(0, spaceIndex);
    final lastName = spaceIndex == -1 ? '' : fullName.substring(spaceIndex + 1);
    final softSkills = (json['softSkillsScore'] as num?)?.toInt();
    final hardSkillScore = (json['hardSkillScore'] as num?)?.toInt();
    final locationJson = json['location'] as Map<String, dynamic>?;
    final location = [locationJson?['city'], locationJson?['country']]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .join(', ');

    return CandidateProfile(
      user: AppUser(
        id: json['candidateId'] as String,
        firstName: firstName,
        lastName: lastName,
        email: '',
      ),
      targetRole: json['targetRole'] as String? ?? '',
      seniority: '',
      fitScore: (json['fitScore'] as num?)?.toInt() ?? 0,
      location: location,
      softSkillsLevel: _qualitative(softSkills),
      hardSkills: hardSkillScore != null ? {'Hard Skills': hardSkillScore} : const {},
      partialData: json['partialData'] as bool? ?? false,
      contractTypes: [if (json['goodFit'] as bool? ?? false) 'Good fit'],
      isImmediate: false,
    );
  }

  static String _qualitative(int? score) {
    if (score == null) return '—';
    if (score >= 75) return 'High';
    if (score >= 50) return 'Medium';
    return 'Developing';
  }

  /// Match côté candidat (`{id, jobOffer: {id, title, companyName}, matchedAt}`)
  /// ou côté recruteur (`{id, candidate: {id, fullName, avatarUrl}, matchedAt}`) ;
  /// l'ancienne forme à plat reste lue par sécurité.
  static MatchEntity _matchFromJson(Map<String, dynamic> json, {String? jobOfferId}) {
    final offer = json['jobOffer'] as Map<String, dynamic>? ?? const {};
    final candidate = json['candidate'] as Map<String, dynamic>? ?? const {};
    return MatchEntity(
      matchId: json['id'] as String? ?? json['matchId'] as String? ?? '',
      candidateId: candidate['id'] as String? ?? json['candidateId'] as String? ?? '',
      jobOfferId:
          offer['id'] as String? ?? json['jobOfferId'] as String? ?? jobOfferId ?? '',
      candidateName:
          candidate['fullName'] as String? ?? json['candidateName'] as String? ?? '',
      jobTitle: offer['title'] as String? ?? json['jobTitle'] as String? ?? '',
      companyName: offer['companyName'] as String? ?? json['companyName'] as String? ?? '',
      matchedAt: DateTime.tryParse(json['matchedAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Runs [action], converting any [DioException] into a typed [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
