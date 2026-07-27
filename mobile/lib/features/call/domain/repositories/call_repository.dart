import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/call.dart';

abstract class CallRepository {
  Future<Either<Failure, Call>> getCall(String id);
  Future<Either<Failure, void>> startCall(Call call);
  Future<Either<Failure, void>> endCall(String id);
}