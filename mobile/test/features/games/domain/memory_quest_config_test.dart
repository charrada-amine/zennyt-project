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

    test('nombre d\'objets : 4 (niveau 1) → 12 (niveau 7)', () {
      expect(MemoryQuestConfig.objectCountForLevel(1), 4);
      expect(MemoryQuestConfig.objectCountForLevel(7), 12);
    });

    // Le gating au niveau ≥ 3 a été levé sur retour client : la distraction ne
    // se voyait jamais en test, une session de démonstration dépassant rarement
    // le niveau 2.
    test('distraction active dès le premier niveau', () {
      expect(MemoryQuestConfig.distractionMinLevel, 1);
      expect(MemoryQuestConfig.distractionActiveAtLevel(1), isTrue);
      expect(MemoryQuestConfig.distractionActiveAtLevel(3), isTrue);
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
