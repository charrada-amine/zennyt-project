import '../../domain/entities/help_chat.dart';

class HelpChatModel {
  final String id;
  final String title;
  final String subtitle;
  final String time;

  const HelpChatModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  factory HelpChatModel.fromJson(Map<String, dynamic> json) {
    return HelpChatModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      time: json['time'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'time': time,
      };

  HelpChat toEntity() => HelpChat(
        id: id,
        title: title,
        subtitle: subtitle,
        time: time,
      );
}
