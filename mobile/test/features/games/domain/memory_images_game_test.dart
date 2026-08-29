import 'dart:io';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/memory_quest_config.dart';
import 'package:zennyt/features/games/domain/entities/memory_distraction.dart';
import 'package:zennyt/features/games/domain/entities/memory_quest_metrics.dart';
import 'package:zennyt/features/games/domain/service/memory_distraction_factory.dart';
import 'package:zennyt/features/games/domain/service/memory_images_game.dart';

/// Moteur de **MemoryQuest · Images** — logique pure, sans interface.
///
/// Le déroulé attendu, validé avec le client :
/// `mémorisation → distraction → réponse → validation → niveau suivant`, un
/// objet de plus par niveau, distraction chronométrée à partir du niveau 2,
/// deux tentatives par niveau puis fin de partie.
void main() {
  /// Horloge pilotée : les budgets de temps ne sont vérifiables qu'en maîtrisant
  /// l'écoulement. `package:clock` est déjà le mécanisme utilisé par le module.
  T atTime<T>(DateTime now, T Function() body) =>
      withClock(Clock.fixed(now), body);

  MemoryImagesGame newGame({int seed = 7}) =>
      MemoryImagesGame(random: math.Random(seed));

  /// Joue un niveau parfaitement et renvoie le jeu, positionné au niveau suivant.
  void playPerfectLevel(MemoryImagesGame game, DateTime start) {
    final expected = game.objects;
    atTime(start, game.endMemorization);
    if (game.phase == MemoryImagesPhase.distraction) {
      final solution = game.challenge!.solutionIndex;
      atTime(start.add(const Duration(seconds: 1)),
          () => game.answerDistraction(solution));
    }
    atTime(start.add(const Duration(seconds: 2)),
        () => game.submitOrder(expected));
  }

  group('Déroulé et progression', () {
    test('un niveau enchaîne mémorisation → réponse → niveau suivant', () {
      final game = newGame()..start();
      final start = DateTime(2026, 1, 1);

      expect(game.level, 1);
      expect(game.phase, MemoryImagesPhase.memorize);
      expect(game.objects, hasLength(3), reason: 'le jeu démarre à 3 objets');

      playPerfectLevel(game, start);

      expect(game.level, 2);
      expect(game.objects, hasLength(4), reason: 'un objet de plus par niveau');
      expect(game.phase, MemoryImagesPhase.memorize);
    });

    /// Le jeu des IMAGES démarre ses tâches parasites plus tôt que celui des
    /// chiffres : dès le niveau 2, à la demande du client.
    test('seul le niveau 1 est sans distraction, le 2 en a déjà une', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);

      expect(game.level, 1);
      expect(game.distractionDue, isFalse);
      atTime(t, game.endMemorization);
      expect(game.phase, MemoryImagesPhase.answer,
          reason: 'niveau 1 : on répond directement');
      atTime(t, () => game.submitOrder(game.objects));

      expect(game.level, 2);
      expect(game.distractionDue, isTrue);
      atTime(t, game.endMemorization);
      expect(game.phase, MemoryImagesPhase.distraction);
      expect(game.challenge, isNotNull);
    });
  });

  group('Tentatives et fin de partie', () {
    test('un niveau raté est rejoué, le second échec termine la partie', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);

      expect(game.attemptsLeft, MemoryQuestConfig.maxFailuresPerLevel);

      // 1ᵉʳ échec : ordre inversé, donc faux dès qu'il y a plus d'un objet.
      atTime(t, game.endMemorization);
      var wrong = game.objects.reversed.toList();
      expect(atTime(t, () => game.submitOrder(wrong)), isFalse);

      expect(game.level, 1, reason: 'un échec ne fait pas monter de niveau');
      expect(game.attemptsLeft, 1);
      expect(game.phase, MemoryImagesPhase.memorize);

      // 2ᵉ échec sur le même niveau → Game Over.
      atTime(t, game.endMemorization);
      wrong = game.objects.reversed.toList();
      expect(atTime(t, () => game.submitOrder(wrong)), isFalse);

      expect(game.phase, MemoryImagesPhase.gameOver);
      expect(game.isOver, isTrue);
    });

    test('le compteur de tentatives repart à zéro en montant de niveau', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);

      atTime(t, game.endMemorization);
      atTime(t, () => game.submitOrder(game.objects.reversed.toList()));
      expect(game.attemptsLeft, 1);

      atTime(t, game.endMemorization);
      atTime(t, () => game.submitOrder(game.objects)); // réussi
      expect(game.level, 2);
      expect(game.attemptsLeft, MemoryQuestConfig.maxFailuresPerLevel);
    });

    test('le dernier niveau réussi termine le parcours', () {
      final game = newGame()..start();
      var t = DateTime(2026, 1, 1);
      for (var i = 0; i < MemoryQuestConfig.totalLevels; i++) {
        playPerfectLevel(game, t);
        t = t.add(const Duration(minutes: 1));
      }
      expect(game.phase, MemoryImagesPhase.completed);
      expect(game.isOver, isTrue);
    });
  });

  group('Chronomètre de la distraction', () {
    test('toute épreuve porte un budget de temps borné', () {
      const factory = MemoryDistractionFactory();
      for (var level = MemoryQuestConfig.distractionMinLevel;
          level <= MemoryQuestConfig.totalLevels;
          level++) {
        for (final kind in MemoryDistractionKind.values) {
          final c = factory.createOfKind(kind, level, math.Random(level));
          expect(c.timeLimitMs, greaterThanOrEqualTo(
              MemoryQuestConfig.distractionMinTimeLimitMs));
          expect(c.timeLimitMs, MemoryQuestConfig.distractionTimeLimitMs(level),
              reason: 'budget identique pour les deux familles à niveau égal');
        }
      }
    });

    test('répondre après l\'expiration compte comme un dépassement', () {
      final game = newGame()..start();
      var t = DateTime(2026, 1, 1);
      // Monter au niveau 3, où la distraction apparaît.
      playPerfectLevel(game, t);
      playPerfectLevel(game, t);
      expect(game.level, 3);

      atTime(t, game.endMemorization);
      final challenge = game.challenge!;
      final solution = challenge.solutionIndex;

      // Bonne réponse, mais une milliseconde trop tard : le chronomètre prime,
      // sinon la contrainte de temps ne mesurerait rien.
      t = t.add(Duration(milliseconds: challenge.timeLimitMs + 1));
      final outcome = atTime(t, () => game.answerDistraction(solution));

      expect(outcome, MemoryDistractionOutcome.timedOut);
      expect(game.phase, MemoryImagesPhase.answer,
          reason: 'la partie continue : la distraction ne bloque jamais');
    });

    test('l\'expiration sans réponse est un échec, et le jeu enchaîne', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);
      // Un seul niveau suffit : le niveau 2 porte déjà une tâche parasite.
      playPerfectLevel(game, t);

      atTime(t, game.endMemorization);
      // Le getter lit l'horloge : il doit être interrogé SOUS l'horloge pilotée,
      // sinon il compare à l'heure réelle et renvoie toujours 0.
      expect(atTime(t, () => game.distractionRemainingMs), greaterThan(0));

      final outcome = atTime(t, game.expireDistraction);
      expect(outcome, MemoryDistractionOutcome.timedOut);
      expect(game.phase, MemoryImagesPhase.answer);

      final m = game.buildMetrics();
      expect(m.distractionTimeouts, 1);
      expect(m.distractionChallengesSolved, 0);
    });

    test('le temps restant décroît et tombe à zéro', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);
      playPerfectLevel(game, t);
      playPerfectLevel(game, t);
      atTime(t, game.endMemorization);

      final limit = game.challenge!.timeLimitMs;
      expect(atTime(t, () => game.distractionRemainingMs), limit);
      expect(
        atTime(t.add(Duration(milliseconds: limit ~/ 2)),
            () => game.distractionRemainingMs),
        closeTo(limit / 2, 2),
      );
      expect(
        atTime(t.add(Duration(milliseconds: limit + 5)),
            () => game.distractionExpired),
        isTrue,
      );
    });
  });

  group('Génération dynamique des distractions', () {
    const factory = MemoryDistractionFactory();

    test('deux tirages au même niveau ne donnent pas la même épreuve', () {
      final a = factory.createOfKind(
          MemoryDistractionKind.oddOneOut, 5, math.Random(1)) as OddOneOutChallenge;
      final b = factory.createOfKind(
          MemoryDistractionKind.oddOneOut, 5, math.Random(2)) as OddOneOutChallenge;
      final differs = a.oddIndex != b.oddIndex ||
          a.trait != b.trait ||
          a.cells.first.glyph != b.cells.first.glyph ||
          a.cells.first.colorIndex != b.cells.first.colorIndex;
      expect(differs, isTrue, reason: 'aucune banque figée : tout est tiré');
    });

    test('« intrus » : exactement une case diffère, et elle est la solution', () {
      for (var level = 3; level <= 7; level++) {
        final c = factory.createOfKind(
            MemoryDistractionKind.oddOneOut, level, math.Random(level))
            as OddOneOutChallenge;

        expect(c.cells.where((cell) => cell.isOdd), hasLength(1));
        expect(c.cells[c.oddIndex].isOdd, isTrue);
        expect(c.solutionIndex, c.oddIndex);
        expect(c.cells, hasLength(MemoryQuestConfig.oddOneOutCellCount(level)));

        // Toutes les autres cases sont rigoureusement identiques : sans cela,
        // l'épreuve aurait plusieurs réponses défendables.
        final others = [
          for (var i = 0; i < c.cells.length; i++)
            if (i != c.oddIndex) c.cells[i]
        ];
        for (final o in others) {
          expect(o.glyph, others.first.glyph);
          expect(o.colorIndex, others.first.colorIndex);
          expect(o.pattern, others.first.pattern);
        }
      }
    });

    test('« pièce manquante » : une seule pièce correcte, et elle complète le trou', () {
      for (var level = 3; level <= 7; level++) {
        final c = factory.createOfKind(
            MemoryDistractionKind.puzzlePiece, level, math.Random(level))
            as PuzzlePieceChallenge;

        expect(c.options.where((o) => o.isCorrect), hasLength(1));
        expect(c.options[c.correctOptionIndex].isCorrect, isTrue);
        expect(c.tiles, hasLength(c.gridSide * c.gridSide));
        expect(c.missingIndex, lessThan(c.tiles.length));

        // La pièce correcte reproduit exactement la case manquante.
        final expected = c.tiles[c.missingIndex];
        final solution = c.options[c.correctOptionIndex];
        expect(solution.glyph, expected.glyph);
        expect(solution.colorIndex, expected.colorIndex);
        expect(solution.quarterTurns, expected.quarterTurns);

        // Aucun leurre ne peut être confondu avec la solution.
        for (final o in c.options.where((o) => !o.isCorrect)) {
          final identical = o.glyph == solution.glyph &&
              o.colorIndex == solution.colorIndex &&
              o.quarterTurns == solution.quarterTurns;
          expect(identical, isFalse);
        }
      }
    });

    /// Un intrus doit se distinguer par un attribut RÉELLEMENT visible.
    ///
    /// La rotation ne l'est pas : cercle, carré, croix, losange et hexagone sont
    /// symétriques par quart de tour, une case « tournée » y est identique aux
    /// autres. Une épreuve construite ainsi n'a pas de réponse trouvable.
    test('l\'intrus diffère toujours par un attribut perceptible', () {
      for (var level = 3; level <= 7; level++) {
        for (var seed = 0; seed < 60; seed++) {
          final c = factory.createOfKind(
              MemoryDistractionKind.oddOneOut, level, math.Random(seed))
              as OddOneOutChallenge;
          final odd = c.cells[c.oddIndex];
          final other =
              c.cells[(c.oddIndex + 1) % c.cells.length];

          final differs = odd.glyph != other.glyph ||
              odd.colorIndex != other.colorIndex ||
              odd.pattern != other.pattern ||
              (odd.scale - other.scale).abs() >= 0.10;

          expect(
            differs,
            isTrue,
            reason: 'niveau $level, graine $seed : intrus indiscernable '
                '(trait ${c.trait.name})',
          );
        }
      }
    });

    /// Un tirage à pile ou face est équitable en moyenne, pas sur les 6 épreuves
    /// d'une partie : le client a vu « intrus » à tous les niveaux jusqu'à 8
    /// objets, et le puzzle seulement au 9ᵉ. Le séquenceur borne les séries.
    test('les deux familles alternent, sans longue série', () {
      for (var seed = 0; seed < 40; seed++) {
        final sequencer = MemoryDistractionSequencer();
        final random = math.Random(seed);
        final kinds = [
          for (var level = 2; level <= 7; level++) sequencer.nextKind(random),
        ];

        var run = 1;
        var longest = 1;
        for (var i = 1; i < kinds.length; i++) {
          run = kinds[i] == kinds[i - 1] ? run + 1 : 1;
          if (run > longest) longest = run;
        }

        expect(longest, lessThanOrEqualTo(2),
            reason: 'graine $seed : série de $longest épreuves identiques');
        expect(
          kinds.toSet(),
          hasLength(2),
          reason: 'graine $seed : une seule famille sur toute la partie',
        );
      }
    });

    test('le séquenceur reste imprévisible d\'une partie à l\'autre', () {
      final first = [
        for (var i = 0; i < 6; i++)
          MemoryDistractionSequencer().nextKind(math.Random(i)),
      ];
      expect(first.toSet(), hasLength(2),
          reason: 'la première épreuve ne doit pas être toujours la même');
    });

    test('les épreuves n\'utilisent que des glyphes déclarés', () {
      // Chaque glyphe doit avoir son fichier : un chemin fantaisiste ne
      // planterait pas le domaine, il afficherait une case vide en jeu.
      for (var level = 3; level <= 7; level++) {
        final odd = factory.createOfKind(
            MemoryDistractionKind.oddOneOut, level, math.Random(level))
            as OddOneOutChallenge;
        for (final cell in odd.cells) {
          expect(MemoryGlyph.values, contains(cell.glyph));
          expect(cell.glyph.assetPath, endsWith('.svg'));
        }
        final puzzle = factory.createOfKind(
            MemoryDistractionKind.puzzlePiece, level, math.Random(level))
            as PuzzlePieceChallenge;
        for (final o in [...puzzle.tiles, ...puzzle.options]) {
          expect(MemoryGlyph.values, contains(o.glyph));
        }
      }
    });

    test('chaque glyphe et chaque motif pointe sur un fichier livré', () async {
      for (final glyph in MemoryGlyph.values) {
        expect(File(glyph.assetPath).existsSync(), isTrue,
            reason: 'asset manquant : ${glyph.assetPath}');
      }
      for (final pattern in MemoryPattern.values) {
        final path = pattern.assetPath;
        if (path == null) continue;
        expect(File(path).existsSync(), isTrue,
            reason: 'asset manquant : $path');
      }
    });
  });

  group('Difficulté croissante', () {
    test('chaque levier durcit avec le niveau', () {
      var cells = 0;
      var similarity = 0.0;
      var options = 0;
      var side = 0;
      var time = 1 << 30;

      for (var level = MemoryQuestConfig.distractionMinLevel;
          level <= MemoryQuestConfig.totalLevels;
          level++) {
        expect(MemoryQuestConfig.oddOneOutCellCount(level),
            greaterThanOrEqualTo(cells));
        expect(MemoryQuestConfig.oddOneOutSimilarity(level),
            greaterThanOrEqualTo(similarity));
        expect(MemoryQuestConfig.puzzleOptionCount(level),
            greaterThanOrEqualTo(options));
        expect(MemoryQuestConfig.puzzleGridSide(level),
            greaterThanOrEqualTo(side));
        expect(MemoryQuestConfig.distractionTimeLimitMs(level),
            lessThanOrEqualTo(time));
        expect(MemoryQuestConfig.objectCountForLevel(level),
            MemoryQuestConfig.minObjectCount + level - 1);

        cells = MemoryQuestConfig.oddOneOutCellCount(level);
        similarity = MemoryQuestConfig.oddOneOutSimilarity(level);
        options = MemoryQuestConfig.puzzleOptionCount(level);
        side = MemoryQuestConfig.puzzleGridSide(level);
        time = MemoryQuestConfig.distractionTimeLimitMs(level);
      }

      // La difficulté a réellement bougé entre le premier et le dernier niveau.
      expect(cells, greaterThan(MemoryQuestConfig.distractionMinGridCells));
      expect(time, lessThan(MemoryQuestConfig.distractionBaseTimeLimitMs));
    });
  });

  group('Mesures envoyées au backend', () {
    test('aucune mesure de chiffres, aucune restitution inversée', () {
      final game = newGame()..start();
      var t = DateTime(2026, 1, 1);
      for (var i = 0; i < 4; i++) {
        playPerfectLevel(game, t);
        t = t.add(const Duration(minutes: 1));
      }
      final m = game.buildMetrics();

      expect(m.mode, MemoryQuestMode.images);
      expect(m.observedDigits, 0);
      expect(m.correctSameDigits, 0);
      expect(m.correctReverseDigits, 0);
      expect(m.highestSequenceLength, 0);
      expect(
        m.tasks.map((t) => t.kind),
        isNot(contains(MemoryTaskKind.reverseOrder)),
        reason: 'le jeu des images ne demande jamais l\'ordre inverse',
      );
      expect(
        m.tasks.map((t) => t.kind),
        isNot(contains(MemoryTaskKind.sameOrder)),
      );
    });

    test('la distraction est journalisée séparément de la restitution', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);
      playPerfectLevel(game, t); // niveau 1 (sans épreuve) → niveau 2

      atTime(t, game.endMemorization);
      final solution = game.challenge!.solutionIndex;
      atTime(t.add(const Duration(seconds: 2)),
          () => game.answerDistraction(solution));
      atTime(t.add(const Duration(seconds: 4)),
          () => game.submitOrder(game.objects));

      final m = game.buildMetrics();
      final challengeTasks = m.tasks
          .where((t) => t.kind == MemoryTaskKind.distractionChallenge)
          .toList();
      final recallTasks = m.tasks
          .where((t) => t.kind == MemoryTaskKind.afterDistraction)
          .toList();

      expect(challengeTasks, hasLength(1));
      expect(challengeTasks.single.level, 2,
          reason: 'le niveau accompagne la tâche : il fixe son délai');
      expect(recallTasks, hasLength(1));
      expect(m.distractionChallengesPlayed, 1);
      expect(m.distractionChallengesSolved, 1);
      expect(m.distractionTimeouts, 0);
    });

    test('la distraction ne change pas ce qu\'il faut restituer', () {
      final game = newGame()..start();
      final t = DateTime(2026, 1, 1);
      playPerfectLevel(game, t);
      playPerfectLevel(game, t);

      final toRestore = game.objects;
      atTime(t, game.endMemorization);
      // Réponse VOLONTAIREMENT fausse à la distraction.
      final wrongOption =
          (game.challenge!.solutionIndex + 1) % game.challenge!.optionCount;
      atTime(t.add(const Duration(seconds: 1)),
          () => game.answerDistraction(wrongOption));

      expect(game.objects, toRestore,
          reason: 'la tâche parasite est indépendante de la mémorisation');
      // Le niveau reste franchissable malgré la distraction ratée.
      expect(
        atTime(t.add(const Duration(seconds: 2)),
            () => game.submitOrder(toRestore)),
        isTrue,
      );
      expect(game.level, 4);
    });
  });
}
