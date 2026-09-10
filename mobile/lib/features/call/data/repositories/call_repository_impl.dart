import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/call.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/call_remote_datasource.dart';
import '../models/call_model.dart';

class CallRepositoryImpl implements CallRepository {
  final CallRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CallRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Call>> getCall(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.getCall(id);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> startCall(Call call) async {
    if (await networkInfo.isConnected) {
      try {
        final model = CallModel(
          id: call.id,
          contactName: call.contactName,
          type: call.type,
          status: call.status,
          startTime: call.startTime,
          duration: call.duration,
        );
        final callId = await remoteDataSource.startCall(model);
        return Right(callId);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> endCall(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.endCall(id);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> joinCall(String callId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.joinCall(callId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(mapStatusCodeToFailure(e.statusCode, e.message));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}