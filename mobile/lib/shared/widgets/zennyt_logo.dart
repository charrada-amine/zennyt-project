import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/constants/app_strings.dart';

/// The "ZENNYT" brand lockup: a stylized circular mark in the brand magenta
/// and blue, optionally followed by the wordmark.
///
/// This is a faithful approximation of the design's logo built purely in code
/// so the maquette has no external asset dependency. Replace [_LogoMark] with
/// the official SVG/PNG asset when available.
class ZennytLogo extends StatelessWidget {
  const ZennytLogo({
    super.key,
    this.size = 64,
    this.showWordmark = true,
    this.showTagline = false,
    this.wordmarkColor,
    this.axis = Axis.vertical,
  });

  final double size;
  final bool showWordmark;

  /// Whether to render the "Careers" sub-label beneath the wordmark.
  final bool showTagline;
  final Color? wordmarkColor;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final mark = _LogoMark(size: size);

    if (!showWordmark) return mark;

    final colors = context.colors;
    final wordmark = _Wordmark(
      color: wordmarkColor ?? colors.primary,
      fontSize: size * 0.32,
      showTagline: showTagline,
    );

    if (axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.22),
          wordmark,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: size * 0.28),
        wordmark,
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Safe fallback when the new asset is not found (e.g. before app restart)
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _LogoMarkPainter(
              ringColor: const Color(
                0xFF21438A,
              ), // Light mode primary (dark blue)
              arrowColor: const Color(
                0xFFD6317A,
              ), // Light mode accent (magenta)
            ),
          ),
        );
      },
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  _LogoMarkPainter({required this.ringColor, required this.arrowColor});

  final Color ringColor;
  final Color arrowColor;

  static double _rad(double deg) => deg * math.pi / 180.0;

  static Offset _onCircle(Offset c, double radius, double deg) => Offset(
    c.dx + radius * math.cos(_rad(deg)),
    c.dy + radius * math.sin(_rad(deg)),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Blue ring with a ~78° gap at the top-right (angles: 0 = right, CW+).
    const gapStart = -70.0; // top-right
    const gapEnd = 8.0; // right
    final bluePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = ringColor;
    canvas.drawArc(
      rect,
      _rad(gapEnd),
      _rad(360 - (gapEnd - gapStart)),
      false,
      bluePaint,
    );

    // Magenta arrowhead filling the gap, pointing up-right. A clean isosceles
    // triangle: tip outside the ring, base spanning the opening near the ring.
    const tipDeg = -45.0;
    final tip = _onCircle(center, radius + strokeWidth * 1.25, tipDeg);
    final baseLeft = _onCircle(
      center,
      radius - strokeWidth * 0.30,
      tipDeg - 30,
    );
    final baseRight = _onCircle(
      center,
      radius - strokeWidth * 0.30,
      tipDeg + 30,
    );
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();
    final magentaPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round
      ..color = arrowColor;
    canvas.drawPath(arrow, magentaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.color,
    required this.fontSize,
    this.showTagline = false,
  });

  final Color color;
  final double fontSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AppStrings.appName,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: AppTypography.extraBold,
            letterSpacing: fontSize * 0.08,
            height: 1,
          ),
        ),
        if (showTagline)
          Padding(
            padding: EdgeInsets.only(top: fontSize * 0.08),
            child: Text(
              AppStrings.appTagline,
              style: TextStyle(
                color: color,
                fontSize: fontSize * 0.42,
                fontWeight: AppTypography.medium,
                letterSpacing: fontSize * 0.06,
                height: 1,
              ),
            ),
          ),
      ],
    );
  }
}
