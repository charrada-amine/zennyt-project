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
  GameSession? _retrySession;

  @override
  Future<GameSession?> build() async => null;

  /// Démarre une nouvelle session pour [gameType].
  Future<void> start(GameType gameType) async {
    _retrySession = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(gamesRepositoryProvider).startSession(gameType),
    );
  }

  /// Soumet les métriques d'un mini-jeu terminé sur la session courante.
  Future<void> submit({
    required MiniGame miniGame,
    required GameMetrics metrics,
    bool preserveSessionOnError = false,
  }) async {
    final session =
        state.value ?? (preserveSessionOnError ? _retrySession : null);
    if (session == null) return;
    // Pas d'AsyncLoading ici : on garde la session (board) affichée pendant
    // l'appel ; l'écran gère son propre indicateur « busy » local.
    final result = await AsyncValue.guard(
      () => ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: miniGame,
            metrics: metrics,
          ),
    );
    // Je Décide soumet une seule fois en fin de parcours : conserver la
    // session permet de réessayer sans perdre les réponses ni rouvrir une partie.
    _retrySession = result.hasError && preserveSessionOnError ? session : null;
    state = result;
  }
}

final gamesControllerProvider =
    AsyncNotifierProvider<GamesController, GameSession?>(GamesController.new);
