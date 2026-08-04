import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_summary.dart';
import '../../domain/usecases/get_chats.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChats getChats;

  ChatListBloc({required this.getChats}) : super(const ChatListState()) {
    on<ChatListStarted>((e, emit) => _load(emit, state.kind),
        transformer: restartable());
    on<ChatTabChanged>((e, emit) => _load(emit, e.kind),
        transformer: restartable());
  }

  Future<void> _load(Emitter<ChatListState> emit, ChatKind? kind) async {
    emit(state.copyWith(status: ChatListStatus.loading, kind: kind, clearKind: kind == null));
    final result = await getChats(GetChatsParams(kind: kind));
    result.fold(
      (f) => emit(state.copyWith(status: ChatListStatus.error, message: f.message)),
      (items) => emit(state.copyWith(status: ChatListStatus.ready, items: items)),
    );
  }
}
