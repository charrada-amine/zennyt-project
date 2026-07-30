/// Type de jeu sérieux. Aligné sur l'enum GameType de
/// contracts/games.openapi.yaml. État actuel : [GameType.moveFast],
/// [GameType.planifik] (3 mini-jeux jouables, /30) et [GameType.memoryQuest]
/// sont implémentés ; [GameType.decision] est déclaré mais sans logique ; la
/// régulation émotionnelle (« Je gère ») héberge Emotional Radar et
/// Reflective Pause.
enum GameType {
  planifik('PLANIFIK'),
  moveFast('MOVE_FAST'),
  memoryQuest('MEMORY_QUEST'),
  decision('DECISION'),

  /// « Je gère » — Emotional Radar + Reflective Pause.
  emotionalRegulation('EMOTIONAL_REGULATION');

  /// Valeur transmise à l'API (nom de l'enum côté back).
  final String wire;
  const GameType(this.wire);

  static GameType fromWire(String value) =>
      GameType.values.firstWhere((g) => g.wire == value);
}
