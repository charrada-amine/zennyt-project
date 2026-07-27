import 'package:equatable/equatable.dart';

enum NotificationType {
  newJob,
  interestConfirmed,
  newComment,
  newLike,
  recommendedTraining,
  applicationRejected,
  applicationApproved,
  identityVerification,
  identityVerificationSuccess,
}

class AppNotification extends Equatable {
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

  const AppNotification({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        subtitle,
        createdAt,
        type,
        isRead,
        contactName,
        contactInitials,
        actionUrl,
        chatId,
      ];
}
