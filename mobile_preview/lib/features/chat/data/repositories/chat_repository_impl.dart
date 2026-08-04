import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_summary.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_local_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource local;
  ChatRepositoryImpl({required this.local});

  @override
  Future<Either<Failure, List<ChatSummary>>> getChats({ChatKind? kind}) async {
    try {
      return Right(await local.getChats(kind));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String chatId) async {
    try {
      return Right(await local.getMessages(chatId));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
