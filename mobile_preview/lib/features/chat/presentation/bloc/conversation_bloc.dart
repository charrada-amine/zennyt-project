import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_messages.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetMessages getMessages;

  ConversationBloc({required this.getMessages})
      : super(const ConversationState()) {
    on<ConversationStarted>(_onStarted);
    on<MessageSent>(_onSent);
    on<OfferConfirmed>((e, emit) => _resolveOffer(emit, OfferStatus.confirmed));
    on<OfferRejected>((e, emit) => _resolveOffer(emit, OfferStatus.rejected));
  }

  Future<void> _onStarted(
      ConversationStarted event, Emitter<ConversationState> emit) async {
    emit(state.copyWith(status: ConvStatus.loading));
    final result = await getMessages(GetMessagesParams(event.chatId));
    result.fold(
      (f) => emit(state.copyWith(status: ConvStatus.error, message: f.message)),
      (msgs) => emit(state.copyWith(status: ConvStatus.ready, messages: msgs)),
    );
  }

  void _onSent(MessageSent event, Emitter<ConversationState> emit) {
    if (event.text.trim().isEmpty) return;
    final msg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: event.text.trim(),
        fromMe: true,
        time: 'now');
    emit(state.copyWith(messages: [...state.messages, msg]));
  }

  void _resolveOffer(Emitter<ConversationState> emit, OfferStatus status) {
    final label = status == OfferStatus.confirmed
        ? 'Offer confirmed ✅'
        : 'Offer rejected';
    final msg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: label,
        fromMe: true,
        time: 'now');
    emit(state.copyWith(
        offerStatus: status, messages: [...state.messages, msg]));
  }
}
