import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../shared/widgets/app_motion.dart';
import 'fit_card_data.dart';
import 'tinder_card.dart';

/// Adaptive browse cards. Natural height accommodates large text and long titles.
class FitScoresGrid extends StatelessWidget {
  const FitScoresGrid({super.key, required this.items});
  final List<FitCardData> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AppReveal(
            key: ValueKey(item.id),
            child: AppPressScale(
              child: Material(
                color: context.colors.cardSurface,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    SoundService.instance.vibrateSelection();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => SizedBox(
                        height: MediaQuery.sizeOf(context).height * .78,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: FitCardContent(data: item),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.badgeText != null) ...[
                          Text(
                            item.badgeText!,
                            style: AppTypography.labelSmall.copyWith(
                              color: context.colors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTypography.titleLarge.copyWith(
                                  color: context.colors.textDarkBlue,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.arrow_outward_rounded,
                              color: context.colors.primary,
                              size: 21,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.primaryValue,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.tags
                              .take(3)
                              .map(
                                (tag) => Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(tag),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
