import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/data/reflective_pause_bank_loader.dart';
import 'package:zennyt/features/games/domain/config/reflective_pause_config.dart';
import 'package:zennyt/features/games/domain/entities/reflective_pause_bank.dart';
import 'package:zennyt/features/games/domain/entities/reflective_pause_metrics.dart';

/// Banque « Temps Réflexif » — ce que l'asset doit garantir.
///
/// L'asset est engendré depuis un .docx par un script. Une fiche mal lue ne
/// casse rien à la compilation : elle se verrait en partie, ou pas du tout.
/// Ces tests sont le seul filet entre le document du client et le jeu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReflectivePauseBank bank;
  setUpAll(() async {
    ReflectivePauseBankLoader.resetForTest();
    bank = await ReflectivePauseBankLoader.load();
  });

  test('les 84 situations sont là, identifiants uniques', () {
    // 60 fiches du client (TR-001..060) + 24 situations de la proposition
    // validée, calquée sur le STEM (TR-101..124). Les identifiants sont
    // disjoints : les nouvelles s'ajoutent, elles ne remplacent rien.
    expect(bank.situations, hasLength(84));
    expect(bank.situations.map((s) => s.id).toSet(), hasLength(84));
    expect(bank.byId('TR-124'), isNotNull);
    expect(bank.byId('TR-001').pilotValidated, isTrue);
    // TR-001 à TR-005 sont les pilotes validés par le psychologue.
    expect(bank.situations.where((s) => s.pilotValidated), hasLength(5));
  });

  test('les dix catégories restent toutes couvertes', () {
    // L'équilibre strict de la banque d'origine (6 par catégorie, 20 par
    // difficulté) ne tient plus : l'apport suit le blueprint du STEM, qui
    // structure par ÉMOTION et non par catégorie. Ce qui doit rester vrai,
    // c'est qu'aucune catégorie ne disparaisse et qu'aucune ne domine.
    final parCategorie = <int, int>{};
    for (final s in bank.situations) {
      parCategorie[s.categoryNumber] = (parCategorie[s.categoryNumber] ?? 0) + 1;
    }
    expect(parCategorie.keys, hasLength(10));
    expect(parCategorie.values.every((n) => n >= 6), isTrue);
    expect(parCategorie.values.every((n) => n <= 12), isTrue);

    for (final d in ReflectivePauseDifficulty.values) {
      expect(bank.byDifficulty(d).length, greaterThanOrEqualTo(20));
    }
  });

  test('chaque situation propose les cinq réactions, cotées 0 à 3', () {
    for (final s in bank.situations) {
      expect(s.choices, hasLength(5), reason: s.id);
      expect(
        s.choices.map((c) => c.responseType).toSet(),
        hasLength(5),
        reason: '${s.id} : une réaction est en double',
      );
      expect(s.choices.every((c) => c.score >= 0 && c.score <= 3), isTrue);
      expect(s.bestScore, 3, reason: '${s.id} : aucune réponse à 3 points');
    }
  });

  test('rien n\'est vide : contexte, question et délai', () {
    for (final s in bank.situations) {
      expect(s.context, isNotEmpty, reason: s.id);
      expect(s.question, isNotEmpty, reason: s.id);
      expect(s.trigger, isNotEmpty, reason: s.id);
      // Les guillemets du document ne doivent pas rester dans la question.
      expect(s.question.startsWith('«'), isFalse, reason: s.id);
      expect(
        s.responseDeadlineSec,
        inInclusiveRange(10, 40),
        reason: '${s.id} : délai hors de toute plage plausible',
      );
      expect(s.wordsToRead, greaterThan(0), reason: s.id);
    }
  });

  test('la réponse impulsive n\'est jamais la mieux cotée', () {
    // Le jeu mesure le recul : une situation où s'emporter serait la meilleure
    // réponse signalerait une fiche mal lue, pas une subtilité clinique.
    for (final s in bank.situations) {
      final impulsive = s.byResponseType(
        ReflectivePauseResponseType.respondImpulsively,
      );
      expect(impulsive.score, lessThan(s.bestScore), reason: s.id);
    }
  });

  test('l\'ordre d\'affichage casse la position apprise de la banque', () {
    // Dans le document, « A » est la réponse impulsive des soixante fiches et
    // « B » toujours « respirer ». Affiché tel quel, l'ordre s'apprend en deux
    // situations et se répond sans lire la scène.
    // Le défaut est propre aux 60 fiches du client : « A » y est la réponse
    // impulsive sans exception.
    final clientBrut = bank.situations
        .where((s) => s.id.startsWith('TR-0'))
        .map((s) => s.choices.first.responseType)
        .toSet();
    expect(
      clientBrut,
      {ReflectivePauseResponseType.respondImpulsively},
      reason: 'le défaut de la banque livrée, qu\'il faut neutraliser',
    );

    // Les situations de la proposition validée ne l'ont pas : leur ordre a été
    // mélangé à la rédaction. Le mélange à l'affichage reste néanmoins appliqué
    // à toute la banque, puisqu'elle mêle les deux.
    final propositionBrut = bank.situations
        .where((s) => s.id.startsWith('TR-1'))
        .map((s) => s.choices.first.responseType)
        .toSet();
    expect(
      propositionBrut.length,
      greaterThan(1),
      reason: 'la position ne doit plus trahir la catégorie',
    );

    var deplacees = 0;
    for (final s in bank.situations) {
      final affichees = s.choicesInDisplayOrder(4242);
      expect(affichees.toSet(), s.choices.toSet(), reason: 'aucune perte');
      if (affichees.first.responseType !=
          ReflectivePauseResponseType.respondImpulsively) {
        deplacees++;
      }
    }
    expect(
      deplacees,
      greaterThan(40),
      reason: 'la réponse impulsive doit cesser d\'ouvrir la liste',
    );
  });

  test('l\'ordre reste stable pour une même graine', () {
    // Sans quoi les réponses se réordonneraient sous les doigts du joueur à
    // chaque reconstruction de l'écran.
    final s = bank.byId('TR-030');
    final premier = s.choicesInDisplayOrder(7).map((c) => c.letter).toList();
    expect(s.choicesInDisplayOrder(7).map((c) => c.letter).toList(), premier);
  });

  test('le support écrit existe désormais, sans avoir été inventé', () {
    // Le client attend « une vidéo OU un message écrit selon le scénario »,
    // mais la banque livrée ne fait pas ce partage : les soixante fiches
    // portent un prompt vidéo et une durée vidéo, y compris celles dont la
    // scène est un SMS — TR-001 est une notification lue à l'écran, spécifiée
    // comme une vidéo de 10 s dont le prompt interdit de rendre le texte
    // lisible.
    //
    // Ce test dit donc l'état RÉEL de la banque, pas une règle définitive : le
    // jour où le client fournit des situations écrites, il tombe, et c'est
    // exactement le signal qu'on veut.
    // Les 60 fiches du client déclarent toutes une mini-vidéo — y compris
    // celles dont la scène est un SMS, dont le prompt interdit de rendre le
    // texte lisible. La proposition validée apporte 7 situations réellement
    // écrites, avec le texte littéral du message : elles sont jouables sans
    // attendre la production vidéo.
    final ecrites = bank.situations
        .where((s) => s.medium == ReflectivePauseMedium.written)
        .toList();
    expect(ecrites, hasLength(7));
    expect(
      ecrites.every((s) => s.trigger.isNotEmpty),
      isTrue,
      reason: 'une situation écrite sans message n\'est pas jouable',
    );
    expect(
      bank.situations.where((s) => s.id.startsWith('TR-0')).every(
            (s) => s.medium == ReflectivePauseMedium.video,
          ),
      isTrue,
      reason: 'les 60 fiches du client restent toutes des vidéos',
    );
  });

  test('le barème serveur connaît les 84 identifiants', () {
    // La table était écrite à la main sur dix moments inventés. Un identifiant
    // absent fait lever le domaine : la partie échouerait à l'enregistrement.
    for (final s in bank.situations) {
      expect(
        ReflectivePauseConfig.recommended.containsKey(s.id),
        isTrue,
        reason: '${s.id} absent du barème',
      );
      // La réaction recommandée est celle qui porte la cotation maximale.
      final attendues = s.choices
          .where((c) => c.score == s.bestScore)
          .map((c) => c.responseType)
          .toSet();
      expect(ReflectivePauseConfig.recommended[s.id], attendues, reason: s.id);
    }
  });
}
