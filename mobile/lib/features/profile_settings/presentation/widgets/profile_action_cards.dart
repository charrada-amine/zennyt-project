import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';

/// The two action cards below the profile header: "Add your card" and "Invite
/// Friends". Both now navigate to their real screens.
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
            colors: colors,
            onTap: () => context.push(AppRoutes.wallet),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionCard(
            iconAsset:
                'assets/images/add.png', // Assuming add.png is the user+ icon
            label: l10n.inviteFriends,
            colors: colors,
            onTap: () => context.push(AppRoutes.referral),
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
    required this.colors,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
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
                    color: colors.textSecondary,
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
