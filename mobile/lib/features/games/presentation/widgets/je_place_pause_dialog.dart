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
  const JePlacePauseDialog({super.key, required this.measuredRunInterrupted});

  final bool measuredRunInterrupted;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GamePauseScaffold(
        description: measuredRunInterrupted
            ? 'This measured round was interrupted. Restart from level 1 to '
                  'keep one comparable journey.'
            : 'Take your time. The practice clock is safely frozen.',
        buttons: [
          if (!measuredRunInterrupted)
            GamePrimaryButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  Navigator.of(context).pop(JePlacePauseAction.resume),
            ),
          if (measuredRunInterrupted)
            GamePrimaryButton(
              label: 'Restart run',
              icon: Icons.replay_rounded,
              onPressed: () =>
                  Navigator.of(context).pop(JePlacePauseAction.restartRun),
            ),
          GameOutlineButton(
            label: 'View rules / Help',
            icon: Icons.help_outline_rounded,
            onPressed: () =>
                Navigator.of(context).pop(JePlacePauseAction.rules),
          ),
          GamePauseExitButton(
            label: 'Exit mission',
            onPressed: () =>
                Navigator.of(context).pop(JePlacePauseAction.exit),
          ),
        ],
      ),
    );
  }
}
