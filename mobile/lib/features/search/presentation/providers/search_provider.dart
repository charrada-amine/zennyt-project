import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/user_role.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../fits/domain/entities/candidate_profile.dart';
import '../../../fits/presentation/providers/swipe_deck_provider.dart';
import '../../../fits/presentation/widgets/fit_card_data.dart';

/// Filtres appliqués depuis /search-filter. `null` = filtre inactif.
/// Les valeurs sont les valeurs "wire" du backend (FULL_TIME, JUNIOR, HYBRID…).
class SearchFilters {
  final double? salaryMin;
  final double? salaryMax;
  final String? workplace;
  final String? level;
  final String? contractType;

  const SearchFilters({
    this.salaryMin,
    this.salaryMax,
    this.workplace,
    this.level,
    this.contractType,
  });

  bool get isActive =>
      salaryMin != null || workplace != null || level != null || contractType != null;
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void apply(SearchFilters filters) => state = filters;
  void clear() => state = const SearchFilters();
}

/// Non-autoDispose : les filtres survivent à l'aller-retour /search-filter.
final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(
  SearchFiltersNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider.autoDispose<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Candidats fit-scorés de l'offre actuellement sourcée (même sélection que
/// l'onglet Fits) — le backend intégré n'expose pas de liste "tous
/// candidats" indépendante d'une offre.
final _allCandidatesProvider =
    FutureProvider.autoDispose<List<CandidateProfile>>((ref) async {
  final job = ref.watch(activeJobContextProvider);
  if (job == null) return const [];
  return ref.watch(fitsRepositoryProvider).getCandidateFeed(job.id);
});

final _allJobOffersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fitsRepositoryProvider).getCandidateDeck();
});

final searchResultsProvider = Provider.autoDispose<AsyncValue<List<FitCardData>>>((ref) {
  final user = ref.watch(currentUserProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filters = ref.watch(searchFiltersProvider);

  if (user == null) return const AsyncData([]);

  if (user.role == UserRole.recruiter) {
    final candidatesAsync = ref.watch(_allCandidatesProvider);
    return candidatesAsync.whenData((list) {
      var filtered = query.isEmpty
          ? list
          : list.where((c) {
              return c.name.toLowerCase().contains(query) ||
                  c.targetRole.toLowerCase().contains(query) ||
                  c.location.toLowerCase().contains(query);
            }).toList();
      // Les profils candidats portent seniority + contractTypes ;
      // salaire/workplace ne s'appliquent qu'aux offres.
      if (filters.level != null) {
        filtered = filtered
            .where((c) => c.seniority.toUpperCase() == filters.level)
            .toList();
      }
      if (filters.contractType != null) {
        filtered = filtered
            .where((c) => c.contractTypes
                .map((t) => t.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_'))
                .contains(filters.contractType))
            .toList();
      }
      return filtered.map(FitCardData.fromCandidate).toList();
    });
  }

  final jobsAsync = ref.watch(_allJobOffersProvider);
  return jobsAsync.whenData((list) {
    var filtered = query.isEmpty
        ? list
        : list.where((j) {
            return j.title.toLowerCase().contains(query) ||
                j.companyName.toLowerCase().contains(query) ||
                j.city.toLowerCase().contains(query);
          }).toList();
    if (filters.workplace != null) {
      filtered =
          filtered.where((j) => j.workplaceType.value == filters.workplace).toList();
    }
    if (filters.level != null) {
      filtered =
          filtered.where((j) => j.experienceLevel.value == filters.level).toList();
    }
    if (filters.contractType != null) {
      filtered =
          filtered.where((j) => j.contractType.value == filters.contractType).toList();
    }
    if (filters.salaryMin != null && filters.salaryMax != null) {
      filtered = filtered
          .where((j) =>
              j.salaryMax >= filters.salaryMin! && j.salaryMin <= filters.salaryMax!)
          .toList();
    }
    return filtered.map(FitCardData.fromJobOffer).toList();
  });
});
