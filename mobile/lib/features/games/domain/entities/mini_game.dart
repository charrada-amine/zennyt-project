/// Mini-jeu de Planifik. Aligné sur l'enum MiniGame de
/// contracts/games.openapi.yaml. Seul [MiniGame.optimalPath] est implémenté.
enum MiniGame {
  optimalPath('OPTIMAL_PATH'),
  taskScheduling('TASK_SCHEDULING'),
  previsionPuzzle('PREVISION_PUZZLE'),
  moveFastCore('MOVE_FAST_CORE'),
  memoryQuestCore('MEMORY_QUEST_CORE'),
  decisionCore('DECISION_CORE'),
  emotionalRadarCore('EMOTIONAL_RADAR_CORE'),
  reflectivePauseCore('REFLECTIVE_PAUSE_CORE'),
  strategicChoicesCore('STRATEGIC_CHOICES_CORE'),
  continuousAttentionCore('CONTINUOUS_ATTENTION_CORE'),
  coordinationTrackingCore('COORDINATION_TRACKING_CORE'),

  /// « Je place » — raw object/location restitution protocol.
  objectLocationBindingCore('OBJECT_LOCATION_BINDING_CORE'),

  /// BART — Balloon Analogue Risk Task (Lejuez et al., 2002).
  bartCore('BART_CORE'),

  /// IST — Information Sampling Task (Clark et al., 2006).
  informationSamplingCore('INFORMATION_SAMPLING_CORE');

  final String wire;
  const MiniGame(this.wire);

  static MiniGame fromWire(String value) =>
      MiniGame.values.firstWhere((m) => m.wire == value);
}
