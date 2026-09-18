import 'dart:convert';

import 'package:flutter/services.dart';
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
  late Map<String, dynamic> rawBank;
  setUpAll(() async {
    StrategicChoicesBankLoader.resetForTest();
    rawBank =
        jsonDecode(
              await rootBundle.loadString(StrategicChoicesBankLoader.assetPath),
            )
            as Map<String, dynamic>;
    bank = await StrategicChoicesBankLoader.load();
  });

  test('les 80 situations sont là, identifiants uniques', () {
    // 60 fiches du client (CS-001..060) + 20 situations de la proposition,
    // dont la clé découle de l'hypothèse de correspondance
    // (CS-101..120). Identifiants disjoints : rien n'est remplacé.
    expect(bank.scenarios, hasLength(80));
    expect(bank.scenarios.map((s) => s.id).toSet(), hasLength(80));
    expect(bank.byId('CS-120'), isNotNull);
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

  test('les fiches à valider sont toutes signalées', () {
    // Le barème a été reconstruit à partir des seuls titres, sans visionnage.
    // Sa propre synthèse nomme trois situations dont le contexte est ambigu et
    // demande une validation du psychologue. Perdre ce signal à la conversion
    // ferait passer une cotation provisoire pour une cotation validée.
    final aValider = bank.scenarios
        .where((s) => s.needsPsychologistValidation)
        .map((s) => s.id)
        .toList();
    // Trois fiches du client dont il signale lui-même l'ambiguïté, plus les
    // vingt situations de la proposition : leur clé est dérivée de la théorie,
    // elle n'a pas été cotée par un panel.
    expect(aValider.where((id) => id.startsWith('CS-0')).toList(), [
      'CS-002',
      'CS-017',
      'CS-047',
    ]);
    expect(aValider.where((id) => id.startsWith('CS-1')), hasLength(20));
  });

  test('le support écrit existe, avec le texte littéral du message', () {
    // Les 60 fiches du client décrivent toutes une mini-vidéo et ne
    // fournissent aucun texte de message. Six situations de la proposition
    // sont des écrits, avec leur contenu exact : elles sont jouables sans
    // attendre la production vidéo.
    final ecrites = bank.scenarios
        .where((s) => s.medium == StrategicChoiceMedium.written)
        .toList();
    expect(ecrites, hasLength(6));
    expect(
      {for (final situation in ecrites) situation.id: situation.message},
      const {
        'CS-102':
            '« Votre demande a bien été enregistrée. » — seule réponse reçue, il y a huit jours. Vos deux relances depuis sont restées sans réponse.',
        'CS-104':
            "« Après examen, votre candidature n'a pas été retenue pour ce poste. La décision est définitive. »",
        'CS-108':
            "« Priorité absolue sur le dossier Legrand aujourd'hui. » — et, dix minutes plus tôt : « Rien avant l'audit, on gèle Legrand. »",
        'CS-112':
            '« Bonjour, nous venons de réceptionner la livraison : la référence ne correspond pas à la commande. Que prévoyez-vous ? »',
        'CS-115':
            "« Le comité a décidé l'arrêt du projet. Votre réaffectation prend effet lundi prochain. »",
        'CS-116': "« J'ai confirmé au client pour jeudi. Tu gères ? »",
      },
      reason: 'les six messages doivent rester littéraux et reproductibles',
    );
    expect(
      bank.scenarios
          .where((s) => s.id.startsWith('CS-0'))
          .every((s) => s.medium == StrategicChoiceMedium.video),
      isTrue,
      reason: 'les 60 fiches du client restent toutes des vidéos',
    );
    // Aucune situation vidéo ne doit porter de message : elle afficherait une
    // bulle ET un emplacement.
    expect(
      bank.scenarios
          .where((s) => s.medium == StrategicChoiceMedium.video)
          .every((s) => s.message == null),
      isTrue,
    );
  });

  test('une situation WRITTEN sans message est rejetée', () {
    final source = (rawBank['situations'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((situation) => situation['id'] == 'CS-112');
    final invalid = jsonDecode(jsonEncode(source)) as Map<String, dynamic>
      ..remove('message');

    expect(
      () => StrategicChoiceScenario.fromJson(invalid),
      throwsArgumentError,
    );
  });

  test('une situation VIDEO avec message est rejetée', () {
    final source = (rawBank['situations'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((situation) => situation['id'] == 'CS-001');
    final invalid = jsonDecode(jsonEncode(source)) as Map<String, dynamic>
      ..['message'] = 'Message inattendu';

    expect(
      () => StrategicChoiceScenario.fromJson(invalid),
      throwsArgumentError,
    );
  });

  test(
    '« Ruminate » reste la moins adaptative, sans être un leurre constant',
    () {
      // Constat, pas reproche : ruminer n'est jamais la réponse. La stratégie ne
      // départage donc aucun joueur au-delà du premier essai — elle fonctionne
      // comme un leurre, pas comme une mesure. À signaler au client plutôt qu'à
      // corriger ici : c'est son barème.
      // Cotée 0 dans les 60 fiches du client, elle ne départageait personne
      // au-delà du premier essai. La proposition la fait varier de 0 à 1 selon
      // que ressasser coupe ou non l'action — elle reste la stratégie la moins
      // adaptative de la banque, mais elle porte enfin de l'information.
      double moyenne(StrategicChoiceStrategy st) =>
          bank.scenarios
              .map((s) => s.byStrategy(st).score)
              .reduce((a, b) => a + b) /
          bank.scenarios.length;
      final ruminer = moyenne(StrategicChoiceStrategy.ruminate);
      for (final st in StrategicChoiceStrategy.values) {
        if (st == StrategicChoiceStrategy.ruminate) continue;
        expect(ruminer, lessThanOrEqualTo(moyenne(st)), reason: '$st');
      }
      expect(
        bank.scenarios
            .map((s) => s.byStrategy(StrategicChoiceStrategy.ruminate).score)
            .toSet(),
        isNot({0}),
        reason: 'une stratégie constante à 0 ne mesure plus rien',
      );
    },
  );

  test('aucune stratégie constante ne sature le barème', () {
    // Un joueur qui coche toujours le même libellé, sans lire la scène, ne
    // doit pas s'approcher du plafond. « Communication assertive » obtient
    // aujourd'hui 1,94/3 de moyenne contre 2,99 pour un jeu parfait : c'est
    // exploitable, et ce test fige le niveau pour qu'il ne s'aggrave pas.
    double moyenne(StrategicChoiceStrategy s) =>
        bank.scenarios
            .map((x) => x.byStrategy(s).score)
            .reduce((a, b) => a + b) /
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
      reason:
          'une stratégie constante vaut déjà ${meilleure.toStringAsFixed(2)}'
          ' sur un plafond de ${plafond.toStringAsFixed(2)}',
    );
  });
}
