import 'package:flutter/material.dart';

import 'game_system_components.dart';

enum ContinuousAttentionPauseAction { resume, rules, restartPhase, exit }

/// Menu de pause dédié à « Je continue ».
///
/// Rendu identique aux autres jeux via [GamePauseScaffold]. Une phase mesurée
/// ne peut pas être reprise au milieu : le menu masque alors « Resume » et
/// impose son redémarrage afin de préserver une timeline comparable.
class ContinuousAttentionPauseDialog extends StatelessWidget {
  const ContinuousAttentionPauseDialog({
    super.key,
    required this.restartRequired,
    this.canRestartPhase = true,
    this.countdown,
    this.onCountdownExpired,
  });

  final bool restartRequired;
  final bool canRestartPhase;

  /// Temps restant sur la fenêtre unique de pause (CdC pause §2-3).
  final Duration? countdown;
  final VoidCallback? onCountdownExpired;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GamePauseScaffold(
        countdown: countdown,
        onCountdownExpired: onCountdownExpired,
        description: restartRequired
            ? 'This measured phase was interrupted. Restart it from the '
                  'beginning to keep the result comparable.'
            : 'Take the time you need. The practice clock is stopped.',
        actions: [
          if (!restartRequired)
            GamePauseMenuAction.resume(
              onPressed: () => Navigator.of(
                context,
              ).pop(ContinuousAttentionPauseAction.resume),
            ),
          if (canRestartPhase)
            GamePauseMenuAction.restart(
              label: 'Restart phase',
              onPressed: () => Navigator.of(
                context,
              ).pop(ContinuousAttentionPauseAction.restartPhase),
            ),
          GamePauseMenuAction.rules(
            onPressed: () =>
                Navigator.of(context).pop(ContinuousAttentionPauseAction.rules),
          ),
          GamePauseMenuAction.exit(
            label: 'Exit journey',
            onPressed: () =>
                Navigator.of(context).pop(ContinuousAttentionPauseAction.exit),
          ),
        ],
      ),
    );
  }
}
