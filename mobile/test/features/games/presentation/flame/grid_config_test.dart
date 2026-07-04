import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/presentation/flame/grid_config.dart';

void main() {
  group('GridConfig.randomLevels', () {
    test('generates solvable levels with increasing shortest paths', () {
      for (var seed = 0; seed < 25; seed++) {
        _expectValidSequence(GridConfig.randomLevels(seed: seed));
      }
    });

    test('varies generated maps between seeds', () {
      final first = GridConfig.randomLevels(seed: 1).map(_signature).toList();
      final second = GridConfig.randomLevels(seed: 2).map(_signature).toList();

      expect(first, isNot(second));
    });
  });
}

void _expectValidSequence(List<GridConfig> levels) {
  expect(levels, hasLength(GridConfig.levelCount));

  var previousOptimal = 0;
  for (final config in levels) {
    final shortest = _shortestPath(config);

    expect(shortest, isNotNull);
    expect(shortest!.length - 1, config.optimalLength);
    expect(config.optimalLength, greaterThan(previousOptimal));
    expect(config.obstacles, isNot(contains(config.start)));
    expect(config.obstacles, isNot(contains(config.end)));
    expect(config.costlyZones.intersection(config.obstacles), isEmpty);
    expect(config.objectives.intersection(config.obstacles), isEmpty);

    previousOptimal = config.optimalLength;
  }
}

List<int>? _shortestPath(GridConfig config) {
  final previous = List<int>.filled(config.cellCount, -1);
  final visited = List<bool>.filled(config.cellCount, false);
  final queue = ListQueue<int>()..add(config.start);
  visited[config.start] = true;

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == config.end) break;

    for (final next in _neighbors(config, current)) {
      if (visited[next]) continue;
      visited[next] = true;
      previous[next] = current;
      queue.add(next);
    }
  }

  if (!visited[config.end]) return null;

  final path = <int>[];
  var current = config.end;
  while (current != -1) {
    path.add(current);
    if (current == config.start) break;
    current = previous[current];
  }
  return path.reversed.toList();
}

Iterable<int> _neighbors(GridConfig config, int index) sync* {
  final row = config.rowOf(index);
  final col = config.colOf(index);
  final candidates = [
    if (row > 0) index - config.cols,
    if (row < config.rows - 1) index + config.cols,
    if (col > 0) index - 1,
    if (col < config.cols - 1) index + 1,
  ];

  for (final candidate in candidates) {
    if (config.isWalkable(candidate)) yield candidate;
  }
}

String _signature(GridConfig config) {
  final obstacles = config.obstacles.toList()..sort();
  final costly = config.costlyZones.toList()..sort();
  final objectives = config.objectives.toList()..sort();
  return '${config.cols}x${config.rows}:${config.start}>${config.end}:'
      '$obstacles:$costly:$objectives';
}
