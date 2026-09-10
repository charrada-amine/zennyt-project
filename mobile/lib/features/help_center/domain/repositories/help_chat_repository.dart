import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_chat.dart';
import '../entities/help_message.dart';

abstract class HelpChatRepository {
  Future<Either<Failure, List<HelpChat>>> getHelpChats(String userId);
  Future<Either<Failure, List<HelpMessage>>> getHelpMessages(String helpChatId,String userId);
  Future<Either<Failure, HelpChat>> openHelpChat({String? title, String? subtitle});
  Future<Either<Failure, HelpMessage>> sendHelpMessage(String helpChatId, String text);
  Future<Either<Failure, HelpChat>> rateHelpChat(
      String helpChatId, HelpChatRating rating, String? comment);
}
