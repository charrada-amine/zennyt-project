import 'dart:collection';
import 'dart:math' as math;

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

  /// Nombre de niveaux joués dans une séquence Planifik.
  static const int levelCount = 4;

  /// Génère une nouvelle séquence solvable à chaque partie.
  ///
  /// Chaque carte candidate est résolue par BFS sur le graphe de grille. On
  /// conserve les cartes dont le plus court chemin est plus long, plus tortueux
  /// et plus contraint à mesure que le niveau augmente.
  static List<GridConfig> randomLevels({int? seed}) {
    return _GridConfigGenerator(seed: seed).generate();
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
    obstacles: {
      6,
      7,
      8,
      9,
      13,
      14,
      15,
      19,
      20,
      21,
      25,
      26,
      31,
      32,
      37,
      38,
      43,
      44,
    },
    costlyZones: {},
    objectives: {11, 35},
    optimalLength: 12,
  );

  /// Suite de secours déterministe, utile pour les aperçus et tests figés.
  static const List<GridConfig> levels = [level1, level2, level3, level4];
}

class _LevelSpec {
  const _LevelSpec({
    required this.cols,
    required this.rows,
    required this.obstacleRatio,
    required this.minOptimal,
    required this.maxOptimal,
    required this.minTurns,
    required this.minDetour,
    required this.objectiveCount,
    required this.costlyZoneCount,
  });

  final int cols;
  final int rows;
  final double obstacleRatio;
  final int minOptimal;
  final int maxOptimal;
  final int minTurns;
  final int minDetour;
  final int objectiveCount;
  final int costlyZoneCount;
}

class _GridConfigGenerator {
  _GridConfigGenerator({int? seed}) : _random = math.Random(seed);

  final math.Random _random;

  static const _specs = [
    _LevelSpec(
      cols: 5,
      rows: 6,
      obstacleRatio: 0.16,
      minOptimal: 8,
      maxOptimal: 12,
      minTurns: 2,
      minDetour: 0,
      objectiveCount: 1,
      costlyZoneCount: 2,
    ),
    _LevelSpec(
      cols: 6,
      rows: 6,
      obstacleRatio: 0.22,
      minOptimal: 10,
      maxOptimal: 15,
      minTurns: 3,
      minDetour: 1,
      objectiveCount: 1,
      costlyZoneCount: 3,
    ),
    _LevelSpec(
      cols: 6,
      rows: 7,
      obstacleRatio: 0.27,
      minOptimal: 12,
      maxOptimal: 18,
      minTurns: 4,
      minDetour: 2,
      objectiveCount: 2,
      costlyZoneCount: 4,
    ),
    _LevelSpec(
      cols: 8,
      rows: 8,
      obstacleRatio: 0.30,
      minOptimal: 17,
      maxOptimal: 30,
      minTurns: 5,
      minDetour: 3,
      objectiveCount: 2,
      costlyZoneCount: 5,
    ),
  ];

  List<GridConfig> generate() {
    final levels = <GridConfig>[];
    final signatures = <String>{};
    var previousOptimal = 0;

    for (final spec in _specs) {
      final config = _generateLevel(
        spec: spec,
        previousOptimal: previousOptimal,
        usedSignatures: signatures,
      );
      levels.add(config);
      signatures.add(_signature(config));
      previousOptimal = config.optimalLength;
    }

    return levels;
  }

  GridConfig _generateLevel({
    required _LevelSpec spec,
    required int previousOptimal,
    required Set<String> usedSignatures,
  }) {
    final targetMin = math.max(spec.minOptimal, previousOptimal + 1);
    var bestScore = -1 << 30;
    GridConfig? best;

    for (var attempt = 0; attempt < 900; attempt++) {
      final candidate = _tryCandidate(
        spec: spec,
        targetMin: targetMin,
        usedSignatures: usedSignatures,
        strict: true,
      );
      if (candidate == null) continue;

      final score = _candidateScore(candidate, spec);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    if (best != null) return best;

    for (var attempt = 0; attempt < 900; attempt++) {
      final candidate = _tryCandidate(
        spec: spec,
        targetMin: targetMin,
        usedSignatures: usedSignatures,
        strict: false,
      );
      if (candidate != null) return candidate;
    }

    final fallback = GridConfig.levels[_specs.indexOf(spec)];
    return fallback.optimalLength > previousOptimal
        ? fallback
        : GridConfig.level4;
  }

  GridConfig? _tryCandidate({
    required _LevelSpec spec,
    required int targetMin,
    required Set<String> usedSignatures,
    required bool strict,
  }) {
    final start = _pickStart(spec);
    final end = _pickEnd(spec);
    if (start == end) return null;

    final manhattan = _manhattan(spec.cols, start, end);
    final obstacles = _randomObstacles(spec, start: start, end: end);
    final shortestPath = _shortestPath(
      cols: spec.cols,
      rows: spec.rows,
      start: start,
      end: end,
      obstacles: obstacles,
    );
    if (shortestPath == null) return null;

    final optimalLength = shortestPath.length - 1;
    if (optimalLength < targetMin || optimalLength > spec.maxOptimal) {
      return null;
    }

    final turns = _turnCount(spec.cols, shortestPath);
    final detour = optimalLength - manhattan;
    if (strict && (turns < spec.minTurns || detour < spec.minDetour)) {
      return null;
    }

    final config = GridConfig(
      cols: spec.cols,
      rows: spec.rows,
      start: start,
      end: end,
      obstacles: obstacles,
      costlyZones: _pickCostlyZones(spec, obstacles, shortestPath),
      objectives: _pickObjectives(spec, obstacles, shortestPath),
      optimalLength: optimalLength,
    );

    if (usedSignatures.contains(_signature(config))) return null;
    return config;
  }

  int _candidateScore(GridConfig config, _LevelSpec spec) {
    final path = _shortestPath(
      cols: config.cols,
      rows: config.rows,
      start: config.start,
      end: config.end,
      obstacles: config.obstacles,
    );
    if (path == null) return -1 << 30;

    final detour =
        config.optimalLength -
        _manhattan(config.cols, config.start, config.end);
    final turns = _turnCount(config.cols, path);
    final decisions = _decisionCount(
      cols: config.cols,
      rows: config.rows,
      obstacles: config.obstacles,
      path: path,
    );

    final idealOptimal = ((spec.minOptimal + spec.maxOptimal) / 2).round();

    return 1000 -
        (config.optimalLength - idealOptimal).abs() * 30 +
        config.optimalLength * 5 +
        detour * 14 +
        turns * 10 +
        decisions * 3 +
        config.obstacles.length;
  }

  int _pickStart(_LevelSpec spec) {
    final rowLimit = math.max(1, (spec.rows * 0.45).floor());
    final colLimit = math.max(1, (spec.cols * 0.35).floor());
    final row = _random.nextInt(rowLimit);
    final col = _random.nextBool() ? 0 : _random.nextInt(colLimit);
    return row * spec.cols + col;
  }

  int _pickEnd(_LevelSpec spec) {
    final rowLimit = math.max(1, (spec.rows * 0.45).floor());
    final colLimit = math.max(1, (spec.cols * 0.35).floor());
    final row = spec.rows - 1 - _random.nextInt(rowLimit);
    final col = _random.nextBool()
        ? spec.cols - 1
        : spec.cols - 1 - _random.nextInt(colLimit);
    return row * spec.cols + col;
  }

  Set<int> _randomObstacles(
    _LevelSpec spec, {
    required int start,
    required int end,
  }) {
    final count = (spec.cols * spec.rows * spec.obstacleRatio).round();
    final blocked = <int>{};
    var guard = 0;
    while (blocked.length < count && guard < spec.cols * spec.rows * 4) {
      guard++;
      final index = _random.nextInt(spec.cols * spec.rows);
      if (index == start || index == end) continue;
      blocked.add(index);
    }
    return blocked;
  }

  Set<int> _pickObjectives(
    _LevelSpec spec,
    Set<int> obstacles,
    List<int> shortestPath,
  ) {
    final result = <int>{};
    final pathCandidates =
        shortestPath.skip(1).take(math.max(0, shortestPath.length - 2)).toList()
          ..shuffle(_random);

    for (final index in pathCandidates) {
      if (result.length >= spec.objectiveCount) break;
      result.add(index);
    }

    final allCandidates = _walkableCells(spec, obstacles, shortestPath.toSet())
      ..shuffle(_random);
    for (final index in allCandidates) {
      if (result.length >= spec.objectiveCount) break;
      result.add(index);
    }

    return result;
  }

  Set<int> _pickCostlyZones(
    _LevelSpec spec,
    Set<int> obstacles,
    List<int> shortestPath,
  ) {
    final pathSet = shortestPath.toSet();
    final candidates = _walkableCells(spec, obstacles, pathSet)
      ..shuffle(_random);
    return candidates.take(spec.costlyZoneCount).toSet();
  }

  List<int> _walkableCells(
    _LevelSpec spec,
    Set<int> obstacles,
    Set<int> excluded,
  ) {
    final cells = <int>[];
    for (var index = 0; index < spec.cols * spec.rows; index++) {
      if (obstacles.contains(index) || excluded.contains(index)) continue;
      cells.add(index);
    }
    return cells;
  }

  List<int>? _shortestPath({
    required int cols,
    required int rows,
    required int start,
    required int end,
    required Set<int> obstacles,
  }) {
    final count = cols * rows;
    final previous = List<int>.filled(count, -1);
    final visited = List<bool>.filled(count, false);
    final queue = ListQueue<int>()..add(start);
    visited[start] = true;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == end) break;

      for (final next in _neighbors(
        cols: cols,
        rows: rows,
        index: current,
        obstacles: obstacles,
      )) {
        if (visited[next]) continue;
        visited[next] = true;
        previous[next] = current;
        queue.add(next);
      }
    }

    if (!visited[end]) return null;

    final path = <int>[];
    var current = end;
    while (current != -1) {
      path.add(current);
      if (current == start) break;
      current = previous[current];
    }
    return path.reversed.toList();
  }

  Iterable<int> _neighbors({
    required int cols,
    required int rows,
    required int index,
    required Set<int> obstacles,
  }) sync* {
    final row = index ~/ cols;
    final col = index % cols;
    final candidates = [
      if (row > 0) index - cols,
      if (row < rows - 1) index + cols,
      if (col > 0) index - 1,
      if (col < cols - 1) index + 1,
    ]..shuffle(_random);

    for (final candidate in candidates) {
      if (!obstacles.contains(candidate)) yield candidate;
    }
  }

  int _turnCount(int cols, List<int> path) {
    if (path.length < 3) return 0;
    var turns = 0;
    var previousDelta = path[1] - path[0];
    for (var i = 2; i < path.length; i++) {
      final delta = path[i] - path[i - 1];
      if (delta != previousDelta) turns++;
      previousDelta = delta;
    }
    return turns;
  }

  int _decisionCount({
    required int cols,
    required int rows,
    required Set<int> obstacles,
    required List<int> path,
  }) {
    var decisions = 0;
    for (final index in path.skip(1).take(math.max(0, path.length - 2))) {
      final degree = _neighbors(
        cols: cols,
        rows: rows,
        index: index,
        obstacles: obstacles,
      ).length;
      if (degree >= 3) decisions++;
    }
    return decisions;
  }

  int _manhattan(int cols, int a, int b) {
    return ((a ~/ cols) - (b ~/ cols)).abs() + ((a % cols) - (b % cols)).abs();
  }

  String _signature(GridConfig config) {
    final obstacles = config.obstacles.toList()..sort();
    return '${config.cols}x${config.rows}:${config.start}>${config.end}:$obstacles';
  }
}
