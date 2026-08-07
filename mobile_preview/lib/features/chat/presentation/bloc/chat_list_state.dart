part of 'chat_list_bloc.dart';

enum ChatListStatus { initial, loading, ready, error }

class ChatListState extends Equatable {
  final ChatListStatus status;
  final ChatKind? kind; // null = All
  final List<ChatSummary> items;
  final String message;

  const ChatListState({
    this.status = ChatListStatus.initial,
    this.kind,
    this.items = const [],
    this.message = '',
  });

  ChatListState copyWith({
    ChatListStatus? status,
    ChatKind? kind,
    bool clearKind = false,
    List<ChatSummary>? items,
    String? message,
  }) {
    return ChatListState(
      status: status ?? this.status,
      kind: clearKind ? null : (kind ?? this.kind),
      items: items ?? this.items,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, kind, items, message];
}
