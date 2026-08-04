part of 'conversation_bloc.dart';

enum ConvStatus { initial, loading, ready, error }

enum OfferStatus { pending, confirmed, rejected }

class ConversationState extends Equatable {
  final ConvStatus status;
  final List<ChatMessage> messages;
  final OfferStatus offerStatus;
  final String message;

  const ConversationState({
    this.status = ConvStatus.initial,
    this.messages = const [],
    this.offerStatus = OfferStatus.pending,
    this.message = '',
  });

  ConversationState copyWith({
    ConvStatus? status,
    List<ChatMessage>? messages,
    OfferStatus? offerStatus,
    String? message,
  }) {
    return ConversationState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      offerStatus: offerStatus ?? this.offerStatus,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, messages, offerStatus, message];
}
