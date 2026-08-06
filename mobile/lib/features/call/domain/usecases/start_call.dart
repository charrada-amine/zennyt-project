import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/call.dart';
import '../repositories/call_repository.dart';

class StartCall implements UseCase<String, StartCallParams> {
  final CallRepository repository;
  StartCall(this.repository);

  @override
  Future<Either<Failure, String>> call(StartCallParams params) =>
      repository.startCall(params.call);
}

class StartCallParams extends Equatable {
  final Call call;
  const StartCallParams({required this.call});

  @override
  List<Object?> get props => [call];
}