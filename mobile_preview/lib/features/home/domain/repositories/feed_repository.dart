import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/feed_post.dart';

/// Port du domaine : contrat que la couche data doit implémenter.
///
/// Le domaine dépend de cette abstraction, jamais de la source mock/réseau.
abstract class FeedRepository {
  Future<Either<Failure, List<FeedPost>>> getFeed();
}
