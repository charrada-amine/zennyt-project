import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/enums/user_role.dart';
import '../../core/audio/sound_service.dart';
import 'app_motion.dart';

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

    // iOS : contrôle segmenté natif (Liquid Glass sur iOS 26+, glissant
    // Cupertino avant). Android garde la pilule de la marque.
    if (PlatformInfo.isIOS) {
      return AdaptiveSegmentedControl(
        labels: [for (final role in roles) role.label],
        selectedIndex: roles.indexOf(selected),
        color: context.colors.accent,
        onValueChanged: (index) {
          if (roles[index] == selected) return;
          SoundService.instance.vibrateSelection();
          onChanged(roles[index]);
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.colors.inputFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (var i = 0; i < roles.length; i++) ...[
            Expanded(
              child: _Segment(
                label: roles[i].label,
                isSelected: roles[i] == selected,
                onTap: () => onChanged(roles[i]),
              ),
            ),
            if (i < roles.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
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
    return Semantics(
      selected: isSelected,
      button: true,
      child: AppPressScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (isSelected) return;
              SoundService.instance.vibrateSelection();
              onTap();
            },
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.settle),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.cardSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.transparent),
                boxShadow: isSelected ? AppShadows.sm : AppShadows.none,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.buttonSmall.copyWith(
                  color: isSelected ? colors.accent : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
