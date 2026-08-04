import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/suggestion.dart';
import '../repositories/search_repository.dart';

/// Use case : rechercher des suggestions selon l'onglet et la requête.
class SearchSuggestions implements UseCase<List<Suggestion>, SearchParams> {
  final SearchRepository repository;
  SearchSuggestions(this.repository);

  @override
  Future<Either<Failure, List<Suggestion>>> call(SearchParams params) {
    return repository.search(kind: params.kind, query: params.query);
  }
}

class SearchParams extends Equatable {
  final SuggestionKind kind;
  final String query;
  const SearchParams({required this.kind, this.query = ''});

  @override
  List<Object?> get props => [kind, query];
}
