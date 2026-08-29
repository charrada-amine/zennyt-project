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
