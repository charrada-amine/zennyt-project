import '../service/deterministic_random.dart';

/// Phase d'un ballon : l'entraînement n'entre jamais dans le score.
enum BartPhase {
  practice('PRACTICE'),
  test('TEST');

  const BartPhase(this.wire);
  final String wire;
}

/// Issue d'un ballon.
enum BartBalloonOutcome {
  collected('COLLECTED'),
  exploded('EXPLODED');

  const BartBalloonOutcome(this.wire);
  final String wire;
}

/// Configuration MOTEUR du BART — Lejuez et al. (2002), JEP: Applied 8(2), 75–84.
///
/// PARITÉ MOCK ⇄ BACKEND : miroir de `BartConfig.java` et de
/// `BartSequenceGenerator.java`. Toute modification ici impose la même
/// modification côté serveur, dans la même PR.
class BartConfig {
  BartConfig._();

  static const protocolVersion = 'BART_LEJUEZ_V1';
  static const practiceBalloonCount = 2;
  static const testBalloonCount = 30;
  static const totalBalloonCount = practiceBalloonCount + testBalloonCount;

  /// Point d'éclatement uniforme sur 1..128 ; le ballon éclate SUR cette pompe.
  static const maxPumps = 128;

  /// Échelle d'affichage (1 point = maquette concept) ; le score est un ratio.
  static const pointsPerPump = 1;

  static BartPhase phaseOf(int balloonIndex) {
    if (balloonIndex < 0 || balloonIndex >= totalBalloonCount) {
      throw RangeError.range(balloonIndex, 0, totalBalloonCount - 1, 'balloonIndex');
    }
    return balloonIndex < practiceBalloonCount ? BartPhase.practice : BartPhase.test;
  }

  static double survivalProbability(int pumps) => (maxPumps - pumps) / maxPumps;

  /// Stratégie fixe optimale en espérance : argmax n × P(point > n). Vaut 64.
  static int optimalFixedPumps() {
    var best = 0;
    var bestValue = -1.0;
    for (var n = 0; n < maxPumps; n++) {
      final value = n * survivalProbability(n);
      if (value > bestValue) {
        bestValue = value;
        best = n;
      }
    }
    return best;
  }

  /// Points d'éclatement des 32 ballons, dérivés de l'UUID de session.
  static List<int> explosionPoints(String sessionId) {
    final random = DeterministicRandom.forSession(sessionId, protocolVersion);
    return List<int>.unmodifiable(
      List<int>.generate(totalBalloonCount, (_) => 1 + random.nextInt(maxPumps)),
    );
  }
}
