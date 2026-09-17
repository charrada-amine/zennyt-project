import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/settings/accessibility_provider.dart';

class _NonlinearTextScaler extends TextScaler {
  const _NonlinearTextScaler();

  @override
  double scale(double fontSize) =>
      fontSize <= 20 ? fontSize * 2 : 40 + (fontSize - 20) * 1.5;

  @override
  double get textScaleFactor => throw StateError('Do not linearize the scaler');
}

void main() {
  group('AccessibilityPrefs.textScaler', () {
    test('the default preserves the system scaler instance', () {
      const systemScaler = _NonlinearTextScaler();
      final scaler = const AccessibilityPrefs().textScaler(systemScaler);

      expect(scaler, same(systemScaler));
      expect(scaler.scale(12), 24);
      expect(scaler.scale(40), 70);
    });

    test('composes the app factor with linear system scaling', () {
      final scaler = const AccessibilityPrefs(textSizePx: 27)
          .textScaler(const TextScaler.linear(2));

      expect(scaler.scale(12), 36);
      expect(scaler.scale(40), 120);
    });

    test('applies the app factor without linearizing system scaling', () {
      const systemScaler = _NonlinearTextScaler();
      for (final size in [12.0, 27.0]) {
        final prefs = AccessibilityPrefs(textSizePx: size);
        final scaler = prefs.textScaler(systemScaler);

        for (final fontSize in [0.0, 12.0, 20.0, 40.0, 80.0]) {
          expect(scaler.scale(fontSize),
              closeTo(systemScaler.scale(fontSize) * prefs.textScale, 0.001));
        }
      }
    });

    test('retains app scaling when system scaling is disabled', () {
      final scaler = const AccessibilityPrefs(textSizePx: 27)
          .textScaler(TextScaler.noScaling);

      expect(scaler.scale(12), 18);
      expect(scaler.scale(40), 60);
    });

    test('only clamps the app factor, not the system scaling', () {
      final scaler = const AccessibilityPrefs(textSizePx: 36)
          .textScaler(const TextScaler.linear(3));

      expect(scaler.scale(20), 105);
    });

    test('equality includes both the system scaler and the app factor', () {
      const prefs = AccessibilityPrefs(textSizePx: 27);
      final scaler = prefs.textScaler(const TextScaler.linear(2));
      final equivalent = prefs.textScaler(const TextScaler.linear(2));

      expect(scaler, equivalent);
      expect(scaler.hashCode, equivalent.hashCode);
      expect(scaler, isNot(prefs.textScaler(const TextScaler.linear(3))));
      expect(scaler, isNot(const AccessibilityPrefs(textSizePx: 24)
          .textScaler(const TextScaler.linear(2))));
    });
  });

  group('AccessibilityPrefs.textScale', () {
    test('18 px is the 1.0 baseline', () {
      const prefs = AccessibilityPrefs(textSizePx: 18);
      expect(prefs.textScale, 1.0);
    });

    test('scales linearly and is clamped to a safe range', () {
      expect(const AccessibilityPrefs(textSizePx: 9).textScale, closeTo(0.55, 0.001));
      expect(const AccessibilityPrefs(textSizePx: 36).textScale, closeTo(1.75, 0.001));
    });

    test('defaults match the design (contrast on, 18 px)', () {
      const prefs = AccessibilityPrefs();
      expect(prefs.highContrast, isTrue);
      expect(prefs.textSizePx, 18);
    });
  });
}
