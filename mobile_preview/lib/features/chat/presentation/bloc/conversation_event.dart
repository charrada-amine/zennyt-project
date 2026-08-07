part of 'conversation_bloc.dart';

sealed class ConversationEvent extends Equatable {
  const ConversationEvent();
  @override
  List<Object?> get props => [];
}

class ConversationStarted extends ConversationEvent {
  final String chatId;
  const ConversationStarted(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class MessageSent extends ConversationEvent {
  final String text;
  const MessageSent(this.text);
  @override
  List<Object?> get props => [text];
}

class OfferConfirmed extends ConversationEvent {
  const OfferConfirmed();
}

class OfferRejected extends ConversationEvent {
  const OfferRejected();
}
