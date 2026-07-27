import '../../domain/entities/message.dart';

/// DTO de la couche data : sérialisation JSON + mapping vers l'entité domaine.
///
/// Aligné sur le contrat OpenAPI `engagement.openapi.yaml` (Message schema).
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final SenderRole senderRole;
  final String content;
  final MessageContentType contentType;
  final String? attachmentUrl;
  final DateTime sentAt;
  final DateTime? readAt;

  const MessageModel({
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

  static SenderRole _parseSenderRole(String? value) {
    switch (value) {
      case 'CANDIDATE':
        return SenderRole.candidate;
      case 'RECRUITER':
        return SenderRole.recruiter;
      case 'SYSTEM':
        return SenderRole.system;
      default:
        return SenderRole.candidate;
    }
  }

  static String _senderRoleToString(SenderRole role) {
    switch (role) {
      case SenderRole.candidate:
        return 'CANDIDATE';
      case SenderRole.recruiter:
        return 'RECRUITER';
      case SenderRole.system:
        return 'SYSTEM';
    }
  }

  static MessageContentType _parseContentType(String? value) {
    switch (value) {
      case 'TEXT':
        return MessageContentType.text;
      case 'IMAGE':
        return MessageContentType.image;
      case 'FILE':
        return MessageContentType.file;
      case 'SYSTEM':
        return MessageContentType.system;
      default:
        return MessageContentType.text;
    }
  }

  static String _contentTypeToString(MessageContentType type) {
    switch (type) {
      case MessageContentType.text:
        return 'TEXT';
      case MessageContentType.image:
        return 'IMAGE';
      case MessageContentType.file:
        return 'FILE';
      case MessageContentType.system:
        return 'SYSTEM';
    }
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderRole: _parseSenderRole(json['senderRole'] as String?),
      content: json['content'] as String,
      contentType: _parseContentType(json['contentType'] as String?),
      attachmentUrl: json['attachmentUrl'] as String?,
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        (json['sentAt'].toDouble() * 1000).toInt(),
      ),
      readAt: json['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['readAt'].toDouble() * 1000).toInt(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderRole': _senderRoleToString(senderRole),
        'content': content,
        'contentType': _contentTypeToString(contentType),
        'attachmentUrl': attachmentUrl,
        'sentAt': sentAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  /// Mapping DTO → entité domaine.
  Message toEntity() => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderRole: senderRole,
        content: content,
        contentType: contentType,
        attachmentUrl: attachmentUrl,
        sentAt: sentAt,
        readAt: readAt,
      );
}

/// DTO pour la création d'un message (corps de requête POST).
class MessageCreateModel {
  final String content;
  final MessageContentType contentType;
  final String? attachmentUrl;

  const MessageCreateModel({
    required this.content,
    this.contentType = MessageContentType.text,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'contentType': MessageModel._contentTypeToString(contentType),
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      };
}
