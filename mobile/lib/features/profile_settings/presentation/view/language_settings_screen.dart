import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/language_option_tile.dart';

/// Lets the user pick between the shipped app languages (English / French).
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  static const _options = <_LanguageOption>[
    _LanguageOption(code: 'en', label: 'English'),
    _LanguageOption(code: 'fr', label: 'Français'),
  ];

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingH,
                vertical: AppSpacing.lg,
              ),
              child: _LanguageTopBar(title: l10n.language),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _options.length,
                separatorBuilder: (context, _) =>
                    Divider(height: 1, thickness: 1, color: colors.divider),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final animation = CurvedAnimation(
                    parent: _entrance,
                    curve: Interval(
                      0.15 + index * 0.2,
                      0.55 + index * 0.2,
                      curve: Curves.easeOut,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: LanguageOptionTile(
                        label: option.label,
                        selected: locale.languageCode == option.code,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(option.code)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTopBar extends StatelessWidget {
  const _LanguageTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.label});

  final String code;
  final String label;
}
