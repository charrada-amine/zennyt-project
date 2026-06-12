import '../../domain/entities/job.dart';

/// DTO de la couche data : sérialisation JSON + mapping vers l'entité domaine.
///
/// Séparé de l'entité [Job] pour que le domaine ne dépende pas du format de
/// l'API. Si le contrat OpenAPI change, seul ce modèle est impacté.
class JobModel {
  final String id;
  final String title;
  final String companyName;
  final String location;
  final bool remoteAllowed;
  final String contractType;
  final String experienceLevel;
  final String? salaryRange;
  final List<String> requiredSkills;
  final bool hasApplied;

  const JobModel({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.remoteAllowed,
    required this.contractType,
    required this.experienceLevel,
    this.salaryRange,
    this.requiredSkills = const [],
    this.hasApplied = false,
  });

  /// Aligné sur le schéma JobPost de contracts/recruitment.openapi.yaml.
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      companyName: json['companyName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      remoteAllowed: json['remoteAllowed'] as bool? ?? false,
      contractType: json['contractType'] as String? ?? '',
      experienceLevel: json['experienceLevel'] as String? ?? '',
      salaryRange: json['salaryRange'] as String?,
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hasApplied: json['hasApplied'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'companyName': companyName,
        'location': location,
        'remoteAllowed': remoteAllowed,
        'contractType': contractType,
        'experienceLevel': experienceLevel,
        'salaryRange': salaryRange,
        'requiredSkills': requiredSkills,
        'hasApplied': hasApplied,
      };

  /// Mapping DTO → entité domaine.
  Job toEntity() => Job(
        id: id,
        title: title,
        companyName: companyName,
        location: location,
        remoteAllowed: remoteAllowed,
        contractType: contractType,
        experienceLevel: experienceLevel,
        salaryRange: salaryRange,
        requiredSkills: requiredSkills,
        hasApplied: hasApplied,
      );
}
