import 'package:dio/dio.dart';

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
      final res = await _dio.get<List<dynamic>>('/job-offers');
      return res.data!
          .map((e) => _jobOfferFromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<JobOffer>> getMyActiveOffers() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>(
        '/recruiters/me/job-offers',
        queryParameters: {'status': 'ACTIVE'},
      );
      return res.data!
          .map((e) => _jobOfferFromJson(e as Map<String, dynamic>))
          .toList();
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
  Future<List<String>> getSwipedTargetIds({String? jobOfferId}) {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>(
        '/swipes/targets',
        queryParameters: {if (jobOfferId != null) 'jobOfferId': jobOfferId},
      );
      return res.data!.map((e) => e.toString()).toList();
    });
  }

  @override
  Future<SwipeResult> swipe({
    required String targetId,
    required SwipeTargetType targetType,
    required String jobOfferId,
    required SwipeDirection direction,
  }) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/swipes',
        data: {
          'targetId': targetId,
          'targetType': targetType.value,
          'jobOfferId': jobOfferId,
          'direction': direction.value,
        },
      );
      final data = res.data!;
      return SwipeResult(
        swipeId: data['swipeId'] as String,
        direction: direction,
        matched: data['matched'] as bool? ?? false,
        matchId: data['matchId'] as String?,
      );
    });
  }

  @override
  Future<void> undoSwipe(String swipeId) {
    return _guard(() => _dio.delete<void>('/swipes/$swipeId'));
  }

  @override
  Future<List<MatchEntity>> getCandidateMatches() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/candidates/me/matches');
      return res.data!
          .map((e) => _matchFromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<MatchEntity>> getRecruiterMatches({String? jobOfferId}) {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>(
        '/recruiters/me/matches',
        queryParameters: {if (jobOfferId != null) 'jobOfferId': jobOfferId},
      );
      return res.data!
          .map((e) => _matchFromJson(e as Map<String, dynamic>))
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

  static MatchEntity _matchFromJson(Map<String, dynamic> json) => MatchEntity(
        matchId: json['matchId'] as String? ?? '',
        candidateId: json['candidateId'] as String? ?? '',
        jobOfferId: json['jobOfferId'] as String? ?? '',
        candidateName: json['candidateName'] as String? ?? '',
        jobTitle: json['jobTitle'] as String? ?? '',
        companyName: json['companyName'] as String? ?? '',
        matchedAt: json['matchedAt'] != null
            ? DateTime.tryParse(json['matchedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  /// Runs [action], converting any [DioException] into a typed [ApiException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
