import '../../domain/entities/suggestion.dart';

/// DTO de la couche data : sérialisation JSON + mapping vers l'entité domaine.
class SuggestionModel {
  final String id;
  final SuggestionKind kind;
  final int fitScore;
  final String name;
  final String imageUrl;
  final String role;
  final String location;
  final List<String> tags;
  final String? salary;

  const SuggestionModel({
    required this.id,
    required this.kind,
    required this.fitScore,
    required this.name,
    required this.imageUrl,
    required this.role,
    required this.location,
    this.tags = const [],
    this.salary,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String,
      kind: (json['kind'] as String? ?? 'jobOffer') == 'professional'
          ? SuggestionKind.professional
          : SuggestionKind.jobOffer,
      fitScore: json['fitScore'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      role: json['role'] as String? ?? '',
      location: json['location'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      salary: json['salary'] as String?,
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
      };

  Suggestion toEntity() => Suggestion(
        id: id,
        kind: kind,
        fitScore: fitScore,
        name: name,
        imageUrl: imageUrl,
        role: role,
        location: location,
        tags: tags,
        salary: salary,
      );
}
