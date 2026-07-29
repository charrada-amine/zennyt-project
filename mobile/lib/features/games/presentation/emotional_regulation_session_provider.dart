import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/mini_game.dart';

/// Session en cours partagée par les jeux de régulation émotionnelle.
///
/// Emotional Radar et Reflective Pause alimentent le même agrégat backend afin
/// que le composite provisoire /37 soit réellement complété lorsque les deux
/// jeux sont joués dans la même exécution de l'application.
class EmotionalRegulationSessionNotifier extends Notifier<GameSession?> {
  @override
  GameSession? build() => null;

  void keep(GameSession session) {
    if (session.gameType != GameType.emotionalRegulation) return;
    state = session;
  }

  GameSession? reusableFor(MiniGame miniGame) {
    final current = state;
    if (current == null ||
        current.gameType != GameType.emotionalRegulation ||
        current.isCompleted ||
        current.attempts.any((attempt) => attempt.miniGame == miniGame)) {
      return null;
    }
    return current;
  }
}

final emotionalRegulationSessionProvider =
    NotifierProvider<EmotionalRegulationSessionNotifier, GameSession?>(
      EmotionalRegulationSessionNotifier.new,
    );
