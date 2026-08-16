import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'grid_config.dart';

/// Palette du plateau « Optimal Path » (stations circulaires), alignée sur la
/// maquette Figma 04 Route Draft.
class BoardPalette {
  BoardPalette._();

  static const Color start = Color(0xFFFFFFFF); // LAB (départ)
  static const Color startRing = Color(0xFF6C8CF5);
  static const Color finish = Color(0xFF22C55E); // MTG (arrivée)
  static const Color block = Color(0xFFF6C9C9); // bloc (éclair)
  static const Color blockIcon = Color(0xFFE8574C);
  static const Color star = Color(0xFFF5B800); // étoile bonus
  static const Color route = Color(0xFFD12E7D); // ligne du chemin
  static const Color node = Color(0xFFCDEBF5); // station normale (cyan clair)
  static const Color nodeInPath = Color(0xFF7ED8EE); // station du chemin
}

/// Station tactile de la grille (composant Flame), dessinée comme un cercle.
///
/// Elle se dessine selon son [kind] et son état [inPath], puis notifie le jeu
/// quand on la touche. Toute la logique de tracé vit dans `PlanifikGame`.
class CellComponent extends PositionComponent with TapCallbacks {
  CellComponent({
    required this.row,
    required this.col,
    required this.kind,
    required this.onCellTap,
    required super.position,
    required super.size,
  });

  final int row;
  final int col;
  final CellKind kind;
  final void Function(int row, int col) onCellTap;

  bool inPath = false;

  static const _gap = 5.0;

  // Échelle d'appui : la station grossit instantanément quand on la touche
  // (×[_pressScale]) puis redescend vers 1 sur ~300 ms au relâché. Le tracé est
  // mis à l'échelle autour de son centre, sans toucher au positionnement (topLeft)
  // géré par PlanifikGame.
  static const double _pressScale = 1.25;
  static const double _releaseDurationMs = 300;
  double _scale = 1;
  double _scaleTarget = 1;

  @override
  void update(double dt) {
    super.update(dt);
    if (_scale == _scaleTarget) return;
    // Retour progressif vers la cible sur ~_releaseDurationMs.
    final step = (_pressScale - 1) * (dt * 1000 / _releaseDurationMs);
    if (_scale > _scaleTarget) {
      _scale = math.max(_scaleTarget, _scale - step);
    } else {
      _scale = math.min(_scaleTarget, _scale + step);
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = math.min(size.x, size.y) / 2 - _gap;

    final scaled = _scale != 1;
    if (scaled) {
      canvas.save();
      canvas
        ..translate(center.dx, center.dy)
        ..scale(_scale)
        ..translate(-center.dx, -center.dy);
    }

    canvas.drawCircle(center, radius, Paint()..color = _fillColor());

    // Anneau pour départ / arrivée / bloc.
    final ring = _ringColor();
    if (ring != null) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    _drawGlyph(canvas, center, radius);

    if (scaled) canvas.restore();
  }

  Color _fillColor() {
    return switch (kind) {
      CellKind.start => BoardPalette.start,
      CellKind.end => BoardPalette.finish,
      CellKind.obstacle => BoardPalette.block,
      CellKind.costly => BoardPalette.node,
      CellKind.objective => inPath ? BoardPalette.nodeInPath : BoardPalette.node,
      CellKind.normal => inPath ? BoardPalette.nodeInPath : BoardPalette.node,
    };
  }

  Color? _ringColor() {
    return switch (kind) {
      CellKind.start => BoardPalette.startRing,
      CellKind.obstacle => BoardPalette.blockIcon.withValues(alpha: 0.5),
      _ => null,
    };
  }

  void _drawGlyph(Canvas canvas, Offset center, double radius) {
    switch (kind) {
      case CellKind.start:
        _label(canvas, center, radius, 'LAB', BoardPalette.startRing);
      case CellKind.end:
        _label(canvas, center, radius, 'MTG', Colors.white);
      case CellKind.obstacle:
        _bolt(canvas, center, radius * 0.5, BoardPalette.blockIcon);
      case CellKind.objective:
        _star(canvas, center, radius * 0.55, BoardPalette.star);
      case CellKind.costly:
      case CellKind.normal:
        break;
    }
  }

  void _label(Canvas canvas, Offset c, double radius, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final o = Offset(c.dx + rad * math.cos(angle), c.dy + rad * math.sin(angle));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _bolt(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx + s * 0.12, c.dy - s)
      ..lineTo(c.dx - s * 0.55, c.dy + s * 0.15)
      ..lineTo(c.dx - s * 0.05, c.dy + s * 0.15)
      ..lineTo(c.dx - s * 0.12, c.dy + s)
      ..lineTo(c.dx + s * 0.55, c.dy - s * 0.15)
      ..lineTo(c.dx + s * 0.05, c.dy - s * 0.15)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Grossit instantanément à la sélection.
    _scale = _pressScale;
    _scaleTarget = _pressScale;
    onCellTap(row, col);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _scaleTarget = 1; // redescend vers 1 (animé dans update).
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _scaleTarget = 1;
  }
}
