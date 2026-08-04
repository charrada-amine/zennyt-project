import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../entities/chat_summary.dart';

abstract class ChatRepository {
  /// [kind] null = tous les chats.
  Future<Either<Failure, List<ChatSummary>>> getChats({ChatKind? kind});

  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId);
}
