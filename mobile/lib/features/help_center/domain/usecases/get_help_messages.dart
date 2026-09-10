import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_message.dart';
import '../repositories/help_chat_repository.dart';

class GetHelpMessages {
  final HelpChatRepository repository;

  GetHelpMessages(this.repository);

  Future<Either<Failure, List<HelpMessage>>> call(String helpChatId,String userId) async {
    return await repository.getHelpMessages(helpChatId,userId);
  }
}
