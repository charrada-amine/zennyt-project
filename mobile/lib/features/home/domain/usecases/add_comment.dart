import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/comment.dart';
import '../repositories/post_repository.dart';

/// Use case pour ajouter un commentaire.
class AddComment implements UseCase<Comment, Comment> {
  final PostRepository repository;
  AddComment(this.repository);

  @override
  Future<Either<Failure, Comment>> call(Comment params) {
    return repository.addComment(params);
  }
}
