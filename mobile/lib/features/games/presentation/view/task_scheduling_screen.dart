import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import '../widgets/day_stack_calendar.dart';
import '../widgets/day_stack_tutorial.dart';
import '../widgets/memory_prompt.dart';
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';
import '../widgets/zennyt_loader.dart';

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

enum _Stage {
  loading,
  intro,
  howToPlay,
  gameplay,
  levelComplete,
  score,
  comparison,
}

/// Nombre de plannings d'une partie.
///
/// Un seul planning ne mesurait qu'un univers : le joueur pouvait tomber sur
/// celui qui lui parle et n'être jamais confronté aux autres. Trois manches, un
/// univers différent à chaque fois, rendent le score moins dépendant du tirage
/// — et donnent une durée conforme aux « 10-13 min » annoncés au catalogue.
/// Quatre univers par session — réponse du client du 2026-09-11.
///
/// Son document n'en disait rien et raisonnait au singulier (« l'univers de la
/// session ») ; interrogé, il a fixé quatre. La banque en compte sept, et le
/// tirage exclut ceux déjà joués : une partie ne rejoue donc jamais le même.
const int kDayStackLevels = 4;

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

  /// Dernière partie notée de la visite, pour l'écran de comparaison.
  _DayStackRun? _previousRun;

  /// Partie en cours, dès que le serveur l'a notée.
  _DayStackRun? get _currentRun {
    final score = _serverSession?.lastAttempt?.score;
    if (score == null) return null;
    return _DayStackRun(
      points: score.rawPoints,
      maxPoints: score.maxPoints,
      edgesOk: _totalEdgesOk,
      edges: _totalEdges,
      timingOk: _totalTimingOk,
      timingCount: _totalTimingCount,
      deadTimeRatio: _aggregateDeadTimeRatio.clamp(0.0, 1.0),
    );
  }

  /// Les glissements sont le contrôle normal du jeu et restent hors score,
  /// conformément au choix produit demandé pour cette interface.
  final int _proactiveAdjustments = 0;

  /// Corrections déclenchées par un signal d'erreur du système.
  ///
  /// Nécessairement nulles ici : le plateau n'affiche AUCUNE violation pendant
  /// la manche — elles n'apparaissent qu'au débrief. Sans signal en cours de
  /// jeu, une correction réactive au sens du client ne peut pas exister. Le
  /// jour où le plateau signalerait les erreurs en direct, c'est ce compteur-là
  /// qui s'alimenterait.
  final int _reactiveAdjustments = 0;

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
    // 2^32 graines : un univers de 12 tâches compte 4^12 ≈ 16,8 millions de
    // feuilles, un tirage sur 2^20 n'en aurait atteint que 6 %.
    _variantSeed = widget.variantSeed ?? random.nextInt(1 << 32);

    _slots = List<int>.generate(_universe.tasks.length, (i) => i)..shuffle();
    _validatedSchedule = null;
    _boardShownAt = null;
    // La latence initiale est conservée entre les manches de la partie.
    if (_level == 1) {
      _planningLatencyMs = null;
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
    // La partie terminée devient la référence de la prochaine comparaison.
    _previousRun = _currentRun ?? _previousRun;
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
      // Score déjà reçu pendant le débrief : le tableau sonne à l'affichage.
      if (_serverSession != null) SoundService.instance.playScoreboard();
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
      if (_stage == _Stage.score) SoundService.instance.playScoreboard();
    } catch (error) {
      if (mounted) setState(() => _submitError = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _stage == _Stage.gameplay;
    final isTutorial = _stage == _Stage.howToPlay;
    // Les commandes restent à l'intérieur de la zone sûre.
    final content = SafeArea(
      bottom: !isDark,
      child: GameContentFrame(maxWidth: 980, child: _buildStage()),
    );
    return PopScope(
      canPop: _stage == _Stage.intro || _stage == _Stage.score,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage == _Stage.comparison) {
          setState(() => _stage = _Stage.score);
        } else if (!didPop && _stage != _Stage.intro) {
          setState(() => _stage = _Stage.intro);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? ZennytGamePalette.gameBlue : Colors.white,
        // En partie, le plateau gère lui-même la marge basse du bouton
        // « Valider », pour que le fond aille jusqu'au bord de l'écran.
        body: isTutorial
            ? AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.dark,
                child: content,
              )
            : content,
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
    final action = await showGamePauseMenu<GamePauseAction>(
      context,
      builder: (context) => GamePauseScaffold(
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(context).pop(GamePauseAction.resume),
        description:
            'Le plateau est figé. Les tâches déjà posées sont conservées.',
        actions: [
          GamePauseMenuAction.resume(
            onPressed: () => Navigator.of(context).pop(GamePauseAction.resume),
          ),
          GamePauseMenuAction.rules(
            onPressed: () => Navigator.of(context).pop(GamePauseAction.help),
          ),
          GamePauseMenuAction.exit(
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
        roundCount: kDayStackLevels,
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
          universe: _universe,
          labelOf: _labelOf,
          slots: _slots,
          onMove: _moveSlot,
          onValidate: _validateLevel,
          onPause: _openMenu,
          affordance: _pauseAllowance.affordance,
        ),
      ),
      _Stage.score => _ScoreView(
        rawScore: _serverSession?.lastAttempt?.score.rawPoints,
        maxScore: _serverSession?.lastAttempt?.score.maxPoints,
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
        onCompare: () => setState(() => _stage = _Stage.comparison),
        onBack: () => context.go(AppRoutes.games),
      ),
      _Stage.comparison => _ComparisonView(
        current: _currentRun,
        previous: _previousRun,
        onReplay: _beginGame,
        onBack: () => setState(() => _stage = _Stage.score),
      ),
    };
  }
}

// ── Gameplay ─────────────────────────────────────────────────────────────────

class _GameplayView extends StatefulWidget {
  const _GameplayView({
    required this.level,
    required this.levelCount,
    required this.universe,
    required this.labelOf,
    required this.slots,
    required this.onMove,
    required this.onValidate,
    required this.onPause,
    required this.affordance,
  });

  final List<int> slots;
  final DayStackUniverse universe;
  final String Function(DayStackTask) labelOf;
  final int level;
  final int levelCount;
  final void Function(int from, int to) onMove;
  final VoidCallback onValidate;
  final VoidCallback onPause;
  final GameMenuAffordance affordance;

  @override
  State<_GameplayView> createState() => _GameplayViewState();
}

/// Barre de progression des manches terminées, sous la consigne de la manche.
class _RoundProgressBar extends StatelessWidget {
  const _RoundProgressBar({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    return Semantics(
      key: const ValueKey('day-stack-round-progress'),
      label: '$completed manches terminées sur $total, $percent pour cent',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Manches terminées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$completed / $total · $percent %',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: ratio),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation(
                  ZennytGamePalette.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameplayViewState extends State<_GameplayView> {
  /// Mission de l'univers, lue dans la banque (`mission`) : une phrase par
  /// univers, modifiable sans toucher au code.
  String get _mission => widget.universe.mission.isNotEmpty
      ? widget.universe.mission
      : 'Organise la journée en respectant horaires et étapes.';

  bool _dragging = false;

  /// Hauteur mesurée de la zone flottante du bouton « Valider ».
  double _footerHeight = 0;

  @override
  Widget build(BuildContext context) {
    // « Valider » flotte au-dessus du calendrier, qui défile dessous jusqu'au
    // bas de l'écran et reste visible en fondu autour du bouton.
    return Stack(
      children: [
        Positioned.fill(child: _buildBoard()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MeasureSize(
            onChange: (size) {
              if (size.height != _footerHeight) {
                setState(() => _footerHeight = size.height);
              }
            },
            child: _buildValidationArea(context),
          ),
        ),
      ],
    );
  }

  /// Plateau mauve : consigne, progression et calendrier.
  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // La mission reste visible au-dessus du calendrier pendant la manche.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manche ${widget.level} / ${widget.levelCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 6),
          MemoryPrompt(
            _mission,
            key: const ValueKey('day-stack-mission'),
            textAlign: TextAlign.start,
            style: const TextStyle(fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 10),
          // Séparation entre la consigne et le calendrier : la progression de
          // la partie, en manches TERMINÉES (la manche en cours ne compte pas).
          _RoundProgressBar(
            completed: widget.level - 1,
            total: widget.levelCount,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRect(
              key: const ValueKey('day-stack-calendar-viewport'),
              child: DayStackCalendar(
                universe: widget.universe,
                slots: widget.slots,
                labelOf: widget.labelOf,
                onMove: widget.onMove,
                bottomInset: _footerHeight,
                onDraggingChanged: (dragging) {
                  if (dragging != _dragging) {
                    setState(() => _dragging = dragging);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Le bouton « Valider » flottant, posé sur un fondu du fond : les tâches
  /// restent visibles autour et derrière lui.
  ///
  /// Seul le bouton capte les touchers ; le fondu et les marges laissent passer
  /// les gestes vers le calendrier.
  Widget _buildValidationArea(BuildContext context) {
    return Stack(
      key: const ValueKey('day-stack-validation-area'),
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ZennytGamePalette.gameBlue.withValues(alpha: 0),
                    ZennytGamePalette.gameBlue.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            28,
            16,
            14 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: DecoratedBox(
                // Ombre portée : le bouton se détache du calendrier qu'il
                // survole.
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: GamePrimaryButton(
                  key: const ValueKey('day-stack-validate'),
                  label: 'Valider',
                  onPressed: _dragging ? null : widget.onValidate,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rapporte la taille de son enfant après chaque mise en page.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) => renderObject.onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    // Après la frame : on ne reconstruit pas pendant la mise en page.
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(size));
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          // Débrief sur un seul écran : il se réduit d'un bloc si besoin.
          child: GameFitToScreen(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
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
    child: ZennytLoader(semanticsLabel: 'Chargement des tâches'),
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
                  'Classe les tâches pour respecter leurs dépendances et leurs horaires.',
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
                child: ResultStatTile(label: 'Objectif', value: 'Planifier'),
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
          GamePrimaryButton(label: 'Commencer', onPressed: onStart),
        ],
      ),
    );
  }
}

class _HowToPlayView extends StatelessWidget {
  const _HowToPlayView({
    required this.onStart,
    required this.onBack,
    required this.roundCount,
    this.reviewing = false,
  });
  final bool reviewing;
  final int roundCount;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => DayStackTutorial(
    leading: _BackButton(onPressed: onBack),
    onComplete: onStart,
    roundCount: roundCount,
    reviewing: reviewing,
  );
}

// ── Score ───────────────────────────────────────────────────────────────────

class _ScoreView extends StatelessWidget {
  const _ScoreView({
    required this.rawScore,
    required this.maxScore,
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
    required this.onCompare,
    required this.onBack,
  });

  final int? rawScore;
  final int? maxScore;
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
  final VoidCallback onCompare;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    // Modèle commun des écrans de résultats (référence « Je Bouge »), sur un
    // seul écran. Les mesures CUMULÉES expliquent le score : un nombre nu
    // n'apprend rien au joueur.
    return GameResultsTemplate(
      onBack: onBack,
      gameName: 'Day Stack',
      pending: busy,
      scoreLabel: 'Planning score',
      scorePercent: gameResultPercent(rawScore, maxScore),
      points: rawScore,
      maxPoints: maxScore,
      stats: [
        GameResultStat(
          label: 'Dépendances',
          value: '$edgesOk/$edges',
          color: edgesOk == edges
              ? ZennytGamePalette.success
              : ZennytGamePalette.error,
        ),
        GameResultStat(
          label: 'Horaires',
          value: '$timingOk/$timingCount',
          color: timingOk == timingCount
              ? ZennytGamePalette.success
              : ZennytGamePalette.error,
        ),
        GameResultStat(
          label: 'Temps mort',
          value: '${(deadTimeRatio * 100).round()}%',
          color: deadTimeRatio < 0.10
              ? ZennytGamePalette.success
              : ZennytGamePalette.magenta,
        ),
      ],
      notice: failed
          // Un tiret seul laissait croire à une partie sans points. Le score
          // est calculé SERVEUR : s'il n'est pas arrivé, on le dit et on
          // propose de renvoyer le même planning, plutôt que de faire rejouer.
          ? Container(
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ZennytGamePalette.muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            )
          : null,
      insight: failed || busy ? null : _insight,
      // Barres de la maquette, sur les mesures CUMULÉES envoyées au serveur.
      insightBars: failed || busy
          ? const []
          : [
              GameResultInsightBar(
                label: 'Dependencies respected',
                fraction: edges == 0 ? 1 : edgesOk / edges,
                color: edgesOk == edges
                    ? ZennytGamePalette.success
                    : ZennytGamePalette.magenta,
              ),
              GameResultInsightBar(
                label: 'Deadlines met',
                fraction: timingCount == 0 ? 1 : timingOk / timingCount,
                color: timingOk == timingCount
                    ? ZennytGamePalette.success
                    : ZennytGamePalette.magenta,
              ),
              // Cohérence : part de la journée sans temps mort, nulle dès
              // qu'une collision rend le planning impossible.
              GameResultInsightBar(
                label: 'Schedule consistency',
                fraction: collisionFree ? 1 - deadTimeRatio : 0,
                color: collisionFree && deadTimeRatio < 0.10
                    ? ZennytGamePalette.success
                    : ZennytGamePalette.magenta,
              ),
              // Corrections faites APRÈS une alerte : pleine sous deux.
              GameResultInsightBar(
                label: 'Adjustments (<2)',
                fraction: reactive < 2 ? 1 : 2 / reactive,
                color: reactive < 2
                    ? ZennytGamePalette.success
                    : ZennytGamePalette.magenta,
              ),
            ],
      // Plus d'enchaînement vers un AUTRE jeu depuis cet écran : les deux
      // suites légitimes d'une partie sont la rejouer ou revenir au catalogue.
      primaryLabel: failed
          ? (busy ? 'Envoi…' : 'Renvoyer le résultat')
          : 'Replay',
      onPrimary: busy ? null : (failed ? onRetrySubmit : onReplay),
      secondaryLabel: failed ? 'Replay' : 'Compare',
      onSecondary: failed ? onReplay : onCompare,
    );
  }

  String get _insight {
    final latency = latencyMs == null
        ? ''
        : ' Temps de réflexion initial : '
              '${(latencyMs! / 1000).toStringAsFixed(1)} s.';
    return '${level == null ? '' : '$level — '}'
        '$levelsPlayed manche(s) · ${universeNames.join(' · ')}. '
        'Collisions : ${collisionFree ? 'aucune' : 'oui'}. '
        'Corrections : $proactive avant alerte · $reactive après.$latency';
  }
}

/// Mesures d'une partie de Day Stack notée par le serveur, conservées pour la
/// comparer à la suivante.
class _DayStackRun {
  const _DayStackRun({
    required this.points,
    required this.maxPoints,
    required this.edgesOk,
    required this.edges,
    required this.timingOk,
    required this.timingCount,
    required this.deadTimeRatio,
  });

  final int points;
  final int maxPoints;
  final int edgesOk;
  final int edges;
  final int timingOk;
  final int timingCount;
  final double deadTimeRatio;
}

/// « Comparative Results » de Day Stack, d'après la maquette client.
///
/// Aucun classement n'existe côté plateforme (réseau, global) : l'écran ne
/// l'invente pas. Il compare la partie à la PRÉCÉDENTE jouée pendant cette
/// visite, avec les mesures notées par le serveur, et dit que le classement
/// attend ses données.
class _ComparisonView extends StatelessWidget {
  const _ComparisonView({
    required this.current,
    required this.previous,
    required this.onReplay,
    required this.onBack,
  });

  final _DayStackRun? current;
  final _DayStackRun? previous;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  static String _ratio(int ok, int total) => '$ok/$total';

  @override
  Widget build(BuildContext context) {
    final now = current;
    final before = previous;
    final delta = now == null || before == null
        ? null
        : now.points - before.points;
    final evolution = switch (delta) {
      null =>
        'First scored attempt of this visit. Replay to measure how your '
            'planning evolves.',
      > 0 =>
        'Your planning improved: +$delta point${delta > 1 ? 's' : ''} over '
            'your previous attempt.',
      < 0 =>
        'This attempt scored $delta point${delta < -1 ? 's' : ''} versus the '
            'previous one. Check dependencies and deadlines first.',
      _ => 'Same score as your previous attempt.',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: GameFitToScreen(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GameResultsBackButton(onPressed: onBack),
            ),
            Text(
              'Comparative Results',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: ZennytGamePalette.blue,
                letterSpacing: 0,
              ),
            ),
            Text(
              'Ranking data required from platform',
              textAlign: TextAlign.center,
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
              child: Row(
                children: [
                  Text(
                    delta == null
                        ? '—'
                        : delta > 0
                        ? '+$delta'
                        : '$delta',
                    key: const ValueKey('day-stack-compare-delta'),
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      delta == null
                          ? 'no previous attempt to compare yet'
                          : 'points versus your previous attempt',
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: ResultStatTile(
                    label: 'This attempt',
                    value: now == null ? '—' : '${now.points}/${now.maxPoints}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ResultStatTile(
                    label: 'Previous attempt',
                    value: before == null
                        ? '—'
                        : '${before.points}/${before.maxPoints}',
                    valueColor: ZennytGamePalette.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ResultStatTile(
                    label: 'Dependencies',
                    value: now == null
                        ? '—'
                        : before == null
                        ? _ratio(now.edgesOk, now.edges)
                        : '${_ratio(before.edgesOk, before.edges)} → '
                              '${_ratio(now.edgesOk, now.edges)}',
                    valueColor: ZennytGamePalette.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ResultStatTile(
                    label: 'Deadlines',
                    value: now == null
                        ? '—'
                        : before == null
                        ? _ratio(now.timingOk, now.timingCount)
                        : '${_ratio(before.timingOk, before.timingCount)} → '
                              '${_ratio(now.timingOk, now.timingCount)}',
                    valueColor: ZennytGamePalette.magenta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GamePanel(
              backgroundColor: ZennytGamePalette.mist,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance evolution',
                    style: AppTypography.titleMedium.copyWith(
                      color: ZennytGamePalette.blue,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    evolution,
                    style: AppTypography.bodyMedium.copyWith(
                      color: ZennytGamePalette.muted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GamePrimaryButton(label: 'Replay to improve', onPressed: onReplay),
          ],
        ),
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
