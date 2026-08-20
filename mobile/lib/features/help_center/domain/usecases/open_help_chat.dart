import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_chat.dart';
import '../repositories/help_chat_repository.dart';

/// Ouvre une conversation avec le support.
///
/// Titre et sous-titre dependent de l'endroit d'ou l'aide est ouverte : le bouton
/// generique du menu n'en fournit pas, et le serveur applique alors ses valeurs de repli.
class OpenHelpChat {
  final HelpChatRepository repository;

  OpenHelpChat(this.repository);

  Future<Either<Failure, HelpChat>> call({String? title, String? subtitle}) {
    return repository.openHelpChat(title: title, subtitle: subtitle);
  }
}
