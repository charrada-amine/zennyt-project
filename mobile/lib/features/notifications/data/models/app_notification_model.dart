import '../../domain/entities/app_notification.dart';

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String? subtitle;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String? contactName;
  final String? contactInitials;
  final String? actionUrl;
  final String? chatId;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.contactName,
    this.contactInitials,
    this.actionUrl,
    this.chatId,
  });

  static NotificationType _parseType(String? value) {
    switch (value) {
      case 'NEW_JOB':
        return NotificationType.newJob;
      case 'JOB_MATCH':
        return NotificationType.newJob;
      case 'INTEREST_CONFIRMED':
        return NotificationType.interestConfirmed;
      case 'PROFILE_VIEWED':
        return NotificationType.interestConfirmed;
      case 'NEW_COMMENT':
        return NotificationType.newComment;
      case 'NEW_LIKE':
        return NotificationType.newLike;
      case 'RECOMMENDED_TRAINING':
        return NotificationType.recommendedTraining;
      case 'APPLICATION_REJECTED':
        return NotificationType.applicationRejected;
      case 'APPLICATION_APPROVED':
        return NotificationType.applicationApproved;
      // New contract values — map to closest legacy icon
      case 'APPLICATION_VIEWED':
        return NotificationType.applicationApproved;
      case 'APPLICATION_STATUS_CHANGED':
        return NotificationType.applicationApproved;
      case 'NEW_MESSAGE':
        return NotificationType.newJob;
      case 'IDENTITY_VERIFICATION':
        return NotificationType.identityVerification;
      case 'IDENTITY_VERIFICATION_SUCCESS':
        return NotificationType.identityVerificationSuccess;
      default:
        return NotificationType.newJob;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.newJob:
        return 'NEW_JOB';
      case NotificationType.interestConfirmed:
        return 'INTEREST_CONFIRMED';
      case NotificationType.newComment:
        return 'NEW_COMMENT';
      case NotificationType.newLike:
        return 'NEW_LIKE';
      case NotificationType.recommendedTraining:
        return 'RECOMMENDED_TRAINING';
      case NotificationType.applicationRejected:
        return 'APPLICATION_REJECTED';
      case NotificationType.applicationApproved:
        return 'APPLICATION_APPROVED';
      case NotificationType.identityVerification:
        return 'IDENTITY_VERIFICATION';
      case NotificationType.identityVerificationSuccess:
        return 'IDENTITY_VERIFICATION_SUCCESS';
    }
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'];

    final parsedDate = rawDate is num
        ? (rawDate < 10000000000
              ? DateTime.fromMillisecondsSinceEpoch((rawDate * 1000).toInt())
              : DateTime.fromMillisecondsSinceEpoch(rawDate.toInt()))
        : DateTime.parse(rawDate as String);

    return AppNotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String,
      // Backend contract uses `body` (OpenAPI) — older mock uses `subtitle`. Accept both.
      subtitle: (json['subtitle'] as String?) ?? (json['body'] as String?),
      createdAt: parsedDate,
      type: _parseType(json['type'] as String?),
      // Backend serialises as `isRead` via @JsonProperty("isRead") — be tolerant to `read`
      isRead: (json['isRead'] as bool?) ?? (json['read'] as bool?) ?? false,
      contactName: json['contactName'] as String?,
      contactInitials: json['contactInitials'] as String?,
      actionUrl: json['actionUrl'] as String?,
      chatId: json['chatId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'subtitle': subtitle,
    'createdAt': createdAt.toIso8601String(),
    'type': _typeToString(type),
    'isRead': isRead,
    'contactName': contactName,
    'contactInitials': contactInitials,
    'actionUrl': actionUrl,
    'chatId': chatId,
  };

  AppNotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? subtitle,
    DateTime? createdAt,
    NotificationType? type,
    bool? isRead,
    String? contactName,
    String? contactInitials,
    String? actionUrl,
    String? chatId,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      contactName: contactName ?? this.contactName,
      contactInitials: contactInitials ?? this.contactInitials,
      actionUrl: actionUrl ?? this.actionUrl,
      chatId: chatId ?? this.chatId,
    );
  }

  AppNotification toEntity() => AppNotification(
    id: id,
    userId: userId,
    title: title,
    subtitle: subtitle,
    createdAt: createdAt,
    type: type,
    isRead: isRead,
    contactName: contactName,
    contactInitials: contactInitials,
    actionUrl: actionUrl,
    chatId: chatId,
  );
}
