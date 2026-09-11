import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/strategic_choices_bank_loader.dart';
import 'package:zennyt/features/games/domain/config/strategic_choices_content.dart';
import 'package:zennyt/features/games/domain/entities/strategic_choices_bank.dart';

/// Banque « Choix Stratégiques » — ce que l'asset doit garantir.
///
/// L'asset est engendré depuis un .docx par un script. Une fiche mal lue ne
/// casse rien à la compilation : elle se verrait en partie, ou pas du tout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StrategicChoicesBank bank;
  setUpAll(() async {
    StrategicChoicesBankLoader.resetForTest();
    bank = await StrategicChoicesBankLoader.load();
  });

  test('les 60 situations du barème sont là, identifiants uniques', () {
    expect(bank.scenarios, hasLength(60));
    expect(bank.scenarios.map((s) => s.id).toSet(), hasLength(60));
    expect(bank.byId('CS-001').title, 'La réunion interrompue');
    expect(bank.byId('CS-060'), isNotNull);
  });

  test('chaque situation cote les huit stratégies de 0 à 3', () {
    for (final s in bank.scenarios) {
      expect(s.choices, hasLength(8), reason: s.id);
      expect(
        s.choices.map((c) => c.strategy).toSet(),
        StrategicChoiceStrategy.values.toSet(),
        reason: '${s.id} : les huit stratégies ne sont pas toutes cotées',
      );
      expect(s.choices.every((c) => c.score >= 0 && c.score <= 3), isTrue);
      expect(s.bestScore, greaterThanOrEqualTo(2), reason: s.id);
    }
  });

  test('rien n\'est vide : contexte et scène', () {
    for (final s in bank.scenarios) {
      expect(s.context, isNotEmpty, reason: s.id);
      expect(s.scene, isNotEmpty, reason: s.id);
      expect(s.title, isNotEmpty, reason: s.id);
      // Le signal de validation est une donnée, il ne doit pas rester dans le
      // texte affiché au joueur.
      expect(s.context.contains('[ATTENTION]'), isFalse, reason: s.id);
      // Le document cite la scène en bloc Markdown : le chevron ne doit pas
      // survivre à la conversion.
      expect(s.scene.startsWith('>'), isFalse, reason: s.id);
    }
  });

  test('les trois fiches à valider sont conservées telles quelles', () {
    // Le barème a été reconstruit à partir des seuls titres, sans visionnage.
    // Sa propre synthèse nomme trois situations dont le contexte est ambigu et
    // demande une validation du psychologue. Perdre ce signal à la conversion
    // ferait passer une cotation provisoire pour une cotation validée.
    final aValider = bank.scenarios
        .where((s) => s.needsPsychologistValidation)
        .map((s) => s.id)
        .toList();
    expect(aValider, ['CS-002', 'CS-017', 'CS-047']);
  });

  test('les 60 situations sont des vidéos, comme la banque les déclare', () {
    // Le cahier des charges prévoit vidéo ET message écrit ; la banque livrée
    // ne décrit que des mini-vidéos. Ce test dit l'état réel, pas une règle :
    // le jour où des fiches écrites arrivent, il tombe.
    expect(
      bank.scenarios.map((s) => s.medium).toSet(),
      {StrategicChoiceMedium.video},
    );
  });

  test('« Ruminate » est cotée 0 dans les soixante situations', () {
    // Constat, pas reproche : ruminer n'est jamais la réponse. La stratégie ne
    // départage donc aucun joueur au-delà du premier essai — elle fonctionne
    // comme un leurre, pas comme une mesure. À signaler au client plutôt qu'à
    // corriger ici : c'est son barème.
    final scores = bank.scenarios
        .map((s) => s.byStrategy(StrategicChoiceStrategy.ruminate).score)
        .toSet();
    expect(scores, {0});
  });

  test('aucune stratégie constante ne sature le barème', () {
    // Un joueur qui coche toujours le même libellé, sans lire la scène, ne
    // doit pas s'approcher du plafond. « Assertive communication » obtient
    // aujourd'hui 2,00/3 de moyenne contre 2,98 pour un jeu parfait : c'est
    // exploitable, et ce test fige le niveau pour qu'il ne s'aggrave pas.
    double moyenne(StrategicChoiceStrategy s) =>
        bank.scenarios.map((x) => x.byStrategy(s).score).reduce((a, b) => a + b) /
        bank.scenarios.length;

    final meilleure = StrategicChoiceStrategy.values
        .map(moyenne)
        .reduce((a, b) => a > b ? a : b);
    final plafond =
        bank.scenarios.map((s) => s.bestScore).reduce((a, b) => a + b) /
        bank.scenarios.length;

    expect(plafond, greaterThan(2.9));
    expect(
      meilleure,
      lessThan(2.1),
      reason: 'une stratégie constante vaut déjà ${meilleure.toStringAsFixed(2)}'
          ' sur un plafond de ${plafond.toStringAsFixed(2)}',
    );
  });
}
