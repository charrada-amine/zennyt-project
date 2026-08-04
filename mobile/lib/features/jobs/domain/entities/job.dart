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

enum ExperienceLevel {
  junior('JUNIOR'),
  mid('MID'),
  senior('SENIOR'),
  executive('EXECUTIVE');

  final String value;
  const ExperienceLevel(this.value);

  static ExperienceLevel fromString(String v) =>
      ExperienceLevel.values.firstWhere((e) => e.value == v, orElse: () => ExperienceLevel.junior);

  String get label {
    switch (this) {
      case ExperienceLevel.junior: return 'Junior';
      case ExperienceLevel.mid: return 'Mid';
      case ExperienceLevel.senior: return 'Senior';
      case ExperienceLevel.executive: return 'Executive';
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
    status, postedAt,
  ];
}
