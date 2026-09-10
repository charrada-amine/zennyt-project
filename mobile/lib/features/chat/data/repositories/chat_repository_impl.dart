import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// Implémentation du port [ConversationRepository] avec datasource distante.
class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ConversationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Conversation>>> getConversations(
      String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getConversations(userId);
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      } catch (e) {
        print("Erreur de formatage JSON dans le Repository: $e");
        return Left(DataParsingFailure("Impossible de lire le JSON: $e"));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Conversation>> createConversation(
      String applicationId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final model =
            await remoteDataSource.createConversation(applicationId, userId);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markConversationRead(
      String conversationId, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markConversationRead(conversationId, userId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
