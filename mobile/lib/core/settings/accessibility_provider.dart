import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/shared_preferences_provider.dart';

/// Accessibility preferences (design screens 110 / 259).
///
/// There is **no backend endpoint** for these preferences yet (see
/// `docs/SCREENS_1TO1_PLAN.md` §2) — they are persisted locally so the choice
/// survives an app restart. The text size is applied globally as a scale
/// relative to the design's 18 px preview baseline.
@immutable
class AccessibilityPrefs {
  const AccessibilityPrefs({this.highContrast = true, this.textSizePx = 18});

  final bool highContrast;

  /// Preview/base font size in px (design shows 18 px). Range 10–30.
  final double textSizePx;

  /// Scale applied to the app's text, relative to the 18 px baseline.
  double get textScale => (textSizePx / 18).clamp(0.55, 1.75);

  TextScaler textScaler(TextScaler systemScaler) => textScale == 1
      ? systemScaler
      : _AppTextScaler(systemScaler, textScale);

  AccessibilityPrefs copyWith({bool? highContrast, double? textSizePx}) =>
      AccessibilityPrefs(
        highContrast: highContrast ?? this.highContrast,
        textSizePx: textSizePx ?? this.textSizePx,
      );
}

class _AppTextScaler extends TextScaler {
  const _AppTextScaler(this.systemScaler, this.factor);

  final TextScaler systemScaler;
  final double factor;

  @override
  double scale(double fontSize) => systemScaler.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _AppTextScaler &&
      other.systemScaler == systemScaler &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(systemScaler, factor);
}

const _kContrastKey = 'a11y_high_contrast';
const _kTextSizeKey = 'a11y_text_size';

class AccessibilityNotifier extends Notifier<AccessibilityPrefs> {
  @override
  AccessibilityPrefs build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AccessibilityPrefs(
      highContrast: prefs.getBool(_kContrastKey) ?? true,
      textSizePx: prefs.getDouble(_kTextSizeKey) ?? 18,
    );
  }

  void setHighContrast(bool value) {
    state = state.copyWith(highContrast: value);
    ref.read(sharedPreferencesProvider).setBool(_kContrastKey, value);
  }

  void setTextSize(double px) {
    final clamped = px.clamp(10, 30).toDouble();
    state = state.copyWith(textSizePx: clamped);
    ref.read(sharedPreferencesProvider).setDouble(_kTextSizeKey, clamped);
  }
}

final accessibilityProvider = NotifierProvider<AccessibilityNotifier, AccessibilityPrefs>(
  AccessibilityNotifier.new,
);
