import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../flame/planifik_game.dart';
import '../games_controller.dart';

/// Écran du mini-jeu « Chemin Optimal ».
///
/// Il assemble trois briques indépendantes :
/// - [PlanifikGame] (Flame) pour le gameplay et la collecte des métriques ;
/// - [gamesControllerProvider] (Riverpod) pour le cycle session/score ;
/// - l'UI Flutter (consignes, bouton Valider, panneau de score).
///
/// Flame ne connaît pas Riverpod : l'écran fait le pont au clic sur « Valider ».
class PlanifikScreen extends ConsumerStatefulWidget {
  const PlanifikScreen({super.key});

  @override
  ConsumerState<PlanifikScreen> createState() => _PlanifikScreenState();
}

class _PlanifikScreenState extends ConsumerState<PlanifikScreen> {
  final PlanifikGame _game = PlanifikGame();
  int _attempts = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Démarre la session dès l'ouverture de l'écran.
    Future.microtask(
      () => ref.read(gamesControllerProvider.notifier).start(GameType.planifik),
    );
  }

  Future<void> _onValidate() async {
    final next = _attempts + 1;
    final metrics = _game.buildMetrics(attempts: next);
    if (metrics == null) return;
    _attempts = next;
    setState(() => _busy = true);
    await ref.read(gamesControllerProvider.notifier).submit(
      miniGame: MiniGame.optimalPath,
      metrics: metrics,
    );
    if (mounted) setState(() => _busy = false);
  }

  void _replay() {
    _attempts = 0;
    _game.resetPath();
    ref.read(gamesControllerProvider.notifier).start(GameType.planifik);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gamesControllerProvider);
    final session = async.value;

    ref.listen(gamesControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Chemin Optimal')),
      body: Builder(
        builder: (context) {
          if (session == null) {
            if (async.hasError) {
              return _ErrorView(message: '${async.error}', onRetry: _replay);
            }
            return const Center(child: CircularProgressIndicator());
          }
          final scored = session.lastAttempt != null;
          return _PlayView(
            game: _game,
            busy: _busy,
            session: scored ? session : null,
            onValidate: _onValidate,
            onReplay: _replay,
          );
        },
      ),
    );
  }
}

class _PlayView extends StatelessWidget {
  const _PlayView({
    required this.game,
    required this.busy,
    required this.session,
    required this.onValidate,
    required this.onReplay,
  });

  final PlanifikGame game;
  final bool busy;
  final GameSession? session;
  final VoidCallback onValidate;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Trace le chemin le plus court de la case verte à la rouge. '
            'Évite les zones oranges (coûteuses), attrape l\'objectif jaune.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GameWidget(game: game),
          ),
        ),
        if (session != null)
          _ScorePanel(session: session!, onReplay: onReplay)
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: game.resetPath,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Recommencer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.canValidate,
                    builder: (context, canValidate, _) => FilledButton.icon(
                      onPressed: (canValidate && !busy) ? onValidate : null,
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Valider'),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.session, required this.onReplay});

  final GameSession session;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final attempt = session.lastAttempt;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Résultat', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (attempt != null) ...[
              Text(
                '${attempt.score.rawPoints} / ${attempt.score.maxPoints} points',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Chip(label: Text(attempt.score.level)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReplay,
              icon: const Icon(Icons.replay),
              label: const Text('Rejouer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
