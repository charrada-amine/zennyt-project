import '../../domain/entities/chat.dart';
import 'job_opportunity_model.dart';

/// DTO de la couche data : sérialisation JSON + mapping vers l'entité domaine.
///
/// Aligné sur le contrat OpenAPI `engagement.openapi.yaml` (Conversation schema).
class ConversationModel {
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
  final JobOpportunityModel? jobOpportunity;

  const ConversationModel({
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

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final jobOpportunityJson = json['jobOpportunity'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as String,
      applicationId: json['applicationId'] as String?,
      jobTitle: json['jobTitle'] as String?,
      counterpartName: json['counterpartName'] as String,
      counterpartId: json['counterpartId'] as String?,
      counterpartPhotoUrl: json['counterpartPhotoUrl'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch(
        (json['lastMessageAt'].toDouble() * 1000).toInt(),
      ),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isHiringContact: json['isHiringContact'] as bool? ?? false,
      jobOpportunity: jobOpportunityJson != null
          ? JobOpportunityModel.fromJson(jobOpportunityJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicationId': applicationId,
        'jobTitle': jobTitle,
        'counterpartName': counterpartName,
        'counterpartId': counterpartId,
        'counterpartPhotoUrl': counterpartPhotoUrl,
        'lastMessagePreview': lastMessagePreview,
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'unreadCount': unreadCount,
        'isHiringContact': isHiringContact,
        if (jobOpportunity != null) 'jobOpportunity': jobOpportunity!.toJson(),
      };

  /// Mapping DTO → entité domaine.
  Conversation toEntity() => Conversation(
        id: id,
        applicationId: applicationId,
        jobTitle: jobTitle,
        counterpartName: counterpartName,
        counterpartId: counterpartId,
        counterpartPhotoUrl: counterpartPhotoUrl,
        lastMessagePreview: lastMessagePreview,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
        isHiringContact: isHiringContact,
        jobOpportunity: jobOpportunity?.toEntity(),
      );
}
