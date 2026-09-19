import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/zennyt_loader.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../domain/entities/candidate_profile.dart';
import '../providers/swipe_deck_provider.dart';
import '../widgets/fit_card_data.dart';
import '../widgets/resume_sheet.dart';
import '../widgets/tinder_action_buttons.dart';
import '../widgets/tinder_card.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Interface de swipe, ouverte par « View more » depuis la grille Fit Scores
/// (maquettes « Fits job-1/2 ») : la carte occupe l'écran, les actions la
/// chevauchent en bas. Affichée à la place de la grille dans [FitsScreen] pour
/// garder la barre de navigation. Même deck (providers Riverpod partagés).
class FitsSwipeView extends ConsumerWidget {
  const FitsSwipeView({super.key, required this.isRecruiter});

  final bool isRecruiter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = DeckBinding.watch(ref, isRecruiter: isRecruiter);
    final activeJob = isRecruiter ? ref.watch(activeJobContextProvider) : null;

    VoidCallback? resumeFor(FitCardData card) => isRecruiter && activeJob != null
        ? () => showCandidateResumeSheet(
              context,
              candidateId: card.id,
              candidateName: card.title,
              jobOfferId: activeJob.id,
            )
        : null;

    if (deck.loading) return const Center(child: ZennytLoader());
    if (deck.hasError || deck.cards.isEmpty) {
      return FitsDeckStatus(failed: deck.hasError, onReload: deck.onReload);
    }

    const buttonsBottom = 8.0;
    const cardBottom = buttonsBottom + 16;
    const contentInset =
        TinderActionButtons.bigSize + buttonsBottom - cardBottom + 18;
    return Stack(
      children: [
        if (deck.cards.length > 1)
          Positioned.fill(
            left: 12,
            right: 12,
            top: 4,
            bottom: cardBottom,
            child: IgnorePointer(
              child: TinderCard(
                data: deck.cards[1],
                onSwipeLeft: () {},
                onSwipeRight: () {},
                isFront: false,
                bottomInset: contentInset,
              ),
            ),
          ),
        Positioned.fill(
          left: 12,
          right: 12,
          top: 4,
          bottom: cardBottom,
          child: TinderCard(
            key: ValueKey(deck.cards.first.id),
            data: deck.cards.first,
            onSwipeLeft: deck.onLeft,
            onSwipeRight: deck.onRight,
            isFront: true,
            onResume: resumeFor(deck.cards.first),
            bottomInset: contentInset,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: buttonsBottom,
          child: TinderActionButtons(
            canUndo: deck.canUndo,
            onUndo: deck.onUndo,
            onReject: deck.onLeft,
            onApprove: deck.onRight,
            onForward: deck.onForward,
          ),
        ),
      ],
    );
  }
}

/// Accès au deck du rôle courant, pour ne pas brancher l'UI sur les génériques
/// CandidateProfile / JobOffer.
class DeckBinding {
  const DeckBinding({
    required this.cards,
    required this.canUndo,
    required this.loading,
    required this.hasError,
    required this.onLeft,
    required this.onRight,
    required this.onUndo,
    required this.onForward,
    required this.onReload,
  });

  factory DeckBinding.watch(WidgetRef ref, {required bool isRecruiter}) {
    if (isRecruiter) {
      final async = ref.watch(recruiterSwipeDeckProvider);
      final notifier = ref.read(recruiterSwipeDeckProvider.notifier);
      return DeckBinding(
        cards: (async.asData?.value.remaining ?? const <CandidateProfile>[])
            .map(FitCardData.fromCandidate)
            .toList(),
        canUndo: async.asData?.value.canUndo ?? false,
        loading: async.isLoading,
        hasError: async.hasError,
        onLeft: notifier.swipeLeft,
        onRight: notifier.swipeRight,
        onUndo: notifier.undo,
        onForward: notifier.skip,
        onReload: notifier.reload,
      );
    }
    final async = ref.watch(candidateSwipeDeckProvider);
    final notifier = ref.read(candidateSwipeDeckProvider.notifier);
    return DeckBinding(
      cards: (async.asData?.value.remaining ?? const <JobOffer>[])
          .map(FitCardData.fromJobOffer)
          .toList(),
      canUndo: async.asData?.value.canUndo ?? false,
      loading: async.isLoading,
      hasError: async.hasError,
      onLeft: notifier.swipeLeft,
      onRight: notifier.swipeRight,
      onUndo: notifier.undo,
      onForward: notifier.skip,
      onReload: notifier.reload,
    );
  }

  final List<FitCardData> cards;
  final bool canUndo;
  final bool loading;
  final bool hasError;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onUndo;
  final VoidCallback onForward;
  final Future<void> Function() onReload;
}

/// Deck vide (« all caught up ») ou en échec, avec relance.
class FitsDeckStatus extends StatelessWidget {
  const FitsDeckStatus({super.key, required this.failed, required this.onReload});

  final bool failed;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                failed
                    ? HugeIcons.strokeRoundedWifiOff01
                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                color: context.colors.primary,
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                failed ? 'Could not load your matches' : 'You’re all caught up',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: context.colors.textDarkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                failed
                    ? 'Check your connection and try again.'
                    : 'Check back for new opportunities.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: failed ? 'Try again' : 'Refresh',
                onPressed: onReload,
              ),
            ],
          ),
        ),
      );
}
