import 'package:equatable/equatable.dart';

/// Type de carte dans le deck "Fits" : offre d'emploi ou professionnel.
enum FitKind { jobOffer, professional }

/// Élément du deck "Fits" — couvre une offre (candidat qui swipe) ou un
/// professionnel (recruteur qui swipe). Pur, sans framework.
class FitItem extends Equatable {
  final String id;
  final FitKind kind;
  final int fitScore; // 0–100
  final String name; // "Google inc" ou "Alberta Flores"
  final String imageUrl; // logo ou avatar
  final String role; // "UX/UI Designer" / "Developer | Senior"
  final String location;
  final List<String> tags;

  // Offre uniquement
  final String? salary; // "$15K/Mo"
  final String? about; // "About the job" texte

  // Professionnel uniquement
  final String? targetRole; // "UX Designer | Senior"
  final List<String> softSkills; // ex. "Decision Making: High"
  final List<String> hardSkills; // ex. "InDesign: 88%"

  // Offre uniquement : tests rattachés (pour lancer une tentative côté candidat).
  final List<String> assessmentIds;

  const FitItem({
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

  @override
  List<Object?> get props => [
        id, kind, fitScore, name, imageUrl, role, location, tags,
        salary, about, targetRole, softSkills, hardSkills, assessmentIds,
      ];
}
