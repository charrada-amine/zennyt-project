import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/feed_post.dart';
import '../repositories/feed_repository.dart';

/// Use case : récupérer le fil d'actualité.
class GetFeed implements UseCase<List<FeedPost>, NoParams> {
  final FeedRepository repository;
  GetFeed(this.repository);

  @override
  Future<Either<Failure, List<FeedPost>>> call(NoParams params) {
    return repository.getFeed();
  }
}
