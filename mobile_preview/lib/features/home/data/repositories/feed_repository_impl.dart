import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_local_datasource.dart';

/// Implémentation du port [FeedRepository].
///
/// Pour l'instant 100% mock (source locale). La conversion exception → Failure
/// se fait ici, isolant le domaine des détails techniques — exactement comme
/// le repository de référence du feature jobs.
class FeedRepositoryImpl implements FeedRepository {
  final FeedLocalDataSource local;

  FeedRepositoryImpl({required this.local});

  @override
  Future<Either<Failure, List<FeedPost>>> getFeed() async {
    try {
      final models = await local.getFeed();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
