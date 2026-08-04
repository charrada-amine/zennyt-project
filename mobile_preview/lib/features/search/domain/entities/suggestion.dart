import 'package:equatable/equatable.dart';

/// Onglet de recherche : offres d'emploi ou professionnels.
enum SuggestionKind { jobOffer, professional }

/// Entité métier d'une suggestion de recherche — couvre les deux onglets.
///
/// - Offre (`jobOffer`)  : [name] = entreprise, [salary] renseigné.
/// - Pro   (`professional`) : [name] = personne, pas de [salary].
class Suggestion extends Equatable {
  final String id;
  final SuggestionKind kind;
  final int fitScore; // 0–100
  final String name; // "Google inc" ou "Alberta Flores"
  final String imageUrl; // logo entreprise ou avatar
  final String role; // "Developer" / "Developer | Senior"
  final String location;
  final List<String> tags;
  final String? salary; // "$25K/Mo" (offres uniquement)

  const Suggestion({
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

  @override
  List<Object?> get props =>
      [id, kind, fitScore, name, imageUrl, role, location, tags, salary];
}
