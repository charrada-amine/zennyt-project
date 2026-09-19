import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// A single item in [AppBottomNav]: an icon above a label.
///
/// Icons are HugeIcons outlines; the [selected] tab draws a heavier stroke in
/// the active colour. Provide either [icon] (+ optional [activeIcon]) or an
/// [iconBuilder] for fully custom marks.
/// The active item's label is brand navy + semibold; inactive labels are muted
/// gray. An optional [showBadge] renders a small magenta notification dot.
class AppNavItem extends StatelessWidget {
  const AppNavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.activeIcon,
    this.iconBuilder,
    this.showBadge = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppIconData? icon;
  final AppIconData? activeIcon;
  final Widget Function(bool selected)? iconBuilder;
  final bool showBadge;

  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = colors.navLabelSelected;
    final inactive = colors.navLabelUnselected;

    Widget iconWidget = iconBuilder != null
        ? iconBuilder!(selected)
        : AppIcon(
            selected ? (activeIcon ?? icon) : icon,
            size: _iconSize,
            strokeWidth: selected ? 2.0 : 1.6,
            color: selected ? active : inactive,
          );

    if (showBadge) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: colors.actionCardFilled,
                shape: BoxShape.circle,
                border: Border.all(color: colors.navBg, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: active.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Onglet actif : une pastille teintée derrière l'icône.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 52 : 40,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? active.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      letterSpacing: 0,
                      color: selected ? active : inactive,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Home" tab glyph: a rounded pentagon house with an arched doorway.
/// Outline when [filled] is false, solid navy (with the door cut out) when
/// selected — matching the bottom-nav design.
class NavHomeIcon extends StatelessWidget {
  const NavHomeIcon({super.key, required this.filled, this.size = 26});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HomeIconPainter(
          filled: filled,
          color: colors.navLabelSelected,
          cutoutColor: colors.navBg,
        ),
      ),
    );
  }
}

class _HomeIconPainter extends CustomPainter {
  _HomeIconPainter({
    required this.filled,
    required this.color,
    required this.cutoutColor,
  });

  final bool filled;
  final Color color;
  final Color cutoutColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.085;
    final p = s * 0.10 + (filled ? 0 : stroke / 2);

    final left = p;
    final right = s - p;
    final bottom = s - p;
    final shoulderY = s * 0.44;
    final cx = s / 2;
    final apexY = p;

    // Rounded pentagon "house" silhouette.
    final house = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, shoulderY)
      ..quadraticBezierTo(cx, apexY - s * 0.02, cx, apexY)
      ..quadraticBezierTo(cx, apexY - s * 0.02, right, shoulderY)
      ..lineTo(right, bottom)
      ..close();

    // Arched doorway centered on the bottom edge.
    final doorW = s * 0.26;
    final doorLeft = cx - doorW / 2;
    final doorRight = cx + doorW / 2;
    final doorTop = s * 0.52;
    final door = Path()
      ..moveTo(doorLeft, bottom)
      ..lineTo(doorLeft, doorTop)
      ..arcToPoint(
        Offset(doorRight, doorTop),
        radius: Radius.circular(doorW / 2),
        clockwise: true,
      )
      ..lineTo(doorRight, bottom);

    if (filled) {
      canvas.drawPath(house, Paint()..color = color);
      // Punch the door out so it reads as a clean cutout on the white bar.
      final doorFill = Path.from(door)..close();
      canvas.drawPath(doorFill, Paint()..color = cutoutColor);
    } else {
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawPath(house, outline);
      canvas.drawPath(door, outline);
    }
  }

  @override
  bool shouldRepaint(covariant _HomeIconPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.color != color;
}
