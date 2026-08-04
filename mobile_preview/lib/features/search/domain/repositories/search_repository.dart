import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/suggestion.dart';

/// Port du domaine : contrat que la couche data doit implémenter.
abstract class SearchRepository {
  Future<Either<Failure, List<Suggestion>>> search({
    required SuggestionKind kind,
    String query = '',
  });
}
