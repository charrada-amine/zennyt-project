/// Mini-jeu de Planifik. Aligné sur l'enum MiniGame de
/// contracts/games.openapi.yaml. Seul [MiniGame.optimalPath] est implémenté.
enum MiniGame {
  optimalPath('OPTIMAL_PATH'),
  taskScheduling('TASK_SCHEDULING'),
  previsionPuzzle('PREVISION_PUZZLE');

  final String wire;
  const MiniGame(this.wire);

  static MiniGame fromWire(String value) =>
      MiniGame.values.firstWhere((m) => m.wire == value);
}
