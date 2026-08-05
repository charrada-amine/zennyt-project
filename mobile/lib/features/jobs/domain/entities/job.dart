import 'package:equatable/equatable.dart';

enum ContractType {
  fullTime('FULL_TIME'),
  partTime('PART_TIME'),
  contract('CONTRACT'),
  temporary('TEMPORARY'),
  apprenticeship('APPRENTICESHIP'),
  volunteer('VOLUNTEER');

  final String value;
  const ContractType(this.value);

  static ContractType fromString(String v) =>
      ContractType.values.firstWhere((e) => e.value == v, orElse: () => ContractType.fullTime);

  String get label {
    switch (this) {
      case ContractType.fullTime: return 'Full time';
      case ContractType.partTime: return 'Part time';
      case ContractType.contract: return 'Contract';
      case ContractType.temporary: return 'Temporary';
      case ContractType.apprenticeship: return 'Apprenticeship';
      case ContractType.volunteer: return 'Volunteer';
    }
  }
}

enum WorkplaceType {
  onSite('ON_SITE'),
  hybrid('HYBRID'),
  remote('REMOTE');

  final String value;
  const WorkplaceType(this.value);

  static WorkplaceType fromString(String v) =>
      WorkplaceType.values.firstWhere((e) => e.value == v, orElse: () => WorkplaceType.onSite);

  String get label {
    switch (this) {
      case WorkplaceType.onSite: return 'On site';
      case WorkplaceType.hybrid: return 'Hybrid';
      case WorkplaceType.remote: return 'Remote';
    }
  }
}

/// Les 4 bandes de la matrice de pondération Fit Score (CdC v3 §4.1).
///
/// Changement cassant du 2026-08-04 (décision D-A, tâche F31) : retour à
/// l'échelle du cahier des charges. MID -> SENIOR, SENIOR -> LEAD,
/// EXECUTIVE -> MANAGER. Le pic du poids hard skills est désormais porté par
/// SENIOR, comme le prévoit le CdC.
enum ExperienceLevel {
  junior('JUNIOR'),
  senior('SENIOR'),
  lead('LEAD'),
  manager('MANAGER');

  final String value;
  const ExperienceLevel(this.value);

  static ExperienceLevel fromString(String v) =>
      ExperienceLevel.values.firstWhere((e) => e.value == v, orElse: () => ExperienceLevel.junior);

  String get label {
    switch (this) {
      case ExperienceLevel.junior: return 'Junior';
      case ExperienceLevel.senior: return 'Senior';
      case ExperienceLevel.lead: return 'Lead';
      case ExperienceLevel.manager: return 'Manager';
    }
  }
}

enum JobStatus {
  active('ACTIVE'),
  closed('CLOSED'),
  draft('DRAFT');

  final String value;
  const JobStatus(this.value);

  static JobStatus fromString(String v) =>
      JobStatus.values.firstWhere((e) => e.value == v, orElse: () => JobStatus.active);
}

/// F19 (FITSCORE_REMEDIATION.md §3 index F19) — informational only, never
/// used in the Fit Score calculation. PORTFOLIO_BASED is distinct from INFO:
/// it means "no QCM is expected for this creative role, that's normal," not
/// "consider adding one."
enum HardSkillsAlertLevel {
  none('NONE'),
  info('INFO'),
  moderate('MODERATE'),
  strong('STRONG'),
  portfolioBased('PORTFOLIO_BASED');

  final String value;
  const HardSkillsAlertLevel(this.value);

  static HardSkillsAlertLevel fromString(String? v) => HardSkillsAlertLevel.values
      .firstWhere((e) => e.value == v, orElse: () => HardSkillsAlertLevel.none);
}

class JobOffer extends Equatable {
  final String id;
  final String recruiterId;
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
  final JobStatus status;
  final DateTime postedAt;

  /// F17 (FITSCORE_REMEDIATION.md §3 index F17) — the candidate's Fit Score for
  /// this offer. "Absent si non connecté" per the contract: null on the
  /// recruiter's own offer list (no candidate context), populated on the
  /// candidate-facing deck/search results.
  final int? fitScore;

  /// F16/F19/F29 (FITSCORE_REMEDIATION.md §3) — recruiter-facing signal: is a
  /// hard-skills QCM missing where this offer's métier/level would expect
  /// one. Defaults to `none` when absent from the response.
  final HardSkillsAlertLevel hardSkillsAlert;

  const JobOffer({
    required this.id,
    required this.recruiterId,
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
    required this.status,
    required this.postedAt,
    this.fitScore,
    this.hardSkillsAlert = HardSkillsAlertLevel.none,
  });

  JobOffer copyWith({
    String? id,
    String? recruiterId,
    String? title,
    String? companyName,
    String? city,
    String? country,
    bool? remote,
    double? salaryMin,
    double? salaryMax,
    String? currency,
    ContractType? contractType,
    WorkplaceType? workplaceType,
    ExperienceLevel? experienceLevel,
    String? fieldOfWork,
    String? description,
    String? responsibilities,
    String? minimumQualifications,
    String? preferredQualifications,
    String? whatWeOffer,
    String? howToApply,
    String? companyInfo,
    String? assessmentId,
    bool? openToInternational,
    JobStatus? status,
    DateTime? postedAt,
    int? fitScore,
    HardSkillsAlertLevel? hardSkillsAlert,
  }) {
    return JobOffer(
      id: id ?? this.id,
      recruiterId: recruiterId ?? this.recruiterId,
      title: title ?? this.title,
      companyName: companyName ?? this.companyName,
      city: city ?? this.city,
      country: country ?? this.country,
      remote: remote ?? this.remote,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      currency: currency ?? this.currency,
      contractType: contractType ?? this.contractType,
      workplaceType: workplaceType ?? this.workplaceType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      fieldOfWork: fieldOfWork ?? this.fieldOfWork,
      description: description ?? this.description,
      responsibilities: responsibilities ?? this.responsibilities,
      minimumQualifications: minimumQualifications ?? this.minimumQualifications,
      preferredQualifications: preferredQualifications ?? this.preferredQualifications,
      whatWeOffer: whatWeOffer ?? this.whatWeOffer,
      howToApply: howToApply ?? this.howToApply,
      companyInfo: companyInfo ?? this.companyInfo,
      assessmentId: assessmentId ?? this.assessmentId,
      openToInternational: openToInternational ?? this.openToInternational,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
      fitScore: fitScore ?? this.fitScore,
      hardSkillsAlert: hardSkillsAlert ?? this.hardSkillsAlert,
    );
  }

  String get locationDisplay => '$city, $country';

  String get salaryDisplay {
    if (salaryMin == salaryMax) return '\$$salaryMin$currency';
    return '\$$salaryMin - \$$salaryMax$currency';
  }

  @override
  List<Object?> get props => [
    id, recruiterId, title, companyName, city, country, remote,
    salaryMin, salaryMax, currency, contractType, workplaceType,
    experienceLevel, fieldOfWork, description, responsibilities,
    minimumQualifications, preferredQualifications, whatWeOffer,
    howToApply, companyInfo, assessmentId, openToInternational,
    status, postedAt, fitScore, hardSkillsAlert,
  ];
}
