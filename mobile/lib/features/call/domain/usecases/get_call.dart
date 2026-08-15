import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/call.dart';
import '../repositories/call_repository.dart';

class GetCall implements UseCase<Call, GetCallParams> {
  final CallRepository repository;
  GetCall(this.repository);

  @override
  Future<Either<Failure, Call>> call(GetCallParams params) =>
      repository.getCall(params.id);
}

class GetCallParams extends Equatable {
  final String id;
  const GetCallParams({required this.id});

  @override
  List<Object?> get props => [id];
}