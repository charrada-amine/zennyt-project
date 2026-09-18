import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/domain/entities/user_preferences.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../providers/preferences_provider.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// The settings menu list matching the design screenshot.
class SettingsMenuList extends ConsumerWidget {
  const SettingsMenuList({super.key, this.recruiter = false});

  final bool recruiter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final preferences = ref.watch(preferencesProvider).value;
    final bool notifEnabled =
        preferences?.notificationsEnabled ?? ref.watch(notificationsEnabledProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),

        // ── Referral ──
        _SettingsMenuItem(
          icon: recruiter
              ? HugeIcons.strokeRoundedUserMultiple
              : HugeIcons.strokeRoundedUserAdd01,
          boxColor: AppColors.iconPurple,
          label: recruiter ? l10n.hiredCandidates : l10n.referral,
          trailing: _buildChevron(colors),
          onTap: recruiter
              ? () => context.push(AppRoutes.hiredCandidates)
              : () => context.push(AppRoutes.referral),
        ),
        _buildDivider(colors),

        // ── Account Center ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedUserAccount,
          boxColor: const Color(0xFFD02F7C),
          label: l10n.accountCenter,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.accountCenter),
        ),
        _buildDivider(colors),

        // ── Notifications (with toggle) ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedNotification01,
          boxColor: AppColors.iconBlue,
          label: l10n.notifications,
          trailing: SizedBox(
            height: 28,
            child: FittedBox(
              child: Switch.adaptive(
                value: notifEnabled,
                activeTrackColor: colors.primary,
                onChanged: (val) {
                  final current = preferences ?? UserPreferences.defaults;
                  ref
                      .read(preferencesProvider.notifier)
                      .save(current.copyWith(notificationsEnabled: val));
                },
              ),
            ),
          ),
          onTap: () {
            final current = preferences ?? UserPreferences.defaults;
            ref
                .read(preferencesProvider.notifier)
                .save(current.copyWith(notificationsEnabled: !current.notificationsEnabled));
          },
        ),
        _buildDivider(colors),

        // ── Theme (with toggle) ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedMoon02,
          boxColor: AppColors.iconBlack,
          label: l10n.theme,
          trailing: SizedBox(
            height: 28,
            child: FittedBox(
              child: Switch.adaptive(
                value: isDark,
                activeTrackColor: colors.primary,
                onChanged: (val) {
                  ref
                      .read(themeProvider.notifier)
                      .setMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
          ),
          onTap: () {
            ref.read(themeProvider.notifier).toggle();
          },
        ),
        _buildDivider(colors),

        // ── Language ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedGlobe02,
          boxColor: AppColors.iconDeepPurple,
          label: l10n.language,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.languageSettings),
        ),
        _buildDivider(colors),

        // ── Accessibility ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedUniversalAccess,
          boxColor: AppColors.iconDeepPurple,
          label: l10n.accessibility,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.accessibility),
        ),
        _buildDivider(colors),

        if (recruiter) ...[
          _SettingsMenuItem(
            icon: HugeIcons.strokeRoundedDollar01,
            boxColor: AppColors.iconPink,
            label: l10n.plansAndPricing,
            trailing: _buildChevron(colors),
            onTap: () => context.push(AppRoutes.plans),
          ),
          _buildDivider(colors),
        ],
        // ── Help Center ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedCustomerSupport,
          boxColor: AppColors.iconMediumBlue,
          label: l10n.helpCenter,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.helpCenter),
        ),
        _buildDivider(colors),

        // ── Terms of Service & Conditions ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedLegalDocument01,
          boxColor: AppColors.iconGrey,
          label: l10n.termsOfServiceAndConditions,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.termsOfUse),
        ),

        const SizedBox(height: AppSpacing.sm),
        Divider(height: 24, thickness: 1, color: colors.divider),
        const SizedBox(height: AppSpacing.sm),

        // ── Log out ──
        _SettingsMenuItem(
          icon: HugeIcons.strokeRoundedLogout01,
          boxColor: AppColors.iconNavy,
          label: l10n.logOut,
          trailing: _buildChevron(colors),
          onTap: () {
            _showLogoutDialog(context, ref);
          },
        ),

        const SizedBox(height: AppSpacing.base),
      ],
    );
  }

  Widget _buildDivider(AppColorScheme colors) {
    return const SizedBox(height: 8);
  }

  Widget _buildChevron(AppColorScheme colors) {
    return AppIcon(
      HugeIcons.strokeRoundedArrowRight01,
      color: colors.chevron,
      size: 16,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(l10n.logOut),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Clears tokens + revokes the refresh token; the router redirect
              // then sends the user back to login on the session change.
              ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(
              l10n.logOut,
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single settings menu row with icon, label, and trailing widget.
class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.icon,
    required this.boxColor,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final AppIconData icon;
  final Color boxColor;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPressScale(
      enabled: onTap != null,
      child: Material(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap == null
              ? null
              : () {
                  SoundService.instance.vibrateSelection();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AppIcon(icon, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.menuLabelText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (onTap == null)
                  Tooltip(
                    message: context.l10n.comingSoon,
                    child: AppIcon(
                      HugeIcons.strokeRoundedLockKey,
                      size: 18,
                      semanticLabel: context.l10n.comingSoon,
                      color: colors.textSecondary,
                    ),
                  )
                else
                  trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
