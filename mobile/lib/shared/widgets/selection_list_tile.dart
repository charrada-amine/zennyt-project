import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A single selectable row used in full-screen selection lists (e.g. the
/// "Field of work" screen). Shows a trailing check when [selected].
class SelectionListTile extends StatelessWidget {
  const SelectionListTile({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: selected
                      ? colors.actionCardFilled
                      : colors.textPrimary,
                  fontWeight: selected
                      ? AppTypography.semiBold
                      : AppTypography.regular,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check,
                color: colors.actionCardFilled,
                size: AppSpacing.iconMd,
              ),
          ],
        ),
      ),
    );
  }
}
