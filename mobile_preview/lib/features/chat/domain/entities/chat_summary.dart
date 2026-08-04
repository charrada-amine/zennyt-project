import 'package:equatable/equatable.dart';

enum ChatKind { jobOffer, professional }

/// Résumé d'une conversation dans la liste des chats.
class ChatSummary extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final ChatKind kind;
  final bool hiringContact;
  final bool hasOffer; // affiche une carte "Job Opportunity"
  final String? offerRole;
  final String? offerSalary;

  const ChatSummary({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.kind,
    this.hiringContact = false,
    this.hasOffer = false,
    this.offerRole,
    this.offerSalary,
  });

  @override
  List<Object?> get props =>
      [id, name, avatarUrl, lastMessage, kind, hiringContact, hasOffer, offerRole, offerSalary];
}
