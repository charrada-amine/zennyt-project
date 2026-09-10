import '../../domain/entities/help_chat.dart';

class HelpChatModel {
  final String id;
  final String title;
  final String subtitle;
  final DateTime? lastMessageAt;
  final String? rating;
  final String? ratingComment;

  const HelpChatModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.lastMessageAt,
    this.rating,
    this.ratingComment,
  });

  /// Le champ lu etait `time`, que le serveur n'envoie pas : il expose `lastMessageAt`,
  /// nullable. Le cast echouait donc des la premiere conversation reelle — le defaut
  /// restait invisible tant que la table etait vide.
  factory HelpChatModel.fromJson(Map<String, dynamic> json) {
    final horodatage = json['lastMessageAt'];
    return HelpChatModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      lastMessageAt: horodatage == null
          ? null
          : (horodatage is num
              ? DateTime.fromMillisecondsSinceEpoch((horodatage * 1000).toInt())
              : DateTime.parse(horodatage as String)),
      rating: json['rating'] as String?,
      ratingComment: json['ratingComment'] as String?,
    );
  }

  HelpChat toEntity() => HelpChat(
        id: id,
        title: title,
        subtitle: subtitle,
        lastMessageAt: lastMessageAt,
        rating: HelpChatRatingX.fromWire(rating),
        ratingComment: ratingComment,
      );
}
