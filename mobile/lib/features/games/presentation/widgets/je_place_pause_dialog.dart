import 'package:flutter/material.dart';

import 'game_system_components.dart';

enum JePlacePauseAction { resume, rules, restartRun, exit }

/// Pause semantics for « Je place ».
///
/// Practice can resume from its frozen monotonic clock. Any pause during a
/// measured phase invalidates that measured run, so no Resume action exists.
class JePlacePauseDialog extends StatelessWidget {
  const JePlacePauseDialog({super.key, required this.measuredRunInterrupted});

  final bool measuredRunInterrupted;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: ZennytGamePalette.gameBlue,
                  size: 36,
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
                measuredRunInterrupted
                    ? 'This measured round was interrupted. Restart from level 1 to keep one comparable journey.'
                    : 'Take your time. The practice clock is safely frozen.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ZennytGamePalette.muted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              if (!measuredRunInterrupted) ...[
                GamePrimaryButton(
                  label: 'Resume',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () =>
                      Navigator.of(context).pop(JePlacePauseAction.resume),
                ),
                const SizedBox(height: 12),
              ],
              if (measuredRunInterrupted) ...[
                GamePrimaryButton(
                  label: 'Restart run',
                  icon: Icons.replay_rounded,
                  onPressed: () =>
                      Navigator.of(context).pop(JePlacePauseAction.restartRun),
                ),
                const SizedBox(height: 12),
              ],
              GameOutlineButton(
                label: 'View rules / Help',
                icon: Icons.help_outline_rounded,
                onPressed: () =>
                    Navigator.of(context).pop(JePlacePauseAction.rules),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(JePlacePauseAction.exit),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Exit mission',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB33B3B),
                    backgroundColor: const Color(0xFFFDF6F6),
                    side: const BorderSide(color: Color(0xFFF3C9C9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
