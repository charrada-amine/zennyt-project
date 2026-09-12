import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/strategic_choices_bank_loader.dart';
import 'package:zennyt/features/games/domain/config/strategic_choices_content.dart';
import 'package:zennyt/features/games/domain/entities/strategic_choices_bank.dart';
import 'package:zennyt/features/games/domain/entities/strategic_choices_metrics.dart';
import 'package:zennyt/features/games/domain/service/strategic_choices_scoring.dart';

/// Barème « Choix Stratégiques » — parité avec le serveur.
///
/// Ces valeurs doivent rester identiques à celles de
/// `StrategicChoicesScoringTest.java` : hors ligne et en ligne, un même parcours
/// doit donner le même score, sinon le joueur verrait son résultat changer selon
/// l'état du réseau.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StrategicChoicesBank bank;
  setUpAll(() async {
    StrategicChoicesBankLoader.resetForTest();
    bank = await StrategicChoicesBankLoader.load();
  });

  StrategicChoicesMetrics journeyOf(
    StrategicChoiceStrategy strategy, {
    List<String>? ids,
  }) {
    final situations =
        ids ?? [for (var i = 1; i <= 10; i++) 'CS-${i.toString().padLeft(3, '0')}'];
    return StrategicChoicesMetrics(
      answers: [
        for (final id in situations)
          StrategicChoiceAnswerMetric(
            situationId: id,
            selectedStrategy: strategy,
            responseTimeMs: 4000,
            medium: StrategicChoiceMedium.video,
          ),
      ],
    );
  }

  test('ruminer ne rapporte rien : 0/30 et dix réponses contre-productives', () {
    final report = strategicChoicesReport(
      journeyOf(StrategicChoiceStrategy.ruminate),
      bank,
    );

    expect(report.rawPoints, 0);
    expect(report.maxPoints, 30);
    expect(report.counterProductiveChoices, 10);
    expect(report.optimalChoices, 0);
    expect(report.level, 'Reactive strategies');
    expect(report.chanceCorrectedPercent, 0);
  });

  test('le maximum suit le nombre de situations jouées', () {
    expect(strategicChoicesMaxPoints(10), 30);
    expect(strategicChoicesMaxPoints(4), 12);
  });

  test('une stratégie constante se voit au nombre de stratégies mobilisées', () {
    // Aucun seuil de score ne peut trahir une partie menée avec un seul
    // libellé : « Assertive communication » vaut 3 dans 23 fiches sur 60, donc
    // un tirage favorable donne le maximum sans rien lire. C'est ce compteur
    // qui le dit.
    final report = strategicChoicesReport(
      journeyOf(StrategicChoiceStrategy.assertiveCommunication),
      bank,
    );

    expect(report.distinctStrategiesUsed, 1);
    expect(
      report.mostUsedStrategy,
      StrategicChoiceStrategy.assertiveCommunication,
    );
  });

  test('le rapport nomme les fiches que le psychologue doit valider', () {
    final report = strategicChoicesReport(
      journeyOf(StrategicChoiceStrategy.breathePause),
      bank,
    );

    expect(report.provisionalScoring, isTrue);
    expect(report.situationsAwaitingReview, ['CS-002']);
  });

  test('les paliers portent sur l\'indice corrigé, pas sur le brut', () {
    expect(strategicChoicesInterpret(100), 'Highly adaptive strategies');
    expect(strategicChoicesInterpret(60), 'Highly adaptive strategies');
    expect(strategicChoicesInterpret(59.9), 'Adaptive strategies');
    expect(strategicChoicesInterpret(25), 'Adaptive strategies');
    expect(strategicChoicesInterpret(24.9), 'Reactive strategies');
    expect(strategicChoicesInterpret(0), 'Reactive strategies');
  });

  test('le hasard vaut 0 sur l\'indice corrigé, pas 38 % comme en brut', () {
    final report = strategicChoicesReport(
      journeyOf(StrategicChoiceStrategy.breathePause),
      bank,
    );

    final base = report.chanceBaseline;
    expect(base / report.maxPoints * 100, inInclusiveRange(30, 45));
    expect(
      strategicChanceCorrectedPercent(base.round(), report.maxPoints, base),
      closeTo(0, 3),
    );
    expect(
      strategicChanceCorrectedPercent(report.maxPoints, report.maxPoints, base),
      100,
    );
    // Sous le hasard, l'indice est planché à 0 — pas négatif.
    expect(strategicChanceCorrectedPercent(0, 30, 11.4), 0);
  });

  test('le profil de coping range les huit stratégies selon Carver', () {
    expect(
      strategicChoicesReport(
        journeyOf(StrategicChoiceStrategy.directAction),
        bank,
      ).copingProfile[CopingFamily.problemFocused],
      10,
    );
    expect(
      strategicChoicesReport(
        journeyOf(StrategicChoiceStrategy.humor),
        bank,
      ).copingProfile[CopingFamily.emotionFocused],
      10,
    );
    expect(
      strategicChoicesReport(
        journeyOf(StrategicChoiceStrategy.avoidFlee),
        bank,
      ).copingProfile[CopingFamily.dysfunctional],
      10,
    );

    // « Seek support » recouvre chez Carver deux échelles rangées dans deux
    // familles : la classer d'office fausserait le profil.
    final soutien = strategicChoicesReport(
      journeyOf(StrategicChoiceStrategy.seekSupport),
      bank,
    );
    expect(soutien.copingProfile[CopingFamily.unresolved], 10);
    expect(soutien.sharePercent(CopingFamily.unresolved), 100.0);
  });
}
