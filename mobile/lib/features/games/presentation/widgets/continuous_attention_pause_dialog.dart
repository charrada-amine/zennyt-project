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
  });

  final bool restartRequired;
  final bool canRestartPhase;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GamePauseScaffold(
        description: restartRequired
            ? 'This measured phase was interrupted. Restart it from the '
                  'beginning to keep the result comparable.'
            : 'Take the time you need. The practice clock is stopped.',
        buttons: [
          if (!restartRequired)
            GamePrimaryButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.of(
                context,
              ).pop(ContinuousAttentionPauseAction.resume),
            ),
          if (canRestartPhase)
            GameOutlineButton(
              label: 'Restart phase',
              icon: Icons.replay_rounded,
              onPressed: () => Navigator.of(
                context,
              ).pop(ContinuousAttentionPauseAction.restartPhase),
            ),
          GameOutlineButton(
            label: 'View rules / Help',
            icon: Icons.help_outline_rounded,
            onPressed: () =>
                Navigator.of(context).pop(ContinuousAttentionPauseAction.rules),
          ),
          GamePauseExitButton(
            label: 'Exit journey',
            onPressed: () =>
                Navigator.of(context).pop(ContinuousAttentionPauseAction.exit),
          ),
        ],
      ),
    );
  }
}
