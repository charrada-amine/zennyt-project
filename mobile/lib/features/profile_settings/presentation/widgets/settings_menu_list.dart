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
          iconAsset: recruiter ? null : 'assets/images/referral.png',
          icon: recruiter ? Icons.people_outline_rounded : null,
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
          iconAsset: 'assets/images/account_center.png',
          boxColor: Colors.transparent,
          isFullBoxIcon: true,
          label: l10n.accountCenter,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.accountCenter),
        ),
        _buildDivider(colors),

        // ── Notifications (with toggle) ──
        _SettingsMenuItem(
          iconAsset: 'assets/images/notification_unselected.png',
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
          iconAsset: 'assets/images/theme.png',
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
          icon: Icons.language_rounded,
          boxColor: AppColors.iconDeepPurple,
          label: l10n.language,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.languageSettings),
        ),
        _buildDivider(colors),

        // ── Accessibility ──
        _SettingsMenuItem(
          iconAsset: 'assets/images/accessibility.png',
          boxColor: AppColors.iconDeepPurple,
          label: l10n.accessibility,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.accessibility),
        ),
        _buildDivider(colors),

        if (recruiter) ...[
          _SettingsMenuItem(
            icon: Icons.monetization_on_outlined,
            boxColor: AppColors.iconPink,
            label: l10n.plansAndPricing,
            trailing: _buildChevron(colors),
            onTap: null,
          ),
          _buildDivider(colors),
        ],
        // ── Help Center ──
        _SettingsMenuItem(
          iconAsset: 'assets/images/help_center.png',
          boxColor: AppColors.iconMediumBlue,
          label: l10n.helpCenter,
          trailing: _buildChevron(colors),
          onTap: () => context.push(AppRoutes.helpCenter),
        ),
        _buildDivider(colors),

        // ── Terms of Service & Conditions ──
        _SettingsMenuItem(
          iconAsset: 'assets/images/block.png',
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
          iconAsset: 'assets/images/logout.png',
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
    return Icon(
      Icons.arrow_forward_ios_rounded,
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
    this.iconAsset,
    this.icon,
    required this.boxColor,
    this.isFullBoxIcon = false,
    required this.label,
    required this.trailing,
    required this.onTap,
  }) : assert(iconAsset != null || icon != null);

  final String? iconAsset;
  final IconData? icon;
  final Color boxColor;
  final bool isFullBoxIcon;
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
                    child: icon != null
                        ? Icon(icon, color: Colors.white, size: 20)
                        : Image.asset(
                            iconAsset!,
                            width: isFullBoxIcon ? 36 : 20,
                            height: isFullBoxIcon ? 36 : 20,
                            color: isFullBoxIcon ? null : Colors.white,
                          ),
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
                    child: Icon(
                      Icons.lock_outline_rounded,
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
