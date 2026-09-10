import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/post_repository.dart';

/// Use case pour liker un post.
class LikePost implements UseCase<void, LikePostParams> {
  final PostRepository repository;
  LikePost(this.repository);

  @override
  Future<Either<Failure, void>> call(LikePostParams params) {
    return repository.likePost(params.postId, params.userId);
  }
}

class LikePostParams {
  final String postId;
  final String userId;
  LikePostParams({required this.postId, required this.userId});
}
