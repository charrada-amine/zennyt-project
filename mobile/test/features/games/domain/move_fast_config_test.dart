import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/move_fast_config.dart';

/// Move Fast — config configurable (mode de fin) + bandes centralisées.
void main() {
  test('mode de fin par défaut = fixedBudget (comportement produit inchangé)', () {
    // ⚠️ Diverge de la fiche (reachMaxMultiplier) mais reste le défaut — miroir
    // du backend MoveFastConfig.SESSION_END_MODE.
    expect(MoveFastConfig.sessionEndMode, MoveFastSessionEndMode.fixedBudget);
    expect(MoveFastConfig.targetCorrectAnswers, 12);
    expect(MoveFastConfig.maxResponses, 18);
    expect(MoveFastConfig.sessionSeconds, 84);
  });

  test('bandes d\'interprétation centralisées — seuils <40/<60/<75/<90/sinon', () {
    expect(MoveFastConfig.interpretMoveFast(0), 'Très faible');
    expect(MoveFastConfig.interpretMoveFast(39.9), 'Très faible');
    expect(MoveFastConfig.interpretMoveFast(40), 'Moyen faible');
    expect(MoveFastConfig.interpretMoveFast(60), 'Moyen');
    expect(MoveFastConfig.interpretMoveFast(75), 'Bon');
    expect(MoveFastConfig.interpretMoveFast(90), 'Excellent');
    expect(MoveFastConfig.interpretMoveFast(100), 'Excellent');
  });
}
