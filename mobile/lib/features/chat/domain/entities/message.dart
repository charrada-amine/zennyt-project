import 'package:equatable/equatable.dart';

/// Rôle de l'expéditeur d'un message.
enum SenderRole { candidate, recruiter, system }

/// Type de contenu d'un message.
enum MessageContentType { text, image, file, system }

/// Entité métier Message — pure, sans dépendance framework ni sérialisation.
///
/// Alignée sur le contrat OpenAPI `engagement.openapi.yaml` (Message schema).
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final SenderRole senderRole;
  final String content;
  final MessageContentType contentType;
  final String? attachmentUrl;
  final DateTime sentAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.contentType = MessageContentType.text,
    this.attachmentUrl,
    required this.sentAt,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderRole,
        content,
        contentType,
        attachmentUrl,
        sentAt,
        readAt,
      ];
}