import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ZennytGamePalette {
  ZennytGamePalette._();

  static const Color blue = Color(0xFF26224D);
  static const Color magenta = Color(0xFFD12E7D);
  static const Color mist = Color(0xFFF6F8FF);
  static const Color ink = Color(0xFF071333);
  static const Color muted = Color(0xFF7C87A6);
  static const Color border = Color(0xFFE2E8F4);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF5B5B);
  static const Color cyan = Color(0xFF00A9D6);
  static const Color ruleOrange = Color(0xFFFF9F43);
  static const Color gameBlue = Color(0xFF4E46E8);
  static const Color gamePanel = Color(0xFF675DE6);
}

enum GameDirection {
  up(Icons.arrow_upward, 'haut'),
  right(Icons.arrow_forward, 'droite'),
  down(Icons.arrow_downward, 'bas'),
  left(Icons.arrow_back, 'gauche');

  const GameDirection(this.icon, this.label);

  final IconData icon;
  final String label;
}

class GamePrimaryButton extends StatelessWidget {
  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = ZennytGamePalette.magenta,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          );

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: ZennytGamePalette.border,
        foregroundColor: Colors.white,
        disabledForegroundColor: ZennytGamePalette.muted,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: AppTypography.buttonLarge.copyWith(letterSpacing: 0),
      ),
      child: child,
    );
  }
}

class GameOutlineButton extends StatelessWidget {
  const GameOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = ZennytGamePalette.blue,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: const BorderSide(color: ZennytGamePalette.border, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: AppTypography.buttonMedium.copyWith(letterSpacing: 0),
      ),
    );
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = Colors.white,
    this.borderColor = ZennytGamePalette.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class GameRuleChip extends StatelessWidget {
  const GameRuleChip({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Règle active: $label',
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleSmall.copyWith(
            color: filled && color == Colors.white
                ? ZennytGamePalette.blue
                : filled
                ? Colors.white
                : color,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.timeLabel,
    required this.progress,
    required this.onPause,
    this.progressColor = ZennytGamePalette.success,
  });

  final int score;
  final String timeLabel;
  final double progress;
  final VoidCallback onPause;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HudTile(label: 'Score', value: '$score'),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _HudTile(label: 'Timer', value: timeLabel),
            ),
            const SizedBox(width: AppSpacing.base),
            SizedBox(
              width: 56,
              height: 52,
              child: IconButton.filled(
                tooltip: 'Mettre en pause',
                onPressed: onPause,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                icon: const Icon(Icons.pause),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress.clamp(0, 1),
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}

class _HudTile extends StatelessWidget {
  const _HudTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class SeriesRibbon extends StatelessWidget {
  const SeriesRibbon({
    super.key,
    required this.current,
    required this.multiplier,
    required this.color,
    this.statusLabel,
  });

  final int current;
  final int multiplier;
  final Color color;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: ZennytGamePalette.mist,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Text(
            'Series',
            style: AppTypography.labelSmall.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (var i = 1; i <= 4; i++) ...[
            _SeriesDot(index: i, active: i <= current, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Spacer(),
          if (statusLabel != null)
            Flexible(
              child: Text(
                statusLabel!,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  letterSpacing: 0,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'x$multiplier',
            style: AppTypography.headlineLarge.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesDot extends StatelessWidget {
  const _SeriesDot({
    required this.index,
    required this.active,
    required this.color,
  });

  final int index;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: active ? color : ZennytGamePalette.border),
      ),
      child: Text(
        '$index',
        style: AppTypography.labelSmall.copyWith(
          color: active ? Colors.white : ZennytGamePalette.muted,
          fontSize: 10,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class GameDirectionControls extends StatelessWidget {
  const GameDirectionControls({
    super.key,
    required this.onDirection,
    this.enabled = true,
    this.correctDirection,
    this.wrongDirection,
    this.compact = false,
  });

  final ValueChanged<GameDirection> onDirection;
  final bool enabled;
  final GameDirection? correctDirection;
  final GameDirection? wrongDirection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? 64.0 : 72.0;
    final gap = compact ? 14.0 : 18.0;
    // Croix compacte (D-pad) centrée comme la maquette Figma : les boutons
    // gauche/droite restent proches du centre au lieu d'être collés aux bords.
    final crossExtent = buttonSize * 3 + gap * 2;
    return Center(
      child: SizedBox(
        width: crossExtent,
        height: crossExtent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: _DirectionButton(
                direction: GameDirection.up,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.up),
                onTap: onDirection,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _DirectionButton(
                direction: GameDirection.left,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.left),
                onTap: onDirection,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _DirectionButton(
                direction: GameDirection.right,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.right),
                onTap: onDirection,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _DirectionButton(
                direction: GameDirection.down,
                size: buttonSize,
                enabled: enabled,
                state: _buttonState(GameDirection.down),
                onTap: onDirection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DirectionButtonState _buttonState(GameDirection direction) {
    if (direction == correctDirection) return _DirectionButtonState.correct;
    if (direction == wrongDirection) return _DirectionButtonState.wrong;
    return _DirectionButtonState.neutral;
  }
}

enum _DirectionButtonState { neutral, correct, wrong }

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.direction,
    required this.size,
    required this.enabled,
    required this.state,
    required this.onTap,
  });

  final GameDirection direction;
  final double size;
  final bool enabled;
  final _DirectionButtonState state;
  final ValueChanged<GameDirection> onTap;

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      _DirectionButtonState.correct => ZennytGamePalette.success,
      _DirectionButtonState.wrong => ZennytGamePalette.error.withValues(
        alpha: 0.12,
      ),
      _DirectionButtonState.neutral => Colors.white,
    };
    final border = switch (state) {
      _DirectionButtonState.correct => ZennytGamePalette.success,
      _DirectionButtonState.wrong => ZennytGamePalette.error,
      _DirectionButtonState.neutral => ZennytGamePalette.border,
    };
    final iconColor = switch (state) {
      _DirectionButtonState.correct => Colors.white,
      _DirectionButtonState.wrong => ZennytGamePalette.error,
      _DirectionButtonState.neutral => ZennytGamePalette.blue,
    };

    return Semantics(
      button: true,
      label: 'Répondre ${direction.label}',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: enabled ? () => onTap(direction) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border, width: 2),
            ),
            child: Icon(direction.icon, size: 34, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class MoveFastPlane extends StatelessWidget {
  const MoveFastPlane({
    super.key,
    required this.noseDirection,
    required this.color,
    this.size = 120,
    this.opacity = 1,
  });

  final GameDirection noseDirection;
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: _angleFor(noseDirection),
        child: CustomPaint(
          size: Size.square(size),
          painter: _PlanePainter(color),
        ),
      ),
    );
  }

  static double _angleFor(GameDirection direction) {
    return switch (direction) {
      GameDirection.up => -math.pi / 2,
      GameDirection.right => 0,
      GameDirection.down => math.pi / 2,
      GameDirection.left => math.pi,
    };
  }
}

class _PlanePainter extends CustomPainter {
  const _PlanePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shadow = Paint()
      ..color = ZennytGamePalette.ink.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFFD8D9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final accent = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ink = Paint()
      ..color = ZennytGamePalette.ink
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    final cyan = Paint()
      ..color = ZennytGamePalette.cyan
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(w * 0.08, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.30, w * 0.92, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.70, w * 0.08, h * 0.50)
      ..close();
    final leftWing = Path()
      ..moveTo(w * 0.45, h * 0.43)
      ..lineTo(w * 0.22, h * 0.12)
      ..lineTo(w * 0.65, h * 0.36)
      ..close();
    final rightWing = Path()
      ..moveTo(w * 0.45, h * 0.57)
      ..lineTo(w * 0.22, h * 0.88)
      ..lineTo(w * 0.65, h * 0.64)
      ..close();
    final tailTop = Path()
      ..moveTo(w * 0.22, h * 0.46)
      ..lineTo(w * 0.02, h * 0.26)
      ..lineTo(w * 0.32, h * 0.42)
      ..close();
    final tailBottom = Path()
      ..moveTo(w * 0.22, h * 0.54)
      ..lineTo(w * 0.02, h * 0.74)
      ..lineTo(w * 0.32, h * 0.58)
      ..close();

    canvas.save();
    canvas.translate(w * 0.06, h * 0.08);
    canvas.drawPath(body, shadow);
    canvas.drawPath(leftWing, shadow);
    canvas.drawPath(rightWing, shadow);
    canvas.drawPath(tailTop, shadow);
    canvas.drawPath(tailBottom, shadow);
    canvas.restore();

    for (final path in [leftWing, rightWing, tailTop, tailBottom, body]) {
      canvas.drawPath(path, outline);
      canvas.drawPath(path, white);
    }
    canvas.drawPath(leftWing, accent);
    canvas.drawPath(rightWing, accent);
    canvas.drawPath(tailTop, accent);
    canvas.drawPath(tailBottom, accent);
    canvas.drawPath(body, white);
    canvas.drawLine(
      Offset(w * 0.16, h * 0.50),
      Offset(w * 0.78, h * 0.50),
      ink,
    );

    final nose = Path()
      ..moveTo(w * 0.88, h * 0.50)
      ..lineTo(w * 0.74, h * 0.42)
      ..lineTo(w * 0.74, h * 0.58)
      ..close();
    canvas.drawPath(nose, cyan);
  }

  @override
  bool shouldRepaint(covariant _PlanePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ResultStatTile extends StatelessWidget {
  const ResultStatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = ZennytGamePalette.blue,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: valueColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
