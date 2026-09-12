import 'package:dio/dio.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/domain/entities/job_position.dart';
import 'package:zennyt/features/jobs/domain/entities/public_assessment.dart';
import 'package:zennyt/features/jobs/domain/entities/test_attempt.dart';
/// [JobsRepository] backed by Dio, talking to the integrated recruitment API.
///
/// Route/field names below are the merged backend's actual contract
/// (`JobOfferController`, `AssessmentController`) — the recruiter/candidate
/// id is always derived from the JWT, never sent as a parameter.
class JobsRepositoryImpl implements JobsRepository {
  JobsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<JobOffer>> getJobOffers() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/recruiters/me/job-offers');
      return res.data!.map((e) => _jobFromJson(e as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<JobOffer> getJobOfferById(String id) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/job-offers/$id');
      return _jobFromJson(res.data!);
    });
  }

  @override
  Future<List<JobOffer>> searchJobOffers({
    String? query,
    String? location,
    ContractType? contractType,
    ExperienceLevel? experienceLevel,
  }) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/job-offers', queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (location != null && location.trim().isNotEmpty) 'location': location.trim(),
        if (contractType != null) 'contractType': contractType.value,
        if (experienceLevel != null) 'experienceLevel': experienceLevel.value,
      });
      final content = res.data!['content'] as List? ?? const [];
      return content
          .map((e) => _jobFromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<JobOffer> createJobOffer(CreateJobOfferParams p) {
    return _guard(() async {
      // F24 (FITSCORE_REMEDIATION.md §3 index F24): `CreateJobOfferRequest` has
      // no assessmentId field by design (contract squad web §3.3 reserves
      // assignment for PATCH) and the backend runs Jackson with
      // fail-on-unknown-properties: true — sending it here doesn't get
      // silently dropped, it 400s the whole request. Callers that want to
      // attach an assessment at creation time call assignAssessmentToJob
      // right after this returns (see JobOffersNotifier.createJob).
      final res = await _dio.post<Map<String, dynamic>>('/job-offers', data: {
        'title': p.title,
        'city': p.city,
        'country': p.country,
        'salaryMin': p.salaryMin,
        'salaryMax': p.salaryMax,
        'salaryCurrency': p.salaryCurrency,
        'salaryPeriod': p.salaryPeriod.value,
        'contractType': p.contractType.value,
        'workplaceType': p.workplaceType.value,
        'experienceLevel': p.experienceLevel.value,
        'description': p.description,
        'responsibilities': p.responsibilities,
        'minimumQualifications': p.minimumQualifications,
        'preferredQualifications': p.preferredQualifications,
        'whatWeOffer': p.whatWeOffer,
        'howToApply': p.howToApply,
        'openToInternational': p.openToInternational,
        // F06 (FITSCORE_REMEDIATION.md §3 index F06): required server-side
        // since the AI-fallback path was removed — every create call failed
        // without it. Le sélecteur de métier du formulaire de création le
        // renseigne désormais ; s'il reste null, le 422 du serveur est le bon
        // signal et ne doit pas être masqué ici.
        'jobPositionId': p.jobPositionId,
      });
      return _jobFromJson(res.data!);
    });
  }

  @override
  Future<JobOffer> updateJobOffer(UpdateJobOfferParams p) {
    return _guard(() async {
      // Content changes go through PUT (same shape as create). The backend
      // PATCH only accepts `status`/`assessmentId` and runs with
      // fail-on-unknown-properties — sending the whole form via PATCH 400s
      // (contract §5.2, F23/F24).
      final putBody = <String, dynamic>{
        if (p.title != null) 'title': p.title,
        if (p.city != null) 'city': p.city,
        if (p.country != null) 'country': p.country,
        if (p.salaryMin != null) 'salaryMin': p.salaryMin,
        if (p.salaryMax != null) 'salaryMax': p.salaryMax,
        if (p.salaryCurrency != null) 'salaryCurrency': p.salaryCurrency,
        if (p.salaryPeriod != null) 'salaryPeriod': p.salaryPeriod!.value,
        if (p.contractType != null) 'contractType': p.contractType!.value,
        if (p.workplaceType != null) 'workplaceType': p.workplaceType!.value,
        if (p.experienceLevel != null) 'experienceLevel': p.experienceLevel!.value,
        if (p.description != null) 'description': p.description,
        if (p.responsibilities != null) 'responsibilities': p.responsibilities,
        if (p.minimumQualifications != null) 'minimumQualifications': p.minimumQualifications,
        if (p.preferredQualifications != null) 'preferredQualifications': p.preferredQualifications,
        if (p.whatWeOffer != null) 'whatWeOffer': p.whatWeOffer,
        if (p.howToApply != null) 'howToApply': p.howToApply,
        if (p.openToInternational != null) 'openToInternational': p.openToInternational,
        if (p.jobPositionId != null) 'jobPositionId': p.jobPositionId,
      };
      Response<Map<String, dynamic>>? res;
      if (putBody.isNotEmpty) {
        res = await _dio.put<Map<String, dynamic>>('/job-offers/${p.id}', data: putBody);
      }
      if (p.assessmentId != null) {
        res = await _dio.patch<Map<String, dynamic>>(
          '/job-offers/${p.id}',
          data: {'assessmentId': p.assessmentId},
        );
      }
      if (p.status != null) {
        res = await _dio.patch<Map<String, dynamic>>(
          '/job-offers/${p.id}/status',
          data: {'status': p.status!.value},
        );
      }
      res ??= await _dio.get<Map<String, dynamic>>('/job-offers/${p.id}');
      return _jobFromJson(res.data!);
    });
  }

  @override
  Future<void> deleteJobOffer(String id) {
    return _guard(() => _dio.delete<void>('/job-offers/$id'));
  }

  /// F06 — le catalogue des métiers, nécessaire au sélecteur du formulaire de création.
  /// L'API ne renvoie que les métiers APPROVED : un métier encore en attente d'approbation
  /// n'a pas de profil, donc aucune pondération, donc l'offre resterait sans Fit Score.
  @override
  Future<List<JobPosition>> getJobPositions() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/job-positions');
      return res.data!
          .map((e) => JobPosition.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  /// F30 — les 24 lignes du référentiel de pondération. Petit et fixe : chargé
  /// intégralement, puis filtré côté écran sur le couple (profil, niveau) choisi.
  @override
  Future<List<JobRoleProfile>> getJobRoleProfiles() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/job-role-profiles');
      return res.data!.map((e) => JobRoleProfile.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<List<Assessment>> getAssessments() {
    return _guard(() async {
      final res = await _dio.get<List<dynamic>>('/assessments');
      return res.data!.map((e) => _assessmentFromJson(e as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<Assessment> getAssessmentById(String id) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/assessments/$id');
      return _assessmentFromJson(res.data!);
    });
  }

  @override
  Future<Assessment> createAssessment(CreateAssessmentParams p) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>('/assessments', data: {
        'title': p.title,
        'timeLimitSeconds': p.timeLimitSeconds,
        'questions': p.questions
            .map((q) => {
                  'text': q.text,
                  'options': q.options,
                  'correctOptionIndex': q.correctOptionIndex,
                })
            .toList(),
      });
      return _assessmentFromJson(res.data!);
    });
  }

  @override
  Future<Assessment> generateAssessmentAi(GenerateAssessmentAiParams p) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>('/assessments/generate', data: {
        'jobTitle': p.jobTitle,
        if (p.jobDescription != null && p.jobDescription!.isNotEmpty)
          'jobDescription': p.jobDescription,
        'questionCount': p.questionCount,
        if (p.difficulty != null) 'difficulty': p.difficulty,
        if (p.title != null && p.title!.isNotEmpty) 'title': p.title,
        if (p.timeLimitSeconds != null) 'timeLimitSeconds': p.timeLimitSeconds,
      });
      return _assessmentFromJson(res.data!);
    });
  }

  @override
  Future<Assessment> updateAssessment(UpdateAssessmentParams p) {
    return _guard(() async {
      final body = <String, dynamic>{
        if (p.title != null) 'title': p.title,
        if (p.timeLimitSeconds != null) 'timeLimitSeconds': p.timeLimitSeconds,
        if (p.questions != null)
          'questions': p.questions!
              .map((q) => {
                    'text': q.text,
                    'options': q.options,
                    'correctOptionIndex': q.correctOptionIndex,
                  })
              .toList(),
      };
      final res = await _dio.put<Map<String, dynamic>>('/assessments/${p.id}', data: body);
      return _assessmentFromJson(res.data!);
    });
  }

  @override
  Future<void> deleteAssessment(String id) {
    return _guard(() => _dio.delete<void>('/assessments/$id'));
  }

  @override
  Future<PublicAssessment> getPublicTest(String token) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>('/tests/$token');
      return PublicAssessment.fromJson(res.data!);
    });
  }

  @override
  Future<JobOffer> assignAssessmentToJob({required String jobId, required String? assessmentId}) {
    return _guard(() async {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/job-offers/$jobId',
        data: {'assessmentId': assessmentId},
      );
      return _jobFromJson(res.data!);
    });
  }

  // ── Hard-skills test attempts & results ───────────────────────────────────

  @override
  Future<TestAttemptStarted> startTestAttempt(String jobOfferId) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/job-offers/$jobOfferId/test-attempts',
      );
      return TestAttemptStarted.fromJson(res.data!);
    });
  }

  @override
  Future<TestResult> submitTestAttempt({
    required String attemptId,
    required List<TestAttemptAnswer> answers,
  }) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>(
        '/test-attempts/$attemptId/submit',
        data: {'answers': answers.map((a) => a.toJson()).toList()},
      );
      return TestResult.fromJson(res.data!);
    });
  }

  @override
  Future<TestResult> abandonTestAttempt(String attemptId) {
    return _guard(() async {
      final res = await _dio.post<Map<String, dynamic>>('/test-attempts/$attemptId/abandon');
      return TestResult.fromJson(res.data!);
    });
  }

  @override
  Future<TestResult?> getMyTestResult(String jobOfferId) {
    return _guard(() async {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          '/job-offers/$jobOfferId/test-results/me',
        );
        return TestResult.fromJson(res.data!);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) return null;
        throw ApiException.fromDio(e);
      }
    });
  }

  @override
  Future<TestResultPage> getJobTestResults(String jobOfferId, {int page = 0, int size = 20}) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/job-offers/$jobOfferId/test-results',
        queryParameters: {'page': page, 'size': size},
      );
      return TestResultPage.fromJson(res.data!);
    });
  }

  @override
  Future<TestResultsSummary> getJobTestResultsSummary(String jobOfferId) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/job-offers/$jobOfferId/test-results/summary',
      );
      return TestResultsSummary.fromJson(res.data!);
    });
  }

  @override
  Future<TestResultDetail> getJobTestResultDetail({
    required String jobOfferId,
    required String candidateId,
  }) {
    return _guard(() async {
      final res = await _dio.get<Map<String, dynamic>>(
        '/job-offers/$jobOfferId/test-results/$candidateId',
      );
      return TestResultDetail.fromJson(res.data!);
    });
  }

  // --- mappers -------------------------------------------------------------

  static JobOffer _jobFromJson(Map<String, dynamic> json) {
    // companyName/companyInfo are joined at read time from the Identity actor
    // projection (`recruiter`), never stored on the offer (contract §5.2,
    // migrations V31/V32). `fieldOfWork`/`currency`/`remote` no longer exist on
    // the wire — kept on the entity for the editor, derived here.
    final recruiter = json['recruiter'] as Map<String, dynamic>? ?? const {};
    final workplace = WorkplaceType.fromString(json['workplaceType'] as String? ?? '');
    return JobOffer(
      id: json['id'] as String,
      recruiterId: json['recruiterId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      companyName: json['companyName'] as String? ??
          recruiter['companyName'] as String? ??
          '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      remote: json['remote'] as bool? ?? (workplace == WorkplaceType.remote),
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? 'EUR',
      salaryPeriod: SalaryPeriod.fromString(json['salaryPeriod'] as String?),
      currency: json['currency'] as String? ?? '',
      contractType: ContractType.fromString(json['contractType'] as String? ?? ''),
      workplaceType: workplace,
      experienceLevel:
          ExperienceLevel.fromString(json['experienceLevel'] as String? ?? ''),
      fieldOfWork: json['fieldOfWork'] as String? ?? '',
      description: json['description'] as String? ?? '',
      responsibilities: json['responsibilities'] as String? ?? '',
      minimumQualifications: json['minimumQualifications'] as String? ?? '',
      preferredQualifications: json['preferredQualifications'] as String? ?? '',
      whatWeOffer: json['whatWeOffer'] as String? ?? '',
      howToApply: json['howToApply'] as String? ?? '',
      companyInfo: json['companyInfo'] as String? ??
          recruiter['companyInfo'] as String? ??
          '',
      assessmentId: json['assessmentId'] as String?,
      jobPositionId: json['jobPositionId'] as String?,
      openToInternational: json['openToInternational'] as bool? ?? false,
      status: JobStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
      postedAt: json['postedAt'] != null
          ? DateTime.tryParse(json['postedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      applicantCount: (json['applicantCount'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toInt(),
      shareableLink: json['shareableLink'] as String?,
      // F16/F17/F19 (FITSCORE_REMEDIATION.md §3): null on the recruiter's own
      // offer list (no candidate context — "absent si non connecté" per the
      // contract), populated on the candidate-facing deck/search response.
      fitScore: (json['fitScore'] as num?)?.toInt(),
      hardSkillsAlert: HardSkillsAlertLevel.fromString(json['hardSkillsAlert'] as String?),
    );
  }

  static Assessment _assessmentFromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    return Assessment(
      id: json['id'] as String,
      recruiterId: json['recruiterId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      maxQuestions: (json['maxQuestions'] as num?)?.toInt() ?? 0,
      questions: rawQuestions.map((q) {
        final m = q as Map<String, dynamic>;
        return Question(
          id: m['id']?.toString() ?? '',
          order: (m['order'] as num?)?.toInt() ?? 0,
          text: m['text'] as String? ?? '',
          options: List<String>.from(m['options'] as List? ?? const []),
          correctOptionIndex: (m['correctOptionIndex'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      shareableLink: json['shareableLink'] as String?,
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
