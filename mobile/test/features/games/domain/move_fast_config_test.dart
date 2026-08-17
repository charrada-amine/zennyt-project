import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/move_fast_config.dart';

/// Move Fast — config configurable (mode de fin) + bandes centralisées.
void main() {
  test('mode de fin par défaut = fixedBudget (comportement produit inchangé)', () {
    // ⚠️ Diverge de la fiche (reachMaxMultiplier) mais reste le défaut — miroir
    // du backend MoveFastConfig.SESSION_END_MODE.
    expect(MoveFastConfig.sessionEndMode, MoveFastSessionEndMode.fixedBudget);
    expect(MoveFastConfig.targetCorrectAnswers, 40);
    expect(MoveFastConfig.maxResponses, 60);
    expect(MoveFastConfig.sessionSeconds, 600);
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

  test('le budget de session permet d\'atteindre le multiplicateur maximum', () {
    // Le multiplicateur monte d'un cran toutes [correctStreakForUpgrade] bonnes
    // réponses consécutives. Passer de 1 à [maxMultiplier] demande donc
    // (maxMultiplier - 1) × correctStreakForUpgrade bonnes réponses.
    //
    // C'est exactement l'invariant qui était rompu : avec targetCorrectAnswers = 12
    // la session s'arrêtait après 3 montées, et ×10 était inatteignable — le
    // multiplicateur plafonnait à ×4 quoi que fasse le joueur.
    final requiredCorrect =
        (MoveFastConfig.maxMultiplier - 1) * MoveFastConfig.correctStreakForUpgrade;

    expect(
      MoveFastConfig.targetCorrectAnswers,
      greaterThan(requiredCorrect),
      reason:
          'la session doit durer au-delà des $requiredCorrect bonnes réponses '
          'nécessaires pour atteindre x${MoveFastConfig.maxMultiplier}',
    );
    expect(
      MoveFastConfig.maxResponses,
      greaterThanOrEqualTo(MoveFastConfig.targetCorrectAnswers),
      reason: 'le plafond de réponses ne doit pas couper avant la cible',
    );
  });
}
