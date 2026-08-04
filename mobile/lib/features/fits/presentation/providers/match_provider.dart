import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/match_entity.dart';
import 'swipe_deck_provider.dart';

/// Matchs mutuels du candidat connecté.
final candidateMatchesProvider =
    FutureProvider.autoDispose<List<MatchEntity>>((ref) {
  return ref.watch(fitsRepositoryProvider).getCandidateMatches();
});

/// Matchs mutuels du recruteur connecté, toutes offres confondues.
final recruiterMatchesProvider =
    FutureProvider.autoDispose<List<MatchEntity>>((ref) {
  return ref.watch(fitsRepositoryProvider).getRecruiterMatches();
});
