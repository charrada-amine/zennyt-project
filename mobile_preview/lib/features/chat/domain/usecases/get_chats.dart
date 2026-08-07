import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat_summary.dart';
import '../repositories/chat_repository.dart';

class GetChats implements UseCase<List<ChatSummary>, GetChatsParams> {
  final ChatRepository repository;
  GetChats(this.repository);

  @override
  Future<Either<Failure, List<ChatSummary>>> call(GetChatsParams params) {
    return repository.getChats(kind: params.kind);
  }
}

class GetChatsParams extends Equatable {
  final ChatKind? kind;
  const GetChatsParams({this.kind});
  @override
  List<Object?> get props => [kind];
}
