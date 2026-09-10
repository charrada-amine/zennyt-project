import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat.dart';

/// Port du domaine : contrat que la couche data doit implémenter.
abstract class ConversationRepository {
  /// Récupérer les conversations de l'utilisateur connecté.
  Future<Either<Failure, List<Conversation>>> getConversations(String userId);

  /// Démarrer une conversation liée à une candidature.
  Future<Either<Failure, Conversation>> createConversation(String applicationId, String userId);

  /// Marquer une conversation comme lue.
  Future<Either<Failure, void>> markConversationRead(String conversationId, String userId);
}