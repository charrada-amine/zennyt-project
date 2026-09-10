import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
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
class PlanifikGame extends FlameGame with DragCallbacks {
  PlanifikGame({
    this.config = GridConfig.level1,
    this.onWrongCell,
    this.onBlockedTap,
    this.onPointAdded,
  });

  final GridConfig config;

  /// Notifié quand le joueur touche une case interdite (rouge) **adjacente au
  /// tracé** : c'est une erreur de planification, la présentation applique la
  /// pénalité de score. Le jeu, lui, dessine puis efface le « faux » segment.
  final void Function()? onWrongCell;

  /// Notifié à **chaque** appui sur une case interdite, adjacente ou non : la
  /// présentation joue le retour d'erreur (son + vibration).
  ///
  /// Distinct de [onWrongCell], et c'est le fond du correctif : le retour
  /// d'erreur était porté par le seul cas adjacent, si bien qu'appuyer sur une
  /// case rouge ailleurs sur la grille ne produisait **rien** — ni son, ni
  /// vibration, ni flash. Le client ne sentait donc aucune vibration, sans que
  /// le câblage haptique soit en cause.
  ///
  /// La pénalité, elle, reste sur le cas adjacent : sanctionner une case rouge
  /// touchée à l'autre bout de la grille punirait l'exploration, pas une faute.
  final void Function()? onBlockedTap;

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

  // ── Tracé au glissement ────────────────────────────────────────────────────
  //
  // Retour client : « dans le trajet je peux avoir un glissement — tracer le
  // trajet par glissement (swipe) le long du parcours ». Poser le doigt sur la
  // tête du tracé et le faire glisser de station en station étend la route ;
  // rebrousser chemin l'efface. L'appui station par station reste possible : les
  // deux gestes passent par les mêmes règles (adjacence, obstacles, pas de
  // boucle) et produisent exactement le même tracé.

  /// Un glissement traçant est en cours (le doigt a bien été posé sur la tête).
  bool _dragging = false;

  /// Dernière case passée sous le doigt, déjà traitée. Évite qu'un doigt
  /// immobile sur une case interdite ne rejoue le retour d'erreur à chaque frame.
  int? _lastDragCell;

  /// Position du doigt à l'événement précédent, dans le repère du plateau.
  ///
  /// On la suit nous-mêmes, en cumulant les deltas, plutôt que de lire le couple
  /// début/fin de l'événement : Flame le construit à partir de
  /// `DragUpdateDetails.globalPosition`, or Flutter n'y met pas la même chose
  /// selon l'événement — la position d'AVANT le mouvement pour le premier
  /// (synthétisé par `MultiDragPointerState._startDrag`), celle d'APRÈS pour les
  /// suivants. Le couple est donc décalé d'un mouvement une fois sur deux.
  /// `canvasDelta`, lui, est toujours le déplacement réel de l'événement.
  Vector2? _dragFrom;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final at = event.canvasPosition;
    final index = _indexAt(at);
    // Le glissement ne peut saisir que la TÊTE du tracé — la seule prise qui ne
    // détruise rien. Posé ailleurs, le doigt ne trace pas : on ne veut pas
    // qu'un geste de travers réécrive une route déjà posée.
    if (index == null || _path.isEmpty || index != _path.last) return;
    _dragging = true;
    _lastDragCell = index;
    _dragFrom = at.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final from = _dragFrom;
    if (!_dragging || from == null) return;
    final to = from + event.canvasDelta;
    _dragFrom = to;
    _walkSegment(from, to);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragging = false;
    _lastDragCell = null;
    _dragFrom = null;
  }

  /// Parcourt les cases traversées par le segment [from] → [to], dans l'ordre.
  ///
  /// On échantillonne le segment au lieu de ne regarder que son extrémité : un
  /// swipe rapide franchit plusieurs cases entre deux frames, et sauter les
  /// intermédiaires couperait la route — elles ne seraient plus adjacentes.
  void _walkSegment(Vector2 from, Vector2 to) {
    final step = math.max(1.0, _cellSize / 3);
    final samples = math.max(1, (from.distanceTo(to) / step).ceil());
    for (var i = 1; i <= samples; i++) {
      final at = from + (to - from) * (i / samples);
      final index = _indexAt(at);
      if (index == null || index == _lastDragCell) continue;
      _lastDragCell = index;
      _extendByDrag(index);
    }
  }

  /// Case sous un point exprimé dans le repère du plateau, ou `null` hors grille.
  int? _indexAt(Vector2 point) {
    if (size.x <= 0 || size.y <= 0) return null;
    final col = (point.x / (size.x / config.cols)).floor();
    final row = (point.y / (size.y / config.rows)).floor();
    if (row < 0 || row >= config.rows || col < 0 || col >= config.cols) {
      return null;
    }
    return config.index(row, col);
  }

  void _extendByDrag(int index) {
    final last = _path.last;
    if (index == last) return;

    // Rebrousser chemin sur l'avant-dernière case efface le dernier pas : c'est
    // la correction naturelle du glissement, sans lever le doigt.
    if (_path.length >= 2 && index == _path[_path.length - 2]) {
      undo();
      return;
    }

    // Le doigt s'est éloigné du tracé (diagonale, sortie de route) : on ne
    // raccroche pas, on attend qu'il revienne sur une case adjacente.
    if (!_adjacent(index, last)) return;

    if (!config.isWalkable(index)) {
      // Même sanction qu'à l'appui : traverser un obstacle EST une erreur de
      // planification. Le filtre d'adjacence suffit à ne pas punir un doigt qui
      // balaie le plateau à distance du tracé.
      onBlockedTap?.call();
      _flashError(index);
      return;
    }

    if (_path.contains(index)) return; // pas de boucle
    _cellAt(index).pulse();
    _addToPath(index);
  }

  /// Simule un glissement passant par le centre de chaque case de [cells] —
  /// seam de test. Emprunte le même chemin de code qu'un vrai swipe : mêmes
  /// règles de saisie, même échantillonnage du segment.
  @visibleForTesting
  void dragThrough(List<(int row, int col)> cells) {
    if (cells.isEmpty) return;
    Vector2 centerOf((int, int) c) => Vector2(
      (c.$2 + 0.5) * size.x / config.cols,
      (c.$1 + 0.5) * size.y / config.rows,
    );
    var at = centerOf(cells.first);
    final start = _indexAt(at);
    if (start == null || _path.isEmpty || start != _path.last) return;
    _dragging = true;
    _lastDragCell = start;
    for (var i = 1; i < cells.length; i++) {
      final next = centerOf(cells[i]);
      _walkSegment(at, next);
      at = next;
    }
    _dragging = false;
    _lastDragCell = null;
    _dragFrom = null;
  }

  void _handleTap(int row, int col) {
    final index = config.index(row, col);
    if (!config.isWalkable(index)) {
      // Toute tentative sur une case interdite est une erreur du point de vue du
      // joueur : elle doit s'entendre et se sentir, où qu'elle se produise.
      onBlockedTap?.call();
      // Si en plus elle jouxte la fin du tracé, c'est une erreur de
      // planification : faux segment qui s'efface + pénalité de score.
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
