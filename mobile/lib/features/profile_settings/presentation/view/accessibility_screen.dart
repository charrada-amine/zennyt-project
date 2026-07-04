import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';

class AccessibilityScreen extends ConsumerStatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  ConsumerState<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends ConsumerState<AccessibilityScreen> {
  bool _contrastEnabled = true;
  double _textSize = 18.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);
    final l10n = context.l10n;
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
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
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
                            value: _contrastEnabled,
                            activeTrackColor: colors.success,
                            onChanged: (val) {
                              setState(() {
                                _contrastEnabled = val;
                              });
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
                                '${_textSize.toInt()} px',
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
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_textSize > 10) {
                                      setState(() {
                                        _textSize -= 1;
                                      });
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
                                    child: Slider(
                                      value: _textSize,
                                      min: 10,
                                      max: 30,
                                      onChanged: (val) {
                                        setState(() {
                                          _textSize = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildSliderButton(
                                  colors,
                                  icon: Icons.add,
                                  onTap: () {
                                    if (_textSize < 30) {
                                      setState(() {
                                        _textSize += 1;
                                      });
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
                              fontSize: _textSize,
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
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
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
    required IconData icon,
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
        child: Icon(icon, size: 16, color: colors.textPrimary),
      ),
    );
  }
}
