import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';

/// « J'investigue » — système de niveaux + calibrage/timeout + validité (miroir backend).
void main() {
  group('Système de niveaux (fiche Tableau 1)', () {
    test('longueur de séquence par niveau : 3 → 9, plafonnée', () {
      expect(MemoryQuestConfig.sequenceLengthForLevel(1), 3);
      expect(MemoryQuestConfig.sequenceLengthForLevel(2), 4); // montée de niveau
      expect(MemoryQuestConfig.sequenceLengthForLevel(7), 9);
      expect(MemoryQuestConfig.sequenceLengthForLevel(20), 9); // plafonné
    });

    // Pas CONSTANT d'un objet par niveau, comme le chiffre supplémentaire du
    // jeu de chiffres. L'interpolation 4→12 sur 7 niveaux donnait 4, 5, 7, 8, 9,
    // 11, 12 : la charge sautait de deux objets à certains paliers.
    test('nombre d\'objets : un de plus à chaque niveau', () {
      expect(
        [for (var l = 1; l <= MemoryQuestConfig.totalLevels; l++)
          MemoryQuestConfig.objectCountForLevel(l)],
        [3, 4, 5, 6, 7, 8, 9],
      );
      expect(
        MemoryQuestConfig.objectCountForLevel(50),
        MemoryQuestConfig.maxObjectCount,
        reason: 'plafonné à la taille du catalogue',
      );
    });

    // Le gating avait été levé à 1 pour rendre la distraction visible : elle
    // n'apparaissait jamais. La cause réelle était son accrochage à la mission
    // d'objets (voir `investigate_screen_test.dart`), pas le gating — qui garde
    // donc sa valeur de fiche, celle du backend.
    test('distraction absente aux niveaux 1-2, puis à CHAQUE niveau', () {
      expect(MemoryQuestConfig.distractionMinLevel, 3);
      expect(MemoryQuestConfig.distractionActiveAtLevel(1), isFalse);
      expect(MemoryQuestConfig.distractionActiveAtLevel(2), isFalse);
      expect(MemoryQuestConfig.distractionActiveAtLevel(3), isTrue);
      expect(MemoryQuestConfig.distractionActiveAtLevel(7), isTrue);
    });

    test('deux échecs sur un même niveau terminent la partie', () {
      expect(MemoryQuestConfig.maxFailuresPerLevel, 2);
    });
  });

  group('Temps de mémorisation (modèle à rupture de capacité)', () {
    // Le point du modèle : la pente change à la capacité de la mémoire de
    // travail. Un barème proportionnel donnerait le même supplément partout, et
    // les niveaux hauts deviendraient injouables.
    test('le pas grandit une fois la capacité dépassée', () {
      final k = MemoryQuestConfig.workingMemoryCapacity;
      int step(int n) => MemoryQuestConfig.objectObservationMs(n) -
          MemoryQuestConfig.objectObservationMs(n - 1);

      expect(step(k), MemoryQuestConfig.objectObservationMsPerItem);
      expect(
        step(k + 1),
        MemoryQuestConfig.objectObservationMsPerItem +
            MemoryQuestConfig.objectObservationRehearsalMsPerItem,
      );
      expect(step(k + 1), greaterThan(step(k)));
    });

    test('valeurs de référence du barème communiqué au client', () {
      expect(MemoryQuestConfig.objectObservationMs(3), 4400);
      expect(MemoryQuestConfig.objectObservationMs(4), 5200);
      expect(MemoryQuestConfig.objectObservationMs(6), 7800);
      expect(MemoryQuestConfig.objectObservationMs(9), 11700);
      expect(MemoryQuestConfig.objectObservationMs(12), 15600);
    });

    test('croissance monotone sur tout le parcours', () {
      var previous = 0;
      for (var l = 1; l <= MemoryQuestConfig.totalLevels; l++) {
        final ms = MemoryQuestConfig.objectObservationMs(
          MemoryQuestConfig.objectCountForLevel(l),
        );
        expect(ms, greaterThan(previous), reason: 'niveau $l');
        previous = ms;
      }
    });

    // Sans ce plancher, une série de réussites finirait par servir des niveaux
    // où le joueur n'a pas même le temps de poser les yeux sur chaque image.
    test('l\'allure la plus rapide laisse une fixation par objet', () {
      for (var n = 1; n <= MemoryQuestConfig.maxObjectCount; n++) {
        expect(
          MemoryQuestConfig.objectObservationMs(
            n,
            playerFactor: MemoryQuestConfig.playerPaceMin,
          ),
          greaterThanOrEqualTo(
            MemoryQuestConfig.objectObservationMinMsPerItem * n,
          ),
          reason: '$n objets',
        );
      }
    });

    test('plafonné : au-delà, le joueur s\'ennuie sans mieux retenir', () {
      expect(
        MemoryQuestConfig.objectObservationMs(60),
        MemoryQuestConfig.objectObservationMaxMs,
      );
      // Mais le plafond ne doit JAMAIS rogner un niveau réel, même au joueur le
      // plus lent : sinon il perdrait du temps sans que rien ne l'indique.
      expect(
        MemoryQuestConfig.objectObservationMs(
          MemoryQuestConfig.maxObjectCount,
          playerFactor: MemoryQuestConfig.playerPaceMax,
        ),
        lessThan(MemoryQuestConfig.objectObservationMaxMs),
      );
    });

    test('l\'allure lente allonge, l\'allure rapide raccourcit', () {
      final neutral = MemoryQuestConfig.objectObservationMs(6);
      expect(
        MemoryQuestConfig.objectObservationMs(6, playerFactor: 1.4),
        greaterThan(neutral),
      );
      expect(
        MemoryQuestConfig.objectObservationMs(6, playerFactor: 0.7),
        lessThan(neutral),
      );
    });
  });

  group('Allure du joueur (escalier adaptatif)', () {
    test('une réussite raccourcit, un échec rallonge — et plus fort', () {
      const start = MemoryQuestConfig.playerPaceNeutral;
      final afterWin = MemoryQuestConfig.nextPlayerFactor(start, success: true);
      final afterLoss =
          MemoryQuestConfig.nextPlayerFactor(start, success: false);

      expect(afterWin, lessThan(start));
      expect(afterLoss, greaterThan(start));
      expect(
        afterLoss - start,
        greaterThan(start - afterWin),
        reason: 'pas asymétriques : c\'est ce qui vise 85 % et non 50 %',
      );
    });

    // Propriété qui définit l'escalier : au taux visé, les descentes compensent
    // exactement les remontées. C'est ce qui empêche le temps de dériver.
    test('au taux visé, l\'allure ne dérive pas', () {
      var factor = MemoryQuestConfig.playerPaceNeutral;
      // 100 niveaux au rythme visé : 3 échecs pour 17 réussites (15 %), répartis
      // et non groupés — une salve d'échecs taperait dans les bornes et ne
      // dirait plus rien du point d'équilibre.
      for (var i = 0; i < 100; i++) {
        final failed = i % 20 == 3 || i % 20 == 10 || i % 20 == 17;
        factor = MemoryQuestConfig.nextPlayerFactor(factor, success: !failed);
      }
      expect(factor, closeTo(MemoryQuestConfig.playerPaceNeutral, 0.02));
    });

    test('sous le taux visé l\'allure remonte, au-dessus elle descend', () {
      var slow = MemoryQuestConfig.playerPaceNeutral;
      var fast = MemoryQuestConfig.playerPaceNeutral;
      for (var i = 0; i < 30; i++) {
        slow = MemoryQuestConfig.nextPlayerFactor(slow, success: i % 2 == 0);
        fast = MemoryQuestConfig.nextPlayerFactor(fast, success: true);
      }
      expect(slow, greaterThan(MemoryQuestConfig.playerPaceNeutral));
      expect(fast, lessThan(MemoryQuestConfig.playerPaceNeutral));
    });

    test('bornée dans les deux sens', () {
      var low = MemoryQuestConfig.playerPaceNeutral;
      var high = MemoryQuestConfig.playerPaceNeutral;
      for (var i = 0; i < 500; i++) {
        low = MemoryQuestConfig.nextPlayerFactor(low, success: true);
        high = MemoryQuestConfig.nextPlayerFactor(high, success: false);
      }
      expect(low, MemoryQuestConfig.playerPaceMin);
      expect(high, MemoryQuestConfig.playerPaceMax);
    });
  });

  group('Temps de restitution (loi de Hick)', () {
    test('valeurs de référence du barème communiqué au client', () {
      expect(MemoryQuestConfig.restoreTimeLimitMs(3), 5900);
      expect(MemoryQuestConfig.restoreTimeLimitMs(4), 6608);
      expect(MemoryQuestConfig.restoreTimeLimitMs(6), 7676);
      expect(MemoryQuestConfig.restoreTimeLimitMs(9), 8808);
    });

    // Tout l'intérêt de la loi de Hick : le temps de décision ne double pas
    // quand le nombre d'options double. Une droite ici rendrait les grands
    // niveaux beaucoup trop généreux.
    test('croît en logarithme, pas en droite', () {
      expect(
        MemoryQuestConfig.restoreTimeLimitMs(6),
        greaterThan(MemoryQuestConfig.restoreTimeLimitMs(3)),
      );
      expect(
        MemoryQuestConfig.restoreTimeLimitMs(6),
        lessThan(2 * MemoryQuestConfig.restoreTimeLimitMs(3)),
        reason: 'deux fois plus de cartes, pas deux fois plus de temps',
      );

      // Signature de la loi : chaque doublement du nombre d'options ajoute la
      // MÊME durée. Le terme est en log2(n + 1), donc on double `n + 1` : 4, 8,
      // 16 — soit 3, 7 et 15 cartes.
      final at4 = MemoryQuestConfig.restoreTimeLimitMs(3);
      final at8 = MemoryQuestConfig.restoreTimeLimitMs(7);
      final at16 = MemoryQuestConfig.restoreTimeLimitMs(15);
      expect(at8 - at4, MemoryQuestConfig.restoreMsPerDoubling);
      expect(at16 - at8, MemoryQuestConfig.restoreMsPerDoubling);
    });

    // La restitution est plus longue que la mémorisation aux petits niveaux
    // (choisir prend du temps quand on retient facilement) et plus courte aux
    // grands. Une seule et même loi pour les deux phases raterait les deux.
    test('le rapport avec la mémorisation s\'inverse avec le niveau', () {
      expect(
        MemoryQuestConfig.restoreTimeLimitMs(3),
        greaterThan(MemoryQuestConfig.objectObservationMs(3)),
      );
      expect(
        MemoryQuestConfig.restoreTimeLimitMs(9),
        lessThan(MemoryQuestConfig.objectObservationMs(9)),
      );
    });

    test('borné, et l\'allure du joueur s\'y applique aussi', () {
      expect(MemoryQuestConfig.restoreTimeLimitMs(0),
          MemoryQuestConfig.restoreMinMs);
      expect(MemoryQuestConfig.restoreTimeLimitMs(5000),
          MemoryQuestConfig.restoreMaxMs);
      expect(
        MemoryQuestConfig.restoreTimeLimitMs(9, playerFactor: 1.5),
        greaterThan(MemoryQuestConfig.restoreTimeLimitMs(9)),
      );
    });

    test('assez de temps pour poser chaque carte, à tous les niveaux', () {
      for (var l = 1; l <= MemoryQuestConfig.totalLevels; l++) {
        final n = MemoryQuestConfig.objectCountForLevel(l);
        final perCard = MemoryQuestConfig.restoreTimeLimitMs(
              n,
              playerFactor: MemoryQuestConfig.playerPaceMin,
            ) /
            n;
        expect(perCard, greaterThan(400),
            reason: 'niveau $l : moins d\'une demi-seconde par carte');
      }
    });
  });

  group('Calibrage → timeout par tâche (le score dépend du temps)', () {
    test('offset remonte le seuil : tâche trop lente devient non-timeout', () {
      final overMax = MemoryQuestConfig.maxTaskTimeMs + 1;
      expect(MemoryQuestConfig.isTaskTimedOut(overMax, 0), isTrue);
      expect(MemoryQuestConfig.isTaskTimedOut(overMax, 2000), isFalse);
    });
  });

  group('Validité de session (fiche Tableau 3)', () {
    test('invalide si offset critique / abandon / trop de timeouts', () {
      // valide : complété, offset faible, peu de timeouts
      expect(MemoryQuestConfig.isSessionValid(10, true, 0), isTrue);
      // offset critique
      expect(
        MemoryQuestConfig.isSessionValid(
            MemoryQuestConfig.criticalCalibrationOffsetMs + 1, true, 0),
        isFalse,
      );
      // abandon
      expect(MemoryQuestConfig.isSessionValid(10, false, 0), isFalse);
      // trop de timeouts
      expect(
        MemoryQuestConfig.isSessionValid(
            10, true, MemoryQuestConfig.maxTimeoutTasks + 1),
        isFalse,
      );
    });
  });
}
