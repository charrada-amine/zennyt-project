import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/call_repository.dart';

class JoinCall implements UseCase<void, JoinCallParams> {
  final CallRepository repository;
  JoinCall(this.repository);

  @override
  Future<Either<Failure, void>> call(JoinCallParams params) =>
      repository.joinCall(params.callId);
}

class JoinCallParams extends Equatable {
  final String callId;
  const JoinCallParams({required this.callId});

  @override
  List<Object?> get props => [callId];
}
