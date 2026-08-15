import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_chat.dart';
import '../entities/help_message.dart';

abstract class HelpChatRepository {
  Future<Either<Failure, List<HelpChat>>> getHelpChats(String userId);
  Future<Either<Failure, List<HelpMessage>>> getHelpMessages(String helpChatId,String userId);
}
