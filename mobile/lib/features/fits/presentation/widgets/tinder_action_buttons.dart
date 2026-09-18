import 'package:flutter/material.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_motion.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

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

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _action(
          context,
          'Undo',
          HugeIcons.strokeRoundedUndo02,
          context.colors.primary,
          canUndo ? onUndo : null,
        ),
        _action(
          context,
          'Pass',
          HugeIcons.strokeRoundedCancel01,
          context.colors.accent,
          enabled ? onReject : null,
          prominent: true,
        ),
        _action(
          context,
          'Like',
          HugeIcons.strokeRoundedTick02,
          context.colors.success,
          enabled ? onApprove : null,
          prominent: true,
        ),
        _action(
          context,
          'Skip',
          HugeIcons.strokeRoundedNext,
          context.colors.primary,
          enabled ? onForward : null,
        ),
      ],
    ),
  );

  Widget _action(
    BuildContext context,
    String label,
    AppIconData icon,
    Color color,
    VoidCallback? callback, {
    bool prominent = false,
  }) => AppPressScale(
    enabled: callback != null,
    child: IconButton(
      tooltip: label,
      onPressed: callback == null
          ? null
          : () {
              SoundService.instance.vibrateSelection();
              callback();
            },
      style: IconButton.styleFrom(
        minimumSize: Size.square(prominent ? 62 : 48),
        backgroundColor: context.colors.cardSurface,
        foregroundColor: color,
        disabledForegroundColor: context.colors.textMuted.withValues(alpha: .4),
        side: BorderSide(
          color: prominent
              ? color.withValues(alpha: .2)
              : context.colors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(prominent ? 24 : 18),
        ),
      ),
      icon: AppIcon(icon, size: prominent ? 30 : 22),
    ),
  );
}
