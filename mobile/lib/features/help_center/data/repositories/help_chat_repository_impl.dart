import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/help_chat.dart';
import '../../domain/entities/help_message.dart';
import '../../domain/repositories/help_chat_repository.dart';
import '../datasources/help_chat_remote_datasource.dart';

class HelpChatRepositoryImpl implements HelpChatRepository {
  final HelpChatRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HelpChatRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<HelpChat>>> getHelpChats(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getHelpChats(userId);
        return Right(models.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      } catch (e) {
        print("Erreur de formatage JSON dans le Repository helpChats: $e");
        return Left(DataParsingFailure("Impossible de lire le JSON: $e"));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<HelpMessage>>> getHelpMessages(
    String helpChatId,
    String userId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getHelpMessages(helpChatId,userId);
        return Right(models.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
