import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
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
    this.playClickSound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  /// Joue le clic générique de bouton. À désactiver quand l'action déclenche
  /// déjà son propre son (ex. « Add Move » du Predictive-Puzzle → son de disque).
  final bool playClickSound;

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
      onPressed: onPressed == null
          ? null
          : () {
              if (playClickSound) {
                SoundService.instance.playSfx(GameSfx.buttonClick);
              }
              onPressed!();
            },
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
      onPressed: onPressed == null
          ? null
          : () {
              SoundService.instance.playSfx(GameSfx.buttonClick);
              onPressed!();
            },
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
          _AnimatedMultiplier(
            multiplier: multiplier,
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

/// Multiplicateur qui grossit instantanément (×1.25) quand sa valeur change,
/// puis redescend à l'échelle 1 sur ~500 ms (fiche « Je bouge »).
class _AnimatedMultiplier extends StatefulWidget {
  const _AnimatedMultiplier({required this.multiplier, required this.style});

  final int multiplier;
  final TextStyle style;

  @override
  State<_AnimatedMultiplier> createState() => _AnimatedMultiplierState();
}

class _AnimatedMultiplierState extends State<_AnimatedMultiplier>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );

  @override
  void didUpdateWidget(_AnimatedMultiplier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.multiplier != widget.multiplier) {
      // Agrandissement instantané puis retour animé vers l'échelle 1.
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 + 0.25 * (1 - Curves.easeOut.transform(_controller.value));
        return Transform.scale(scale: scale, child: child);
      },
      child: Text('x${widget.multiplier}', style: widget.style),
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
    final silhouette = Path()
      ..moveTo(w * 0.03, h * 0.39)
      ..quadraticBezierTo(w * 0.04, h * 0.35, w * 0.08, h * 0.37)
      ..lineTo(w * 0.17, h * 0.45)
      ..lineTo(w * 0.32, h * 0.45)
      ..lineTo(w * 0.20, h * 0.21)
      ..quadraticBezierTo(w * 0.18, h * 0.16, w * 0.24, h * 0.18)
      ..lineTo(w * 0.64, h * 0.40)
      ..lineTo(w * 0.79, h * 0.42)
      ..lineTo(w * 0.97, h * 0.49)
      ..quadraticBezierTo(w, h * 0.50, w * 0.97, h * 0.51)
      ..lineTo(w * 0.79, h * 0.58)
      ..lineTo(w * 0.64, h * 0.60)
      ..lineTo(w * 0.24, h * 0.82)
      ..quadraticBezierTo(w * 0.18, h * 0.84, w * 0.20, h * 0.79)
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(w * 0.17, h * 0.55)
      ..lineTo(w * 0.08, h * 0.63)
      ..quadraticBezierTo(w * 0.04, h * 0.65, w * 0.03, h * 0.61)
      ..lineTo(w * 0.08, h * 0.50)
      ..close();
    final upperWingPanel = Path()
      ..moveTo(w * 0.29, h * 0.26)
      ..lineTo(w * 0.61, h * 0.42)
      ..lineTo(w * 0.76, h * 0.45)
      ..lineTo(w * 0.38, h * 0.43)
      ..close();
    final lowerWingPanel = Path()
      ..moveTo(w * 0.38, h * 0.57)
      ..lineTo(w * 0.76, h * 0.55)
      ..lineTo(w * 0.61, h * 0.58)
      ..lineTo(w * 0.29, h * 0.74)
      ..close();
    final upperTailPanel = Path()
      ..moveTo(w * 0.07, h * 0.40)
      ..lineTo(w * 0.18, h * 0.47)
      ..lineTo(w * 0.29, h * 0.47)
      ..lineTo(w * 0.12, h * 0.39)
      ..close();
    final lowerTailPanel = Path()
      ..moveTo(w * 0.12, h * 0.61)
      ..lineTo(w * 0.29, h * 0.53)
      ..lineTo(w * 0.18, h * 0.53)
      ..lineTo(w * 0.07, h * 0.60)
      ..close();

    final shadow = Paint()
      ..color = const Color(0xFF574BFF).withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.018);
    final outline = Paint()
      ..color = const Color(0xFF4C46FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final white = Paint()..color = const Color(0xFFFDFDFF);
    final panel = Paint()..color = const Color(0xFFD9D9EF);
    final accent = Paint()..color = color;
    final underBody = Paint()..color = const Color(0xFFD8D9E4);
    final cockpit = Paint()..color = const Color(0xFF343052);

    canvas.save();
    canvas.translate(-w * 0.012, h * 0.035);
    canvas.drawPath(silhouette, shadow);
    canvas.restore();

    canvas.drawPath(silhouette, white);
    canvas.drawPath(silhouette, outline);
    canvas.drawPath(upperTailPanel, panel);
    canvas.drawPath(lowerTailPanel, panel);
    canvas.drawPath(upperWingPanel, accent);
    canvas.drawPath(lowerWingPanel, accent);

    final fuselage = Path()
      ..moveTo(w * 0.08, h * 0.43)
      ..lineTo(w * 0.74, h * 0.43)
      ..quadraticBezierTo(w * 0.86, h * 0.43, w * 0.97, h * 0.50)
      ..quadraticBezierTo(w * 0.86, h * 0.57, w * 0.74, h * 0.57)
      ..lineTo(w * 0.08, h * 0.57)
      ..lineTo(w * 0.14, h * 0.50)
      ..close();
    canvas.drawPath(fuselage, white);
    final lowerFuselage = Path()
      ..moveTo(w * 0.11, h * 0.51)
      ..lineTo(w * 0.77, h * 0.51)
      ..quadraticBezierTo(w * 0.86, h * 0.51, w * 0.92, h * 0.50)
      ..quadraticBezierTo(w * 0.84, h * 0.56, w * 0.74, h * 0.56)
      ..lineTo(w * 0.08, h * 0.56)
      ..close();
    canvas.drawPath(lowerFuselage, underBody);

    final centerStripe = Path()
      ..moveTo(w * 0.15, h * 0.485)
      ..lineTo(w * 0.80, h * 0.485)
      ..quadraticBezierTo(w * 0.88, h * 0.485, w * 0.94, h * 0.50)
      ..quadraticBezierTo(w * 0.88, h * 0.515, w * 0.80, h * 0.515)
      ..lineTo(w * 0.15, h * 0.515)
      ..close();
    canvas.drawPath(centerStripe, accent);

    final canopyPath = Path()
      ..moveTo(w * 0.69, h * 0.43)
      ..lineTo(w * 0.82, h * 0.43)
      ..quadraticBezierTo(w * 0.87, h * 0.44, w * 0.89, h * 0.47)
      ..lineTo(w * 0.68, h * 0.47)
      ..close();
    canvas.drawPath(canopyPath, cockpit);
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
          _AnimatedStatValue(
            value: value,
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

/// Valeur d'une tuile de résultat : si le texte contient **exactement un**
/// nombre (ex. `97%`, `+2`, `0.42s`, `3 series`), il s'anime de 0 → valeur en
/// préservant le préfixe/suffixe et le nombre de décimales. Sinon (`Flexibility`,
/// `8-10 min`, `Mobile`…), le texte est affiché tel quel.
class _AnimatedStatValue extends StatelessWidget {
  const _AnimatedStatValue({required this.value, required this.style});

  final String value;
  final TextStyle style;

  static final RegExp _single = RegExp(r'^(\D*?)(-?\d+(?:\.\d+)?)(\D*)$');

  @override
  Widget build(BuildContext context) {
    final match = _single.firstMatch(value);
    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (match == null) return text;

    final prefix = match.group(1)!;
    final numberStr = match.group(2)!;
    final suffix = match.group(3)!;
    final target = double.parse(numberStr);
    final dotIndex = numberStr.indexOf('.');
    final decimals = dotIndex < 0 ? 0 : numberStr.length - dotIndex - 1;

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(value),
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(
        '$prefix${animated.toStringAsFixed(decimals)}$suffix',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// Nombre qui s'anime de 0 jusqu'à [value] au montage (écrans de score des jeux).
///
/// Rejoue l'animation si [value] change. [prefix]/[suffix] encadrent le nombre
/// (ex. `%`). [style] et [textAlign] sont transmis au [Text] final.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    this.textAlign,
    this.onCompleted,
  });

  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final Duration duration;
  final TextAlign? textAlign;

  /// Appelé une fois quand le comptage 0 → [value] atteint sa valeur finale.
  /// Utilisé pour couper le son du tableau de score en fin d'animation.
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // La clé force un redémarrage à 0 quand la cible change.
      key: ValueKey<int>(value),
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      onEnd: onCompleted,
      builder: (context, animated, _) => Text(
        '$prefix${animated.round()}$suffix',
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// Action renvoyée par le menu pause partagé ([GamePauseScaffold]).
enum GamePauseAction { resume, help, exit, restart }

/// Coquille visuelle **unique** du menu pause, identique dans tous les jeux :
/// carte blanche arrondie, titre « Pause », une section optionnelle en tête
/// (ex. « Input mode »), une description optionnelle, le bloc « Audio options »
/// puis la pile de boutons d'action fournie par l'écran appelant.
///
/// Chaque jeu garde son propre enum/handler : il passe simplement ses boutons
/// (Resume / Restart / View rules / Exit…) via [buttons]. Le rendu reste donc
/// strictement le même partout — voir la maquette de référence « Je bouge ».
class GamePauseScaffold extends StatelessWidget {
  const GamePauseScaffold({
    super.key,
    this.title = 'Pause',
    this.titleKey,
    this.inputMode,
    this.description,
    this.showAudioOptions = true,
    required this.buttons,
  });

  final String title;
  final Key? titleKey;

  /// Section optionnelle affichée entre le titre et « Audio options »
  /// (ex. le sélecteur « Input mode » de Je bouge / Emotional Radar).
  final Widget? inputMode;

  /// Texte d'aide/avertissement optionnel (ex. phase mesurée non reprenable).
  final String? description;

  /// Affiche le bloc « Audio options » (effets + musique). Vrai partout.
  final bool showAudioOptions;

  /// Boutons d'action, dans l'ordre (Resume, Restart, View rules, Exit…).
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                key: titleKey,
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: ZennytGamePalette.blue,
                  letterSpacing: 0,
                ),
              ),
              if (inputMode != null) ...[
                const SizedBox(height: AppSpacing.xl),
                inputMode!,
              ],
              if (description != null) ...[
                SizedBox(
                  height: inputMode != null ? AppSpacing.lg : AppSpacing.xl,
                ),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: ZennytGamePalette.muted,
                    height: 1.45,
                  ),
                ),
              ],
              if (showAudioOptions) ...[
                SizedBox(
                  height: (inputMode != null || description != null)
                      ? AppSpacing.lg
                      : AppSpacing.xl,
                ),
                const GamePauseAudioOptions(),
              ],
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                buttons[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bloc « Audio options » commun : deux interrupteurs (effets sonores +
/// musique) reliés **directement** au [SoundService]. Auto-géré : aucun état à
/// tenir côté écran, l'état initial reflète le service.
class GamePauseAudioOptions extends StatefulWidget {
  const GamePauseAudioOptions({super.key});

  @override
  State<GamePauseAudioOptions> createState() => _GamePauseAudioOptionsState();
}

class _GamePauseAudioOptionsState extends State<GamePauseAudioOptions> {
  late bool _soundEffects = SoundService.instance.sfxEnabled;
  late bool _music = SoundService.instance.musicEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Audio options',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GamePauseSwitchTile(
          label: 'Sound effects',
          value: _soundEffects,
          onChanged: (value) {
            setState(() => _soundEffects = value);
            SoundService.instance.setSfxEnabled(value);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        GamePauseSwitchTile(
          label: 'Music',
          value: _music,
          onChanged: (value) {
            setState(() => _music = value);
            SoundService.instance.setMusicEnabled(value);
          },
        ),
      ],
    );
  }
}

/// Ligne d'interrupteur bordée du menu pause (label + « On/Off » + [Switch]).
class GamePauseSwitchTile extends StatelessWidget {
  const GamePauseSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: ZennytGamePalette.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: ZennytGamePalette.blue,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            value ? 'On' : 'Off',
            style: AppTypography.labelMedium.copyWith(
              color: value
                  ? ZennytGamePalette.success
                  : ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Sélecteur « Input mode » (Boutons / Tactile) commun, présenté au-dessus des
/// options audio pour les jeux qui gèrent une entrée directionnelle.
class GamePauseInputModeToggle extends StatelessWidget {
  const GamePauseInputModeToggle({
    super.key,
    required this.buttonsSelected,
    required this.onChanged,
  });

  final bool buttonsSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Input mode',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Buttons')),
            ButtonSegment(value: false, label: Text('Tactile')),
          ],
          selected: {buttonsSelected},
          showSelectedIcon: true,
          onSelectionChanged: (selected) => onChanged(selected.first),
        ),
      ],
    );
  }
}

/// Bouton « Exit … » commun (contour rouge sur fond rosé), identique partout.
class GamePauseExitButton extends StatelessWidget {
  const GamePauseExitButton({
    super.key,
    this.label = 'Exit mission',
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ZennytGamePalette.error,
          side: const BorderSide(color: ZennytGamePalette.error),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          textStyle: AppTypography.buttonMedium.copyWith(letterSpacing: 0),
        ),
        child: Text(label),
      ),
    );
  }
}
