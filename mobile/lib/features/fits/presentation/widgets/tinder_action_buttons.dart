import 'package:flutter/material.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_motion.dart';
import 'fits_palette.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Undo · Pass · Like · Skip, as in the maquettes: white floating circles, the
/// two main ones large, overlapping the bottom of the swipe card.
class TinderActionButtons extends StatelessWidget {
  const TinderActionButtons({
    super.key,
    required this.onUndo,
    required this.onReject,
    required this.onApprove,
    required this.onForward,
    required this.canUndo,
    this.enabled = true,
  });
  final VoidCallback onUndo, onReject, onApprove, onForward;
  final bool canUndo;
  final bool enabled;

  static const double bigSize = 74;
  static const double smallSize = 48;

  @override
  Widget build(BuildContext context) {
    final palette = FitsPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleAction(
          label: 'Undo',
          size: smallSize,
          onPressed: canUndo ? onUndo : null,
          child: AppIcon(
            HugeIcons.strokeRoundedReload,
            size: 24,
            strokeWidth: 2,
            color: palette.dark ? const Color(0xFF7FA6F5) : const Color(0xFF1A5BB0),
          ),
        ),
        const SizedBox(width: 22),
        _CircleAction(
          label: 'Pass',
          size: bigSize,
          onPressed: enabled ? onReject : null,
          child: const AppIcon(
            HugeIcons.strokeRoundedCancel01,
            size: 42,
            strokeWidth: 1.8,
            color: FitsPalette.magenta,
          ),
        ),
        const SizedBox(width: 46),
        _CircleAction(
          label: 'Like',
          size: bigSize,
          onPressed: enabled ? onApprove : null,
          child: const AppIcon(
            HugeIcons.strokeRoundedTick02,
            size: 44,
            strokeWidth: 2.4,
            color: FitsPalette.green,
          ),
        ),
        const SizedBox(width: 22),
        _CircleAction(
          label: 'Skip',
          size: smallSize,
          onPressed: enabled ? onForward : null,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF3B2A8C), FitsPalette.magenta],
            ).createShader(rect),
            child: const AppIcon(
              HugeIcons.strokeRoundedSent,
              size: 24,
              filled: true,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.label,
    required this.size,
    required this.onPressed,
    required this.child,
  });

  final String label;
  final double size;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AppPressScale(
      enabled: enabled,
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: context.colors.cardSurface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: !enabled
                    ? null
                    : () {
                        SoundService.instance.vibrateSelection();
                        onPressed!();
                      },
                child: Center(
                  child: Opacity(opacity: enabled ? 1 : .35, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
