import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class VotePoll implements UseCase<Post, VotePollParams> {
  final PostRepository repository;
  VotePoll(this.repository);

  @override
  Future<Either<Failure, Post>> call(VotePollParams params) {
    return repository.votePoll(params.postId, params.optionId, params.userId);
  }
}

class VotePollParams {
  final String postId;
  final String optionId;
  final String userId;
  VotePollParams({
    required this.postId,
    required this.optionId,
    required this.userId,
  });
}
