import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/message.dart';
import '../repositories/message_repository.dart';

/// Use case : envoyer un message dans une conversation.
class SendMessage implements UseCase<Message, SendMessageParams> {
  final MessageRepository repository;
  SendMessage(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) {
    return repository.sendMessage(
      conversationId: params.conversationId,
      userId: params.userId,
      content: params.content,
      contentType: params.contentType,
      attachmentUrl: params.attachmentUrl,
    );
  }
}

class SendMessageParams extends Equatable {
  final String conversationId;
  final String userId;
  final String content;
  final MessageContentType contentType;
  final String? attachmentUrl;

  const SendMessageParams({
    required this.conversationId,
    required this.userId,
    required this.content,
    this.contentType = MessageContentType.text,
    this.attachmentUrl,
  });

  @override
  List<Object?> get props => [conversationId, userId, content, contentType, attachmentUrl];
}
