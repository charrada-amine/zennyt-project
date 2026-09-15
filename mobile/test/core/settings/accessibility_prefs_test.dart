import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/settings/accessibility_provider.dart';

void main() {
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
