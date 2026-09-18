import 'package:flutter/material.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';

/// The two action cards right below the profile header (design « Profile &
/// Settings ») : « Add your card » en aplat magenta, « Invite Friends » en
/// contour navy. Couleurs lues dans [AppColorScheme] (`actionCard*`), donc
/// adaptées au thème sombre.
class ProfileActionCards extends StatelessWidget {
  const ProfileActionCards({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ActionCard(
              key: const ValueKey('profile-action-add-card'),
              icon: HugeIcons.strokeRoundedCreditCardAdd,
              label: l10n.addYourCard,
              background: colors.actionCardFilled,
              foreground: Colors.white,
              border: colors.actionCardFilled,
              shadow: colors.actionCardFilled.withValues(alpha: 0.35),
              alignStart: true,
              onTap: () => context.push(AppRoutes.wallet),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ActionCard(
              key: const ValueKey('profile-action-invite'),
              icon: HugeIcons.strokeRoundedUserAdd01,
              label: l10n.inviteFriends,
              background: colors.actionCardOutlineBg,
              foreground: colors.actionCardOutlineText,
              border: colors.actionCardOutlineBorder,
              onTap: () => context.push(AppRoutes.referral),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onTap,
    this.shadow,
    this.alignStart = false,
  });

  final AppIconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final Color? shadow;

  /// Carte pleine : icône et texte calés à gauche, comme sur la maquette.
  final bool alignStart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadow == null
              ? null
              : [
                  BoxShadow(
                    color: shadow!,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: border, width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 116),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: alignStart
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    AppIcon(icon, size: 28, color: foreground),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      label,
                      textAlign: alignStart ? TextAlign.start : TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
