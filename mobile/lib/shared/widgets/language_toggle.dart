import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/l10n_extension.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/theme.dart';

/// A compact pill that flips the app language between English and French.
///
/// It shows the language you'd switch TO (e.g. "FR" while the app is in
/// English). Use [light] over dark imagery (onboarding) for a white,
/// translucent look; the default navy-on-surface style suits light screens.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final target = locale.languageCode == 'en' ? 'FR' : 'EN';

    final colors = context.colors;
    final Color foreground = light ? Colors.white : colors.primary;
    final Color background = light
        ? Colors.white.withValues(alpha: 0.18)
        : colors.scaffoldBg;
    final BorderSide border = light
        ? BorderSide(color: Colors.white.withValues(alpha: 0.45))
        : BorderSide(color: colors.border);

    return Tooltip(
      message: context.l10n.changeLanguage,
      child: Material(
        color: background,
        shape: StadiumBorder(side: border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ref.read(localeProvider.notifier).toggle(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  target,
                  style: AppTypography.labelMedium.copyWith(
                    color: foreground,
                    fontWeight: AppTypography.semiBold,
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
