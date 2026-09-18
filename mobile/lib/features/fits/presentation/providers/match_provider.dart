import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/match_entity.dart';
import 'swipe_deck_provider.dart';

/// Matchs mutuels du candidat connecté.
final candidateMatchesProvider =
    FutureProvider.autoDispose<List<MatchEntity>>((ref) {
  return ref.watch(fitsRepositoryProvider).getCandidateMatches();
});

/// Matchs mutuels du recruteur connecté pour l'offre sourcée
/// (`GET /job-offers/{id}/matches`).
final recruiterMatchesProvider =
    FutureProvider.autoDispose<List<MatchEntity>>((ref) {
  final job = ref.watch(activeJobContextProvider);
  if (job == null) return Future.value(const []);
  return ref.watch(fitsRepositoryProvider).getRecruiterMatches(jobOfferId: job.id);
});
