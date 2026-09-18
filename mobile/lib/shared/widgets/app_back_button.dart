import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/audio/sound_service.dart';
import 'app_motion.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Icon-only back button pinned to the top-left of a screen.
///
/// Replaces the full-width transparent [AppBar] band so content no longer
/// scrolls under an empty area. Tapping it pops the current route by default;
/// pass [onPressed] to override (e.g. when the screen was reached with
/// `context.go` and there's nothing on the navigation stack to pop).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xs),
        child: AppPressScale(
          child: IconButton(
            onPressed: () {
              SoundService.instance.vibrateSelection();
              (onPressed ?? () => _pop(context))();
            },
            style: IconButton.styleFrom(
              backgroundColor: context.colors.cardSurface,
              side: BorderSide(color: context.colors.border),
            ),
            icon: const AppIcon(HugeIcons.strokeRoundedArrowLeft02),
            color: context.colors.backButtonIcon,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    if (context.canPop()) context.pop();
  }
}
