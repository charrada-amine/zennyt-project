import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetPosts {
  final PostRepository repository;

  GetPosts(this.repository);

  Future<Either<Failure, List<Post>>> call({int page = 0, int size = 100}) async {
    return await repository.getPosts(page: page, size: size);
  }
}
