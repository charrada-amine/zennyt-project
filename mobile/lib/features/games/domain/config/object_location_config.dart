import 'dart:convert';

/// Asset/catalog entry for the modern 2.5D objects used by « Je place ».
class ObjectLocationCatalogItem {
  const ObjectLocationCatalogItem({
    required this.id,
    required this.accessibleName,
    required this.assetPath,
  });

  final String id;
  final String accessibleName;
  final String assetPath;
}

enum ObjectLocationReserveZone { below, left, right, both }

enum ObjectLocationReserveSide { below, left, right }

class ObjectLocationLevelLayout {
  ObjectLocationLevelLayout({
    required this.levelIndex,
    required this.objectCount,
    required Map<String, int> originalCells,
    required List<String> reserveOrder,
    required this.reserveZone,
    required Map<String, ObjectLocationReserveSide> reserveSides,
  }) : originalCells = Map.unmodifiable(originalCells),
       reserveOrder = List.unmodifiable(reserveOrder),
       reserveSides = Map.unmodifiable(reserveSides);

  final int levelIndex;
  final int objectCount;
  final Map<String, int> originalCells;
  final List<String> reserveOrder;
  final ObjectLocationReserveZone reserveZone;
  final Map<String, ObjectLocationReserveSide> reserveSides;

  List<String> get objectIds => List.unmodifiable(originalCells.keys);
}

/// PROVISOIRE — non validé par le psychologue.
///
/// Exact Dart mirror of backend `ObjectLocationConfig` and its deterministic
/// generator. Keep both implementations and the golden vector aligned in the
/// same change. No position generated here is ever sent to the API.
class ObjectLocationConfig {
  const ObjectLocationConfig._();

  static const protocolVersion = 'OBJECT_LOCATION_FINE_V1';
  static const gridSize = 4;
  static const cellCount = gridSize * gridSize;
  static const practiceObjectCount = 2;
  static const measuredObjectCounts = <int>[3, 4, 5, 6, 7, 8];
  static const reserveZones = <ObjectLocationReserveZone>[
    ObjectLocationReserveZone.below,
    ObjectLocationReserveZone.below,
    ObjectLocationReserveZone.left,
    ObjectLocationReserveZone.right,
    ObjectLocationReserveZone.both,
    ObjectLocationReserveZone.below,
    ObjectLocationReserveZone.left,
  ];
  static const encodingPerObjectMs = 1500;
  static const retentionDurationMs = 2000;
  static const recallPerObjectMs = 4000;
  static const minimumValidMeasuredLevels = 3;
  static const maxGenerationAttempts = 256;
  static const maxActionsPerLevel = 256;
  static const technicalTimingToleranceMs = 100;
  static const minimumRecallPerObjectMs = 150;
  static const technicalRecallGraceMs = 250;
  static const advancementRatio = 0.60;
  static const _fallbackPattern = <int>[
    0,
    5,
    10,
    3,
    12,
    7,
    9,
    14,
    1,
    6,
    11,
    4,
    13,
    2,
    8,
    15,
  ];

  static int encodingDurationMs(int objectCount) =>
      objectCount * encodingPerObjectMs;

  static int recallDurationMs(int objectCount) =>
      objectCount * recallPerObjectMs;

  static int exactPlacementsToAdvance(int objectCount) =>
      (objectCount * advancementRatio).ceil();

  static const catalog = <ObjectLocationCatalogItem>[
    ObjectLocationCatalogItem(
      id: 'SMARTPHONE',
      accessibleName: 'smartphone',
      assetPath: 'assets/games icons/Je Place Object 01.png',
    ),
    ObjectLocationCatalogItem(
      id: 'WIRELESS_EARBUDS',
      accessibleName: 'wireless earbuds',
      assetPath: 'assets/games icons/Je Place Object 02.png',
    ),
    ObjectLocationCatalogItem(
      id: 'SMARTWATCH',
      accessibleName: 'smartwatch',
      assetPath: 'assets/games icons/Je Place Object 03.png',
    ),
    ObjectLocationCatalogItem(
      id: 'REUSABLE_BOTTLE',
      accessibleName: 'reusable bottle',
      assetPath: 'assets/games icons/Je Place Object 04.png',
    ),
    ObjectLocationCatalogItem(
      id: 'INSTANT_CAMERA',
      accessibleName: 'instant camera',
      assetPath: 'assets/games icons/Je Place Object 05.png',
    ),
    ObjectLocationCatalogItem(
      id: 'SNEAKER',
      accessibleName: 'sneaker',
      assetPath: 'assets/games icons/Je Place Object 06.png',
    ),
    ObjectLocationCatalogItem(
      id: 'SUCCULENT',
      accessibleName: 'succulent plant',
      assetPath: 'assets/games icons/Je Place Object 07.png',
    ),
    ObjectLocationCatalogItem(
      id: 'CERAMIC_MUG',
      accessibleName: 'travel mug',
      assetPath: 'assets/games icons/Je Place Object 08.png',
    ),
    ObjectLocationCatalogItem(
      id: 'BACKPACK',
      accessibleName: 'backpack',
      assetPath: 'assets/games icons/Je Place Object 09.png',
    ),
    ObjectLocationCatalogItem(
      id: 'GAME_CONTROLLER',
      accessibleName: 'game controller',
      assetPath: 'assets/games icons/Je Place Object 10.png',
    ),
    ObjectLocationCatalogItem(
      id: 'BICYCLE_HELMET',
      accessibleName: 'bicycle helmet',
      assetPath: 'assets/games icons/Je Place Object 11.png',
    ),
    ObjectLocationCatalogItem(
      id: 'DESK_LAMP',
      accessibleName: 'desk lamp',
      assetPath: 'assets/games icons/Je Place Object 12.png',
    ),
    ObjectLocationCatalogItem(
      id: 'NOTEBOOK',
      accessibleName: 'notebook',
      assetPath: 'assets/games icons/Je Place Object 13.png',
    ),
    ObjectLocationCatalogItem(
      id: 'SUNGLASSES',
      accessibleName: 'sunglasses',
      assetPath: 'assets/games icons/Je Place Object 14.png',
    ),
    ObjectLocationCatalogItem(
      id: 'KEYCARD',
      accessibleName: 'key card',
      assetPath: 'assets/games icons/Je Place Object 15.png',
    ),
    ObjectLocationCatalogItem(
      id: 'COMPACT_DRONE',
      accessibleName: 'compact drone',
      assetPath: 'assets/games icons/Je Place Object 16.png',
    ),
    ObjectLocationCatalogItem(
      id: 'PORTABLE_SPEAKER',
      accessibleName: 'portable speaker',
      assetPath: 'assets/games icons/Je Place Object 17.png',
    ),
    ObjectLocationCatalogItem(
      id: 'POWER_BANK',
      accessibleName: 'power bank',
      assetPath: 'assets/games icons/Je Place Object 18.png',
    ),
    ObjectLocationCatalogItem(
      id: 'STYLUS_TABLET',
      accessibleName: 'tablet and stylus',
      assetPath: 'assets/games icons/Je Place Object 19.png',
    ),
    ObjectLocationCatalogItem(
      id: 'TRAVEL_POUCH',
      accessibleName: 'travel pouch',
      assetPath: 'assets/games icons/Je Place Object 20.png',
    ),
  ];

  static ObjectLocationCatalogItem item(String id) =>
      catalog.firstWhere((item) => item.id == id);

  static int seedForSession(String sessionId) =>
      _fnv1a32(utf8.encode('${sessionId.toLowerCase()}|$protocolVersion'));

  static List<ObjectLocationLevelLayout> generateLayouts(String sessionId) {
    final random = _XorShift32(seedForSession(sessionId));
    final useCounts = <String, int>{for (final item in catalog) item.id: 0};
    final priorCells = <String, Set<int>>{};
    final layouts = <ObjectLocationLevelLayout>[];
    final loads = <int>[practiceObjectCount, ...measuredObjectCounts];

    for (var order = 0; order < loads.length; order++) {
      final load = loads[order];
      final levelIndex = order == 0 ? 0 : order;
      final chosen = _chooseBalancedObjects(random, useCounts, load);
      final cells = _chooseCells(random, chosen, priorCells);
      final originalCells = <String, int>{};
      for (var index = 0; index < chosen.length; index++) {
        originalCells[chosen[index]] = cells[index];
        priorCells.putIfAbsent(chosen[index], () => <int>{}).add(cells[index]);
      }
      final reserveOrder = [...chosen];
      random.shuffle(reserveOrder);
      final reserveSides = <String, ObjectLocationReserveSide>{};
      for (var index = 0; index < reserveOrder.length; index++) {
        reserveSides[reserveOrder[index]] = switch (reserveZones[order]) {
          ObjectLocationReserveZone.below => ObjectLocationReserveSide.below,
          ObjectLocationReserveZone.left => ObjectLocationReserveSide.left,
          ObjectLocationReserveZone.right => ObjectLocationReserveSide.right,
          ObjectLocationReserveZone.both =>
            index.isEven
                ? ObjectLocationReserveSide.left
                : ObjectLocationReserveSide.right,
        };
      }
      layouts.add(
        ObjectLocationLevelLayout(
          levelIndex: levelIndex,
          objectCount: load,
          originalCells: originalCells,
          reserveOrder: reserveOrder,
          reserveZone: reserveZones[order],
          reserveSides: reserveSides,
        ),
      );
    }
    return List.unmodifiable(layouts);
  }

  static List<String> _chooseBalancedObjects(
    _XorShift32 random,
    Map<String, int> useCounts,
    int count,
  ) {
    final result = <String>[];
    while (result.length < count) {
      final minimum = catalog
          .where((item) => !result.contains(item.id))
          .map((item) => useCounts[item.id]!)
          .reduce((a, b) => a < b ? a : b);
      final candidates = catalog
          .where(
            (item) =>
                !result.contains(item.id) && useCounts[item.id] == minimum,
          )
          .map((item) => item.id)
          .toList();
      random.shuffle(candidates);
      final chosen = candidates.first;
      result.add(chosen);
      useCounts[chosen] = useCounts[chosen]! + 1;
    }
    return result;
  }

  static List<int> _chooseCells(
    _XorShift32 random,
    List<String> objectIds,
    Map<String, Set<int>> priorCells,
  ) {
    for (var attempt = 0; attempt < maxGenerationAttempts; attempt++) {
      final cells = List<int>.generate(cellCount, (index) => index);
      random.shuffle(cells);
      final candidates = cells.take(objectIds.length).toList();
      if (_hasCompleteRegularLine(candidates)) continue;
      final assignment = _matchCells(objectIds, candidates, priorCells);
      if (assignment != null) {
        return [for (final objectId in objectIds) assignment[objectId]!];
      }
    }
    return _fallbackCells(objectIds, priorCells);
  }

  static List<int> _fallbackCells(
    List<String> objectIds,
    Map<String, Set<int>> priorCells,
  ) {
    for (var rowOffset = 0; rowOffset < gridSize; rowOffset++) {
      for (var columnOffset = 0; columnOffset < gridSize; columnOffset++) {
        final translated = <int>[];
        for (var index = 0; index < objectIds.length; index++) {
          final cell = _fallbackPattern[index];
          final row = (cell ~/ gridSize + rowOffset) % gridSize;
          final column = (cell % gridSize + columnOffset) % gridSize;
          translated.add(row * gridSize + column);
        }
        if (_hasCompleteRegularLine(translated)) continue;
        final assignment = _matchCells(objectIds, translated, priorCells);
        if (assignment != null) {
          return [for (final objectId in objectIds) assignment[objectId]!];
        }
      }
    }
    throw StateError('Unable to build a valid object-location layout');
  }

  static Map<String, int>? _matchCells(
    List<String> objectIds,
    List<int> cells,
    Map<String, Set<int>> priorCells,
  ) {
    final assignment = <String, int>{};
    final used = <int>{};

    bool match(int position) {
      if (position == objectIds.length) return true;
      final objectId = objectIds[position];
      final previous = priorCells[objectId] ?? const <int>{};
      for (final cell in cells) {
        if (used.contains(cell) || previous.contains(cell)) continue;
        used.add(cell);
        assignment[objectId] = cell;
        if (match(position + 1)) return true;
        assignment.remove(objectId);
        used.remove(cell);
      }
      return false;
    }

    return match(0) ? assignment : null;
  }

  static bool _hasCompleteRegularLine(List<int> cells) {
    final set = cells.toSet();
    for (var row = 0; row < gridSize; row++) {
      if (List.generate(
        gridSize,
        (column) => row * gridSize + column,
      ).every(set.contains)) {
        return true;
      }
    }
    for (var column = 0; column < gridSize; column++) {
      if (List.generate(
        gridSize,
        (row) => row * gridSize + column,
      ).every(set.contains)) {
        return true;
      }
    }
    if (const [0, 5, 10, 15].every(set.contains) ||
        const [3, 6, 9, 12].every(set.contains)) {
      return true;
    }
    return false;
  }

  static int _fnv1a32(List<int> bytes) {
    var hash = 0x811C9DC5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

class _XorShift32 {
  _XorShift32(int seed) : _state = seed == 0 ? 0x6D2B79F5 : seed;

  int _state;

  int nextUint32() {
    var value = _state;
    value ^= (value << 13) & 0xFFFFFFFF;
    value ^= value >>> 17;
    value ^= (value << 5) & 0xFFFFFFFF;
    _state = value & 0xFFFFFFFF;
    return _state;
  }

  int nextInt(int upperBound) {
    if (upperBound <= 0) throw ArgumentError.value(upperBound, 'upperBound');
    return nextUint32() % upperBound;
  }

  void shuffle<T>(List<T> values) {
    for (var index = values.length - 1; index > 0; index--) {
      final swapIndex = nextInt(index + 1);
      final value = values[index];
      values[index] = values[swapIndex];
      values[swapIndex] = value;
    }
  }
}
