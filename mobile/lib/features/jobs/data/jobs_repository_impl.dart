import 'package:dio/dio.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
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
        'companyName': p.companyName,
        'city': p.city,
        'country': p.country,
        'remote': p.remote,
        'salaryMin': p.salaryMin,
        'salaryMax': p.salaryMax,
        'currency': p.currency,
        'contractType': p.contractType.value,
        'workplaceType': p.workplaceType.value,
        'experienceLevel': p.experienceLevel.value,
        'fieldOfWork': p.fieldOfWork,
        'description': p.description,
        'responsibilities': p.responsibilities,
        'minimumQualifications': p.minimumQualifications,
        'preferredQualifications': p.preferredQualifications,
        'whatWeOffer': p.whatWeOffer,
        'howToApply': p.howToApply,
        'companyInfo': p.companyInfo,
        'openToInternational': p.openToInternational,
      });
      return _jobFromJson(res.data!);
    });
  }

  @override
  Future<JobOffer> updateJobOffer(UpdateJobOfferParams p) {
    return _guard(() async {
      final body = <String, dynamic>{
        if (p.title != null) 'title': p.title,
        if (p.companyName != null) 'companyName': p.companyName,
        if (p.city != null) 'city': p.city,
        if (p.country != null) 'country': p.country,
        if (p.remote != null) 'remote': p.remote,
        if (p.salaryMin != null) 'salaryMin': p.salaryMin,
        if (p.salaryMax != null) 'salaryMax': p.salaryMax,
        if (p.currency != null) 'currency': p.currency,
        if (p.contractType != null) 'contractType': p.contractType!.value,
        if (p.workplaceType != null) 'workplaceType': p.workplaceType!.value,
        if (p.experienceLevel != null) 'experienceLevel': p.experienceLevel!.value,
        if (p.fieldOfWork != null) 'fieldOfWork': p.fieldOfWork,
        if (p.description != null) 'description': p.description,
        if (p.responsibilities != null) 'responsibilities': p.responsibilities,
        if (p.minimumQualifications != null) 'minimumQualifications': p.minimumQualifications,
        if (p.preferredQualifications != null) 'preferredQualifications': p.preferredQualifications,
        if (p.whatWeOffer != null) 'whatWeOffer': p.whatWeOffer,
        if (p.howToApply != null) 'howToApply': p.howToApply,
        if (p.companyInfo != null) 'companyInfo': p.companyInfo,
        if (p.assessmentId != null) 'assessmentId': p.assessmentId,
        if (p.openToInternational != null) 'openToInternational': p.openToInternational,
        if (p.status != null) 'status': p.status!.value,
      };
      final res = await _dio.patch<Map<String, dynamic>>('/job-offers/${p.id}', data: body);
      return _jobFromJson(res.data!);
    });
  }

  @override
  Future<void> deleteJobOffer(String id) {
    return _guard(() => _dio.delete<void>('/job-offers/$id'));
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
  Future<JobOffer> assignAssessmentToJob({required String jobId, required String? assessmentId}) {
    return _guard(() async {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/job-offers/$jobId',
        data: {'assessmentId': assessmentId},
      );
      return _jobFromJson(res.data!);
    });
  }

  // --- mappers -------------------------------------------------------------

  static JobOffer _jobFromJson(Map<String, dynamic> json) => JobOffer(
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
        openToInternational: json['openToInternational'] as bool? ?? false,
        status: JobStatus.fromString(json['status'] as String? ?? 'ACTIVE'),
        postedAt: json['postedAt'] != null
            ? DateTime.tryParse(json['postedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

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
