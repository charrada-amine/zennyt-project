import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../data/day_stack_bank_loader.dart';
import '../../domain/entities/day_stack_bank.dart';
import '../../domain/entities/task_scheduling_metrics.dart';
import '../../domain/service/day_stack_schedule.dart';
import '../games_providers.dart';
import '../widgets/day_stack_badges.dart';
import '../widgets/game_system_components.dart';

/// Planifik #2 — « Planning journalier » (Day Stack).
///
/// Une partie enchaîne [kDayStackLevels] manches, chacune sur un univers
/// différent de la banque client. Le joueur y ordonne 11 ou 12 tâches en
/// respectant leurs DÉPENDANCES et leurs CONTRAINTES HORAIRES ; le moteur pose
/// l'ordre sur une vraie horloge et en déduit temps morts et collisions.
///
/// L'écran MESURE et **n'attribue aucun score** : le barème /10 est calculé
/// côté serveur (ou par le mock hors ligne), à partir des mesures CUMULÉES sur
/// les trois manches.
class TaskSchedulingScreen extends ConsumerStatefulWidget {
  const TaskSchedulingScreen({
    super.key,
    this.universeIndex,
    this.variantSeed,
    this.levelCount,
  });

  /// Force l'univers joué, au lieu de le tirer au sort.
  ///
  /// Réservé aux tests : les sept univers comptent 11 ou 12 tâches et n'ont ni
  /// les mêmes horaires ni les mêmes dépendances — un tirage aléatoire rendrait
  /// non déterministe tout test qui remplit le planning.
  @visibleForTesting
  final int? universeIndex;

  /// Force la variante de libellé. Réservé aux tests.
  @visibleForTesting
  final int? variantSeed;

  /// Force le nombre de manches. Réservé aux tests : jouer trois plannings de
  /// douze tâches par test les rendrait interminables.
  @visibleForTesting
  final int? levelCount;

  @override
  ConsumerState<TaskSchedulingScreen> createState() =>
      _TaskSchedulingScreenState();
}

enum _Stage { loading, intro, howToPlay, gameplay, levelComplete, score }

/// Nombre de plannings d'une partie.
///
/// Un seul planning ne mesurait qu'un univers : le joueur pouvait tomber sur
/// celui qui lui parle et n'être jamais confronté aux autres. Trois manches, un
/// univers différent à chaque fois, rendent le score moins dépendant du tirage
/// — et donnent une durée conforme aux « 10-13 min » annoncés au catalogue.
const int kDayStackLevels = 3;

class _TaskSchedulingScreenState extends ConsumerState<TaskSchedulingScreen> {
  _Stage _stage = _Stage.loading;

  /// Banque des sept univers, chargée une fois depuis les assets.
  DayStackBank? _bank;
  String? _loadError;

  /// Univers du niveau en cours.
  late DayStackUniverse _universe;

  /// Niveau courant, à partir de 1.
  int _level = 1;

  /// Univers déjà joués, pour ne pas retomber deux fois sur le même.
  final List<DayStackUniverse> _played = [];

  /// Cumuls des niveaux TERMINÉS. Le niveau en cours n'y entre qu'à sa
  /// validation — sinon un abandon en pleine manche fausserait le total.
  int _totalEdges = 0;
  int _totalEdgesOk = 0;
  int _totalDirectViolations = 0;
  int _totalTimingCount = 0;
  int _totalTimingOk = 0;
  bool _allCollisionFree = true;
  int _totalDeadMin = 0;
  int _totalSpanMin = 0;

  /// Graine du tirage de libellé.
  ///
  /// Le tirage porte sur le LIBELLÉ seul : durées, dépendances et contraintes
  /// ne bougent jamais. C'est la règle de conception du référentiel — sans
  /// elle, deux sessions du même univers ne seraient plus comparables.
  int _variantSeed = 0;

  // Toutes les tâches sont présentes dès le départ, dans un ordre mélangé.
  late List<int> _slots;
  DayStackSchedule? _validatedSchedule;
  int _moveCount = 0;

  bool _busy = false;
  bool _reviewingRules = false;

  /// Échec de la remontée du résultat.
  ///
  /// Le score vient du serveur. Quand la remontée échoue, l'écran de résultats
  /// affichait un tiret — un résultat vide, impossible à distinguer d'une
  /// partie sans points. On dit ce qui s'est passé, et on propose de réessayer
  /// plutôt que de perdre la partie.
  String? _submitError;

  Future<GameSession>? _sessionStart;
  GameSession? _serverSession;

  /// Corrections au sens du référentiel : les RETOURS EN ARRIÈRE.
  ///
  /// Compter tous les déplacements serait faux. Trier douze cartes mélangées en
  /// demande sept au minimum, même en jouant parfaitement — vingt et un sur une
  /// partie de trois manches — alors que le barème du client donne 0 point
  /// au-delà de neuf. Chacun tomberait à 0/2, le symétrique du défaut qu'on
  /// corrige. Dans ce plateau, glisser une carte n'est pas une correction :
  /// c'est la façon de jouer.
  ///
  /// Revenir sur une carte DÉJÀ déplacée, en revanche, est bien une correction :
  /// le joueur défait un ordre qu'il avait lui-même posé. C'est cela que le
  /// référentiel veut voir — « monitoring et flexibilité cognitive »
  /// (Miyake et al., 2000), cité par le document du client.
  int _proactiveAdjustments = 0;

  /// Corrections déclenchées par un signal d'erreur du système.
  ///
  /// Nécessairement nulles ici : le plateau n'affiche AUCUNE violation pendant
  /// la manche — elles n'apparaissent qu'au débrief. Sans signal en cours de
  /// jeu, une correction réactive au sens du client ne peut pas exister. Le
  /// jour où le plateau signalerait les erreurs en direct, c'est ce compteur-là
  /// qui s'alimenterait.
  final int _reactiveAdjustments = 0;

  /// Cartes déjà déplacées dans la manche en cours.
  ///
  /// Remis à zéro à chaque manche — l'univers change, les cartes aussi. Les
  /// corrections, elles, s'accumulent sur toute la partie : ce sont des mesures
  /// de PARTIE, et le serveur met ses seuils à l'échelle du nombre de manches.
  final Set<int> _movedOnce = <int>{};

  /// Instant d'ouverture du plateau, pour la latence de planification.
  DateTime? _boardShownAt;

  /// Temps de réflexion avant le tout premier placement.
  ///
  /// Métrique diagnostique du référentiel : à remonter dans le profil
  /// qualitatif, **hors du score** — elle distingue un profil impulsif d'un
  /// profil délibératif à score égal.
  int? _planningLatencyMs;

  @override
  void initState() {
    super.initState();
    _loadBank();
  }

  Future<void> _loadBank() async {
    try {
      final bank = await DayStackBankLoader.load();
      if (!mounted) return;
      setState(() {
        _bank = bank;
        _resetBoard();
        _stage = _Stage.intro;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _stage = _Stage.intro;
      });
    }
  }

  void _resetBoard() {
    final bank = _bank!;
    final random = math.Random();
    if (widget.universeIndex != null) {
      _universe = bank.universes[widget.universeIndex!];
    } else {
      // Jamais deux fois le même univers dans une partie : rejouer le même
      // planning à la manche suivante ne mesurerait plus rien.
      final restants = bank.universes
          .where((u) => !_played.any((p) => p.id == u.id))
          .toList();
      final pool = restants.isEmpty ? bank.universes : restants;
      _universe = pool[random.nextInt(pool.length)];
    }
    _variantSeed = widget.variantSeed ?? random.nextInt(1 << 20);

    _slots = List<int>.generate(_universe.tasks.length, (i) => i)..shuffle();
    _validatedSchedule = null;
    _moveCount = 0;
    _movedOnce.clear();
    _boardShownAt = null;
    // La latence initiale est conservée entre les manches de la partie.
    if (_level == 1) {
      _planningLatencyMs = null;
      _proactiveAdjustments = 0;
    }
    _serverSession = null;
    _busy = false;
  }

  /// Libellé tiré pour [task], stable sur toute la partie.
  String _labelOf(DayStackTask task) => task.variantAt(_variantSeed);

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  void _beginGame() {
    if (_bank == null) return;
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    _reviewingRules = false;
    setState(() {
      _level = 1;
      _played.clear();
      _totalEdges = 0;
      _totalEdgesOk = 0;
      _totalDirectViolations = 0;
      _totalTimingCount = 0;
      _totalTimingOk = 0;
      _allCollisionFree = true;
      _totalDeadMin = 0;
      _totalSpanMin = 0;
      _resetBoard();
      _stage = _Stage.gameplay;
      _boardShownAt = DateTime.now();
    });
    _sessionStart = ref
        .read(gamesRepositoryProvider)
        .startSession(GameType.planifik);
  }

  /// Réordonne sans pénalité ni évaluation avant « Valider ».
  void _moveSlot(int from, int to) {
    if (_stage != _Stage.gameplay || from == to) return;
    setState(() {
      _recordPlanningLatency();
      final task = _slots.removeAt(from);
      _slots.insert(to, task);
      _moveCount++;
      // Premier geste sur cette carte : c'est du rangement. Y revenir : c'est
      // se corriger.
      if (!_movedOnce.add(task)) _proactiveAdjustments++;
    });
  }

  void _recordPlanningLatency() {
    final shown = _boardShownAt;
    if (_planningLatencyMs == null && shown != null) {
      _planningLatencyMs = DateTime.now().difference(shown).inMilliseconds;
    }
  }

  @visibleForTesting
  List<int> get slotsForTest => List<int>.unmodifiable(_slots);

  @visibleForTesting
  void moveSlotForTest(int from, int to) => _moveSlot(from, to);

  /// Corrections comptées jusqu'ici, pour les tests.
  @visibleForTesting
  int get proactiveAdjustmentsForTest => _proactiveAdjustments;

  /// Part de temps mort sur l'ensemble de la partie.
  ///
  /// Rapportée aux amplitudes CUMULÉES, pas à la moyenne des ratios : une
  /// manche courte et une longue ne pèsent pas pareil dans une journée.
  double get _aggregateDeadTimeRatio =>
      _totalSpanMin <= 0 ? 0 : _totalDeadMin / _totalSpanMin;

  TaskSchedulingMetrics _buildMetrics() {
    return TaskSchedulingMetrics(
      // Les univers de la partie, dans l'ordre joué. Le contrat porte un champ
      // unique ; on y met la liste plutôt que d'en perdre deux sur trois.
      universeId: _played.map((u) => u.id).join(','),
      // Les seuils d'autorégulation du référentiel (1 et 3 corrections) ont été
      // calibrés sur UN planning. Une partie en compte trois : sans ce nombre,
      // le serveur appliquerait un barème de manche à un total de partie.
      levelsPlayed: _played.length,
      dependencyEdgeCount: _totalEdges,
      dependencyEdgesRespected: _totalEdgesOk,
      directDependencyViolations: _totalDirectViolations,
      timingConstraintCount: _totalTimingCount,
      timingConstraintsRespected: _totalTimingOk,
      collisionFree: _allCollisionFree,
      // Borné : le contrat serveur refuse un ratio hors [0,1], et une partie
      // dégénérée ne doit pas faire échouer la soumission.
      deadTimeRatio: _aggregateDeadTimeRatio.clamp(0.0, 1.0),
      proactiveAdjustments: _proactiveAdjustments,
      reactiveAdjustments: _reactiveAdjustments,
      // Le référentiel parle du temps de réflexion avant le PREMIER placement :
      // c'est celui de la première manche, pas une moyenne.
      planningLatencyMs: _planningLatencyMs,
    );
  }

  /// Nombre de niveaux de la partie — surchargeable par les tests.
  int get _levelCount => widget.levelCount ?? kDayStackLevels;

  bool get _isLastLevel => _level >= _levelCount;

  /// Clôt le niveau courant : ses mesures rejoignent les cumuls.
  ///
  /// Le cumul se fait ICI, à la validation, et pas au fil des placements : un
  /// joueur qui quitte en pleine manche ne doit pas voir ce demi-planning
  /// compter dans son score.
  void _closeLevel() {
    final s = buildDayStackSchedule(
      universe: _universe,
      order: [for (final slot in _slots) _universe.tasks[slot].id],
    );
    _validatedSchedule = s;
    _totalEdges += s.dependencyEdgeCount;
    _totalEdgesOk += s.dependencyEdgesRespected;
    _totalDirectViolations += s.violations
        .where((v) => v.kind == DayStackViolationKind.dependency)
        .length;
    _totalTimingCount += s.timingConstraintCount;
    _totalTimingOk += s.timingConstraintsRespected;
    if (s.hasCollision) _allCollisionFree = false;
    _totalDeadMin += s.deadTimeMin;
    _totalSpanMin += s.endMin - s.dayStartMin;
    _played.add(_universe);
  }

  /// Valide la manche : on enchaîne, ou on remonte le résultat si c'est la
  /// dernière.
  void _validateLevel() {
    if (_busy || _stage != _Stage.gameplay) return;
    _recordPlanningLatency();
    _closeLevel();
    // TOUTES les manches passent par leur débrief, la dernière comprise : c'est
    // là que le joueur voit ce qui n'a pas tenu. L'écran final, lui, ne montre
    // que les cumuls — sauter le débrief priverait le joueur du détail au
    // moment précis où il lui sert.
    setState(() => _stage = _Stage.levelComplete);
    if (_isLastLevel) unawaited(_submit(showScore: false));
  }

  /// Passe à la manche suivante : nouvel univers, plateau neuf.
  void _nextLevel() {
    if (_isLastLevel) {
      setState(() => _stage = _Stage.score);
      return;
    }
    setState(() {
      _level++;
      _resetBoard();
      _stage = _Stage.gameplay;
      _boardShownAt = DateTime.now();
    });
  }

  Future<void> _submit({bool showScore = true}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _submitError = null;
      if (showScore) _stage = _Stage.score;
    });
    try {
      final session = await (_sessionStart ??= ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.planifik));
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.taskScheduling,
            metrics: _buildMetrics(),
          );
      if (!mounted) return;
      setState(() => _serverSession = updated);
    } catch (error) {
      if (mounted) setState(() => _submitError = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _stage == _Stage.gameplay;
    return PopScope(
      canPop: _stage == _Stage.intro || _stage == _Stage.score,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage != _Stage.intro) {
          setState(() => _stage = _Stage.intro);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? ZennytGamePalette.gameBlue : Colors.white,
        body: SafeArea(
          child: GameContentFrame(maxWidth: 980, child: _buildStage()),
        ),
      ),
    );
  }

  /// Bouton unique du bandeau : menu de pause tant que la fenêtre est ouverte,
  /// confirmation de sortie ensuite. Voir [GameMenuAffordance].
  Future<void> _openMenu() async {
    if (_stage != _Stage.gameplay) return;
    if (_pauseAllowance.canOpen) return _openPause();
    if (await GameExitConfirmDialog.show(context)) {
      if (mounted) context.go(AppRoutes.games);
    }
  }

  /// Menu pause — même `GamePauseScaffold` que tous les autres jeux : reprise,
  /// réglages son/musique/vibration, règles, sortie.
  Future<void> _openPause() async {
    if (_stage != _Stage.gameplay) return;
    // Une seule fenêtre de pause par partie (CdC pause §2-3).
    if (!_pauseAllowance.canOpen) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    _pauseAllowance.open();
    final action = await showDialog<GamePauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseScaffold(
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(context).pop(GamePauseAction.resume),
        description:
            'Le plateau est figé. Les tâches déjà posées sont conservées.',
        buttons: [
          GamePrimaryButton(
            label: 'Resume',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.resume),
          ),
          GameOutlineButton(
            label: 'View rules',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.help),
          ),
          GamePauseExitButton(
            label: 'Exit mission',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.exit),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case GamePauseAction.help:
        // Relire les règles conserve le plateau et la session courante.
        setState(() {
          _reviewingRules = true;
          _stage = _Stage.howToPlay;
        });
        return;
      case GamePauseAction.exit:
        // Quitter annule la tentative : confirmation explicite d'abord.
        if (await GameExitConfirmDialog.show(context)) {
          if (mounted) context.go(AppRoutes.games);
          return;
        }
      case GamePauseAction.resume:
      case GamePauseAction.restart:
      case null:
        break;
    }
    // La partie repart : le temps passé en pause rejoint le budget consommé, et
    // le bandeau se redessine — le bouton reste « Pause » tant qu'il reste du
    // budget, et bascule sur « Exit mission » une fois les 30 s épuisées.
    _pauseAllowance.close();
    if (mounted) setState(() {});
  }

  void _resumeFromRules() {
    _pauseAllowance.close();
    setState(() {
      _reviewingRules = false;
      _stage = _Stage.gameplay;
    });
  }

  Widget _buildStage() {
    return switch (_stage) {
      // La banque vit dans un asset : l'écran attend sa lecture plutôt que de
      // dessiner un plateau vide.
      _Stage.loading => const _LoadingView(),
      // Banque illisible : on le dit, plutôt que d'ouvrir un jeu sans tâches.
      _Stage.intro when _loadError != null => _BankErrorView(
        message: _loadError!,
        onRetry: () {
          setState(() {
            _loadError = null;
            _stage = _Stage.loading;
          });
          _loadBank();
        },
        onBack: () => context.go(AppRoutes.games),
      ),
      _Stage.intro => _IntroView(
        onStart: () => setState(() => _stage = _Stage.howToPlay),
        onBack: () => context.go(AppRoutes.games),
      ),
      _Stage.howToPlay => _HowToPlayView(
        onStart: _reviewingRules ? _resumeFromRules : _beginGame,
        onBack: _reviewingRules
            ? _resumeFromRules
            : () => setState(() => _stage = _Stage.intro),
        reviewing: _reviewingRules,
      ),
      _Stage.levelComplete => _LevelCompleteView(
        level: _level,
        levelCount: _levelCount,
        universe: _universe,
        schedule: _validatedSchedule!,
        labelOf: _labelOf,
        onNext: _nextLevel,
      ),
      _Stage.gameplay => GameplayMusic(
        child: _GameplayView(
          level: _level,
          levelCount: _levelCount,
          universeName: _universe.name,
          tasks: _universe.tasks,
          labelOf: _labelOf,
          slots: _slots,
          moveCount: _moveCount,
          dayStartMin: dayStackStartOf(_universe),
          onMove: _moveSlot,
          onValidate: _validateLevel,
          onPause: _openMenu,
          affordance: _pauseAllowance.affordance,
        ),
      ),
      _Stage.score => _ScoreView(
        rawScore: _serverSession?.lastAttempt?.score.rawPoints,
        level: _serverSession?.lastAttempt?.score.level,
        levelsPlayed: _played.length,
        universeNames: _played.map((u) => u.name).toList(),
        edges: _totalEdges,
        edgesOk: _totalEdgesOk,
        timingCount: _totalTimingCount,
        timingOk: _totalTimingOk,
        collisionFree: _allCollisionFree,
        deadTimeRatio: _aggregateDeadTimeRatio,
        proactive: _proactiveAdjustments,
        reactive: _reactiveAdjustments,
        latencyMs: _planningLatencyMs,
        busy: _busy,
        error: _submitError,
        // Réessayer remonte le MÊME planning : le joueur ne rejoue pas parce
        // que le réseau a flanché.
        onRetrySubmit: _submit,
        onReplay: _beginGame,
        onBack: () => context.go(AppRoutes.games),
      ),
    };
  }
}

// ── Gameplay ─────────────────────────────────────────────────────────────────

class _GameplayView extends StatefulWidget {
  const _GameplayView({
    required this.level,
    required this.levelCount,
    required this.universeName,
    required this.tasks,
    required this.labelOf,
    required this.slots,
    required this.moveCount,
    required this.dayStartMin,
    required this.onMove,
    required this.onValidate,
    required this.onPause,
    required this.affordance,
  });

  final List<int> slots;
  final List<DayStackTask> tasks;
  final String Function(DayStackTask) labelOf;
  final int level;
  final int levelCount;
  final String universeName;
  final int moveCount;
  final int dayStartMin;
  final void Function(int from, int to) onMove;
  final VoidCallback onValidate;
  final VoidCallback onPause;
  final GameMenuAffordance affordance;

  @override
  State<_GameplayView> createState() => _GameplayViewState();
}

class _GameplayViewState extends State<_GameplayView> {
  final _scrollController = ScrollController();
  bool _dragging = false;
  int? _dragStartIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manche ${widget.level} / ${widget.levelCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: widget.affordance.tooltip,
                onPressed: _dragging ? null : widget.onPause,
                style: IconButton.styleFrom(
                  backgroundColor: ZennytGamePalette.gamePanel,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: Icon(widget.affordance.icon),
              ),
            ],
          ),
          Text(
            '${widget.universeName} · ${widget.slots.length} tâches · '
            'Début ${_clock(widget.dayStartMin)}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fais défiler normalement. Maintiens une carte puis glisse-la '
            'pour changer sa position.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Listener(
              onPointerCancel: (_) => setState(() => _dragging = false),
              child: Scrollbar(
                controller: _scrollController,
                child: ReorderableListView.builder(
                  key: const ValueKey('day-stack-schedule'),
                  scrollController: _scrollController,
                  padding: const EdgeInsets.only(bottom: 12),
                  buildDefaultDragHandles: false,
                  // Le décorateur Flutter par défaut ajoute un Material
                  // rectangulaire derrière l'élément soulevé. Un matériau
                  // transparent garde la silhouette arrondie de GamePanel
                  // pendant tout le déplacement.
                  proxyDecorator: (child, index, animation) => Material(
                    key: const ValueKey('day-stack-drag-proxy'),
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                  // Auto-scroll natif aux bords. Un glissement court fait
                  // défiler ; l'appui maintenu transforme la carte en drag.
                  onReorderStart: (index) => setState(() {
                    _dragging = true;
                    _dragStartIndex = index;
                  }),
                  onReorderEnd: (index) {
                    // Le callback de réordre est absent pour un dépôt au même rang.
                    if (index == _dragStartIndex ||
                        index == _dragStartIndex! + 1) {
                      setState(() => _dragging = false);
                    }
                  },
                  onReorderItem: (from, to) {
                    widget.onMove(from, to);
                    // Attendre l'application de l'ordre après l'animation de dépôt.
                    setState(() => _dragging = false);
                  },
                  itemCount: widget.slots.length,
                  itemBuilder: (context, position) {
                    final index = widget.slots[position];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('day-stack-task-$index'),
                      index: position,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GamePanel(
                          padding: const EdgeInsets.all(12),
                          borderColor: Colors.transparent,
                          child: _TaskInfo(
                            tasks: widget.tasks,
                            labelOf: widget.labelOf,
                            task: widget.tasks[index],
                            position: position + 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // Plus de « sans pénalité » : revenir sur une carte compte
            // désormais dans l'autorégulation, et l'affirmer serait faux. On
            // n'annonce pas non plus la règle exacte — le référentiel observe
            // une conduite spontanée, la dire inviterait à la simuler.
            '${widget.moveCount} déplacement(s)',
            key: const ValueKey('day-stack-progress'),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          GamePrimaryButton(
            label: 'Valider',
            onPressed: _dragging ? null : widget.onValidate,
          ),
        ],
      ),
    );
  }
}

/// Heure lisible : 480 -> « 08h00 ».
String _clock(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '${h}h$m';
}

/// Contrainte horaire en une ligne, pour le joueur.
///
/// On n'affiche PAS le texte brut de la banque : il mêle le métier et la règle
/// (« Repos mini. 1h avant cuisson · Repos : 60 min »). Le joueur a besoin de
/// la règle, pas de sa rédaction.
String? _constraintLabel(DayStackTask task) {
  final c = task.constraint;
  return switch (c.kind) {
    DayStackConstraintKind.window =>
      '${_clock(c.startMin!)}–${_clock(c.endMin!)}',
    DayStackConstraintKind.deadline => 'avant ${_clock(c.beforeMin!)}',
    DayStackConstraintKind.anchor =>
      '${_clock(c.startMin!)} pile (±${c.toleranceMin} min)',
    DayStackConstraintKind.relative => 'avant une autre tâche',
    DayStackConstraintKind.minDelay => '${c.minDelayMin} min avant la suite',
    // Le bloc fixe sans heure de la banque : rien à annoncer tant que la
    // donnée manque, plutôt qu'une règle inventée.
    DayStackConstraintKind.unspecified || DayStackConstraintKind.none => null,
  };
}

/// Libellé d'une tâche, sa durée, ses prérequis et sa contrainte.
class _TaskInfo extends StatelessWidget {
  const _TaskInfo({
    required this.tasks,
    required this.labelOf,
    required this.task,
    required this.position,
  });

  final List<DayStackTask> tasks;
  final String Function(DayStackTask) labelOf;
  final DayStackTask task;
  final int position;

  @override
  Widget build(BuildContext context) {
    // Les prérequis sont référencés par IDENTIFIANT, mais montrés au joueur
    // avec le libellé effectivement tiré : lui afficher une autre variante que
    // celle qu'il voit dans la liste l'empêcherait de faire le lien.
    final deps = task.deps
        .map((id) => labelOf(tasks.firstWhere((t) => t.id == id)))
        .join(', ');
    final constraint = _constraintLabel(task);
    final rest = task.restMin > 0 ? ' + ${task.restMin} min repos' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$position',
              style: const TextStyle(
                color: ZennytGamePalette.blue,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 10),
            DayStackTaskBadge(
              category: task.category,
              icon: task.icon,
              compact: true,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                labelOf(task),
                style: const TextStyle(
                  color: ZennytGamePalette.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${task.durationMin} min$rest${constraint == null ? '' : ' · $constraint'}',
          style: const TextStyle(
            color: ZennytGamePalette.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (deps.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Après : $deps',
            style: const TextStyle(
              color: ZennytGamePalette.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

/// Banque illisible — asset absent ou JSON invalide.
class _BankErrorView extends StatelessWidget {
  const _BankErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Les tâches n\'ont pas pu être chargées.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          GamePrimaryButton(label: 'Réessayer', onPressed: onRetry),
          const SizedBox(height: 10),
          GameOutlineButton(label: 'Back to games', onPressed: onBack),
        ],
      ),
    ),
  );
}

/// Fin d'une manche : ce qu'elle a donné, avant d'enchaîner sur la suivante.
///
/// Sans cet écran, le joueur passait d'un planning à l'autre sans jamais
/// apprendre ce qu'il avait manqué — et une partie de trois manches n'aurait
/// été qu'une répétition, pas une progression.
class _LevelCompleteView extends StatelessWidget {
  const _LevelCompleteView({
    required this.level,
    required this.levelCount,
    required this.universe,
    required this.schedule,
    required this.labelOf,
    required this.onNext,
  });

  final int level;
  final int levelCount;
  final DayStackUniverse universe;
  final DayStackSchedule schedule;
  final String Function(DayStackTask) labelOf;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final parfait = schedule.violations.isEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                level >= levelCount
                    ? 'Dernière manche terminée'
                    : 'Manche $level terminée',
                style: AppTypography.headlineSmall.copyWith(
                  color: ZennytGamePalette.ink,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                parfait
                    ? 'Planning tenu de bout en bout.'
                    : 'Voici ce qui n\'a pas tenu.',
                style: AppTypography.bodyMedium.copyWith(
                  color: parfait
                      ? ZennytGamePalette.success
                      : ZennytGamePalette.muted,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DebriefCard(
                universe: universe,
                schedule: schedule,
                labelOf: labelOf,
                // Corrections et latence sont des mesures de PARTIE : les
                // afficher par manche laisserait croire qu'elles se remettent
                // à zéro.
                showSessionMeasures: false,
                proactive: 0,
                reactive: 0,
                latencyMs: null,
              ),
              const SizedBox(height: AppSpacing.xl),
              GamePrimaryButton(
                label: level >= levelCount
                    ? 'Voir mon score'
                    : 'Manche ${level + 1} / $levelCount',
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Débrief de fin de PARTIE — le cumul des manches.
class _SessionDebriefCard extends StatelessWidget {
  const _SessionDebriefCard({
    required this.levelsPlayed,
    required this.universeNames,
    required this.edges,
    required this.edgesOk,
    required this.timingCount,
    required this.timingOk,
    required this.collisionFree,
    required this.deadTimeRatio,
    required this.proactive,
    required this.reactive,
    required this.latencyMs,
  });

  final int levelsPlayed;
  final List<String> universeNames;
  final int edges;
  final int edgesOk;
  final int timingCount;
  final int timingOk;
  final bool collisionFree;
  final double deadTimeRatio;
  final int proactive;
  final int reactive;
  final int? latencyMs;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      border: Border.all(color: ZennytGamePalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$levelsPlayed manche(s) · ${universeNames.join(' · ')}',
          style: const TextStyle(
            color: ZennytGamePalette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        _DebriefRow(
          label: 'Dépendances respectées',
          value: '$edgesOk / $edges',
          good: edgesOk == edges,
        ),
        _DebriefRow(
          label: 'Contraintes horaires tenues',
          value: '$timingOk / $timingCount',
          good: timingOk == timingCount,
        ),
        _DebriefRow(
          label: 'Temps mort',
          value: '${(deadTimeRatio * 100).round()} %',
          good: deadTimeRatio < 0.10,
        ),
        _DebriefRow(
          label: 'Collisions',
          value: collisionFree ? 'aucune' : 'oui',
          good: collisionFree,
        ),
        _DebriefRow(
          label: 'Corrections',
          value: '$proactive avant alerte · $reactive après',
          good: reactive == 0,
        ),
        if (latencyMs != null)
          _DebriefRow(
            // Métrique diagnostique : montrée au joueur, mais le référentiel
            // l'exclut explicitement du barème.
            label: 'Temps de réflexion initial',
            value: '${(latencyMs! / 1000).toStringAsFixed(1)} s',
            good: true,
            neutral: true,
          ),
      ],
    ),
  );
}

/// Débrief de fin de partie.
///
/// Reprend les quatre composantes du barème et, surtout, la liste des
/// contraintes enfreintes : c'est la seule information sur laquelle le joueur
/// peut progresser. Les points ne sont pas recalculés ici — ils viennent du
/// serveur — on n'affiche que les MESURES qui les expliquent.
class _DebriefCard extends StatelessWidget {
  const _DebriefCard({
    required this.universe,
    required this.schedule,
    required this.labelOf,
    required this.proactive,
    required this.reactive,
    required this.latencyMs,
    this.showSessionMeasures = true,
  });

  /// Affiche corrections et latence — mesures de PARTIE, pas de manche.
  final bool showSessionMeasures;

  final DayStackUniverse universe;
  final DayStackSchedule schedule;
  final String Function(DayStackTask) labelOf;
  final int proactive;
  final int reactive;
  final int? latencyMs;

  String _clockOf(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '${h}h$m';
  }

  @override
  Widget build(BuildContext context) {
    final violations = schedule.violations;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: ZennytGamePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            universe.name,
            style: const TextStyle(
              color: ZennytGamePalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Text(
            '${_clockOf(schedule.dayStartMin)} → ${_clockOf(schedule.endMin)}',
            style: const TextStyle(
              color: ZennytGamePalette.muted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          _DebriefRow(
            label: 'Dépendances respectées',
            value:
                '${schedule.dependencyEdgesRespected}'
                ' / ${schedule.dependencyEdgeCount}',
            good:
                schedule.dependencyEdgesRespected ==
                schedule.dependencyEdgeCount,
          ),
          _DebriefRow(
            label: 'Contraintes horaires tenues',
            value:
                '${schedule.timingConstraintsRespected}'
                ' / ${schedule.timingConstraintCount}',
            good:
                schedule.timingConstraintsRespected ==
                schedule.timingConstraintCount,
          ),
          _DebriefRow(
            label: 'Temps mort',
            value:
                '${(schedule.deadTimeRatio * 100).round()} %'
                ' (${schedule.deadTimeMin} min)',
            good: schedule.deadTimeRatio < 0.10,
          ),
          _DebriefRow(
            label: 'Collisions',
            value: schedule.hasCollision ? 'oui' : 'aucune',
            good: !schedule.hasCollision,
          ),
          if (showSessionMeasures)
            _DebriefRow(
              label: 'Corrections',
              value: '$proactive avant alerte · $reactive après',
              good: reactive == 0,
            ),
          if (showSessionMeasures && latencyMs != null)
            _DebriefRow(
              // Métrique diagnostique : affichée pour le joueur, mais elle
              // n'entre pas dans le barème — le référentiel l'exclut.
              label: 'Temps de réflexion initial',
              value: '${(latencyMs! / 1000).toStringAsFixed(1)} s',
              good: true,
              neutral: true,
            ),
          if (violations.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Ce qui n\'a pas tenu',
              style: TextStyle(
                color: ZennytGamePalette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 6),
            for (final v in violations.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: ZennytGamePalette.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${labelOf(universe.byId(v.taskId))} — ${v.detail}',
                        style: const TextStyle(
                          color: ZennytGamePalette.muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (violations.length > 6)
              Text(
                '… et ${violations.length - 6} autre(s)',
                style: const TextStyle(
                  color: ZennytGamePalette.muted,
                  fontSize: 11.5,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DebriefRow extends StatelessWidget {
  const _DebriefRow({
    required this.label,
    required this.value,
    required this.good,
    this.neutral = false,
  });

  final String label;
  final String value;
  final bool good;
  final bool neutral;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: ZennytGamePalette.muted,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: neutral
                ? ZennytGamePalette.ink
                : good
                ? ZennytGamePalette.success
                : ZennytGamePalette.error,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ],
    ),
  );
}

/// Lecture de la banque, avant que le plateau n'existe.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      color: Colors.white,
      semanticsLabel: 'Chargement des tâches',
    ),
  );
}

// ── Intro / How to play (structure Optimal Path) ────────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart, required this.onBack});
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: AppSpacing.base),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 150,
                  child: GameRuleChip(
                    label: 'Planning',
                    color: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Image.asset(
                  'assets/games icons/Task Scheduling transparent.png',
                  height: 112,
                  semanticLabel: 'Day Stack task scheduling',
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Day Stack',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Order the tasks so every dependency and deadline is respected.',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(
                child: ResultStatTile(label: 'Goal', value: 'Planning'),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Planifik',
                  value: 'Mini-jeu 2',
                  valueColor: ZennytGamePalette.magenta,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(label: 'Format', value: '11–12 tâches'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          GamePrimaryButton(label: 'Start', onPressed: onStart),
        ],
      ),
    );
  }
}

class _HowToPlayView extends StatelessWidget {
  const _HowToPlayView({
    required this.onStart,
    required this.onBack,
    this.reviewing = false,
  });
  final bool reviewing;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GamePanel(
        backgroundColor: ZennytGamePalette.mist,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ZennytGamePalette.magenta),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: ZennytGamePalette.blue,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.bodyLarge.copyWith(
                      color: ZennytGamePalette.muted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: AppSpacing.base),
          Text(
            'How to schedule',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          step(
            Icons.touch_app_outlined,
            'Ordonne les tâches',
            'Toutes les tâches sont mélangées au départ. Fais défiler les cartes '
                'normalement. Pour changer une position, maintiens directement '
                'la carte puis déplace-la. Garde-la près du bord pour faire '
                'défiler pendant le déplacement. '
                'Réorganise autant de fois que nécessaire avant de valider.',
          ),
          step(
            Icons.link_rounded,
            'Dependencies',
            'A task must come AFTER the tasks listed in "after: …".',
          ),
          step(
            Icons.schedule_rounded,
            'Horaires',
            'Fenêtres, échéances et blocs fixes sont des HEURES. Le planning se '
                'déroule à partir de l\'ouverture de la journée : une tâche qui '
                'doit attendre son heure crée un temps mort.',
          ),
          const SizedBox(height: AppSpacing.lg),
          GamePrimaryButton(
            label: reviewing ? 'Resume schedule' : 'I am ready',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

// ── Score ───────────────────────────────────────────────────────────────────

class _ScoreView extends StatelessWidget {
  const _ScoreView({
    required this.rawScore,
    required this.level,
    required this.levelsPlayed,
    required this.universeNames,
    required this.edges,
    required this.edgesOk,
    required this.timingCount,
    required this.timingOk,
    required this.collisionFree,
    required this.deadTimeRatio,
    required this.proactive,
    required this.reactive,
    required this.latencyMs,
    required this.busy,
    required this.error,
    required this.onRetrySubmit,
    required this.onReplay,
    required this.onBack,
  });

  final int? rawScore;
  final String? level;
  final bool busy;

  /// Mesures CUMULÉES sur toutes les manches — c'est ce que le serveur a noté.
  /// Montrer la dernière manche laisserait croire que le score n'en dépend
  /// que d'elle.
  final int levelsPlayed;
  final List<String> universeNames;
  final int edges;
  final int edgesOk;
  final int timingCount;
  final int timingOk;
  final bool collisionFree;
  final double deadTimeRatio;

  final int proactive;
  final int reactive;
  final int? latencyMs;

  /// Message d'échec de la remontée, `null` si tout s'est bien passé.
  final String? error;

  final VoidCallback onRetrySubmit;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onPressed: onBack),
          ),
          Text(
            'Results',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          Text(
            busy ? 'Scoring…' : 'Day Stack · Task scheduling',
            style: AppTypography.bodyMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              children: [
                Text(
                  'Planning score',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  rawScore == null ? '—' : '$rawScore/10',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 52,
                    letterSpacing: 0,
                  ),
                ),
                if (level != null)
                  Text(
                    level!,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          // ── Débrief ─────────────────────────────────────────────────────
          //
          // Un nombre nu n'apprend rien : le joueur ne sait ni ce qu'il a
          // manqué, ni pourquoi. Le barème a quatre composantes, on montre les
          // quatre — et surtout les contraintes enfreintes, qui sont la seule
          // chose sur laquelle il peut progresser.
          if (error == null && !busy) ...[
            const SizedBox(height: AppSpacing.lg),
            _SessionDebriefCard(
              levelsPlayed: levelsPlayed,
              universeNames: universeNames,
              edges: edges,
              edgesOk: edgesOk,
              timingCount: timingCount,
              timingOk: timingOk,
              collisionFree: collisionFree,
              deadTimeRatio: deadTimeRatio,
              proactive: proactive,
              reactive: reactive,
              latencyMs: latencyMs,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            // Un tiret seul laissait croire à une partie sans points. Le score
            // est calculé SERVEUR : s'il n'est pas arrivé, on le dit et on
            // propose de renvoyer le même planning, plutôt que de faire rejouer.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3F3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: ZennytGamePalette.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score non calculé',
                    style: TextStyle(
                      color: ZennytGamePalette.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ton planning est intact. Il n\'a pas pu être envoyé.',
                    style: TextStyle(
                      color: ZennytGamePalette.ink,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: ZennytGamePalette.muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GamePrimaryButton(
              label: busy ? 'Envoi…' : 'Renvoyer le résultat',
              onPressed: busy ? null : onRetrySubmit,
            ),
            const SizedBox(height: AppSpacing.md),
            GameOutlineButton(label: 'Replay', onPressed: onReplay),
            const SizedBox(height: AppSpacing.md),
            GameOutlineButton(label: 'Back to games', onPressed: onBack),
          ] else ...[
            const SizedBox(height: AppSpacing.xxl),
            // Plus d'enchaînement vers un AUTRE jeu depuis cet écran.
            // « Continue to Hanoï » était l'action principale : après un seul
            // essai, le geste le plus naturel éjectait le joueur vers Tower of
            // Hanoi, sans qu'il l'ait demandé. Les deux suites légitimes d'une
            // partie sont la rejouer ou revenir au catalogue.
            GamePrimaryButton(
              label: 'Replay',
              onPressed: busy ? null : onReplay,
            ),
            const SizedBox(height: AppSpacing.md),
            GameOutlineButton(label: 'Back to games', onPressed: onBack),
          ],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ZennytGamePalette.mist,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(Icons.chevron_left, color: ZennytGamePalette.blue),
        ),
      ),
    );
  }
}
