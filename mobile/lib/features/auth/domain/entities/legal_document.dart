import 'package:equatable/equatable.dart';

/// Document légal public (`GET /legal/{slug}`) : Conditions d'utilisation,
/// Politique de confidentialité.
class LegalSection extends Equatable {
  final String heading;
  final String body;

  const LegalSection({required this.heading, required this.body});

  factory LegalSection.fromJson(Map<String, dynamic> json) => LegalSection(
        heading: json['heading'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );

  @override
  List<Object?> get props => [heading, body];
}

class LegalDocument extends Equatable {
  final String slug;
  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.slug,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        lastUpdated: json['lastUpdated'] as String? ?? '',
        sections: (json['sections'] as List? ?? const [])
            .map((e) => LegalSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  @override
  List<Object?> get props => [slug, title, lastUpdated];
}
