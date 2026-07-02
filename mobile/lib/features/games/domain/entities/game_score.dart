/// Score noté d'un mini-jeu (entité de domaine, pure et immuable).
///
/// Le score est calculé côté serveur à partir des métriques ; en mode
/// standalone (mock), il est reproduit localement selon le même barème.
class GameScore {
  const GameScore({
    required this.rawPoints,
    required this.maxPoints,
    required this.normalized,
    required this.level,
  });

  final int rawPoints;
  final int maxPoints;
  final double normalized;
  final String level;
}
