import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/mini_game.dart';
import 'games_providers.dart';

/// Source de vérité de la session de jeu courante.
///
/// `AsyncData(null)` = aucune session ; `AsyncData(session)` = session en cours
/// ou terminée (voir `session.status` / `session.lastAttempt`). Le contrôleur
/// ignore si les données viennent du backend ou du mock : c'est le repository
/// injecté qui tranche. Les erreurs remontent en `AsyncError` (ApiException).
class GamesController extends AsyncNotifier<GameSession?> {
  @override
  Future<GameSession?> build() async => null;

  /// Démarre une nouvelle session pour [gameType].
  Future<void> start(GameType gameType) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gamesRepositoryProvider).startSession(gameType),
    );
  }

  /// Soumet les métriques d'un mini-jeu terminé sur la session courante.
  Future<void> submit({
    required MiniGame miniGame,
    required GameMetrics metrics,
  }) async {
    final session = state.value;
    if (session == null) return;
    // Pas d'AsyncLoading ici : on garde la session (board) affichée pendant
    // l'appel ; l'écran gère son propre indicateur « busy » local.
    state = await AsyncValue.guard(
      () => ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: miniGame,
            metrics: metrics,
          ),
    );
  }
}

final gamesControllerProvider =
    AsyncNotifierProvider<GamesController, GameSession?>(GamesController.new);
