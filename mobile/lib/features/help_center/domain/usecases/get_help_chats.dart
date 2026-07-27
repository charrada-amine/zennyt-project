import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/help_chat.dart';
import '../repositories/help_chat_repository.dart';

class GetHelpChats {
  final HelpChatRepository repository;

  GetHelpChats(this.repository);

  Future<Either<Failure, List<HelpChat>>> call(String userId) async {
    return await repository.getHelpChats(userId);
  }
}
