import 'package:flutter/material.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/theme.dart';

/// The two action cards below the profile header: "Add your card" and "Invite
/// Friends".
class ProfileActionCards extends StatelessWidget {
  const ProfileActionCards({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            iconAsset: 'assets/images/card plus.png',
            label: l10n.addYourCard,
            isFilled: true,
            colors: colors,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            iconAsset:
                'assets/images/add.png', // Assuming add.png is the user+ icon
            label: l10n.inviteFriends,
            isFilled: false,
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconAsset,
    required this.label,
    required this.isFilled,
    required this.colors,
  });

  final String iconAsset;
  final String label;
  final bool isFilled;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      decoration: BoxDecoration(
        color: isFilled ? colors.actionCardFilled : colors.actionCardOutlineBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: isFilled
            ? null
            : Border.all(color: colors.actionCardOutlineBorder, width: 1),
        boxShadow: AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.base,
              horizontal: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconAsset, width: 32, height: 32),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    color: isFilled
                        ? Colors.white
                        : colors.actionCardOutlineText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
