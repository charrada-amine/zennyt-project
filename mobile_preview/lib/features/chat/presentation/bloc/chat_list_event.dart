part of 'chat_list_bloc.dart';

sealed class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => [];
}

class ChatListStarted extends ChatListEvent {
  const ChatListStarted();
}

/// [kind] null = onglet "All".
class ChatTabChanged extends ChatListEvent {
  final ChatKind? kind;
  const ChatTabChanged(this.kind);
  @override
  List<Object?> get props => [kind];
}
