import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

class GetMessages implements UseCase<List<ChatMessage>, GetMessagesParams> {
  final ChatRepository repository;
  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(GetMessagesParams params) {
    return repository.getMessages(params.chatId);
  }
}

class GetMessagesParams extends Equatable {
  final String chatId;
  const GetMessagesParams(this.chatId);
  @override
  List<Object?> get props => [chatId];
}
