import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'grid_config.dart';

/// Cellule tactile de la grille (composant Flame).
///
/// Elle se contente de se dessiner selon son [kind] et son état [inPath], et de
/// notifier le jeu quand on la touche. Toute la logique de tracé vit dans
/// `PlanifikGame` — le composant reste « bête ».
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

  static const _gap = 2.0;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(_gap, _gap, size.x - _gap * 2, size.y - _gap * 2);
    const radius = Radius.circular(6);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    canvas.drawRRect(rrect, Paint()..color = _fillColor());

    if (inPath) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.indigo
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  Color _fillColor() {
    if (inPath && kind == CellKind.normal) return Colors.indigo.shade200;
    return switch (kind) {
      CellKind.start => Colors.green.shade400,
      CellKind.end => Colors.red.shade400,
      CellKind.obstacle => Colors.blueGrey.shade800,
      CellKind.costly => Colors.orange.shade300,
      CellKind.objective => Colors.amber.shade400,
      CellKind.normal => inPath ? Colors.indigo.shade200 : Colors.grey.shade200,
    };
  }

  @override
  void onTapDown(TapDownEvent event) {
    onCellTap(row, col);
  }
}
