import 'package:flutter/material.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../shared/widgets/app_motion.dart';
import 'fit_card_data.dart';
import 'fit_score_card.dart';
import 'tinder_card.dart';

/// Two-column "Fit Scores" browse grid (maquettes « Fits pro » / « Fits job »).
///
/// Rows are paired and stretched so both cards share the height of the tallest
/// one without a fixed cell height — long titles and large accessibility text
/// scale never overflow.
class FitScoresGrid extends StatelessWidget {
  const FitScoresGrid({
    super.key,
    required this.items,
    this.onJobTap,
    this.onMore,
    this.onResume,
  });

  final List<FitCardData> items;

  /// Optional override for job-offer cards: when provided, tapping a job opens
  /// the job detail page instead of the generic preview sheet. Candidate cards
  /// keep the preview sheet.
  final void Function(FitCardData item)? onJobTap;

  /// Optional kebab action, per card. The kebab is hidden when null so Search
  /// can reuse the same grid without inventing per-card actions.
  final void Function(FitCardData item)? onMore;

  /// Optional "Resume AI" action shown inside the candidate detail sheet.
  final void Function(FitCardData item)? onResume;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _card(context, items[i])),
                  const SizedBox(width: 14),
                  Expanded(
                    child: i + 1 < items.length
                        ? _card(context, items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, FitCardData item) => AppReveal(
    key: ValueKey(item.id),
    child: FitScoreCard(
      data: item,
      onMore: onMore == null ? null : () => onMore!(item),
      onTap: () {
        SoundService.instance.vibrateSelection();
        if (item.type == FitCardType.jobOffer && onJobTap != null) {
          onJobTap!(item);
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: FitCardContent(
                data: item,
                onResume: onResume == null ? null : () => onResume!(item),
              ),
            ),
          ),
        );
      },
    ),
  );
}
