import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/prevision_puzzle_metrics.dart';
import '../games_controller.dart';
import '../widgets/game_system_components.dart';
import '../widgets/score_detail_panel.dart';

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

const _puzzleLevels = <_PuzzleLevel>[
  _PuzzleLevel(discCount: 3, maxErrors: 3),
  _PuzzleLevel(discCount: 4, maxErrors: 2),
  _PuzzleLevel(discCount: 5, maxErrors: 1),
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
  int _errors = 0;
  int _retries = 0;
  int _runIndex = 0;
  bool _busy = false;
  bool _targetCompleted = false;
  String? _selectedSource;
  String? _selectedDestination;
  String _feedback = 'Tap a tower source, then a destination.';

  // Current difficulty level (index into [_puzzleLevels]).
  int _level = 0;

  // Métriques PAR NIVEAU, cumulées puis soumises une seule fois (le backend
  // note chaque niveau /10 puis fait la moyenne → un seul Attempt).
  final List<PrevisionPuzzleLevelMetrics> _levelMetrics = [];

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

  Future<void> _beginGame() async {
    _timer?.cancel();
    _runTimer?.cancel();
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
      _feedback = 'Level 1: plan the $_discCount-disc sequence.';
      _planningTowers = _initialTowers(_discCount);
      _executionTowers = _initialTowers(_discCount);
      _queue.clear();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _stage == _PuzzleStage.planning) {
        setState(() => _elapsed++);
      }
    });
    await ref.read(gamesControllerProvider.notifier).start(GameType.planifik);
  }

  void _selectTower(String tower) {
    if (_stage != _PuzzleStage.planning || _targetCompleted) return;
    final source = _selectedSource;
    if (source == null) {
      if (_planningTowers[tower]!.isEmpty) {
        setState(() => _feedback = 'Tower $tower has no disc to move.');
        return;
      }
      setState(() {
        _selectedSource = tower;
        _selectedDestination = null;
        _feedback = 'Source Tower $tower selected. Choose destination.';
      });
      return;
    }

    setState(() {
      _selectedDestination = tower;
      _feedback = 'Queue $source->$tower when ready.';
    });
  }

  void _addMove() {
    if (_stage != _PuzzleStage.planning || _targetCompleted) return;
    final source = _selectedSource;
    final destination = _selectedDestination;
    if (source == null || destination == null) {
      setState(() => _feedback = 'Select a source and destination first.');
      return;
    }
    if (source == destination) {
      _addInvalidMove(source, destination, 'same tower');
      return;
    }

    final sourceStack = _planningTowers[source]!;
    final destinationStack = _planningTowers[destination]!;
    if (sourceStack.isEmpty) {
      _addInvalidMove(source, destination, 'empty source');
      return;
    }
    final disc = sourceStack.last;
    if (destinationStack.isNotEmpty && destinationStack.last < disc) {
      _addInvalidMove(source, destination, 'large disc on smaller');
      return;
    }

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
          ? 'Full sequence planned (${_queue.length} moves). Ready to execute.'
          : 'Move ${_queue.length} planned.';
      _targetCompleted = _isTarget(_planningTowers);
    });
  }

  void _addInvalidMove(String source, String destination, String reason) {
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
          'Move ${_queue.length} invalid - $reason (error $_errors/$_maxErrors)';
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
      _feedback = 'Last step removed.';
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
      _feedback = 'Sequence cleared. Plan the full move list again.';
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
      _feedback = 'Machine running the queued plan.';
    });
    _runTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      if (!mounted) return;
      if (_runIndex >= _queue.length) {
        timer.cancel();
        _finishRun(_isTarget(_executionTowers));
        return;
      }
      _executeQueuedMove();
    });
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
        _queue[_runIndex] = move.copyWith(executed: true);
        _runIndex++;
        _feedback = 'Executing move $_runIndex/${_queue.length}.';
        return;
      }

      _queue[_runIndex] = move.copyWith(executed: true, failed: true);
      if (move.isValidAtPlanning) {
        _errors = math.min(_maxErrors, _errors + 1);
      }
      _feedback = 'Execution failed at step ${_runIndex + 1}.';
      _runTimer?.cancel();
      _finishRun(false);
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
        plannedMoves: _queue.length,
        optimalMoves: _optimalMoves,
        retries: _retries,
        completed: completed,
      ),
    );

    // A clean run on a non-final level advances difficulty; a failure (or the
    // final level) ends the session and submits the per-level metrics.
    if (completed && !_isLastLevel) {
      _advanceLevel();
      return;
    }

    _timer?.cancel();
    setState(() {
      _targetCompleted = completed;
      _stage = _PuzzleStage.results;
    });
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
          'Level ${_level + 1}: plan the $_discCount-disc sequence '
          '($_optimalMoves optimal moves).';
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
            levels: List<PrevisionPuzzleLevelMetrics>.unmodifiable(_levelMetrics),
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

  Future<void> _pause() async {
    _timer?.cancel();
    await showDialog<void>(
      context: context,
      builder: (_) => _PredictivePauseDialog(
        elapsed: _elapsed,
        errors: _errors,
        onViewRules: () {
          Navigator.of(context).pop();
          setState(() => _stage = _PuzzleStage.rule);
        },
        onExit: () {
          Navigator.of(context).pop();
          context.go(AppRoutes.games);
        },
      ),
    );
    if (!mounted || _stage != _PuzzleStage.planning) return;
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
      _PuzzleStage.rule => _HowToRuleView(
        onBack: () => setState(() => _stage = _PuzzleStage.intro),
        onStartGame: _beginGame,
      ),
      _PuzzleStage.planning || _PuzzleStage.running => _PuzzleGameplayView(
        elapsed: _timeLabel,
        movesPlanned: _queue.length,
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
        onPause: _pause,
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 300,
            padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x334F46E5),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -6,
                  top: 22,
                  bottom: 62,
                  width: 190,
                  child: Image.asset(
                    'assets/04 Predictive Puzzle/discs.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        'Predictive Reasoning',
                        style: AppTypography.labelMedium.copyWith(
                          color: ZennytGamePalette.blue,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    const Text(
                      'Predict\nive\nPuzzle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Plan every move, then\nexecute.',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: ZennytGamePalette.mist,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: ZennytGamePalette.border),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _IntroMeta(label: 'Goal', value: 'Planning'),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _IntroMeta(
                    label: 'Duration',
                    value: '8-10 min',
                    valueColor: ZennytGamePalette.magenta,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _IntroMeta(label: 'Format', value: 'Mobile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GamePanel(
            borderColor: const Color(0xFF9DB7FF),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Simple rule\n',
                    style: AppTypography.titleMedium.copyWith(
                      color: ZennytGamePalette.blue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Sophie moves a growing stack of discs from Tower A to Tower C across 3 levels (3, then 4, then 5 discs). Plan the entire sequence upfront - the machine executes exactly what she planned, no corrections allowed.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: ZennytGamePalette.muted,
                      height: 1.25,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GamePrimaryButton(label: 'Start', onPressed: onStart),
        ],
      ),
    );
  }
}

class _HowToRuleView extends StatefulWidget {
  const _HowToRuleView({required this.onBack, required this.onStartGame});

  final VoidCallback onBack;
  final VoidCallback onStartGame;

  @override
  State<_HowToRuleView> createState() => _HowToRuleViewState();
}

class _HowToRuleViewState extends State<_HowToRuleView> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SquareIconButton(icon: Icons.chevron_left, onTap: widget.onBack),
              const Expanded(
                child: Text(
                  'How to Play',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ZennytGamePalette.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 54),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Column(
              children: [
                Text(
                  _page == 0 ? 'The Golden Rule' : 'Plan before you act',
                  style: AppTypography.headlineLarge.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_page == 0)
                  SizedBox(
                    height: 190,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Image.asset(
                        'assets/04 Predictive Puzzle/golden_rule.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  const _SequencePreviewArt(),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              _page == 0
                  ? 'Sophie can never place a larger disc on top of a smaller one. She uses Tower B as a relay. Each move takes the top disc from one tower and places it on another valid tower.'
                  : 'Sophie fills in the entire sequence before execution. Once launched, no corrections are possible. Difficulty scales each level (3 → 4 → 5 discs), needing 7, then 15, then 31 optimal moves.',
              style: AppTypography.bodyLarge.copyWith(
                color: ZennytGamePalette.muted,
                height: 1.28,
                letterSpacing: 0,
              ),
            ),
          ),
          const Spacer(),
          GamePrimaryButton(
            label: _page == 0 ? 'Next' : 'Start planning',
            icon: _page == 0 ? Icons.arrow_forward_rounded : null,
            onPressed: () {
              if (_page == 0) {
                setState(() => _page = 1);
                return;
              }
              widget.onStartGame();
            },
          ),
        ],
      ),
    );
  }
}

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
                child: _HudTile(label: 'Timer', value: elapsed),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HudTile(
                  label: 'Moves\nPlanned',
                  value: '$movesPlanned/$optimalMoves',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HudTile(label: 'Errors', value: '$errors/$maxErrors'),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 52,
                height: 58,
                child: FilledButton(
                  onPressed: running ? null : onPause,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.pause_rounded, color: Colors.white),
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
                  'LVL $level/$totalLevels',
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
                    'Goal: move $discCount discs to Tower C',
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
                  label: 'Clear Sequence',
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
                  label: targetReady ? 'Run Plan' : 'Add Move',
                  icon: targetReady
                      ? Icons.play_arrow_rounded
                      : Icons.add_rounded,
                  color: ZennytGamePalette.success,
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
  });

  final String name;
  final List<int> discs;
  final int maxDiscs;
  final bool selected;
  final bool destination;
  final bool disabled;
  final VoidCallback onTap;

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
                  // Keep the whole stack inside the rod height; discs shrink as
                  // the level adds more of them so 5 discs still fit cleanly.
                  const rodHeight = 170.0;
                  final discHeight =
                      (rodHeight / maxDiscs).clamp(20.0, 32.0).toDouble();
                  final gap = discHeight;

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
                            color: Colors.white.withValues(alpha: 0.6),
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
                            color: Colors.white.withValues(alpha: 0.75),
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
              'TOWER $name',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
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
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _colors[disc],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$disc',
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
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
    final failed = move.failed || !move.isValidAtPlanning;
    final color = failed
        ? ZennytGamePalette.error.withValues(alpha: 0.65)
        : move.executed
        ? ZennytGamePalette.success
        : ZennytGamePalette.cyan.withValues(alpha: 0.8);
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
        color: _Disc._colors[disc],
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
    final score = attempt?.score.normalized.round() ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
          ),
          Text(
            'Results',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          Text(
            busy ? 'Synchronizing score...' : 'Predictive Puzzle completed',
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
                  'Cognitive score',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '$score%',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 56,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  targetCompleted
                      ? 'All $totalLevels levels cleared successfully.'
                      : 'Cleared $levelsCleared/$totalLevels levels before a '
                            'plan broke on execution.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
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
                  label: 'Levels',
                  value: '$levelsCleared/$totalLevels',
                  valueColor: targetCompleted
                      ? ZennytGamePalette.success
                      : ZennytGamePalette.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(label: 'Time', value: elapsed),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Errors',
                  value: '$errors',
                  valueColor: errors == 0
                      ? ZennytGamePalette.success
                      : ZennytGamePalette.magenta,
                ),
              ),
            ],
          ),
          if ((session?.scoreBreakdown ?? const []).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            ScoreDetailPanel(lines: session!.scoreBreakdown),
          ],
          const SizedBox(height: AppSpacing.xxl),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Text(
              'The player predicts the complete chain of moves before acting, then observes whether the planned sequence survives execution constraints.',
              style: AppTypography.bodyLarge.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: GamePrimaryButton(label: 'Replay', onPressed: onReplay),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: GameOutlineButton(
                  label: 'Compare',
                  onPressed: onCompare,
                ),
              ),
            ],
          ),
        ],
      ),
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
                  'Comparative Results',
                  style: AppTypography.headlineLarge.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Optimal sequence benchmark',
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
                    'against the optimal $optimalMoves-step plan',
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
              ResultStatTile(label: 'Planned', value: '$moves'),
              const ResultStatTile(label: 'Optimal', value: '15'),
              ResultStatTile(label: 'Surplus', value: '$surplus'),
              ResultStatTile(
                label: 'Level',
                value: session?.lastAttempt?.score.level ?? '-',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Text(
              'Retries: $retries. Sequence errors: $errors. Replay to reduce surplus moves and keep every planned step legal.',
              style: AppTypography.bodyMedium.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePrimaryButton(
            label: 'Replay to improve ranking',
            onPressed: onReplay,
          ),
        ],
      ),
    );
  }
}

class _PredictivePauseDialog extends StatefulWidget {
  const _PredictivePauseDialog({
    required this.elapsed,
    required this.errors,
    required this.onViewRules,
    required this.onExit,
  });

  final int elapsed;
  final int errors;
  final VoidCallback onViewRules;
  final VoidCallback onExit;

  @override
  State<_PredictivePauseDialog> createState() => _PredictivePauseDialogState();
}

class _PredictivePauseDialogState extends State<_PredictivePauseDialog> {
  bool sound = true;
  bool music = false;

  @override
  Widget build(BuildContext context) {
    final time =
        '${(widget.elapsed ~/ 60).toString().padLeft(2, '0')}:${(widget.elapsed % 60).toString().padLeft(2, '0')}';
    return Dialog(
      backgroundColor: const Color(0xFF121A46),
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xxl),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pause',
                style: AppTypography.displayMedium.copyWith(
                  color: ZennytGamePalette.blue,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PauseStat(label: 'Time', value: time),
                  Container(
                    width: 1,
                    height: 42,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    color: ZennytGamePalette.gameBlue,
                  ),
                  _PauseStat(
                    label: 'Errors',
                    value: '${widget.errors}/3',
                    color: ZennytGamePalette.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Audio options',
                style: AppTypography.titleMedium.copyWith(
                  color: ZennytGamePalette.blue,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PauseSwitchTile(
                label: 'Sound effects',
                value: sound,
                onChanged: (v) => setState(() => sound = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PauseSwitchTile(
                label: 'Music',
                value: music,
                onChanged: (v) => setState(() => music = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              GamePrimaryButton(
                label: 'Resume',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.sm),
              GameOutlineButton(
                label: 'View rules',
                onPressed: widget.onViewRules,
              ),
              const SizedBox(height: AppSpacing.sm),
              GameOutlineButton(
                label: 'Exit mission',
                color: ZennytGamePalette.error,
                onPressed: widget.onExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseStat extends StatelessWidget {
  const _PauseStat({
    required this.label,
    required this.value,
    this.color = ZennytGamePalette.magenta,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.blue,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PauseSwitchTile extends StatelessWidget {
  const _PauseSwitchTile({
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
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

class _IntroMeta extends StatelessWidget {
  const _IntroMeta({
    required this.label,
    required this.value,
    this.valueColor = ZennytGamePalette.blue,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: ZennytGamePalette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: ZennytGamePalette.muted,
              fontSize: 10,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: valueColor,
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SequencePreviewArt extends StatelessWidget {
  const _SequencePreviewArt();

  @override
  Widget build(BuildContext context) {
    const moves = ['A->C', 'A->B', 'C->B', 'A->C'];
    const dotColors = [
      Color(0xFF22C55E),
      Color(0xFFF5C518),
      Color(0xFF22C55E),
      Color(0xFF2F6BFF),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < moves.length; i++) ...[
          _PreviewMove(index: i + 1, label: moves[i], dotColor: dotColors[i]),
          const SizedBox(height: 8),
        ],
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Text(
                '5',
                style: AppTypography.labelSmall.copyWith(color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.question_mark_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'plan next',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Text(
                '+ add',
                style: AppTypography.labelSmall.copyWith(
                  color: ZennytGamePalette.cyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Sophie's planned sequence.",
          style: AppTypography.bodyMedium.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PreviewMove extends StatelessWidget {
  const _PreviewMove({
    required this.index,
    required this.label,
    required this.dotColor,
  });

  final int index;
  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: ZennytGamePalette.cyan.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Text(
            '$index',
            style: AppTypography.labelSmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label.replaceAll('->', '→'),
            style: AppTypography.labelMedium.copyWith(
              color: ZennytGamePalette.blue,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const Spacer(),
          Text(
            'planned',
            style: AppTypography.labelSmall.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
