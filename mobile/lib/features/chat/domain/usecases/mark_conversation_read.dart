import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/chat_repository.dart';

/// Use case : marquer une conversation comme lue.
class MarkConversationRead implements UseCase<void, MarkConversationReadParams> {
  final ConversationRepository repository;
  MarkConversationRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkConversationReadParams params) {
    return repository.markConversationRead(params.conversationId, params.userId);
  }
}

class MarkConversationReadParams extends Equatable {
  final String conversationId;
  final String userId;
  const MarkConversationReadParams({required this.conversationId, required this.userId});

  @override
  List<Object?> get props => [conversationId, userId];
}
