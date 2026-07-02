import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/planifik_metrics.dart';
import 'cell_component.dart';
import 'grid_config.dart';

/// Mini-jeu Flame « Chemin Optimal » (Planifik #1).
///
/// Le joueur trace un chemin de la case départ à la case arrivée en touchant
/// des cases adjacentes, en évitant obstacles et zones coûteuses. Le jeu ne
/// calcule PAS de score : il produit des [PlanifikMetrics] objectives que la
/// couche présentation envoie au serveur (ou au mock) pour la notation.
///
/// Découplage avec Flutter/Riverpod : le jeu n'appelle aucun provider. Il
/// expose [canValidate] (pour activer le bouton) et [buildMetrics] (lu par
/// l'écran au clic sur « Valider »).
class PlanifikGame extends FlameGame {
  PlanifikGame({this.config = GridConfig.demo});

  final GridConfig config;

  /// Passe à `true` dès que le chemin tracé atteint l'arrivée.
  final ValueNotifier<bool> canValidate = ValueNotifier<bool>(false);

  final List<CellComponent> _cells = [];
  final List<int> _path = []; // indices des cases du chemin, dans l'ordre

  @override
  Color backgroundColor() => const Color(0xFFFAFAFA);

  @override
  Future<void> onLoad() async {
    for (var row = 0; row < config.rows; row++) {
      for (var col = 0; col < config.cols; col++) {
        final index = config.index(row, col);
        final cell = CellComponent(
          row: row,
          col: col,
          kind: config.kindOf(index),
          onCellTap: _handleTap,
          position: Vector2.zero(),
          size: Vector2.zero(),
        );
        _cells.add(cell);
        add(cell);
      }
    }
    _layout(size);
    _resetPath();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_cells.isNotEmpty) _layout(size);
  }

  /// Calcule taille et position des cases pour occuper une grille carrée centrée.
  void _layout(Vector2 available) {
    if (available.x <= 0 || available.y <= 0) return;
    final board = math.min(available.x, available.y);
    final cellSize = board / math.max(config.cols, config.rows);
    final offsetX = (available.x - cellSize * config.cols) / 2;
    final offsetY = (available.y - cellSize * config.rows) / 2;

    for (final cell in _cells) {
      cell.size = Vector2.all(cellSize);
      cell.position = Vector2(
        offsetX + cell.col * cellSize,
        offsetY + cell.row * cellSize,
      );
    }
  }

  CellComponent _cellAt(int index) => _cells[index];

  bool _adjacent(int a, int b) {
    final ra = config.rowOf(a), ca = config.colOf(a);
    final rb = config.rowOf(b), cb = config.colOf(b);
    return (ra == rb && (ca - cb).abs() == 1) ||
        (ca == cb && (ra - rb).abs() == 1);
  }

  void _handleTap(int row, int col) {
    final index = config.index(row, col);
    if (config.kindOf(index) == CellKind.obstacle) return;

    // Premier appui : doit partir de la case départ.
    if (_path.isEmpty) {
      if (index == config.start) _addToPath(index);
      return;
    }

    final last = _path.last;

    // Retoucher la dernière case = annuler (sans jamais retirer le départ).
    if (index == last) {
      if (_path.length > 1) {
        _path.removeLast();
        _cellAt(index).inPath = false;
      }
      _refresh();
      return;
    }

    // Étendre le chemin sur une case adjacente non déjà visitée.
    if (!_path.contains(index) && _adjacent(index, last)) {
      _addToPath(index);
    }
  }

  void _addToPath(int index) {
    _path.add(index);
    _cellAt(index).inPath = true;
    _refresh();
  }

  void _refresh() {
    canValidate.value = _path.isNotEmpty && _path.last == config.end;
  }

  /// Réinitialise le tracé (garde uniquement la case départ sélectionnée).
  void resetPath() => _resetPath();

  void _resetPath() {
    for (final c in _cells) {
      c.inPath = false;
    }
    _path
      ..clear()
      ..add(config.start);
    _cellAt(config.start).inPath = true;
    _refresh();
  }

  /// Le chemin est-il complet (relie départ → arrivée) ?
  bool get isComplete => _path.isNotEmpty && _path.last == config.end;

  /// Construit les métriques objectives à partir du tracé courant.
  ///
  /// [attempts] est le nombre d'essais de validation (géré par l'écran).
  /// Retourne `null` si le chemin n'atteint pas encore l'arrivée.
  PlanifikMetrics? buildMetrics({required int attempts}) {
    if (!isComplete) return null;
    final pathLength = _path.length - 1; // nombre de déplacements
    final avoidedCostly = !_path.any(config.costlyZones.contains);
    final objectivesHit = _path.where(config.objectives.contains).length;

    return PlanifikMetrics(
      attempts: attempts,
      pathLength: pathLength,
      optimalLength: config.optimalLength,
      costlyZonesAvoided: avoidedCostly,
      secondaryObjectives: objectivesHit,
    );
  }

  @override
  void onRemove() {
    canValidate.dispose();
    super.onRemove();
  }
}
