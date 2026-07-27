import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';

/// Implémentation du port [MessageRepository] avec datasource distante.
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MessageRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    String conversationId,
    String userId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final models =
            await remoteDataSource.getMessages(conversationId, userId);
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
      catch (e) {
        print("Erreur de formatage JSON dans le Repository: $e");
        return Left(DataParsingFailure("Impossible de lire le JSON: $e"));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String conversationId,
    required String userId,
    required String content,
    MessageContentType contentType = MessageContentType.text,
    String? attachmentUrl,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.sendMessage(
          conversationId: conversationId,
          userId: userId,
          content: content,
          contentType: contentType,
          attachmentUrl: attachmentUrl,
        );
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
