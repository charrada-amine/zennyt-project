import '../../domain/entities/help_message.dart';

class HelpMessageModel {
  final String id;
  final String helpChatId;
  final String text;
  final DateTime timestamp;
  final bool isFromUser;

  const HelpMessageModel({
    required this.id,
    required this.helpChatId,
    required this.text,
    required this.timestamp,
    required this.isFromUser,
  });

  factory HelpMessageModel.fromJson(Map<String, dynamic> json) {
    return HelpMessageModel(
      id: json['id'] as String,
      helpChatId: json['helpChatId'] as String,
      text: json['text'] as String,
      // Le serveur sérialise un Instant en ISO-8601 ; certaines réponses plus anciennes
      // portaient un epoch numérique. Ne gérer que le second faisait planter le parsing
      // sur une chaîne — même précaution que ChatModel.
      timestamp: json['timestamp'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timestamp'] as num).toDouble() ~/ 1 * 1000)
          : DateTime.parse(json['timestamp'] as String),
      isFromUser: json['isFromUser'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'helpChatId': helpChatId,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isFromUser': isFromUser,
      };

  HelpMessage toEntity() => HelpMessage(
        id: id,
        helpChatId: helpChatId,
        text: text,
        timestamp: timestamp,
        isFromUser: isFromUser,
      );
}
