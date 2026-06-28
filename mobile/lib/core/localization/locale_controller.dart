import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/shared_preferences_provider.dart';

/// Holds and persists the app's current [Locale].
///
/// On first launch it follows the device locale when it is one we support,
/// otherwise English. Once the user picks a language via the in-app toggle the
/// choice is saved to [SharedPreferences] and always wins on later launches.
class LocaleController extends Notifier<Locale> {
  static const String _key = 'locale_code';

  /// Languages the app ships translations for.
  static const List<Locale> supportedLocales = [Locale('en'), Locale('fr')];

  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (saved != null && _isSupported(saved)) {
      return Locale(saved);
    }
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    return _isSupported(device.languageCode)
        ? Locale(device.languageCode)
        : const Locale('en');
  }

  void setLocale(Locale locale) {
    if (!_isSupported(locale.languageCode) || locale == state) return;
    state = locale;
    ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }

  /// Flips between the two shipped languages (English <-> French).
  void toggle() => setLocale(
    state.languageCode == 'en' ? const Locale('fr') : const Locale('en'),
  );

  static bool _isSupported(String code) =>
      supportedLocales.any((l) => l.languageCode == code);
}

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
