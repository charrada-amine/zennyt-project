import 'package:adaptive_platform_ui/adaptive_platform_ui.dart'
    show AdaptiveSlider;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/settings/accessibility_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/entities/user_preferences.dart';
import '../providers/preferences_provider.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

class AccessibilityScreen extends ConsumerStatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  ConsumerState<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends ConsumerState<AccessibilityScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);
    final l10n = context.l10n;
    final a11y = ref.watch(accessibilityProvider);
    // Triggers the server preferences load; when they arrive, mirror them into
    // the local accessibility provider (a new device picks up the saved values).
    ref.watch(preferencesProvider);
    ref.listen(preferencesProvider, (previous, next) {
      next.whenData((prefs) {
        ref.read(accessibilityProvider.notifier).setHighContrast(prefs.highContrast);
        ref.read(accessibilityProvider.notifier).setTextSize(prefs.textSizePx.toDouble());
      });
    });
    final currentLanguage = Localizations.localeOf(context).languageCode == 'fr' ? 'Français' : 'English';

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPadding,
                vertical: AppSpacing.lg,
              ),
              child: _buildTopBar(context, colors, l10n.accessibility),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hPadding,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Language
                    _buildSettingsRow(
                      context,
                      colors,
                      label: l10n.language,
                      subtitle: currentLanguage,
                      trailing: AppIcon(
                        HugeIcons.strokeRoundedArrowRight01,
                        color: colors.chevron,
                        size: 16,
                      ),
                      onTap: () => context.push(AppRoutes.languageSettings),
                    ),
                    Divider(height: 1, thickness: 1, color: colors.divider),

                    // Contrast
                    _buildSettingsRow(
                      context,
                      colors,
                      label: l10n.contrast,
                      trailing: SizedBox(
                        height: 28,
                        child: FittedBox(
                          child: CupertinoSwitch(
                            value: a11y.highContrast,
                            activeTrackColor: colors.success,
                            onChanged: (val) {
                              ref
                                  .read(accessibilityProvider.notifier)
                                  .setHighContrast(val);
                              _persist();
                            },
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: colors.divider),

                    // Text Size
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.textSize,
                                style: AppTypography.titleSmall.copyWith(
                                  color: colors.textDarkBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${a11y.textSizePx.toInt()} px',
                                style: AppTypography.titleSmall.copyWith(
                                  color: colors.primary, // Using primary blue color
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.placeholderBg, // light gray
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _buildSliderButton(
                                  colors,
                                  icon: HugeIcons.strokeRoundedRemove01,
                                  onTap: () {
                                    if (a11y.textSizePx > 10) {
                                      ref
                                          .read(accessibilityProvider.notifier)
                                          .setTextSize(a11y.textSizePx - 1);
                                      _persist();
                                    }
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: colors.accent, // pink
                                      inactiveTrackColor: colors.divider,
                                      thumbColor: colors.accent,
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape: SliderComponentShape.noOverlay,
                                    ),
                                    child: AdaptiveSlider(
                                      value: a11y.textSizePx,
                                      min: 10,
                                      max: 30,
                                      onChanged: (val) {
                                        ref
                                            .read(accessibilityProvider.notifier)
                                            .setTextSize(val);
                                        _persist();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildSliderButton(
                                  colors,
                                  icon: HugeIcons.strokeRoundedAdd01,
                                  onTap: () {
                                    if (a11y.textSizePx < 30) {
                                      ref
                                          .read(accessibilityProvider.notifier)
                                          .setTextSize(a11y.textSizePx + 1);
                                      _persist();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Preview Box
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: colors.placeholderBg, // light gray
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.preview,
                            style: AppTypography.labelSmall.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.accessibilityPreviewText,
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.textDarkBlue,
                              fontSize: a11y.textSizePx,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pushes the current local accessibility + notification values to the server
  /// (best-effort; the local state already reflects the change).
  void _persist() {
    final a11y = ref.read(accessibilityProvider);
    ref.read(preferencesProvider.notifier).save(
          UserPreferences(
            notificationsEnabled: ref.read(notificationsEnabledProvider),
            highContrast: a11y.highContrast,
            textSizePx: a11y.textSizePx.round(),
          ),
        );
  }

  Widget _buildTopBar(BuildContext context, AppColorScheme colors, String title) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: colors.divider,
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: AppIcon(
              HugeIcons.strokeRoundedArrowLeft01,
              color: colors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildSettingsRow(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.textDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderButton(
    AppColorScheme colors, {
    required AppIconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.scaffoldBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppIcon(icon, size: 16, color: colors.textPrimary),
      ),
    );
  }
}
