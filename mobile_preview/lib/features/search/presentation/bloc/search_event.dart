part of 'search_bloc.dart';

/// Événements entrants du BLoC de recherche.
sealed class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

/// Charger l'onglet courant (au démarrage).
class SearchStarted extends SearchEvent {
  const SearchStarted();
}

/// Changer d'onglet (offres ↔ professionnels).
class SearchTabChanged extends SearchEvent {
  final SuggestionKind kind;
  const SearchTabChanged(this.kind);
  @override
  List<Object?> get props => [kind];
}

/// La requête texte a changé.
class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}
