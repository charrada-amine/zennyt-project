import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class CreatePost {
  final PostRepository repository;

  CreatePost(this.repository);

  Future<Either<Failure, Post>> call(Post post) {
    return repository.createPost(post);
  }
}
