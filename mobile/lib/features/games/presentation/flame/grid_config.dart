/// Nature d'une cellule de la grille du mini-jeu « Chemin Optimal ».
enum CellKind { normal, obstacle, costly, start, end, objective }

/// Définition d'un niveau du mini-jeu « Chemin Optimal ».
///
/// Les cellules sont indexées par `row * cols + col`. La longueur optimale est
/// pré-calculée (barème serveur : respect du chemin optimal ±10%).
class GridConfig {
  const GridConfig({
    required this.cols,
    required this.rows,
    required this.start,
    required this.end,
    required this.obstacles,
    required this.costlyZones,
    required this.objectives,
    required this.optimalLength,
  });

  final int cols;
  final int rows;
  final int start;
  final int end;
  final Set<int> obstacles;
  final Set<int> costlyZones;
  final Set<int> objectives;
  final int optimalLength;

  int index(int row, int col) => row * cols + col;
  int rowOf(int index) => index ~/ cols;
  int colOf(int index) => index % cols;

  CellKind kindOf(int index) {
    if (index == start) return CellKind.start;
    if (index == end) return CellKind.end;
    if (obstacles.contains(index)) return CellKind.obstacle;
    if (objectives.contains(index)) return CellKind.objective;
    if (costlyZones.contains(index)) return CellKind.costly;
    return CellKind.normal;
  }

  /// Une case est franchissable si ce n'est pas un obstacle.
  bool isWalkable(int index) => !obstacles.contains(index);

  int get cellCount => rows * cols;

  /// Niveau de démonstration 6×6 : chemin optimal = 10 pas (5 droite + 5 bas).
  /// Les obstacles ne bloquent aucun chemin monotone ; une zone coûteuse tente
  /// le joueur avec un raccourci ; un objectif secondaire est optionnel.
  static const demo = GridConfig(
    cols: 6,
    rows: 6,
    start: 0, // (0,0)
    end: 35, // (5,5)
    obstacles: {14, 15, 20}, // (2,2)(2,3)(3,2)
    costlyZones: {25, 10}, // (4,1)(1,4)
    objectives: {32}, // (5,2)
    optimalLength: 10,
  );

  /// Niveau « stations » 5×8 (maquette Figma Optimal Path 04).
  static const stations = level3;

  // ─────────────── Niveaux progressifs (difficulté croissante) ───────────────
  // Chaque niveau garantit un chemin monotone LAB→MTG libre d'obstacles ;
  // plus l'indice grandit, plus la grille est grande et dense.

  /// Niveau 1 — 5×6, peu de blocs (facile). Chemin optimal 9 pas.
  static const level1 = GridConfig(
    cols: 5,
    rows: 6,
    start: 0, // (0,0)
    end: 29, // (5,4)
    obstacles: {6, 7, 12, 16, 17, 22},
    costlyZones: {},
    objectives: {14},
    optimalLength: 9,
  );

  /// Niveau 2 — 5×7, plus de blocs (moyen). Chemin optimal 10 pas.
  static const level2 = GridConfig(
    cols: 5,
    rows: 7,
    start: 0, // (0,0)
    end: 34, // (6,4)
    obstacles: {1, 2, 3, 6, 7, 11, 13, 17, 18, 22, 23, 27, 28},
    costlyZones: {},
    objectives: {20, 33},
    optimalLength: 10,
  );

  /// Niveau 3 — 5×8, dense (difficile). Chemin optimal 9 pas.
  static const level3 = GridConfig(
    cols: 5,
    rows: 8,
    start: 10, // (2,0)
    end: 39, // (7,4)
    obstacles: {1, 2, 7, 9, 12, 13, 16, 18, 26, 31, 35, 36},
    costlyZones: {},
    objectives: {21, 33},
    optimalLength: 9,
  );

  /// Niveau 4 — 6×8, très dense (expert). Chemin optimal 12 pas.
  static const level4 = GridConfig(
    cols: 6,
    rows: 8,
    start: 0, // (0,0)
    end: 47, // (7,5)
    obstacles: {6, 7, 8, 9, 13, 14, 15, 19, 20, 21, 25, 26, 31, 32, 37, 38, 43, 44},
    costlyZones: {},
    objectives: {11, 35},
    optimalLength: 12,
  );

  /// Suite ordonnée des niveaux (du plus facile au plus difficile).
  static const List<GridConfig> levels = [level1, level2, level3, level4];
}
