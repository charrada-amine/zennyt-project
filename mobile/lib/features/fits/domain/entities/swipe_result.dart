import 'package:equatable/equatable.dart';

enum SwipeDirection {
  left('LEFT'),
  right('RIGHT');

  final String value;
  const SwipeDirection(this.value);

  /// Accepte les valeurs frontend (LEFT/RIGHT) et backend (PASS/LIKE).
  static SwipeDirection fromString(String v) {
    switch (v.toUpperCase()) {
      case 'RIGHT':
      case 'LIKE':
        return SwipeDirection.right;
      case 'LEFT':
      case 'PASS':
      default:
        return SwipeDirection.left;
    }
  }
}

enum SwipeTargetType {
  candidate('CANDIDATE'),
  jobOffer('JOB_OFFER');

  final String value;
  const SwipeTargetType(this.value);
}

class SwipeResult extends Equatable {
  final String swipeId;
  final SwipeDirection direction;
  final bool matched;
  final String? matchId;

  const SwipeResult({
    required this.swipeId,
    required this.direction,
    required this.matched,
    this.matchId,
  });

  @override
  List<Object?> get props => [swipeId, direction, matched, matchId];
}
