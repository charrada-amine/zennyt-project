import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/core/theme/theme.dart';

class OptionItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? bgColor;

  const OptionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveIconColor = iconColor ?? colors.primary;
    final effectiveBgColor = bgColor ?? colors.inputFill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: FaIcon(
                    icon,
                    color: effectiveIconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
