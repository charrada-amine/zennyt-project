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
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['timestamp'].toDouble() * 1000).toInt(),
      ),
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
