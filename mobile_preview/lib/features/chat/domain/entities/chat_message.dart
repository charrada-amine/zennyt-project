import 'package:equatable/equatable.dart';

/// Un message dans une conversation.
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool fromMe;
  final String time;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.time,
  });

  @override
  List<Object?> get props => [id, text, fromMe, time];
}
