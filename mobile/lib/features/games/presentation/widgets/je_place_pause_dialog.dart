import 'package:flutter/material.dart';

import 'game_system_components.dart';

enum JePlacePauseAction { resume, rules, restartRun, exit }

/// Menu pause de « Je place », rendu identique aux autres jeux via
/// [GamePauseScaffold].
///
/// La pratique reprend depuis son horloge figée. Une pause pendant une phase
/// mesurée invalide ce run mesuré : « Resume » disparaît alors au profit d'un
/// redémarrage, pour garder un parcours comparable.
class JePlacePauseDialog extends StatelessWidget {
  const JePlacePauseDialog({
    super.key,
    required this.measuredRunInterrupted,
    this.countdown,
    this.onCountdownExpired,
  });

  final bool measuredRunInterrupted;

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
        description: measuredRunInterrupted
            ? 'This measured round was interrupted. Restart from level 1 to '
                  'keep one comparable journey.'
            : 'Take your time. The practice clock is safely frozen.',
        actions: [
          if (!measuredRunInterrupted)
            GamePauseMenuAction.resume(
              onPressed: () =>
                  Navigator.of(context).pop(JePlacePauseAction.resume),
            ),
          if (measuredRunInterrupted)
            GamePauseMenuAction.restart(
              label: 'Restart run',
              onPressed: () =>
                  Navigator.of(context).pop(JePlacePauseAction.restartRun),
            ),
          GamePauseMenuAction.rules(
            onPressed: () =>
                Navigator.of(context).pop(JePlacePauseAction.rules),
          ),
          GamePauseMenuAction.exit(
            onPressed: () => Navigator.of(context).pop(JePlacePauseAction.exit),
          ),
        ],
      ),
    );
  }
}
