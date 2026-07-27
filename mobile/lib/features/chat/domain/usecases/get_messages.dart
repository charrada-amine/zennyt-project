import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/message.dart';
import '../repositories/message_repository.dart';

/// Use case : récupérer les messages d'une conversation.
class GetMessages implements UseCase<List<Message>, GetMessagesParams> {
  final MessageRepository repository;
  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(GetMessagesParams params) {
    return repository.getMessages(params.conversationId, params.userId);
  }
}

class GetMessagesParams extends Equatable {
  final String conversationId;
  final String userId;
  const GetMessagesParams({required this.conversationId, required this.userId});

  @override
  List<Object?> get props => [conversationId, userId];
}