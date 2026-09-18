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

/// Périodicité du salaire affiché (maquette 213).
enum SalaryPeriod {
  monthly('MONTHLY'),
  yearly('YEARLY');

  final String value;
  const SalaryPeriod(this.value);

  static SalaryPeriod fromString(String? v) =>
      SalaryPeriod.values.firstWhere((e) => e.value == v, orElse: () => SalaryPeriod.monthly);

  String get label => this == SalaryPeriod.monthly ? 'Monthly' : 'Yearly';
  String get shortSuffix => this == SalaryPeriod.monthly ? '/Mo' : '/Yr';
}

/// Devises proposées par la maquette (maquette 213).
const List<String> kSalaryCurrencies = ['EUR', 'USD', 'GBP', 'MAD', 'TND'];

String salaryCurrencySymbol(String currency) {
  switch (currency) {
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'USD':
      return '\$';
    default:
      return '$currency ';
  }
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
  final String salaryCurrency;
  final SalaryPeriod salaryPeriod;
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

  /// F06 — métier du référentiel Fit Score. Le serveur le renvoie déjà ; le
  /// formulaire d'édition en a besoin pour rouvrir sur le bon métier.
  final String? jobPositionId;
  final bool openToInternational;
  final JobStatus status;
  final DateTime postedAt;

  /// Recruiter-facing stats joined by the backend for list/detail views.
  final int applicantCount;

  /// `%` of candidates who passed every evaluation. Null when unavailable.
  final int? successRate;

  /// Public share URL for the offer, when the backend provides one.
  final String? shareableLink;

  /// F17 — the candidate's Fit Score for this offer.
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
    this.salaryCurrency = 'EUR',
    this.salaryPeriod = SalaryPeriod.monthly,
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
    this.jobPositionId,
    required this.openToInternational,
    required this.status,
    required this.postedAt,
    this.applicantCount = 0,
    this.successRate,
    this.shareableLink,
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
    String? salaryCurrency,
    SalaryPeriod? salaryPeriod,
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
    String? jobPositionId,
    bool? openToInternational,
    JobStatus? status,
    DateTime? postedAt,
    int? applicantCount,
    int? successRate,
    String? shareableLink,
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
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
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
      jobPositionId: jobPositionId ?? this.jobPositionId,
      openToInternational: openToInternational ?? this.openToInternational,
      status: status ?? this.status,
      postedAt: postedAt ?? this.postedAt,
      applicantCount: applicantCount ?? this.applicantCount,
      successRate: successRate ?? this.successRate,
      shareableLink: shareableLink ?? this.shareableLink,
      fitScore: fitScore ?? this.fitScore,
      hardSkillsAlert: hardSkillsAlert ?? this.hardSkillsAlert,
    );
  }

  String get locationDisplay => '$city, $country';

  String get salaryDisplay {
    if (salaryMin <= 0 && salaryMax <= 0) return '';
    final symbol = salaryCurrencySymbol(salaryCurrency);
    String amount(double v) {
      if (v >= 1000) {
        final k = v / 1000;
        return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
      }
      return v.toStringAsFixed(0);
    }

    final range = (salaryMax <= 0 || salaryMax == salaryMin)
        ? '$symbol${amount(salaryMin)}'
        : '$symbol${amount(salaryMin)} - $symbol${amount(salaryMax)}';
    return '$range ${salaryPeriod.shortSuffix}';
  }

  @override
  List<Object?> get props => [
    id, recruiterId, title, companyName, city, country, remote,
    salaryMin, salaryMax, salaryCurrency, salaryPeriod, currency, contractType, workplaceType,
    experienceLevel, fieldOfWork, description, responsibilities,
    minimumQualifications, preferredQualifications, whatWeOffer,
    howToApply, companyInfo, assessmentId, jobPositionId, openToInternational,
    status, postedAt, applicantCount, successRate, shareableLink, fitScore,
    hardSkillsAlert,
  ];
}
