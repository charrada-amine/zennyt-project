import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/shared_preferences_provider.dart';

/// Local progress over the cognitive dimensions shown on the games hub.
///
/// The design (screens 68/73/74) drives a "Coverage X%" indicator and marks
/// completed dimension cards. The backend does **not** expose per-module
/// coverage yet (see `RECRUITMENT_MODULE.md` §15.7 and
/// `docs/SCREENS_1TO1_PLAN.md` §2 — `coverage_ratio` is frozen at 100), so this
/// is a provisional, client-local approximation: a dimension is marked done once
/// its game session is returned from. It is a UI progress indicator only —
/// scores themselves are always computed server-side.
const List<String> kCognitiveDimensions = [
  'Cognitive Flexibility',
  'Working Memory',
  'Decision-Making',
  'Executive Planning',
  'Emotional Regulation',
];

@immutable
class GamesProgress {
  const GamesProgress({
    this.completedDimensions = const {},
    this.consentGiven = false,
    this.introSeen = false,
  });

  final Set<String> completedDimensions;

  /// The anti-fraud monitoring consent modal was accepted (design 76). Asked
  /// once, then remembered locally.
  final bool consentGiven;

  /// The « Play & discover your talent » intro of the games hub was passed
  /// (« Explore games »). Shown once, then the hub opens on the catalogue.
  final bool introSeen;

  double get coverage =>
      kCognitiveDimensions.isEmpty ? 0 : completedDimensions.length / kCognitiveDimensions.length;

  GamesProgress copyWith({
    Set<String>? completedDimensions,
    bool? consentGiven,
    bool? introSeen,
  }) =>
      GamesProgress(
        completedDimensions: completedDimensions ?? this.completedDimensions,
        consentGiven: consentGiven ?? this.consentGiven,
        introSeen: introSeen ?? this.introSeen,
      );
}

const _kCompletedKey = 'games_completed_dimensions';
const _kConsentKey = 'games_monitoring_consent';
const _kIntroSeenKey = 'games_hub_intro_seen';

class GamesProgressNotifier extends Notifier<GamesProgress> {
  @override
  GamesProgress build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final completed = prefs.getStringList(_kCompletedKey) ?? const [];
    return GamesProgress(
      completedDimensions: completed.toSet(),
      consentGiven: prefs.getBool(_kConsentKey) ?? false,
      introSeen: prefs.getBool(_kIntroSeenKey) ?? false,
    );
  }

  void markCompleted(String dimension) {
    if (!kCognitiveDimensions.contains(dimension)) return;
    final next = {...state.completedDimensions, dimension};
    state = state.copyWith(completedDimensions: next);
    ref.read(sharedPreferencesProvider).setStringList(_kCompletedKey, next.toList());
  }

  void setConsent(bool value) {
    state = state.copyWith(consentGiven: value);
    ref.read(sharedPreferencesProvider).setBool(_kConsentKey, value);
  }

  void markIntroSeen() {
    state = state.copyWith(introSeen: true);
    ref.read(sharedPreferencesProvider).setBool(_kIntroSeenKey, true);
  }

  void reset() {
    state = const GamesProgress();
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove(_kCompletedKey);
    prefs.remove(_kConsentKey);
    prefs.remove(_kIntroSeenKey);
  }
}

final gamesProgressProvider = NotifierProvider<GamesProgressNotifier, GamesProgress>(
  GamesProgressNotifier.new,
);
