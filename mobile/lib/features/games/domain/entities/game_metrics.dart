/// Raw game metrics sent to the backend. Clients never submit scores.
abstract class GameMetrics {
  const GameMetrics();

  Map<String, dynamic> toJson();
}
