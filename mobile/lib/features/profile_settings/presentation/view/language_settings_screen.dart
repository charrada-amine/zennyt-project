import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../widgets/language_option_tile.dart';

/// Selection writes through the existing persisted locale controller.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: CustomAppBar(title: context.l10n.language),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: 2,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final code = index == 0 ? 'en' : 'fr';
            return AppReveal(
              child: LanguageOptionTile(
                label: index == 0 ? 'English' : 'Français',
                selected: locale.languageCode == code,
                onTap: () {
                  if (locale.languageCode == code) return;
                  SoundService.instance.vibrateSelection();
                  ref.read(localeProvider.notifier).setLocale(Locale(code));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
