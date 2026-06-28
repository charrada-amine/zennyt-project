import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/enums/user_role.dart';

/// Segmented selector for the account role: Recruiter / Candidate / Student.
///
/// The selected segment is filled with the brand accent (magenta) as in the
/// design. Tapping a segment reports the new [UserRole] via [onChanged].
class RoleTabs extends StatelessWidget {
  const RoleTabs({super.key, required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    const roles = UserRole.values;
    return Row(
      children: [
        for (var i = 0; i < roles.length; i++) ...[
          Expanded(
            child: _Segment(
              label: roles[i].label,
              isSelected: roles[i] == selected,
              onTap: () => onChanged(roles[i]),
            ),
          ),
          if (i < roles.length - 1) const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.actionCardFilled : colors.cardSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? Colors.transparent : colors.border,
          ),
          boxShadow: isSelected ? AppShadows.accentButton : AppShadows.none,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.buttonSmall.copyWith(
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
