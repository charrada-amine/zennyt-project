import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

class GetCommentsByPost implements UseCase<List<Comment>, GetCommentsByPostParams> {
  final PostRepository repository;
  GetCommentsByPost(this.repository);

  @override
  Future<Either<Failure, List<Comment>>> call(GetCommentsByPostParams params) {
    return repository.getCommentsByPost(params.postId, params.userId);
  }
}

class GetCommentsByPostParams {
  final String postId;
  final String userId;
  const GetCommentsByPostParams({required this.postId, required this.userId});
}
