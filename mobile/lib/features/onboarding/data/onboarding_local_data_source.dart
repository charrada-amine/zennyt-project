import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/shared_preferences_provider.dart';

/// Persists whether the user has already completed the onboarding flow, so it
/// is only shown on the very first launch.
class OnboardingLocalDataSource {
  const OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _kCompletedKey = 'onboarding_completed';

  bool isCompleted() => _prefs.getBool(_kCompletedKey) ?? false;

  Future<void> setCompleted() => _prefs.setBool(_kCompletedKey, true);
}

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>(
  (ref) => OnboardingLocalDataSource(ref.watch(sharedPreferencesProvider)),
);
