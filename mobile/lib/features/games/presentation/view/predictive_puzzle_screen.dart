import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_runtime_snapshot.dart';
import '../../domain/config/game_presentation_timing.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/prevision_puzzle_metrics.dart';
import '../games_controller.dart';
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';
import '../widgets/game_tutorial_deck.dart';

/// A difficulty level of the Predictive Puzzle. Difficulty scales purely by the
/// number of discs: a standard Tower of Hanoi with `discCount` discs has a
/// deterministic optimal of `2^discCount - 1` moves (7 → 15 → 31), so each extra
/// disc roughly doubles the planning load. Error tolerance tightens in step.
class _PuzzleLevel {
  const _PuzzleLevel({required this.discCount, required this.maxErrors});

  final int discCount;
  final int maxErrors;

  /// Minimum moves to solve a standard `discCount`-disc tower: `2^n - 1`.
  int get optimalMoves => (1 << discCount) - 1;
}

// 8 niveaux : 3 → 10 disques. L'optimum double à chaque disque
// (7, 15, 31, 63, 127, 255, 511, 1023 coups) et la tolérance aux erreurs se
// resserre au fur et à mesure.
//
// ⚠️ La phase de planification exige de composer CHAQUE coup à la main (tour
// source, tour destination, « Add move »). Le dernier niveau demande donc 1023
// coups, soit environ 3 000 interactions, et l'échelle complète en cumule 2 032.
// C'est jouable au sens strict — rien ne casse, la file est rendue
// paresseusement — mais hors de portée d'un joueur réel. Rendre ces niveaux
// praticables suppose un mode de saisie autre que coup par coup (par exemple
// désigner un disque et sa destination finale, ou une résolution assistée).
// Miroir : PrevisionPuzzleConfig.PUZZLE_LEVELS (backend).
const _puzzleLevels = <_PuzzleLevel>[
  _PuzzleLevel(discCount: 3, maxErrors: 4),
  _PuzzleLevel(discCount: 4, maxErrors: 3),
  _PuzzleLevel(discCount: 5, maxErrors: 3),
  _PuzzleLevel(discCount: 6, maxErrors: 2),
  _PuzzleLevel(discCount: 7, maxErrors: 2),
  _PuzzleLevel(discCount: 8, maxErrors: 1),
  _PuzzleLevel(discCount: 9, maxErrors: 1),
  _PuzzleLevel(discCount: 10, maxErrors: 1),
];

enum _PuzzleStage { intro, rule, planning, running, results, comparison }

class PredictivePuzzleScreen extends ConsumerStatefulWidget {
  const PredictivePuzzleScreen({super.key});

  @override
  ConsumerState<PredictivePuzzleScreen> createState() =>
      _PredictivePuzzleScreenState();
}

class _PredictivePuzzleScreenState
    extends ConsumerState<PredictivePuzzleScreen> {
  _PuzzleStage _stage = _PuzzleStage.intro;
  Timer? _timer;
  Timer? _runTimer;
  int _elapsed = 0;

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();
  int _errors = 0;
  int _retries = 0;
  int _runIndex = 0;
  bool _busy = false;
  bool _targetCompleted = false;
  String? _selectedSource;
  String? _selectedDestination;
  String _feedback = 'Touche une tour source, puis une destination.';

  // Current difficulty level (index into [_puzzleLevels]).
  int _level = 0;

  // Métriques PAR NIVEAU, cumulées puis soumises une seule fois (le backend
  // note chaque niveau /10 puis fait la moyenne → un seul Attempt).
  final List<PrevisionPuzzleLevelMetrics> _levelMetrics = [];

  // Coups du plan qui manipulent RÉELLEMENT un disque. Les coups fautifs restent
  // dans la file (affichage rouge + rejeu) mais ne sont pas des « coups
  // planifiés » : les compter pénaliserait deux fois la même erreur (critère
  // « erreurs de séquence » ET critère « coups superflus »).
  int get _validMoveCount => _queue.where((m) => m.isValidAtPlanning).length;

  // Agrégats dérivés pour l'affichage des résultats (le score fait autorité serveur).
  int get _accPlanned => _levelMetrics.fold(0, (s, l) => s + l.plannedMoves);
  int get _accErrors => _levelMetrics.fold(0, (s, l) => s + l.sequenceErrors);
  int get _accOptimal => _levelMetrics.fold(0, (s, l) => s + l.optimalMoves);
  int get _accRetries => _levelMetrics.fold(0, (s, l) => s + l.retries);

  _PuzzleLevel get _config => _puzzleLevels[_level];
  int get _discCount => _config.discCount;
  int get _optimalMoves => _config.optimalMoves;
  int get _maxErrors => _config.maxErrors;
  bool get _isLastLevel => _level == _puzzleLevels.length - 1;

  Map<String, List<int>> _planningTowers = _initialTowers(
    _puzzleLevels.first.discCount,
  );
  Map<String, List<int>> _executionTowers = _initialTowers(
    _puzzleLevels.first.discCount,
  );
  final List<_QueuedMove> _queue = [];

  static Map<String, List<int>> _initialTowers(int discCount) => {
    'A': [for (var d = discCount; d >= 1; d--) d],
    'B': <int>[],
    'C': <int>[],
  };

  @override
  void dispose() {
    _timer?.cancel();
    _runTimer?.cancel();
    super.dispose();
  }

  bool _starting = false;
  Future<void> _beginGame() async {
    if (_starting) return;
    _starting = true;
    await ref.read(gamesControllerProvider.notifier).start(GameType.planifik);
    _starting = false;
    if (!mounted) return;
    if (ref.read(gamesControllerProvider).value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partie indisponible. Réessayez.')),
      );
      return;
    }
    _timer?.cancel();
    _runTimer?.cancel();
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    setState(() {
      _stage = _PuzzleStage.planning;
      _level = 0;
      _elapsed = 0;
      _errors = 0;
      _retries = 0;
      _runIndex = 0;
      _busy = false;
      _targetCompleted = false;
      _selectedSource = null;
      _selectedDestination = null;
      _levelMetrics.clear();
      _feedback = 'Niveau 1 : planifie la séquence à $_discCount disques.';
      _planningTowers = _initialTowers(_discCount);
      _executionTowers = _initialTowers(_discCount);
      _queue.clear();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _stage == _PuzzleStage.planning) {
        setState(() => _elapsed++);
      }
    });
  }

  void _selectTower(String tower) {
    if (_stage != _PuzzleStage.planning || _targetCompleted) return;
    final source = _selectedSource;
    if (source == null) {
      if (_planningTowers[tower]!.isEmpty) {
        setState(() => _feedback = 'La tour $tower n’a aucun disque à déplacer.');
        return;
      }
      // Une tour source est choisie : on « saisit » le disque du sommet.
      SoundService.instance.playSfx(GameSfx.diskDrag);
      setState(() {
        _selectedSource = tower;
        _selectedDestination = null;
        _feedback = 'Tour source $tower sélectionnée. Choisis la destination.';
      });
      return;
    }

    setState(() {
      _selectedDestination = tower;
      _feedback = 'Ajoute $source->$tower quand tu es prêt.';
    });
  }

  void _addMove() {
    if (_stage != _PuzzleStage.planning || _targetCompleted) return;
    final source = _selectedSource;
    final destination = _selectedDestination;
    if (source == null || destination == null) {
      setState(() => _feedback = 'Choisis d’abord une source et une destination.');
      return;
    }
    if (source == destination) {
      _addInvalidMove(source, destination, 'même tour');
      return;
    }

    final sourceStack = _planningTowers[source]!;
    final destinationStack = _planningTowers[destination]!;
    if (sourceStack.isEmpty) {
      _addInvalidMove(source, destination, 'source vide');
      return;
    }
    final disc = sourceStack.last;
    if (destinationStack.isNotEmpty && destinationStack.last < disc) {
      _addInvalidMove(source, destination, 'grand disque sur un plus petit');
      return;
    }

    // Mouvement valide : le disque est « déposé » sur la tour de destination.
    SoundService.instance.playSfx(GameSfx.diskDrop);
    setState(() {
      sourceStack.removeLast();
      destinationStack.add(disc);
      _queue.add(
        _QueuedMove(
          from: source,
          to: destination,
          disc: disc,
          isValidAtPlanning: true,
        ),
      );
      _selectedSource = null;
      _selectedDestination = null;
      _feedback = _isTarget(_planningTowers)
          ? 'Séquence complète planifiée (${_queue.length} coups). Prête à être exécutée.'
          : 'Coup ${_queue.length} planifié.';
      _targetCompleted = _isTarget(_planningTowers);
    });
  }

  void _addInvalidMove(String source, String destination, String reason) {
    SoundService.instance.playSfx(GameSfx.wrongChoice);
    // Tolérance d'erreurs du niveau dépassée (déjà [_maxErrors] erreurs) : le
    // niveau est échoué → fin de partie + écran de score.
    if (_errors >= _maxErrors) {
      setState(() {
        _feedback =
            'Tolérance d’erreurs dépassée ($_maxErrors max) — niveau échoué.';
      });
      _finishRun(false);
      return;
    }
    final disc = _planningTowers[source]!.isEmpty
        ? 0
        : _planningTowers[source]!.last;
    setState(() {
      _errors = math.min(_maxErrors, _errors + 1);
      _queue.add(
        _QueuedMove(
          from: source,
          to: destination,
          disc: disc,
          isValidAtPlanning: false,
          errorReason: reason,
        ),
      );
      _selectedSource = null;
      _selectedDestination = null;
      _feedback =
          'Coup ${_queue.length} invalide - $reason (erreur $_errors/$_maxErrors)';
    });
  }

  void _undo() {
    if (_stage != _PuzzleStage.planning || _queue.isEmpty || _targetCompleted) {
      return;
    }
    final move = _queue.removeLast();
    setState(() {
      if (move.isValidAtPlanning) {
        _planningTowers[move.to]!.removeLast();
        _planningTowers[move.from]!.add(move.disc);
      } else {
        _errors = math.max(0, _errors - 1);
      }
      _selectedSource = null;
      _selectedDestination = null;
      _feedback = 'Dernier coup retiré.';
    });
  }

  void _clearSequence() {
    if (_stage != _PuzzleStage.planning) return;
    setState(() {
      _retries++;
      _errors = 0;
      _runIndex = 0;
      _targetCompleted = false;
      _selectedSource = null;
      _selectedDestination = null;
      _planningTowers = _initialTowers(_discCount);
      _executionTowers = _initialTowers(_discCount);
      _queue.clear();
      _feedback = 'Séquence effacée. Planifie à nouveau tous les coups.';
    });
  }

  void _runPlan() {
    if (!_targetCompleted ||
        _queue.isEmpty ||
        _stage != _PuzzleStage.planning) {
      return;
    }
    setState(() {
      _stage = _PuzzleStage.running;
      _runIndex = 0;
      _executionTowers = _initialTowers(_discCount);
      for (var i = 0; i < _queue.length; i++) {
        _queue[i] = _queue[i].copyWith(executed: false, failed: false);
      }
      _feedback = 'La machine exécute le plan.';
    });
    final timing = GamePresentationTiming(
      ref.read(gamesControllerProvider).value?.runtime ??
          const GameRuntimeSnapshot(),
    );
    _runTimer = Timer.periodic(
      Duration(milliseconds: timing.puzzlePlaybackStepMs),
      (timer) {
        if (!mounted) return;
        if (_runIndex >= _queue.length) {
          timer.cancel();
          // Réussite = cible atteinte. Les coups fautifs sont sautés pendant le
          // rejeu : ils ne font PAS échouer le niveau tant que la tolérance
          // d'erreurs du niveau n'est pas dépassée (elle l'est déjà gérée par
          // [_addInvalidMove]). Ils restent pénalisés au barème via
          // `firstTrySuccess = false` et le critère « erreurs de séquence ».
          _finishRun(_isTarget(_executionTowers));
          return;
        }
        _executeQueuedMove();
      },
    );
  }

  void _executeQueuedMove() {
    final move = _queue[_runIndex];
    final source = _executionTowers[move.from]!;
    final destination = _executionTowers[move.to]!;
    final legal =
        move.isValidAtPlanning &&
        source.isNotEmpty &&
        source.last == move.disc &&
        (destination.isEmpty || destination.last > move.disc);

    setState(() {
      if (legal) {
        source.removeLast();
        destination.add(move.disc);
        // Rejeu : chaque disque qui passe d'une tour à l'autre fait son bruit.
        SoundService.instance.playSfx(GameSfx.diskDrop);
        _queue[_runIndex] = move.copyWith(executed: true);
        _runIndex++;
        _feedback = 'Exécution du coup $_runIndex/${_queue.length}.';
        return;
      }

      // Coup illégal : on marque la case en rouge + son d'erreur, SANS appliquer
      // le déplacement, puis on continue le rejeu (on ne s'arrête plus au 1er
      // échec) pour signaler tous les coups fautifs.
      _queue[_runIndex] = move.copyWith(executed: true, failed: true);
      if (move.isValidAtPlanning) {
        _errors = math.min(_maxErrors, _errors + 1);
      }
      SoundService.instance.playSfx(GameSfx.wrongChoice);
      _runIndex++;
      _feedback = 'Coup illégal $_runIndex/${_queue.length} ignoré.';
    });
  }

  void _finishRun(bool completed) {
    _runTimer?.cancel();

    // Fige les métriques du niveau courant (barème catégoriel côté serveur).
    // firstTrySuccess : réussi au 1er run, sans retry ni erreur.
    _levelMetrics.add(
      PrevisionPuzzleLevelMetrics(
        levelIndex: _level,
        discCount: _discCount,
        firstTrySuccess: completed && _retries == 0 && _errors == 0,
        sequenceErrors: _errors,
        plannedMoves: _validMoveCount,
        optimalMoves: _optimalMoves,
        retries: _retries,
        completed: completed,
      ),
    );

    // Un rejeu qui atteint la cible fait passer au niveau suivant ; un échec
    // (tolérance d'erreurs dépassée) ou le dernier niveau termine la session et
    // soumet les métriques par niveau.
    if (completed && !_isLastLevel) {
      SoundService.instance.playSfx(GameSfx.correctChoice);
      _advanceLevel();
      return;
    }

    _timer?.cancel();
    setState(() {
      _targetCompleted = completed;
      _stage = _PuzzleStage.results;
    });
    // Tous les niveaux réussis → félicitations ; sinon tableau de score
    // (arrêtable en fin d'animation de comptage).
    if (completed) {
      SoundService.instance.playSfx(GameSfx.congrats);
    } else {
      SoundService.instance.playScoreboard();
    }
    _submitFinal();
  }

  void _advanceLevel() {
    setState(() {
      _level++;
      _errors = 0;
      _retries = 0;
      _runIndex = 0;
      _busy = false;
      _targetCompleted = false;
      _selectedSource = null;
      _selectedDestination = null;
      _planningTowers = _initialTowers(_discCount);
      _executionTowers = _initialTowers(_discCount);
      _queue.clear();
      _stage = _PuzzleStage.planning;
      _feedback =
          'Niveau ${_level + 1} : planifie la séquence à $_discCount disques '
          '($_optimalMoves coups optimaux).';
    });
  }

  Future<void> _submitFinal() async {
    if (_levelMetrics.isEmpty) return;
    setState(() => _busy = true);
    await ref
        .read(gamesControllerProvider.notifier)
        .submit(
          miniGame: MiniGame.previsionPuzzle,
          metrics: PrevisionPuzzleMetrics(
            levels: List<PrevisionPuzzleLevelMetrics>.unmodifiable(
              _levelMetrics,
            ),
          ),
        );
    if (!mounted) return;
    setState(() => _busy = false);
  }

  bool _isTarget(Map<String, List<int>> towers) {
    final target = towers['C']!;
    if (target.length != _discCount) return false;
    for (var i = 0; i < _discCount; i++) {
      if (target[i] != _discCount - i) return false;
    }
    return true;
  }

  /// Bouton unique du HUD : menu de pause tant que la fenêtre est ouverte,
  /// confirmation de sortie ensuite. Voir [GameMenuAffordance].
  Future<void> _openMenu() async {
    if (_pauseAllowance.canOpen) return _pause();
    // Fenêtre consommée : on ne met PAS le jeu en pause. Geler le chronomètre
    // ici rendrait la pause renouvelable à volonté par simple ouverture de la
    // boîte, ce que la fenêtre unique existe pour empêcher.
    if (await GameExitConfirmDialog.show(context)) {
      if (mounted) context.go(AppRoutes.games);
    }
  }

  Future<void> _pause() async {
    // Une seule fenêtre de pause par partie (CdC pause §2-3).
    if (!_pauseAllowance.canOpen) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    _timer?.cancel();
    _pauseAllowance.open();

    final action = await showGamePauseMenu<GamePauseAction>(
      context,
      builder: (dialogCtx) => GamePauseScaffold(
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(dialogCtx).pop(GamePauseAction.resume),
        actions: [
          GamePauseMenuAction.resume(
            onPressed: () =>
                Navigator.of(dialogCtx).pop(GamePauseAction.resume),
          ),
          GamePauseMenuAction.rules(
            onPressed: () => Navigator.of(dialogCtx).pop(GamePauseAction.help),
          ),
          GamePauseMenuAction.exit(
            onPressed: () => Navigator.of(dialogCtx).pop(GamePauseAction.exit),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == GamePauseAction.exit) {
      // Quitter annule la tentative : confirmation explicite d'abord.
      if (await GameExitConfirmDialog.show(context)) {
        if (mounted) context.go(AppRoutes.games);
        return;
      }
      if (!mounted) return;
    } else if (action == GamePauseAction.help) {
      // Les règles occupent tout l'écran ici : on quitte la phase de jeu, donc
      // rien à relancer — le retour des règles rétablit le chronomètre.
      setState(() => _stage = _PuzzleStage.rule);
      return;
    }

    if (!mounted) return;
    // La partie repart : le temps passé en pause rejoint le budget consommé, et
    // le HUD se redessine — le bouton reste « Pause » tant qu'il reste du
    // budget, et bascule sur « Exit mission » une fois les 30 s épuisées.
    _pauseAllowance.close();
    setState(() {});
    if (_stage != _PuzzleStage.planning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _stage == _PuzzleStage.planning) {
        setState(() => _elapsed++);
      }
    });
  }

  String get _timeLabel {
    final minutes = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gamesControllerProvider, (_, next) {
      if (next.hasError && mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${next.error}')));
      }
    });

    final session = ref.watch(gamesControllerProvider).value;
    return PopScope(
      canPop: _stage == _PuzzleStage.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage != _PuzzleStage.intro) {
          setState(() => _stage = _PuzzleStage.intro);
        }
      },
      child: Scaffold(
        backgroundColor:
            _stage == _PuzzleStage.planning || _stage == _PuzzleStage.running
            ? ZennytGamePalette.gameBlue
            : Colors.white,
        body: SafeArea(child: _buildStage(session)),
      ),
    );
  }

  Widget _buildStage(GameSession? session) {
    return switch (_stage) {
      _PuzzleStage.intro => _PredictiveIntroView(
        onBack: () => context.go(AppRoutes.games),
        onStart: () => setState(() => _stage = _PuzzleStage.rule),
      ),
      _PuzzleStage.rule => PredictivePuzzleTutorial(
        leading: _SquareIconButton(
          icon: Icons.chevron_left,
          onTap: () => setState(() => _stage = _PuzzleStage.intro),
        ),
        onComplete: _beginGame,
      ),
      _PuzzleStage.planning || _PuzzleStage.running => GameplayMusic(
        child: _PuzzleGameplayView(
          elapsed: _timeLabel,
          movesPlanned: _validMoveCount,
          optimalMoves: _optimalMoves,
          discCount: _discCount,
          level: _level + 1,
          totalLevels: _puzzleLevels.length,
          errors: _errors,
          maxErrors: _maxErrors,
          towers: _stage == _PuzzleStage.running
              ? _executionTowers
              : _planningTowers,
          selectedSource: _selectedSource,
          selectedDestination: _selectedDestination,
          queue: _queue,
          feedback: _feedback,
          running: _stage == _PuzzleStage.running,
          targetReady: _targetCompleted,
          runProgress: _queue.isEmpty ? 0 : _runIndex / _queue.length,
          onTowerTap: _selectTower,
          onAddMove: _targetCompleted ? _runPlan : _addMove,
          onClear: _clearSequence,
          onUndo: _undo,
          onPause: _openMenu,
          affordance: _pauseAllowance.affordance,
        ),
      ),
      _PuzzleStage.results => _PredictiveResultsView(
        session: session,
        busy: _busy,
        targetCompleted: _targetCompleted,
        elapsed: _timeLabel,
        moves: _accPlanned,
        errors: _accErrors,
        levelsCleared: _targetCompleted ? _puzzleLevels.length : _level,
        totalLevels: _puzzleLevels.length,
        onReplay: _beginGame,
        onCompare: () => setState(() => _stage = _PuzzleStage.comparison),
        onBack: () => context.go(AppRoutes.games),
      ),
      _PuzzleStage.comparison => _PredictiveComparisonView(
        session: session,
        moves: _accPlanned,
        optimalMoves: _accOptimal,
        errors: _accErrors,
        retries: _accRetries,
        targetCompleted: _targetCompleted,
        onReplay: _beginGame,
        onBack: () => setState(() => _stage = _PuzzleStage.results),
      ),
    };
  }
}

class _QueuedMove {
  const _QueuedMove({
    required this.from,
    required this.to,
    required this.disc,
    required this.isValidAtPlanning,
    this.errorReason,
    this.executed = false,
    this.failed = false,
  });

  final String from;
  final String to;
  final int disc;
  final bool isValidAtPlanning;
  final String? errorReason;
  final bool executed;
  final bool failed;

  _QueuedMove copyWith({bool? executed, bool? failed}) => _QueuedMove(
    from: from,
    to: to,
    disc: disc,
    isValidAtPlanning: isValidAtPlanning,
    errorReason: errorReason,
    executed: executed ?? this.executed,
    failed: failed ?? this.failed,
  );
}

class _PredictiveIntroView extends StatelessWidget {
  const _PredictiveIntroView({required this.onBack, required this.onStart});
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => GameWelcomePage(
    title: 'Predictive Puzzle',
    logoAsset: 'assets/games icons/Predictive Puzzle transparent.png',
    mission:
        'Prépare tes déplacements, puis déplace la tour dans le bon ordre.',
    contextText:
        'Prépare ton plan : la machine exécutera tes déplacements sans correction en cours de route.',
    contextDetail: 'La tour B peut servir de relais.',
    journey: const ['Prépare', 'Planifie', 'Exécute'],
    leading: _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
    startLabel: 'Commencer',
    onStart: onStart,
  );
}

class PredictivePuzzleTutorial extends StatelessWidget {
  const PredictivePuzzleTutorial({
    super.key,
    required this.leading,
    required this.onComplete,
  });

  final Widget leading;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => GameTutorialDeck(
    leading: leading,
    onComplete: onComplete,
    completionLabel: 'Commencer à planifier',
    steps: const [
      GameTutorialStep(
        title: 'Petit sur grand, toujours',
        description:
            'Déplace le disque du sommet, un à la fois. Pose-le sur une tour vide '
            'ou un disque plus grand. Objectif : déplacer toute la pile de A vers C.',
        illustration: _GoldenRuleArt(),
        illustrationLabel:
            'Autorisé : le petit disque 1 sur le grand disque 3. '
            'Interdit : le grand disque 3 sur le petit disque 1. '
            'La tour B sert de relais entre A et C.',
      ),
      GameTutorialStep(
        title: 'Prépare tout, puis lance',
        description:
            'Choisis la source puis la destination et appuie sur « Ajouter le coup ». '
            'Quand la pile atteint C dans l’aperçu, appuie sur « Lancer le plan ». '
            'Tu ne peux plus modifier les coups pendant l’exécution.',
        illustration: _SequencePreviewArt(),
        illustrationLabel:
            'Préparer : exemple des trois premiers coups A vers C, A vers B, '
            'C vers B. Compléter le plan, puis « Lancer le plan » démarre l’exécution automatique.',
      ),
    ],
  );
}

/// Le dessin conserve ses proportions ; le texte de la carte reste accessible.
class _PuzzleTutorialDiagram extends StatelessWidget {
  const _PuzzleTutorialDiagram({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 300, height: 270, child: child),
    ),
  );
}

class _GoldenRuleArt extends StatelessWidget {
  const _GoldenRuleArt();

  @override
  Widget build(BuildContext context) => _PuzzleTutorialDiagram(
    child: Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (final allowed in [true, false]) ...[
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        allowed ? Icons.check_circle : Icons.cancel,
                        color: allowed
                            ? ZennytGamePalette.success
                            : ZennytGamePalette.error,
                        size: 30,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        allowed ? 'Autorisé' : 'Interdit',
                        style: AppTypography.titleMedium.copyWith(
                          color: ZennytGamePalette.blue,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      Expanded(
                        child: _TowerView(
                          name: '',
                          discs: allowed ? const [3, 1] : const [1, 3],
                          maxDiscs: 3,
                          selected: false,
                          destination: false,
                          disabled: true,
                          onTap: _ignoreTutorialTap,
                          rodHeight: 90,
                          foregroundColor: ZennytGamePalette.blue,
                          label: allowed
                              ? 'Petit sur grand'
                              : 'Grand sur petit',
                        ),
                      ),
                    ],
                  ),
                ),
                if (allowed) const SizedBox(width: 24),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'A → C',
          style: AppTypography.titleLarge.copyWith(
            color: ZennytGamePalette.magenta,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Avec B comme relais',
          style: AppTypography.bodyMedium.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

void _ignoreTutorialTap() {}

class _PuzzleGameplayView extends StatelessWidget {
  const _PuzzleGameplayView({
    required this.elapsed,
    required this.movesPlanned,
    required this.optimalMoves,
    required this.discCount,
    required this.level,
    required this.totalLevels,
    required this.errors,
    required this.maxErrors,
    required this.towers,
    required this.selectedSource,
    required this.selectedDestination,
    required this.queue,
    required this.feedback,
    required this.running,
    required this.targetReady,
    required this.runProgress,
    required this.onTowerTap,
    required this.onAddMove,
    required this.onClear,
    required this.onUndo,
    required this.onPause,
    required this.affordance,
  });

  final String elapsed;
  final int movesPlanned;
  final int optimalMoves;
  final int discCount;
  final int level;
  final int totalLevels;
  final int errors;
  final int maxErrors;
  final Map<String, List<int>> towers;
  final String? selectedSource;
  final String? selectedDestination;
  final List<_QueuedMove> queue;
  final String feedback;
  final bool running;
  final bool targetReady;
  final double runProgress;
  final ValueChanged<String> onTowerTap;
  final VoidCallback onAddMove;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onPause;

  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;

  @override
  Widget build(BuildContext context) {
    final progress = targetReady
        ? 1.0
        : (movesPlanned / optimalMoves).clamp(0, 1);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _HudTile(label: 'Temps', value: elapsed),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HudTile(
                  label: 'Coups\nplanifiés',
                  value: '$movesPlanned/$optimalMoves',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HudTile(label: 'Erreurs', value: '$errors/$maxErrors'),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 52,
                height: 58,
                child: Semantics(
                  button: true,
                  label: affordance.semanticsLabel,
                  child: FilledButton(
                    onPressed: running ? null : onPause,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: 0.16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(affordance.icon, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: LinearProgressIndicator(
            value: running ? runProgress : progress.toDouble(),
            minHeight: 7,
            color: errors > 0 && !targetReady
                ? ZennytGamePalette.error
                : ZennytGamePalette.success,
            backgroundColor: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'NIV. $level/$totalLevels',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ZennytGamePalette.cyan.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    'Objectif : déplacer $discCount disques vers la tour C',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: _TowerBoard(
              towers: towers,
              maxDiscs: discCount,
              selectedSource: selectedSource,
              selectedDestination: selectedDestination,
              disabled: running,
              onTowerTap: onTowerTap,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            feedback,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: targetReady
                  ? ZennytGamePalette.success
                  : errors > 0
                  ? ZennytGamePalette.error
                  : Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 100,
          padding: const EdgeInsets.fromLTRB(20, 8, 0, 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SOPHIE'S SEQUENCE ($movesPlanned/$optimalMoves MOVES PLANNED)",
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: math.max(7, queue.length + 1),
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    if (index >= queue.length) {
                      return _QueuePlaceholder(index: index + 1);
                    }
                    return _MoveChip(index: index + 1, move: queue[index]);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Row(
            children: [
              Expanded(
                child: GameOutlineButton(
                  label: 'Effacer la séquence',
                  onPressed: running ? null : onClear,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: running ? null : onUndo,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(52, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                icon: const Icon(Icons.undo_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GamePrimaryButton(
                  label: targetReady ? 'Lancer le plan' : 'Ajouter le coup',
                  icon: targetReady
                      ? Icons.play_arrow_rounded
                      : Icons.add_rounded,
                  color: ZennytGamePalette.success,
                  // « Lancer le plan » garde le clic générique ; « Ajouter le coup » ne joue
                  // que le son du disque déposé (géré dans _addMove).
                  playClickSound: targetReady,
                  onPressed: running ? null : onAddMove,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TowerBoard extends StatelessWidget {
  const _TowerBoard({
    required this.towers,
    required this.maxDiscs,
    required this.selectedSource,
    required this.selectedDestination,
    required this.disabled,
    required this.onTowerTap,
  });

  final Map<String, List<int>> towers;
  final int maxDiscs;
  final String? selectedSource;
  final String? selectedDestination;
  final bool disabled;
  final ValueChanged<String> onTowerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final tower in ['A', 'B', 'C']) ...[
            Expanded(
              child: _TowerView(
                name: tower,
                discs: towers[tower]!,
                maxDiscs: maxDiscs,
                selected: selectedSource == tower,
                destination: selectedDestination == tower,
                disabled: disabled,
                onTap: () => onTowerTap(tower),
              ),
            ),
            if (tower != 'C') const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TowerView extends StatelessWidget {
  const _TowerView({
    required this.name,
    required this.discs,
    required this.maxDiscs,
    required this.selected,
    required this.destination,
    required this.disabled,
    required this.onTap,
    this.rodHeight = 170,
    this.foregroundColor = Colors.white,
    this.label,
  });

  final String name;
  final List<int> discs;
  final int maxDiscs;
  final bool selected;
  final bool destination;
  final bool disabled;
  final VoidCallback onTap;
  final double rodHeight;
  final Color foregroundColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: selected || destination
              ? Border.all(
                  color: selected
                      ? ZennytGamePalette.magenta
                      : ZennytGamePalette.success,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnWidth = constraints.maxWidth;
                  // La pile doit tenir DANS la tige : hauteur totale
                  // = maxDiscs × pas. L'ancien plancher de 20 px faisait déborder
                  // dès 9 disques (18 + 8 × 20 = 178 > 170) ; il est abaissé à
                  // 11 px pour que 10 disques rentrent encore.
                  final gap = (rodHeight / maxDiscs)
                      .clamp(11.0, 32.0)
                      .toDouble();
                  final discHeight = gap;

                  double discWidth(int disc) {
                    final t = maxDiscs <= 1 ? 1.0 : (disc - 1) / (maxDiscs - 1);
                    return columnWidth * (0.40 + 0.56 * t);
                  }

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: 20,
                        child: Container(
                          width: 4,
                          height: rodHeight,
                          decoration: BoxDecoration(
                            color: foregroundColor.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          width: columnWidth * 0.94,
                          height: 6,
                          decoration: BoxDecoration(
                            color: foregroundColor.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      for (var i = 0; i < discs.length; i++)
                        Positioned(
                          bottom: 18 + i * gap,
                          child: _Disc(
                            disc: discs[i],
                            width: discWidth(discs[i]),
                            height: discHeight - 2,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Text(
              label ?? 'TOWER $name',
              style: AppTypography.labelMedium.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.disc, this.width = 68, this.height = 32});

  final int disc;
  final double width;
  final double height;

  static const _colors = {
    1: ZennytGamePalette.success,
    2: ZennytGamePalette.magenta,
    3: ZennytGamePalette.error,
    4: ZennytGamePalette.cyan,
    5: ZennytGamePalette.ruleOrange,
    6: Color(0xFF8B5CF6), // violet
    7: Color(0xFF14B8A6), // teal
    8: Color(0xFF6366F1), // indigo
    9: Color(0xFFEAB308), // ambre
    10: Color(0xFFEC4899), // rose
  };

  static const _fallbackColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colors[disc] ?? _fallbackColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$disc',
        // Le numéro doit rester lisible quand le disque s'amincit : à 10 disques
        // la hauteur descend à 17 px, où `labelSmall` déborderait.
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          fontSize: (height * 0.55).clamp(8.0, 13.0),
          height: 1,
        ),
      ),
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
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({required this.index, required this.move});

  final int index;
  final _QueuedMove move;

  @override
  Widget build(BuildContext context) {
    // Chaque coup de la séquence est vert (correct) ou rouge (faute), de façon
    // dynamique : un coup invalide dès la planification ou échoué à l'exécution
    // vire au rouge ; les coups valides sont verts (plus vif une fois exécutés).
    final failed = move.failed || !move.isValidAtPlanning;
    final color = failed
        ? ZennytGamePalette.error.withValues(alpha: 0.85)
        : move.executed
        ? ZennytGamePalette.success
        : ZennytGamePalette.success.withValues(alpha: 0.7);
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$index',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          _MiniDisc(disc: move.disc),
          Text(
            '${move.from}->${move.to}',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueuePlaceholder extends StatelessWidget {
  const _QueuePlaceholder({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$index',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0,
            ),
          ),
          Icon(
            Icons.add_rounded,
            color: Colors.white.withValues(alpha: 0.45),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _MiniDisc extends StatelessWidget {
  const _MiniDisc({required this.disc});

  final int disc;

  @override
  Widget build(BuildContext context) {
    if (disc == 0) {
      return const Text('?', style: TextStyle(color: Colors.white));
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _Disc._colors[disc] ?? _Disc._fallbackColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _PredictiveResultsView extends StatelessWidget {
  const _PredictiveResultsView({
    required this.session,
    required this.busy,
    required this.targetCompleted,
    required this.elapsed,
    required this.moves,
    required this.errors,
    required this.levelsCleared,
    required this.totalLevels,
    required this.onReplay,
    required this.onCompare,
    required this.onBack,
  });

  final GameSession? session;
  final bool busy;
  final bool targetCompleted;
  final String elapsed;
  final int moves;
  final int errors;
  final int levelsCleared;
  final int totalLevels;
  final VoidCallback onReplay;
  final VoidCallback onCompare;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final attempt = session?.lastAttempt;
    return GameResultsTemplate(
      onBack: onBack,
      gameName: 'Predictive Puzzle',
      pending: busy,
      scoreLabel: 'Score cognitif',
      scorePercent: attempt?.score.normalized.round(),
      points: attempt?.score.rawPoints,
      maxPoints: attempt?.score.maxPoints,
      stats: [
        GameResultStat(
          label: 'Niveaux',
          value: '$levelsCleared/$totalLevels',
          color: targetCompleted
              ? ZennytGamePalette.success
              : ZennytGamePalette.error,
        ),
        GameResultStat(label: 'Temps', value: elapsed),
        GameResultStat(
          label: 'Erreurs',
          value: '$errors',
          color: errors == 0
              ? ZennytGamePalette.success
              : ZennytGamePalette.magenta,
        ),
      ],
      insight:
          '${targetCompleted ? 'Les $totalLevels niveaux sont réussis.' : '$levelsCleared/$totalLevels niveaux réussis avant d’épuiser la tolérance d’erreurs.'} '
          'Le joueur anticipe toute la chaîne de coups avant d’agir, puis '
          'vérifie que la séquence planifiée résiste aux contraintes d’exécution.',
      primaryLabel: 'Rejouer',
      onPrimary: onReplay,
      secondaryLabel: 'Comparer',
      onSecondary: onCompare,
    );
  }
}

class _PredictiveComparisonView extends StatelessWidget {
  const _PredictiveComparisonView({
    required this.session,
    required this.moves,
    required this.optimalMoves,
    required this.errors,
    required this.retries,
    required this.targetCompleted,
    required this.onReplay,
    required this.onBack,
  });

  final GameSession? session;
  final int moves;
  final int optimalMoves;
  final int errors;
  final int retries;
  final bool targetCompleted;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final surplus = math.max(0, moves - optimalMoves);
    final rank = targetCompleted && errors == 0
        ? '#1'
        : '#${14 + errors + surplus}';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
          Center(
            child: Column(
              children: [
                Text(
                  'Résultats comparatifs',
                  style: AppTypography.headlineLarge.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Référence : séquence optimale',
                  style: AppTypography.bodyMedium.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
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
                  rank,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 48,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'par rapport au plan optimal en $optimalMoves coups',
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
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.95,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ResultStatTile(label: 'Planifiés', value: '$moves'),
              const ResultStatTile(label: 'Optimal', value: '15'),
              ResultStatTile(label: 'Surplus', value: '$surplus'),
              ResultStatTile(
                label: 'Niveau',
                value: session?.lastAttempt?.score.level ?? '-',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Text(
              'Reprises : $retries. Erreurs de séquence : $errors. Rejoue pour réduire les coups en trop et garder chaque coup planifié valide.',
              style: AppTypography.bodyMedium.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePrimaryButton(
            label: 'Rejouer pour améliorer ton classement',
            onPressed: onReplay,
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: ZennytGamePalette.border),
          ),
          child: Icon(icon, color: ZennytGamePalette.ink, size: 24),
        ),
      ),
    );
  }
}

class _SequencePreviewArt extends StatelessWidget {
  const _SequencePreviewArt();

  @override
  Widget build(BuildContext context) => _PuzzleTutorialDiagram(
    child: Column(
      children: [
        Text(
          '1. Préparer les coups',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        const _PreviewMove(index: 1, label: 'A → C', disc: 1),
        const SizedBox(height: 6),
        const _PreviewMove(index: 2, label: 'A → B', disc: 2),
        const SizedBox(height: 6),
        const _PreviewMove(index: 3, label: 'C → B', disc: 1),
        const SizedBox(height: 8),
        Text(
          '… compléter le plan jusqu’à C',
          style: AppTypography.bodyMedium.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
        const Icon(
          Icons.arrow_downward_rounded,
          color: ZennytGamePalette.magenta,
          size: 26,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill_rounded,
              color: ZennytGamePalette.magenta,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              '2. Lancer le plan',
              style: AppTypography.titleMedium.copyWith(
                color: ZennytGamePalette.blue,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Exécution automatique',
          style: AppTypography.bodyMedium.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class _PreviewMove extends StatelessWidget {
  const _PreviewMove({
    required this.index,
    required this.label,
    required this.disc,
  });

  final int index;
  final String label;
  final int disc;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      border: Border.all(color: ZennytGamePalette.blue.withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Text(
          '$index',
          style: AppTypography.labelMedium.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 12),
        _Disc(disc: disc, width: disc == 1 ? 34 : 50, height: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        Text(
          'prévu',
          style: AppTypography.labelSmall.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}
