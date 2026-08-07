import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/suggestion.dart';
import '../../domain/usecases/search_suggestions.dart';

part 'search_event.dart';
part 'search_state.dart';

/// BLoC de l'écran de recherche : onglet (offres / pros) + requête texte.
///
/// Un seul état immuable (avec `status`) plutôt que des états scellés : c'est
/// plus lisible pour un écran qui combine onglet + champ de recherche + liste.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchSuggestions searchSuggestions;

  SearchBloc({required this.searchSuggestions}) : super(const SearchState()) {
    on<SearchStarted>(
        (e, emit) => _load(emit, state.kind, state.query),
        transformer: restartable());
    on<SearchTabChanged>(
        (e, emit) => _load(emit, e.kind, state.query),
        transformer: restartable());
    on<SearchQueryChanged>(
        (e, emit) => _load(emit, state.kind, e.query),
        transformer: restartable());
  }

  Future<void> _load(
      Emitter<SearchState> emit, SuggestionKind kind, String query) async {
    emit(state.copyWith(status: SearchStatus.loading, kind: kind, query: query));
    final result =
        await searchSuggestions(SearchParams(kind: kind, query: query));
    result.fold(
      (failure) => emit(state.copyWith(
          status: SearchStatus.error, message: failure.message)),
      (list) => emit(state.copyWith(
          status: SearchStatus.ready, suggestions: list)),
    );
  }
}
