import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/call_repository.dart';

class EndCall implements UseCase<void, EndCallParams> {
  final CallRepository repository;
  EndCall(this.repository);

  @override
  Future<Either<Failure, void>> call(EndCallParams params) =>
      repository.endCall(params.id);
}

class EndCallParams extends Equatable {
  final String id;
  const EndCallParams({required this.id});

  @override
  List<Object?> get props => [id];
}