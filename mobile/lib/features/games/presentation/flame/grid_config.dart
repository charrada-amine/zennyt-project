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
}
