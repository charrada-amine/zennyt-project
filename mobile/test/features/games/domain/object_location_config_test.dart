import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/features/games/domain/config/object_location_config.dart';

void main() {
  const sessionId = '00000000-0000-4000-8000-000000000004';

  test('golden vector mirrors all seven backend layouts exactly', () {
    final layouts = ObjectLocationConfig.generateLayouts(sessionId);

    expect(layouts, hasLength(7));
    expect(layouts.map(_canonical).toList(), [
      '0|below|SMARTPHONE@13:below#1,SNEAKER@1:below#0',
      '1|below|SUNGLASSES@0:below#2,PORTABLE_SPEAKER@3:below#0,NOTEBOOK@7:below#1',
      '2|left|BICYCLE_HELMET@9:left#3,SUCCULENT@7:left#0,WIRELESS_EARBUDS@5:left#1,INSTANT_CAMERA@0:left#2',
      '3|right|CERAMIC_MUG@8:right#1,TRAVEL_POUCH@2:right#2,SMARTWATCH@7:right#3,BACKPACK@0:right#4,DESK_LAMP@9:right#0',
      '4|both|COMPACT_DRONE@4:left#1,POWER_BANK@10:left#2,KEYCARD@15:right#1,STYLUS_TABLET@12:left#0,GAME_CONTROLLER@13:right#2,REUSABLE_BOTTLE@11:right#0',
      '5|below|NOTEBOOK@4:below#2,SUNGLASSES@2:below#0,CERAMIC_MUG@7:below#6,SUCCULENT@12:below#1,SMARTWATCH@5:below#3,GAME_CONTROLLER@14:below#5,INSTANT_CAMERA@15:below#4',
      '6|left|SMARTPHONE@2:left#4,KEYCARD@3:left#1,STYLUS_TABLET@4:left#7,DESK_LAMP@6:left#6,BACKPACK@15:left#5,PORTABLE_SPEAKER@7:left#3,SNEAKER@13:left#2,POWER_BANK@14:left#0',
    ]);
  });

  test('generation is deterministic, balanced and avoids repeated pairs', () {
    final first = ObjectLocationConfig.generateLayouts(sessionId);
    final second = ObjectLocationConfig.generateLayouts(sessionId);
    expect(second.map(_canonical), first.map(_canonical));

    final cellsByObject = <String, Set<int>>{};
    final useCounts = <String, int>{};
    for (final layout in first) {
      expect(
        layout.originalCells.values.toSet(),
        hasLength(layout.objectCount),
      );
      expect(_containsCompleteLine(layout.originalCells.values), isFalse);
      for (final entry in layout.originalCells.entries) {
        expect(
          cellsByObject.putIfAbsent(entry.key, () => {}).add(entry.value),
          isTrue,
        );
        useCounts.update(entry.key, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final counts = useCounts.values;
    expect(
      counts.reduce((a, b) => a > b ? a : b) -
          counts.reduce((a, b) => a < b ? a : b),
      lessThanOrEqualTo(1),
    );
  });
}

String _canonical(ObjectLocationLevelLayout layout) {
  String placement(String id) {
    final side = layout.reserveSides[id]!;
    final sideOrder = layout.reserveOrder
        .where((candidate) => layout.reserveSides[candidate] == side)
        .toList()
        .indexOf(id);
    return '$id@${layout.originalCells[id]}:${side.name}#$sideOrder';
  }

  return '${layout.levelIndex}|${layout.reserveZone.name}|'
      '${layout.objectIds.map(placement).join(',')}';
}

bool _containsCompleteLine(Iterable<int> cells) {
  final occupied = cells.toSet();
  for (var row = 0; row < 4; row++) {
    if (List.generate(
      4,
      (column) => row * 4 + column,
    ).every(occupied.contains)) {
      return true;
    }
  }
  for (var column = 0; column < 4; column++) {
    if (List.generate(4, (row) => row * 4 + column).every(occupied.contains)) {
      return true;
    }
  }
  return const [0, 5, 10, 15].every(occupied.contains) ||
      const [3, 6, 9, 12].every(occupied.contains);
}
