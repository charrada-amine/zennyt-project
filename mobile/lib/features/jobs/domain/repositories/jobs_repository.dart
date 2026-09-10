import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import '../entities/job.dart' show ContractType, WorkplaceType, ExperienceLevel, JobStatus, JobOffer;
import 'package:zennyt/features/jobs/domain/entities/job_position.dart';

/// Abstraction over the recruitment API's job-offer and assessment
/// management endpoints. Implementations throw typed `ApiException`s.
abstract class JobsRepository {
  Future<List<JobOffer>> getJobOffers();
  Future<JobOffer> getJobOfferById(String id);
  Future<JobOffer> createJobOffer(CreateJobOfferParams params);
  Future<JobOffer> updateJobOffer(UpdateJobOfferParams params);
  Future<void> deleteJobOffer(String id);

  /// F06/F30 — le référentiel des métiers et sa pondération. Sans le premier, aucune
  /// offre ne peut être créée ; sans le second, le recruteur ne voit pas ce que son
  /// choix de métier et de niveau implique pour le score.
  Future<List<JobPosition>> getJobPositions();
  Future<List<JobRoleProfile>> getJobRoleProfiles();

  Future<List<Assessment>> getAssessments();
  Future<Assessment> getAssessmentById(String id);
  Future<Assessment> createAssessment(CreateAssessmentParams params);
  Future<Assessment> generateAssessmentAi(GenerateAssessmentAiParams params);
  Future<Assessment> updateAssessment(UpdateAssessmentParams params);
  Future<void> deleteAssessment(String id);

  Future<JobOffer> assignAssessmentToJob({
    required String jobId,
    required String? assessmentId,
  });
}

class CreateJobOfferParams {
  final String title;
  final String companyName;
  final String city;
  final String country;
  final bool remote;
  final double salaryMin;
  final double salaryMax;
  final String currency;
  final ContractType contractType;
  final WorkplaceType workplaceType;
  final ExperienceLevel experienceLevel;
  final String fieldOfWork;
  final String description;
  final String responsibilities;
  final String minimumQualifications;
  final String preferredQualifications;
  final String whatWeOffer;
  final String howToApply;
  final String companyInfo;
  final String? assessmentId;
  final bool openToInternational;

  /// F06 (FITSCORE_REMEDIATION.md §3 index F06) — obligatoire côté serveur depuis
  /// la suppression du repli IA : sans métier, la formule n'a aucune pondération.
  /// Le champ était câblé mais aucun écran ne le renseignait — donc toujours `null`,
  /// donc toute création échouait. Le sélecteur de métier existe désormais.
  final String? jobPositionId;

  const CreateJobOfferParams({
    required this.title,
    required this.companyName,
    required this.city,
    required this.country,
    required this.remote,
    required this.salaryMin,
    required this.salaryMax,
    required this.currency,
    required this.contractType,
    required this.workplaceType,
    required this.experienceLevel,
    required this.fieldOfWork,
    required this.description,
    required this.responsibilities,
    required this.minimumQualifications,
    required this.preferredQualifications,
    required this.whatWeOffer,
    required this.howToApply,
    required this.companyInfo,
    this.assessmentId,
    required this.openToInternational,
    this.jobPositionId,
  });
}

class UpdateJobOfferParams {
  final String id;
  final String? title;
  final String? companyName;
  final String? city;
  final String? country;
  final bool? remote;
  final double? salaryMin;
  final double? salaryMax;
  final String? currency;
  final ContractType? contractType;
  final WorkplaceType? workplaceType;
  final ExperienceLevel? experienceLevel;
  final String? fieldOfWork;
  final String? description;
  final String? responsibilities;
  final String? minimumQualifications;
  final String? preferredQualifications;
  final String? whatWeOffer;
  final String? howToApply;
  final String? companyInfo;
  final String? assessmentId;
  final bool? openToInternational;
  final JobStatus? status;

  const UpdateJobOfferParams({
    required this.id,
    this.title,
    this.companyName,
    this.city,
    this.country,
    this.remote,
    this.salaryMin,
    this.salaryMax,
    this.currency,
    this.contractType,
    this.workplaceType,
    this.experienceLevel,
    this.fieldOfWork,
    this.description,
    this.responsibilities,
    this.minimumQualifications,
    this.preferredQualifications,
    this.whatWeOffer,
    this.howToApply,
    this.companyInfo,
    this.assessmentId,
    this.openToInternational,
    this.status,
  });
}

class CreateQuestionParams {
  final String text;
  final List<String> options;
  final int correctOptionIndex;

  const CreateQuestionParams({
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });
}

class CreateAssessmentParams {
  final String title;
  final int timeLimitSeconds;
  final List<CreateQuestionParams> questions;

  const CreateAssessmentParams({
    required this.title,
    required this.timeLimitSeconds,
    required this.questions,
  });
}

/// Génération IA — pas encore disponible sur le backend intégré
/// (POST /assessments/generate absent, cf. PLAN_FITSCORE_V3.md Phase 0).
/// L'appel échoue avec une ApiException claire tant que la route n'existe pas.
class GenerateAssessmentAiParams {
  final String jobTitle;
  final String? jobDescription;
  final int questionCount;
  final String? difficulty;
  final String? title;
  final int? timeLimitSeconds;

  const GenerateAssessmentAiParams({
    required this.jobTitle,
    this.jobDescription,
    this.questionCount = 5,
    this.difficulty,
    this.title,
    this.timeLimitSeconds,
  });
}

class UpdateAssessmentParams {
  final String id;
  final String? title;
  final int? timeLimitSeconds;
  final List<CreateQuestionParams>? questions;

  const UpdateAssessmentParams({
    required this.id,
    this.title,
    this.timeLimitSeconds,
    this.questions,
  });
}

class AssignAssessmentParams {
  final String jobId;
  final String? assessmentId;

  const AssignAssessmentParams({required this.jobId, this.assessmentId});
}
