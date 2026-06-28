import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A lightweight top row that pins an optional [leading] widget (typically an
/// [AppBackButton]) to the left and an optional [trailing] widget (typically a
/// [LanguageToggle]) to the right — without a full-width app-bar band.
class ScreenTopBar extends StatelessWidget {
  const ScreenTopBar({super.key, this.leading, this.trailing});

  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: leading ?? const SizedBox.shrink()),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.base,
              top: AppSpacing.xs,
            ),
            child: trailing,
          ),
      ],
    );
  }
}
