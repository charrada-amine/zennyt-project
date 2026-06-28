import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// A minimal language row: label on the left, accent checkmark when selected.
class LanguageOptionTile extends StatelessWidget {
  const LanguageOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.textDarkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: selected
                    ? Icon(
                        key: ValueKey<String>('check-$label'),
                        Icons.check_rounded,
                        color: colors.accent,
                        size: 24,
                      )
                    : SizedBox(
                        key: ValueKey<String>('empty-$label'),
                        width: 24,
                        height: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
