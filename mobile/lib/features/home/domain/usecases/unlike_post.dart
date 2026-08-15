import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/post_repository.dart';

/// Use case pour annuler un like sur un post.
class UnlikePost implements UseCase<void, UnlikePostParams> {
  final PostRepository repository;
  UnlikePost(this.repository);

  @override
  Future<Either<Failure, void>> call(UnlikePostParams params) {
    return repository.unlikePost(params.postId, params.userId);
  }
}

class UnlikePostParams {
  final String postId;
  final String userId;
  UnlikePostParams({required this.postId, required this.userId});
}
