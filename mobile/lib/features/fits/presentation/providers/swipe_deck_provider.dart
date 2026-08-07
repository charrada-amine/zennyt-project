import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../data/fits_repository_impl.dart';
import '../../domain/entities/candidate_profile.dart';
import '../../domain/entities/swipe_result.dart';
import '../../domain/repositories/fits_repository.dart';

/// Source unique du repository Fits (backend intégré).
final fitsRepositoryProvider = Provider<FitsRepository>((ref) {
  return FitsRepositoryImpl(ref.watch(dioProvider));
});

/// Offres ACTIVE du recruteur connecté (chips « Sourcing: … » au-dessus du deck).
final jobOffersProvider = FutureProvider<List<JobOffer>>((ref) {
  return ref.watch(fitsRepositoryProvider).getMyActiveOffers();
});

@immutable
class _HistoryEntry<T> {
  final T item;
  final SwipeResult? result;
  const _HistoryEntry(this.item, this.result);

  _HistoryEntry<T> withResult(SwipeResult result) => _HistoryEntry(item, result);
}

@immutable
class SwipeDeckState<T> {
  final List<T> remaining;
  final List<_HistoryEntry<T>> _history;
  final T? pendingMatch;

  const SwipeDeckState({
    required this.remaining,
    List<_HistoryEntry<T>> history = const [],
    this.pendingMatch,
  }) : _history = history;

  bool get canUndo => _history.isNotEmpty;

  SwipeDeckState<T> copyWith({
    List<T>? remaining,
    List<_HistoryEntry<T>>? history,
    T? pendingMatch,
    bool clearMatch = false,
  }) {
    return SwipeDeckState(
      remaining: remaining ?? this.remaining,
      history: history ?? _history,
      pendingMatch: clearMatch ? null : (pendingMatch ?? this.pendingMatch),
    );
  }
}

/// Paramètres d'un swipe. Le backend intégré déduit le swiper du JWT et
/// ignore les champs décoratifs — seuls targetId/targetType/jobOfferId/
/// direction partent sur le réseau.
class SwipeParams {
  final SwipeTargetType targetType;
  final String targetId;
  final String jobOfferId;
  final SwipeDirection direction;

  const SwipeParams({
    required this.targetType,
    required this.targetId,
    required this.jobOfferId,
    required this.direction,
  });
}

abstract class BaseSwipeDeckNotifier<T> extends AsyncNotifier<SwipeDeckState<T>> {
  Future<List<T>> fetchItems();
  SwipeParams buildSwipeParams(T item, SwipeDirection direction);

  @override
  Future<SwipeDeckState<T>> build() async {
    final items = await fetchItems();
    return SwipeDeckState<T>(remaining: items);
  }

  Future<void> swipeLeft() => _performSwipe(SwipeDirection.left);
  Future<void> swipeRight() => _performSwipe(SwipeDirection.right);

  Future<void> _performSwipe(SwipeDirection direction) async {
    final current = state.asData?.value;
    if (current == null || current.remaining.isEmpty) return;

    final item = current.remaining.first;
    final params = buildSwipeParams(item, direction);
    final entryIndex = current._history.length;

    state = AsyncData(current.copyWith(
      remaining: current.remaining.sublist(1),
      history: [...current._history, _HistoryEntry<T>(item, null)],
      clearMatch: true,
    ));

    try {
      final swipeResult = await ref.read(fitsRepositoryProvider).swipe(
            targetId: params.targetId,
            targetType: params.targetType,
            jobOfferId: params.jobOfferId,
            direction: params.direction,
          );
      final now = state.asData?.value;
      if (now == null) return;
      final updatedHistory = List<_HistoryEntry<T>>.from(now._history);
      if (entryIndex < updatedHistory.length) {
        updatedHistory[entryIndex] = updatedHistory[entryIndex].withResult(swipeResult);
      }
      state = AsyncData(now.copyWith(
        history: updatedHistory,
        pendingMatch: swipeResult.matched ? item : null,
        clearMatch: !swipeResult.matched,
      ));
    } catch (_) {
      // Le pop optimiste reste ; le swipe pourra être rejoué au prochain reload.
    }
  }

  Future<void> skip() async {
    final current = state.asData?.value;
    if (current == null || current.remaining.isEmpty) return;

    final item = current.remaining.first;

    state = AsyncData(current.copyWith(
      remaining: current.remaining.sublist(1),
      history: [...current._history, _HistoryEntry<T>(item, null)],
      clearMatch: true,
    ));
  }

  Future<void> undo() async {
    final current = state.asData?.value;
    if (current == null || current._history.isEmpty) return;

    final last = current._history.last;

    state = AsyncData(current.copyWith(
      remaining: [last.item, ...current.remaining],
      history: current._history.sublist(0, current._history.length - 1),
      clearMatch: true,
    ));

    if (last.result != null) {
      try {
        await ref.read(fitsRepositoryProvider).undoSwipe(last.result!.swipeId);
      } catch (_) {
        // L'état local reflète déjà l'undo ; l'appel serveur est best-effort.
      }
    }
  }

  void consumeMatchEvent() {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearMatch: true));
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await fetchItems();
      return SwipeDeckState<T>(remaining: items);
    });
  }
}

class SelectedJobContextNotifier extends Notifier<JobOffer?> {
  @override
  JobOffer? build() => null;

  void select(JobOffer job) => state = job;
}

final selectedJobContextProvider =
    NotifierProvider<SelectedJobContextNotifier, JobOffer?>(
  SelectedJobContextNotifier.new,
);

final activeJobContextProvider = Provider<JobOffer?>((ref) {
  final jobs = ref.watch(jobOffersProvider).asData?.value ?? [];
  if (jobs.isEmpty) return null;
  final selected = ref.watch(selectedJobContextProvider);
  if (selected != null && jobs.any((j) => j.id == selected.id)) return selected;
  return jobs.first;
});

class RecruiterSwipeNotifier extends BaseSwipeDeckNotifier<CandidateProfile> {
  @override
  Future<List<CandidateProfile>> fetchItems() async {
    final job = ref.read(activeJobContextProvider) ??
        (await ref.read(jobOffersProvider.future)).firstOrNull;
    if (job == null) return const [];

    final repo = ref.read(fitsRepositoryProvider);
    final all = await repo.getCandidateFeed(job.id);
    final swipedIds =
        (await repo.getSwipedTargetIds(jobOfferId: job.id)).toSet();
    return all.where((c) => !swipedIds.contains(c.id)).toList();
  }

  @override
  SwipeParams buildSwipeParams(CandidateProfile item, SwipeDirection direction) {
    final job = ref.read(activeJobContextProvider)!;

    return SwipeParams(
      targetType: SwipeTargetType.candidate,
      targetId: item.id,
      jobOfferId: job.id,
      direction: direction,
    );
  }
}

final recruiterSwipeDeckProvider =
    AsyncNotifierProvider<RecruiterSwipeNotifier, SwipeDeckState<CandidateProfile>>(
  RecruiterSwipeNotifier.new,
);

class CandidateSwipeNotifier extends BaseSwipeDeckNotifier<JobOffer> {
  @override
  Future<List<JobOffer>> fetchItems() async {
    final repo = ref.read(fitsRepositoryProvider);
    final all = await repo.getCandidateDeck();

    final user = ref.read(currentUserProvider);
    if (user == null) return all;

    final swipedIds = (await repo.getSwipedTargetIds()).toSet();
    return all.where((j) => !swipedIds.contains(j.id)).toList();
  }

  @override
  SwipeParams buildSwipeParams(JobOffer item, SwipeDirection direction) {
    return SwipeParams(
      targetType: SwipeTargetType.jobOffer,
      targetId: item.id,
      jobOfferId: item.id,
      direction: direction,
    );
  }
}

final candidateSwipeDeckProvider =
    AsyncNotifierProvider<CandidateSwipeNotifier, SwipeDeckState<JobOffer>>(
  CandidateSwipeNotifier.new,
);
