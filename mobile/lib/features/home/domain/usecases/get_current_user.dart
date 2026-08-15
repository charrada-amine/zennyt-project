import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/current_user.dart';
import '../repositories/post_repository.dart';

class GetCurrentUser {
  final PostRepository repository;

  GetCurrentUser(this.repository);

  Future<Either<Failure, CurrentUser>> call() {
    return repository.getCurrentUser();
  }
}
