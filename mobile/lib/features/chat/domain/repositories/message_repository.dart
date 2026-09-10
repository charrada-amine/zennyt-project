import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/message.dart';

/// Port du domaine : contrat que la couche data doit implémenter.
abstract class MessageRepository {
  /// Récupérer les messages d'une conversation.
  Future<Either<Failure, List<Message>>> getMessages(
      String conversationId, String userId);

  /// Envoyer un message dans une conversation.
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String userId,
    required String content,
    MessageContentType contentType = MessageContentType.text,
    String? attachmentUrl,
  });
}
