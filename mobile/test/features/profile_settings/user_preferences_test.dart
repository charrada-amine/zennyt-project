import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/auth/domain/entities/user_preferences.dart';

void main() {
  group('UserPreferences', () {
    test('defaults match the design (notifications on, contrast on, 18px)', () {
      expect(UserPreferences.defaults.notificationsEnabled, isTrue);
      expect(UserPreferences.defaults.highContrast, isTrue);
      expect(UserPreferences.defaults.textSizePx, 18);
    });

    test('parses and serializes the wire shape', () {
      final parsed = UserPreferences.fromJson({
        'notificationsEnabled': false,
        'highContrast': true,
        'textSizePx': 24,
      });
      expect(parsed.notificationsEnabled, isFalse);
      expect(parsed.highContrast, isTrue);
      expect(parsed.textSizePx, 24);
      expect(parsed.toJson(), {
        'notificationsEnabled': false,
        'highContrast': true,
        'textSizePx': 24,
      });
    });

    test('missing fields fall back to defaults', () {
      final parsed = UserPreferences.fromJson(const {});
      expect(parsed, UserPreferences.defaults);
    });
  });
}
