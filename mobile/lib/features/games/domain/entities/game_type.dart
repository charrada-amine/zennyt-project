/// Type de jeu sérieux. Aligné sur l'enum GameType de
/// contracts/games.openapi.yaml. Seul [GameType.planifik] est implémenté.
enum GameType {
  planifik('PLANIFIK'),
  moveFast('MOVE_FAST'),
  memoryQuest('MEMORY_QUEST'),
  decision('DECISION');

  /// Valeur transmise à l'API (nom de l'enum côté back).
  final String wire;
  const GameType(this.wire);

  static GameType fromWire(String value) =>
      GameType.values.firstWhere((g) => g.wire == value);
}
