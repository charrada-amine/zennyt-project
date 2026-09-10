import 'dart:math' as math;

import '../config/memory_quest_config.dart';
import '../entities/memory_distraction.dart';

/// Fabrique les tâches parasites de **MemoryQuest · Images**, à la volée.
///
/// Aucune banque d'énigmes n'est stockée : chaque épreuve est construite au
/// moment où elle est jouée, à partir du niveau et d'un tirage aléatoire. Deux
/// parties au même niveau ne verront donc pas la même grille.
///
/// Toute la montée en difficulté vient de [MemoryQuestConfig] — nombre de cases,
/// ressemblance, côté du puzzle, nombre de pièces, budget de temps. Cette classe
/// ne décide de rien : elle applique.
class MemoryDistractionFactory {
  const MemoryDistractionFactory({this.glyphs = MemoryGlyph.values});

  /// Silhouettes disponibles pour habiller les épreuves.
  final List<MemoryGlyph> glyphs;

  /// Teintes que l'interface sait rendre. Le domaine ne manipule que des index :
  /// il reste sans dépendance à Flutter.
  static const int paletteSize = 6;

  /// Motifs utilisables (le motif « none » compris).
  static const List<MemoryPattern> patterns = MemoryPattern.values;

  /// Produit l'épreuve du [level] en tirant l'une des deux familles — une seule
  /// par niveau.
  ///
  /// ⚠️ Tirage BRUT, sans mémoire : à réserver aux tests. Une partie doit passer
  /// par [MemoryDistractionSequencer], qui empêche les longues séries d'un même
  /// type (voir sa documentation).
  MemoryDistractionChallenge create(int level, math.Random random) {
    final kind = random.nextBool()
        ? MemoryDistractionKind.oddOneOut
        : MemoryDistractionKind.puzzlePiece;
    return createOfKind(kind, level, random);
  }

  /// Produit une épreuve d'un type imposé — utilisé par les tests.
  MemoryDistractionChallenge createOfKind(
    MemoryDistractionKind kind,
    int level,
    math.Random random,
  ) =>
      switch (kind) {
        MemoryDistractionKind.oddOneOut => _oddOneOut(level, random),
        MemoryDistractionKind.puzzlePiece => _puzzle(level, random),
      };

  MemoryGlyph _glyph(math.Random random) => glyphs[random.nextInt(glyphs.length)];

  MemoryGlyph _otherGlyph(MemoryGlyph base, math.Random random) {
    if (glyphs.length < 2) return base;
    var other = _glyph(random);
    while (other == base) {
      other = _glyph(random);
    }
    return other;
  }

  // ── « Trouver l'intrus » ────────────────────────────────────────────────

  OddOneOutChallenge _oddOneOut(int level, math.Random random) {
    final cellCount = MemoryQuestConfig.oddOneOutCellCount(level);
    final similarity = MemoryQuestConfig.oddOneOutSimilarity(level);
    final trait = MemoryVisualTrait
        .values[random.nextInt(MemoryVisualTrait.values.length)];

    final base = _glyph(random);
    final baseColor = random.nextInt(paletteSize);
    final basePattern = patterns[random.nextInt(patterns.length)];
    final baseTurns = random.nextInt(4);

    final oddIndex = random.nextInt(cellCount);
    final odd = _applyTrait(
      trait: trait,
      base: base,
      baseColor: baseColor,
      basePattern: basePattern,
      baseTurns: baseTurns,
      similarity: similarity,
      random: random,
    );

    final cells = <OddOneOutCell>[
      for (var i = 0; i < cellCount; i++)
        i == oddIndex
            ? odd
            : OddOneOutCell(
                glyph: base,
                colorIndex: baseColor,
                pattern: basePattern,
                quarterTurns: baseTurns,
                scale: 1.0,
                isOdd: false,
              ),
    ];

    return OddOneOutChallenge(
      level: level,
      timeLimitMs: MemoryQuestConfig.distractionTimeLimitMs(level),
      cells: cells,
      oddIndex: oddIndex,
      trait: trait,
      columns: cellCount <= 4 ? 2 : (cellCount <= 9 ? 3 : 4),
      similarity: similarity,
    );
  }

  /// Construit la case intruse : elle ne diffère que sur [trait], et d'autant
  /// moins que [similarity] est élevée.
  OddOneOutCell _applyTrait({
    required MemoryVisualTrait trait,
    required MemoryGlyph base,
    required int baseColor,
    required MemoryPattern basePattern,
    required int baseTurns,
    required double similarity,
    required math.Random random,
  }) {
    switch (trait) {
      case MemoryVisualTrait.color:
        // Teinte voisine quand la ressemblance est forte, opposée sinon.
        final step = similarity > 0.6 ? 1 : paletteSize ~/ 2;
        return OddOneOutCell(
          glyph: base,
          colorIndex: (baseColor + step) % paletteSize,
          pattern: basePattern,
          quarterTurns: baseTurns,
          scale: 1.0,
          isOdd: true,
        );
      case MemoryVisualTrait.shape:
        return OddOneOutCell(
          glyph: _otherGlyph(base, random),
          colorIndex: baseColor,
          pattern: basePattern,
          quarterTurns: baseTurns,
          scale: 1.0,
          isOdd: true,
        );
      case MemoryVisualTrait.pattern:
        var other = patterns[random.nextInt(patterns.length)];
        while (other == basePattern) {
          other = patterns[random.nextInt(patterns.length)];
        }
        return OddOneOutCell(
          glyph: base,
          colorIndex: baseColor,
          pattern: other,
          quarterTurns: baseTurns,
          scale: 1.0,
          isOdd: true,
        );
      case MemoryVisualTrait.detail:
        // Écart de TAILLE uniquement : 22 % au niveau le plus facile, 12 % au
        // plus dur. Le plancher est volontairement haut — en dessous, l'écart
        // cesse d'être perceptible et l'épreuve devient un tirage au sort.
        //
        // La rotation a été écartée de ce trait : la moitié des glyphes (cercle,
        // carré, croix, losange, hexagone) sont symétriques par quart de tour,
        // une case « tournée » y était donc rigoureusement identique aux autres
        // et l'intrus introuvable.
        final delta = 0.22 - 0.10 * similarity;
        return OddOneOutCell(
          glyph: base,
          colorIndex: baseColor,
          pattern: basePattern,
          quarterTurns: baseTurns,
          scale: 1 + delta,
          isOdd: true,
        );
    }
  }

  // ── « Pièce manquante » ─────────────────────────────────────────────────

  PuzzlePieceChallenge _puzzle(int level, math.Random random) {
    final side = MemoryQuestConfig.puzzleGridSide(level);
    final optionCount = MemoryQuestConfig.puzzleOptionCount(level);
    final cellCount = side * side;

    // Le motif alterne deux glyphes et deux teintes : il a une régularité, donc
    // la case manquante est déductible — c'est ce qui en fait un raisonnement
    // et non un tirage au sort.
    final glyphA = _glyph(random);
    final glyphB = _otherGlyph(glyphA, random);
    final colorA = random.nextInt(paletteSize);
    final colorB = (colorA + 1 + random.nextInt(paletteSize - 1)) % paletteSize;

    PuzzlePieceOption tileAt(int index) {
      final row = index ~/ side;
      final col = index % side;
      final even = (row + col).isEven;
      return PuzzlePieceOption(
        glyph: even ? glyphA : glyphB,
        colorIndex: even ? colorA : colorB,
        quarterTurns: (row + col) % 4,
        isCorrect: false,
      );
    }

    final tiles = [for (var i = 0; i < cellCount; i++) tileAt(i)];
    final missingIndex = random.nextInt(cellCount);
    final expected = tiles[missingIndex];

    // Leurres : chacun s'écarte de la solution sur UN attribut, jamais plus.
    final options = <PuzzlePieceOption>[
      PuzzlePieceOption(
        glyph: expected.glyph,
        colorIndex: expected.colorIndex,
        quarterTurns: expected.quarterTurns,
        isCorrect: true,
      ),
    ];
    var guard = 0;
    while (options.length < optionCount && guard++ < optionCount * 12) {
      final decoy = _decoy(expected, random);
      final duplicate = options.any((o) =>
          o.glyph == decoy.glyph &&
          o.colorIndex == decoy.colorIndex &&
          o.quarterTurns == decoy.quarterTurns);
      if (!duplicate) options.add(decoy);
    }
    options.shuffle(random);

    return PuzzlePieceChallenge(
      level: level,
      timeLimitMs: MemoryQuestConfig.distractionTimeLimitMs(level),
      tiles: tiles,
      gridSide: side,
      missingIndex: missingIndex,
      options: options,
      correctOptionIndex: options.indexWhere((o) => o.isCorrect),
    );
  }

  PuzzlePieceOption _decoy(PuzzlePieceOption expected, math.Random random) {
    switch (random.nextInt(3)) {
      case 0:
        return PuzzlePieceOption(
          glyph: expected.glyph,
          colorIndex:
              (expected.colorIndex + 1 + random.nextInt(paletteSize - 1)) %
                  paletteSize,
          quarterTurns: expected.quarterTurns,
          isCorrect: false,
        );
      case 1:
        return PuzzlePieceOption(
          glyph: _otherGlyph(expected.glyph, random),
          colorIndex: expected.colorIndex,
          quarterTurns: expected.quarterTurns,
          isCorrect: false,
        );
      default:
        return PuzzlePieceOption(
          glyph: expected.glyph,
          colorIndex: expected.colorIndex,
          quarterTurns: (expected.quarterTurns + 1 + random.nextInt(3)) % 4,
          isCorrect: false,
        );
    }
  }
}

/// Choisit le type de chaque tâche parasite d'une partie, en **bornant les
/// séries**.
///
/// Un simple tirage à pile ou face par niveau est équitable en moyenne, mais pas
/// sur les 6 épreuves d'une partie : il produit régulièrement « intrus » cinq
/// fois de suite, et le joueur ne découvre le puzzle qu'à la toute fin — c'est
/// exactement ce que le client a constaté.
///
/// La règle ici : le hasard décide, **sauf** quand le même type vient de sortir
/// [maxSameKindRun] fois d'affilée ; l'autre est alors imposé. On garde donc
/// l'imprévisibilité tout en garantissant que les deux familles apparaissent tôt.
class MemoryDistractionSequencer {
  MemoryDistractionSequencer({
    this.factory = const MemoryDistractionFactory(),
    this.maxSameKindRun = 2,
  });

  final MemoryDistractionFactory factory;

  /// Répétitions consécutives tolérées avant de forcer l'autre type.
  final int maxSameKindRun;

  MemoryDistractionKind? _lastKind;
  int _run = 0;

  /// Type de la dernière épreuve produite (`null` avant la première).
  MemoryDistractionKind? get lastKind => _lastKind;

  /// Prochaine épreuve du [level].
  MemoryDistractionChallenge next(int level, math.Random random) {
    final kind = nextKind(random);
    return factory.createOfKind(kind, level, random);
  }

  /// Type de la prochaine épreuve — exposé pour être vérifiable seul.
  MemoryDistractionKind nextKind(math.Random random) {
    final last = _lastKind;
    final MemoryDistractionKind kind;
    if (last != null && _run >= maxSameKindRun) {
      kind = last == MemoryDistractionKind.oddOneOut
          ? MemoryDistractionKind.puzzlePiece
          : MemoryDistractionKind.oddOneOut;
    } else {
      kind = random.nextBool()
          ? MemoryDistractionKind.oddOneOut
          : MemoryDistractionKind.puzzlePiece;
    }
    _run = kind == last ? _run + 1 : 1;
    _lastKind = kind;
    return kind;
  }

  /// Remet le compteur à zéro (nouvelle partie).
  void reset() {
    _lastKind = null;
    _run = 0;
  }
}
