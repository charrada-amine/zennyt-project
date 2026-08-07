part of 'search_bloc.dart';

enum SearchStatus { initial, loading, ready, error }

/// État de l'écran de recherche.
class SearchState extends Equatable {
  final SearchStatus status;
  final SuggestionKind kind;
  final String query;
  final List<Suggestion> suggestions;
  final String message;

  const SearchState({
    this.status = SearchStatus.initial,
    this.kind = SuggestionKind.jobOffer,
    this.query = '',
    this.suggestions = const [],
    this.message = '',
  });

  SearchState copyWith({
    SearchStatus? status,
    SuggestionKind? kind,
    String? query,
    List<Suggestion>? suggestions,
    String? message,
  }) {
    return SearchState(
      status: status ?? this.status,
      kind: kind ?? this.kind,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, kind, query, suggestions, message];
}
