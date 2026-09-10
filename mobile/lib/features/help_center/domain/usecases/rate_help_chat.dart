import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_chat.dart';
import '../repositories/help_chat_repository.dart';

/// Enregistre l'appreciation de l'utilisateur sur l'echange.
///
/// Le commentaire est facultatif : le formulaire s'ouvre apres la note et peut etre
/// ferme sans rien ecrire.
class RateHelpChat {
  final HelpChatRepository repository;

  RateHelpChat(this.repository);

  Future<Either<Failure, HelpChat>> call(
      String helpChatId, HelpChatRating rating, String? comment) {
    return repository.rateHelpChat(helpChatId, rating, comment);
  }
}
