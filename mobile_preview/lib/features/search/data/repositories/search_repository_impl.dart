import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/suggestion.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_local_datasource.dart';

/// Implémentation du port [SearchRepository] (mock + filtre par requête).
class SearchRepositoryImpl implements SearchRepository {
  final SearchLocalDataSource local;
  SearchRepositoryImpl({required this.local});

  @override
  Future<Either<Failure, List<Suggestion>>> search({
    required SuggestionKind kind,
    String query = '',
  }) async {
    try {
      final models = await local.getSuggestions(kind);
      final q = query.trim().toLowerCase();
      final filtered = q.isEmpty
          ? models
          : models.where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.role.toLowerCase().contains(q));
      return Right(filtered.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
