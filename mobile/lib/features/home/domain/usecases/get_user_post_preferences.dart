import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_post_preferences.dart';
import '../repositories/post_repository.dart';

class GetUserPostPreferences {
  final PostRepository repository;

  GetUserPostPreferences(this.repository);

  Future<Either<Failure, UserPostPreferences>> call(String userId) {
    return repository.getUserPostPreferences(userId);
  }
}
