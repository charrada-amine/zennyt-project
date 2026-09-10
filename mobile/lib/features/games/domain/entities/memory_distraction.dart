/// Glyphes des tâches parasites — famille dédiée, **monochrome**.
///
/// Les objets du jeu (`assets/games icons/Je Place Object NN.png`) sont des
/// illustrations 2.5D multicolores : impossible de les reteinter sans détruire
/// leur rendu, donc impossible d'en faire varier la COULEUR — l'un des quatre
/// traits sur lesquels l'intrus doit pouvoir se distinguer.
///
/// Ces glyphes reprennent le style plat et le gabarit 64 × 64 de la bibliothèque
/// `MemoryObject/svg`, mais en silhouette d'une seule teinte : ils se colorent
/// avec la palette des jeux au moment du rendu.
enum MemoryGlyph {
  circle('Circle'),
  square('Square'),
  triangle('Triangle'),
  hexagon('Hexagon'),
  star('Star'),
  diamond('Diamond'),
  drop('Drop'),
  cross('Cross');

  const MemoryGlyph(this._name);

  final String _name;

  String get assetPath => 'assets/J’investigue/distractors/$_name.svg';
}

/// Motif superposé au glyphe — porte le trait « motif ».
enum MemoryPattern {
  none(null),
  dots('PatternDots'),
  stripes('PatternStripes'),
  ring('PatternRing');

  const MemoryPattern(this._name);

  final String? _name;

  String? get assetPath =>
      _name == null ? null : 'assets/J’investigue/distractors/$_name.svg';
}

/// Tâches parasites du jeu **MemoryQuest · Images**.
///
/// Deux familles seulement, toutes deux **visuelles** : le jeu des images ne
/// présente jamais de chiffres, tâche parasite comprise.
///
/// Rien n'est écrit en dur : chaque épreuve est fabriquée à la volée par
/// `MemoryDistractionFactory` à partir du niveau, du tirage aléatoire et du
/// catalogue d'objets réellement disponibles ([kMemoryObjectLibrary]). Il
/// n'existe donc aucune banque figée d'énigmes à maintenir.
enum MemoryDistractionKind {
  /// Une grille d'éléments presque identiques : il faut désigner l'intrus.
  oddOneOut('ODD_ONE_OUT'),

  /// Un motif troué : il faut choisir la pièce qui comble le vide.
  puzzlePiece('PUZZLE_PIECE');

  const MemoryDistractionKind(this.wire);

  /// Valeur transmise au backend (statistiques).
  final String wire;
}

/// Dimension visuelle sur laquelle l'intrus se distingue.
///
/// Une seule dimension diffère par épreuve : c'est ce qui rend la réponse
/// univoque, et c'est aussi ce qui permet de faire varier la difficulté sans
/// changer la consigne.
enum MemoryVisualTrait {
  color('COLOR'),
  shape('SHAPE'),
  pattern('PATTERN'),
  detail('DETAIL');

  const MemoryVisualTrait(this.wire);

  final String wire;
}

/// Base commune : toute épreuve porte son type et **son propre chronomètre**.
sealed class MemoryDistractionChallenge {
  const MemoryDistractionChallenge({
    required this.kind,
    required this.level,
    required this.timeLimitMs,
  });

  final MemoryDistractionKind kind;

  /// Niveau qui a produit l'épreuve — sert à retrouver son budget de temps.
  final int level;

  /// Budget de temps, identique pour les deux familles à niveau égal.
  final int timeLimitMs;

  /// Index de la bonne réponse parmi les propositions présentées.
  int get solutionIndex;

  /// Nombre de propositions parmi lesquelles trancher.
  int get optionCount;
}

/// Une case de la grille « trouver l'intrus ».
///
/// Les attributs sont des **descripteurs**, pas des couleurs Flutter : le
/// domaine reste sans dépendance à l'interface, qui les traduit en pixels.
class OddOneOutCell {
  const OddOneOutCell({
    required this.glyph,
    required this.colorIndex,
    required this.pattern,
    required this.quarterTurns,
    required this.scale,
    required this.isOdd,
  });

  /// Silhouette affichée.
  final MemoryGlyph glyph;

  /// Index dans la palette de l'interface.
  final int colorIndex;

  /// Motif superposé.
  final MemoryPattern pattern;

  /// Rotation par quarts de tour (0–3).
  final int quarterTurns;

  /// Facteur d'échelle — porte la variation « détail ».
  final double scale;

  final bool isOdd;
}

/// Grille d'éléments presque identiques dont un seul diffère.
class OddOneOutChallenge extends MemoryDistractionChallenge {
  const OddOneOutChallenge({
    required super.level,
    required super.timeLimitMs,
    required this.cells,
    required this.oddIndex,
    required this.trait,
    required this.columns,
    required this.similarity,
  }) : super(kind: MemoryDistractionKind.oddOneOut);

  final List<OddOneOutCell> cells;

  /// Position de l'intrus dans [cells].
  final int oddIndex;

  /// Dimension sur laquelle l'intrus se distingue.
  final MemoryVisualTrait trait;

  final int columns;

  /// Ressemblance appliquée, dans [0, 1] — plus elle est haute, plus l'écart
  /// visuel est ténu.
  final double similarity;

  @override
  int get solutionIndex => oddIndex;

  @override
  int get optionCount => cells.length;
}

/// Une pièce candidate pour combler le trou du motif.
class PuzzlePieceOption {
  const PuzzlePieceOption({
    required this.glyph,
    required this.colorIndex,
    required this.quarterTurns,
    required this.isCorrect,
  });

  final MemoryGlyph glyph;
  final int colorIndex;
  final int quarterTurns;
  final bool isCorrect;
}

/// Motif à trou : une case manque, il faut désigner la pièce qui la complète.
class PuzzlePieceChallenge extends MemoryDistractionChallenge {
  const PuzzlePieceChallenge({
    required super.level,
    required super.timeLimitMs,
    required this.tiles,
    required this.gridSide,
    required this.missingIndex,
    required this.options,
    required this.correctOptionIndex,
  }) : super(kind: MemoryDistractionKind.puzzlePiece);

  /// Contenu du motif, case par case ; l'entrée [missingIndex] est le trou.
  final List<PuzzlePieceOption> tiles;

  final int gridSide;

  /// Case manquante dans [tiles].
  final int missingIndex;

  /// Pièces proposées, dont une seule complète le motif.
  final List<PuzzlePieceOption> options;

  final int correctOptionIndex;

  @override
  int get solutionIndex => correctOptionIndex;

  @override
  int get optionCount => options.length;
}
