import 'package:flutter/material.dart';

import 'game_system_components.dart';

enum ContinuousAttentionPauseAction { resume, rules, restartPhase, exit }

/// Menu de pause dédié à « Je continue ».
///
/// Une phase mesurée ne peut pas être reprise au milieu : le menu l'explique
/// et impose son redémarrage afin de préserver une timeline comparable.
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
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: ZennytGamePalette.gameBlue,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pause',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ZennytGamePalette.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                restartRequired
                    ? 'This measured phase was interrupted. Restart it from the '
                          'beginning to keep the result comparable.'
                    : 'Take the time you need. The practice clock is stopped.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ZennytGamePalette.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              if (!restartRequired) ...[
                GamePrimaryButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(ContinuousAttentionPauseAction.resume),
                ),
                const SizedBox(height: 12),
              ],
              if (canRestartPhase) ...[
                GameOutlineButton(
                  label: 'Restart phase',
                  icon: Icons.replay_rounded,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(ContinuousAttentionPauseAction.restartPhase),
                ),
                const SizedBox(height: 12),
              ],
              GameOutlineButton(
                label: 'View rules / Help',
                icon: Icons.help_outline_rounded,
                onPressed: () => Navigator.of(
                  context,
                ).pop(ContinuousAttentionPauseAction.rules),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(ContinuousAttentionPauseAction.exit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB33B3B),
                    backgroundColor: const Color(0xFFFDF6F6),
                    side: const BorderSide(color: Color(0xFFF3C9C9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: const Text(
                    'Exit journey',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
