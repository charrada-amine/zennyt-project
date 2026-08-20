import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_message.dart';
import '../repositories/help_chat_repository.dart';

class SendHelpMessage {
  final HelpChatRepository repository;

  SendHelpMessage(this.repository);

  Future<Either<Failure, HelpMessage>> call(String helpChatId, String text) {
    return repository.sendHelpMessage(helpChatId, text);
  }
}
