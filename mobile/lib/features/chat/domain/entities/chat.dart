import 'package:equatable/equatable.dart';
import 'job_opportunity.dart';

/// Entité métier Conversation — pure, sans dépendance framework ni sérialisation.
///
/// Alignée sur le contrat OpenAPI `engagement.openapi.yaml` (Conversation schema).
/// Le backend renvoie uniquement les conversations de l'utilisateur connecté
/// (filtrage implicite via JWT).
class Conversation extends Equatable {
  final String id;
  final String? applicationId;
  final String? jobTitle;
  final String counterpartName;
  final String? counterpartId;
  final String? counterpartPhotoUrl;
  final String lastMessagePreview;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isHiringContact;
  final JobOpportunity? jobOpportunity;

  const Conversation({
    required this.id,
    this.applicationId,
    this.jobTitle,
    required this.counterpartName,
    this.counterpartId,
    this.counterpartPhotoUrl,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isHiringContact = false,
    this.jobOpportunity,
  });

  @override
  List<Object?> get props => [
        id,
        applicationId,
        jobTitle,
        counterpartName,
        counterpartId,
        counterpartPhotoUrl,
        lastMessagePreview,
        lastMessageAt,
        unreadCount,
        isHiringContact,
        jobOpportunity,
      ];
}
