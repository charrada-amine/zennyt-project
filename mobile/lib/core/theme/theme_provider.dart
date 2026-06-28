import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/shared_preferences_provider.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// THEME PROVIDER
/// Manages the app's ThemeMode with SharedPreferences persistence.
/// Default is ThemeMode.light.
/// ──────────────────────────────────────────────────────────────────────────────

const _kThemeModeKey = 'theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kThemeModeKey);
    if (stored == 'dark') return ThemeMode.dark;
    return ThemeMode.light; // default
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setMode(next);
  }

  void setMode(ThemeMode mode) {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_kThemeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
