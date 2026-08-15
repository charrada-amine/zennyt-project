import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_post_preferences.dart';
import '../repositories/post_repository.dart';

class UpdateUserPostPreferences {
  final PostRepository repository;

  UpdateUserPostPreferences(this.repository);

  Future<Either<Failure, UserPostPreferences>> call(
    UserPostPreferences preferences,
  ) {
    return repository.updateUserPostPreferences(preferences);
  }
}
