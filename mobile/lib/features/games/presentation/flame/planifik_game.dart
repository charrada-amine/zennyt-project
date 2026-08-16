import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/entities/planifik_metrics.dart';
import 'cell_component.dart';
import 'grid_config.dart';

/// Mini-jeu Flame « Chemin Optimal » (Optimal Path).
///
/// Le joueur trace un chemin de la case départ à la case arrivée en touchant
/// des cases adjacentes, en évitant obstacles et zones coûteuses. Le jeu ne
/// calcule PAS de score : il produit des [PlanifikMetrics] objectives que la
/// couche présentation envoie au serveur (ou au mock) pour la notation.
///
/// Découplage avec Flutter/Riverpod : le jeu n'appelle aucun provider. Il
/// expose [revision] (pour rafraîchir l'UI) plus des getters live lus par
/// l'écran (compteur de pas, bonus, undo…).
///
/// Note : on n'expose PAS de drapeau « le chemin atteint l'arrivée ». Le bouton
/// Valider s'active sur [stepCount] (>= 1), volontairement, pour que valider un
/// chemin INCOMPLET compte comme un essai raté (barème « essais ». Voir
/// GAMES_MODULE.md § Décisions à valider).
class PlanifikGame extends FlameGame {
  PlanifikGame({
    this.config = GridConfig.level1,
    this.onWrongCell,
    this.onPointAdded,
  });

  final GridConfig config;

  /// Notifié quand le joueur touche une case interdite (rouge) adjacente au
  /// tracé : la présentation déclenche le retour haptique et la pénalité de
  /// score. Le jeu, lui, dessine puis efface le « faux » segment (flash rouge).
  final void Function()? onWrongCell;

  /// Notifié à chaque point ajouté au tracé. `isGoal` vaut `true` quand le point
  /// posé est la case d'arrivée (son « goal-point »), sinon c'est un point
  /// courant (départ ou intermédiaire → son « start-point »).
  final void Function(bool isGoal)? onPointAdded;

  // Flash d'erreur : segment temporaire vers la case interdite touchée, qui
  // s'estompe (opacité 1 → 0) puis disparaît.
  int? _errorFlashIndex;
  double _errorFlashOpacity = 0;
  static const double _errorFadePerSec = 2; // ~500 ms d'affichage

  /// Incrémenté à chaque modification du tracé — l'écran l'écoute pour
  /// rafraîchir le HUD (pas, bonus) et l'état des boutons undo/clear.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final List<CellComponent> _cells = [];
  final List<int> _path = []; // indices des cases du chemin, dans l'ordre
  double _cellSize = 0;

  @override
  Color backgroundColor() => const Color(0x00000000); // transparent (plateau violet)

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
    add(_RouteLineComponent(this)..priority = 100);
    _layout(size);
    _resetPath();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_cells.isNotEmpty) _layout(size);
  }

  /// Calcule taille et position des cellules pour remplir la zone (grille
  /// col×row, cellules pouvant être non carrées, nœud circulaire centré).
  void _layout(Vector2 available) {
    if (available.x <= 0 || available.y <= 0) return;
    final cellW = available.x / config.cols;
    final cellH = available.y / config.rows;
    _cellSize = math.min(cellW, cellH);

    for (final cell in _cells) {
      cell.size = Vector2(cellW, cellH);
      cell.position = Vector2(cell.col * cellW, cell.row * cellH);
    }
  }

  CellComponent _cellAt(int index) => _cells[index];

  bool _adjacent(int a, int b) {
    final ra = config.rowOf(a), ca = config.colOf(a);
    final rb = config.rowOf(b), cb = config.colOf(b);
    return (ra == rb && (ca - cb).abs() == 1) ||
        (ca == cb && (ra - rb).abs() == 1);
  }

  /// Simule un appui sur la case (row, col) — seam de test (comportement
  /// identique à un appui réel via [CellComponent.onCellTap]).
  @visibleForTesting
  void tapCell(int row, int col) => _handleTap(row, col);

  void _handleTap(int row, int col) {
    final index = config.index(row, col);
    if (!config.isWalkable(index)) {
      // Case interdite (rouge) : si elle jouxte la fin du tracé, on montre un
      // faux segment qui s'efface + on notifie l'écran (vibration, −score).
      if (_path.isNotEmpty && _adjacent(index, _path.last)) {
        _flashError(index);
      }
      return; // obstacle infranchissable : jamais ajouté au chemin
    }

    // Premier appui : doit partir de la case départ.
    if (_path.isEmpty) {
      if (index == config.start) _addToPath(index);
      return;
    }

    final last = _path.last;

    // Retoucher la dernière case = annuler (sans jamais retirer le départ).
    if (index == last) {
      undo();
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
    onPointAdded?.call(index == config.end);
    _refresh();
  }

  void _flashError(int index) {
    _errorFlashIndex = index;
    _errorFlashOpacity = 1;
    onWrongCell?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_errorFlashIndex == null) return;
    _errorFlashOpacity -= _errorFadePerSec * dt;
    if (_errorFlashOpacity <= 0) {
      _errorFlashOpacity = 0;
      _errorFlashIndex = null;
    }
  }

  void _refresh() {
    // `onLoad`/`_resetPath` peuvent modifier le tracé PENDANT une frame de layout
    // du GameWidget ; notifier `revision` à ce moment déclencherait un
    // markNeedsBuild pendant le build. On diffère alors à la frame suivante.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => revision.value++);
    } else {
      revision.value++;
    }
  }

  /// Annule le dernier pas (garde toujours la case départ).
  void undo() {
    if (_path.length > 1) {
      final removed = _path.removeLast();
      _cellAt(removed).inPath = false;
      _refresh();
    }
  }

  /// Efface tout le tracé (revient au seul point de départ).
  void clear() => _resetPath();

  /// Alias historique conservé pour compatibilité.
  void resetPath() => _resetPath();

  void _resetPath() {
    if (_cells.isEmpty) return; // pas encore chargé
    for (final c in _cells) {
      c.inPath = false;
    }
    _path
      ..clear()
      ..add(config.start);
    _cellAt(config.start).inPath = true;
    _refresh();
  }

  // ───────────── Getters live (lus par l'écran) ─────────────

  /// Le chemin est-il complet (relie départ → arrivée) ?
  bool get isComplete => _path.isNotEmpty && _path.last == config.end;

  /// Nombre de déplacements du tracé courant.
  int get stepCount => math.max(0, _path.length - 1);

  /// Objectifs secondaires touchés par le tracé.
  int get bonusCount => _path.where(config.objectives.contains).length;

  /// Le tracé passe-t-il par une zone coûteuse ?
  bool get crossesCostly => _path.any(config.costlyZones.contains);

  /// Peut-on annuler (au moins un pas après le départ) ?
  bool get canUndo => _path.length > 1;

  int get optimalLength => config.optimalLength;

  int get totalObjectives => config.objectives.length;

  /// Construit les métriques objectives du NIVEAU courant à partir du tracé.
  ///
  /// [levelIndex] index 0-based du niveau ; [attempts] nombre d'essais de
  /// validation (géré par l'écran). Retourne `null` si le chemin n'atteint pas
  /// encore l'arrivée. Les enums suivent la fiche : le Flame ne connaît que
  /// l'évitement binaire (→ TOTAL/NONE) mais distingue l'atteinte partielle des
  /// objectifs secondaires (YES/PARTIAL/NO).
  PlanifikLevelMetrics? buildLevelMetrics({
    required int levelIndex,
    required int attempts,
  }) {
    if (!isComplete) return null;
    final secondary = totalObjectives == 0 || bonusCount == 0
        ? SecondaryObjectivesReached.no
        : bonusCount >= totalObjectives
        ? SecondaryObjectivesReached.yes
        : SecondaryObjectivesReached.partial;
    return PlanifikLevelMetrics(
      levelIndex: levelIndex,
      attempts: attempts,
      pathLength: stepCount,
      optimalLength: config.optimalLength,
      costlyZonesAvoided: crossesCostly
          ? CostlyZonesAvoided.none
          : CostlyZonesAvoided.total,
      secondaryObjectivesReached: secondary,
    );
  }

  /// Métriques d'un niveau ÉCHOUÉ (3 validations ratées, sortie jamais atteinte).
  ///
  /// Reste fidèle au barème sans mettre 0 brutalement :
  /// chemin optimal 0/4 (jamais atteint → `pathLength = 0`, écart 100 %),
  /// essais 1/3 (`attempts` ≥ 3 → `attemptScore = 1`), zones 0/2 (`NONE`),
  /// objectif 0/1 (`NO`) → **1/10**. Scoré à l'identique par le mock et le backend.
  PlanifikLevelMetrics buildFailedLevelMetrics({
    required int levelIndex,
    required int attempts,
  }) {
    return PlanifikLevelMetrics(
      levelIndex: levelIndex,
      attempts: attempts, // >= 3 → 1 pt sur « essais »
      pathLength: 0, // chemin jamais atteint → écart 100 % → 0 pt sur « chemin optimal »
      optimalLength: config.optimalLength,
      costlyZonesAvoided: CostlyZonesAvoided.none,
      secondaryObjectivesReached: SecondaryObjectivesReached.no,
    );
  }

  @override
  void onRemove() {
    revision.dispose();
    super.onRemove();
  }
}

/// Trace la « planned route line » (magenta) reliant le centre des cases du
/// chemin — composant partagé de la charte Optimal Path.
class _RouteLineComponent extends PositionComponent {
  _RouteLineComponent(this._game);

  final PlanifikGame _game;

  @override
  void render(Canvas canvas) {
    final path = _game._path;
    final width = math.max(3.0, _game._cellSize * 0.14);

    if (path.length >= 2) {
      final line = Path();
      for (var i = 0; i < path.length; i++) {
        final cell = _game._cellAt(path[i]);
        final center = cell.position + cell.size / 2;
        if (i == 0) {
          line.moveTo(center.x, center.y);
        } else {
          line.lineTo(center.x, center.y);
        }
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = BoardPalette.route
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Faux segment (rouge) vers la case interdite touchée, en train de s'effacer.
    final errIndex = _game._errorFlashIndex;
    if (errIndex != null && path.isNotEmpty && _game._errorFlashOpacity > 0) {
      final from = _game._cellAt(path.last);
      final to = _game._cellAt(errIndex);
      final a = from.position + from.size / 2;
      final b = to.position + to.size / 2;
      canvas.drawLine(
        Offset(a.x, a.y),
        Offset(b.x, b.y),
        Paint()
          ..color = BoardPalette.blockIcon.withValues(
            alpha: _game._errorFlashOpacity.clamp(0, 1),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
