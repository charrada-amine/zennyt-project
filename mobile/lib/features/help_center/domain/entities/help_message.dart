import 'package:equatable/equatable.dart';

class HelpMessage extends Equatable {
  final String id;
  final String helpChatId;
  final String text;
  final DateTime timestamp;
  final bool isFromUser;

  const HelpMessage({
    required this.id,
    required this.helpChatId,
    required this.text,
    required this.timestamp,
    required this.isFromUser,
  });

  @override
  List<Object?> get props => [id, helpChatId, text, timestamp, isFromUser];
}
