import 'package:equatable/equatable.dart';

/// Appreciation portee sur un echange avec le support.
enum HelpChatRating { poor, ok, great }

extension HelpChatRatingX on HelpChatRating {
  /// Le jeton attendu par le serveur (POOR / OK / GREAT).
  String get wireValue => name.toUpperCase();

  static HelpChatRating? fromWire(String? value) {
    if (value == null) return null;
    for (final rating in HelpChatRating.values) {
      if (rating.wireValue == value) return rating;
    }
    return null;
  }
}

class HelpChat extends Equatable {
  final String id;
  final String title;
  final String subtitle;

  /// Date du dernier message. Nulle tant que la conversation vient d'etre ouverte :
  /// le serveur ne la renseigne qu'au premier message echange.
  final DateTime? lastMessageAt;

  final HelpChatRating? rating;
  final String? ratingComment;

  const HelpChat({
    required this.id,
    required this.title,
    required this.subtitle,
    this.lastMessageAt,
    this.rating,
    this.ratingComment,
  });

  bool get isRated => rating != null;

  @override
  List<Object?> get props => [id, title, subtitle, lastMessageAt, rating];
}
