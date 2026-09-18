import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/accessibility_provider.dart';
import '../../../auth/domain/entities/user_preferences.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/auth_providers.dart';

/// Local notifications toggle state, kept for instant UI feedback.
class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
  NotificationsEnabledNotifier.new,
);

/// Server-synced preferences (`GET/PUT /users/me/preferences`).
///
/// Loads the account preferences once and mirrors them into the local
/// accessibility + notifications providers (instant UI, app-wide text scale).
/// Saving updates the local state immediately and pushes to the server
/// best-effort, so a flaky connection never blocks the toggle.
class PreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    UserPreferences preferences;
    // No network call when signed out (or in widget tests): fall back to the
    // current local values immediately.
    final signedIn = ref.read(authControllerProvider).value != null;
    if (!signedIn) {
      preferences = _localFallback();
    } else {
      try {
        preferences = await ref
            .read(authRepositoryProvider)
            .getPreferences()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Offline / server error / no network in tests: fall back to local values.
        preferences = _localFallback();
      }
    }
    // NOTE: never mutate other providers here — doing so during build creates a
    // rebuild loop. The UI mirrors the loaded values via `ref.listen` instead.
    return preferences;
  }

  UserPreferences _localFallback() {
    final a11y = ref.read(accessibilityProvider);
    return UserPreferences(
      notificationsEnabled: ref.read(notificationsEnabledProvider),
      highContrast: a11y.highContrast,
      textSizePx: a11y.textSizePx.round(),
    );
  }

  Future<void> save(UserPreferences preferences) async {
    state = AsyncData(preferences);
    _mirrorLocally(preferences);
    try {
      await ref.read(authRepositoryProvider).updatePreferences(preferences);
    } catch (_) {
      // Best-effort sync; the local state already reflects the choice.
    }
  }

  void _mirrorLocally(UserPreferences preferences) {
    ref.read(notificationsEnabledProvider.notifier).set(preferences.notificationsEnabled);
    ref.read(accessibilityProvider.notifier).setHighContrast(preferences.highContrast);
    ref.read(accessibilityProvider.notifier).setTextSize(preferences.textSizePx.toDouble());
  }
}

final preferencesProvider = AsyncNotifierProvider<PreferencesNotifier, UserPreferences>(
  PreferencesNotifier.new,
);
