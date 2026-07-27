import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

/// Use case : récupérer la liste des conversations de l'utilisateur connecté.
class GetConversations implements UseCase<List<Conversation>, String> {
  final ConversationRepository repository;
  GetConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(String userId) {
    return repository.getConversations(userId);
  }
}