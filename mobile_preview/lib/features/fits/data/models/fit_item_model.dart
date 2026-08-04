import '../../domain/entities/fit_item.dart';

/// DTO de la couche data : JSON + mapping vers l'entité [FitItem].
class FitItemModel {
  final String id;
  final FitKind kind;
  final int fitScore;
  final String name;
  final String imageUrl;
  final String role;
  final String location;
  final List<String> tags;
  final String? salary;
  final String? about;
  final String? targetRole;
  final List<String> softSkills;
  final List<String> hardSkills;
  final List<String> assessmentIds;

  const FitItemModel({
    required this.id,
    required this.kind,
    required this.fitScore,
    required this.name,
    required this.imageUrl,
    required this.role,
    required this.location,
    this.tags = const [],
    this.salary,
    this.about,
    this.targetRole,
    this.softSkills = const [],
    this.hardSkills = const [],
    this.assessmentIds = const [],
  });

  factory FitItemModel.fromJson(Map<String, dynamic> json) {
    List<String> strList(String k) =>
        (json[k] as List<dynamic>?)?.map((e) => e as String).toList() ??
        const [];
    return FitItemModel(
      id: json['id'] as String,
      kind: (json['kind'] as String? ?? 'jobOffer') == 'professional'
          ? FitKind.professional
          : FitKind.jobOffer,
      fitScore: json['fitScore'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      role: json['role'] as String? ?? '',
      location: json['location'] as String? ?? '',
      tags: strList('tags'),
      salary: json['salary'] as String?,
      about: json['about'] as String?,
      targetRole: json['targetRole'] as String?,
      softSkills: strList('softSkills'),
      hardSkills: strList('hardSkills'),
      assessmentIds: strList('assessmentIds'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'fitScore': fitScore,
        'name': name,
        'imageUrl': imageUrl,
        'role': role,
        'location': location,
        'tags': tags,
        'salary': salary,
        'about': about,
        'targetRole': targetRole,
        'softSkills': softSkills,
        'hardSkills': hardSkills,
        'assessmentIds': assessmentIds,
      };

  FitItem toEntity() => FitItem(
        id: id,
        kind: kind,
        fitScore: fitScore,
        name: name,
        imageUrl: imageUrl,
        role: role,
        location: location,
        tags: tags,
        salary: salary,
        about: about,
        targetRole: targetRole,
        softSkills: softSkills,
        hardSkills: hardSkills,
        assessmentIds: assessmentIds,
      );
}
