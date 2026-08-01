import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../../navigation/presentation/widgets/app_bottom_nav.dart';
import '../../data/continuous_attention_scoring.dart';
import '../../domain/config/continuous_attention_config.dart';
import '../../domain/entities/continuous_attention_metrics.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../games_providers.dart';
import '../widgets/continuous_attention_pause_dialog.dart';
import '../widgets/game_system_components.dart';

const _navy = Color(0xFF28234F);
const _indigo = Color(0xFF5146E8);
const _cyan = Color(0xFF087F91);
const _magenta = Color(0xFFD72C83);
const _muted = Color(0xFF607091);
const _border = Color(0xFFDCE5F5);
const _canvas = Color(0xFFF7F9FE);
const _logoAsset = 'assets/games icons/Je Continue.png';

/// Tempo lent réservé au raccourci de test manuel (`kDebugMode`). Les lettres
/// restent affichées bien plus longtemps pour être confortables à jouer et le
/// repos est ramené à quelques secondes. Ne modifie jamais le protocole validé.
const _quickTestTempo = ContinuousAttentionTempo(
  stimulusDuration: Duration(milliseconds: 1200),
  interStimulusDuration: Duration(milliseconds: 400),
  scheduledRestDuration: Duration(seconds: 3),
);

/// Nombre d'essais joués par phase en mode test rapide (jamais soumis).
const _quickTestTrialsPerPhase = 6;

/// TEMPORAIRE — mode rapide (lent + court) activé pour toutes les parties le
/// temps des tests manuels. Repasser à `false` rétablit le protocole complet.
const _quickModeForAllPlays = true;

enum _AttentionStage {
  cover,
  format,
  xTutorial,
  loading,
  playing,
  xTestReady,
  rest,
  axTutorial,
  axTestReady,
  submitting,
  results,
  insights,
  interrupted,
  error,
}

/// Horloge monotone injectable : la production utilise [Stopwatch], tandis
/// que les tests peuvent fournir une horloge virtuelle.
abstract interface class ContinuousAttentionClock {
  int get elapsedMicroseconds;
  bool get isRunning;
  void start();
  void stop();
  void reset();
}

class StopwatchContinuousAttentionClock implements ContinuousAttentionClock {
  StopwatchContinuousAttentionClock() : _stopwatch = Stopwatch();

  final Stopwatch _stopwatch;

  @override
  int get elapsedMicroseconds => _stopwatch.elapsedMicroseconds;

  @override
  bool get isRunning => _stopwatch.isRunning;

  @override
  void reset() => _stopwatch.reset();

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();
}

ContinuousAttentionClock _productionClockFactory() =>
    StopwatchContinuousAttentionClock();

/// Parcours complet « Je continue ».
///
/// La production conserve toujours 44 blocs × 31 stimuli et le tempo
/// 690 ms + 230 ms. Seuls l'horloge et le tempo sont injectables pour les
/// tests de widgets ; les séquences et métriques restent contract-first.
class ContinuousAttentionScreen extends ConsumerStatefulWidget {
  const ContinuousAttentionScreen({
    super.key,
    this.tempo = ContinuousAttentionTempo.production,
    this.clockFactory = _productionClockFactory,
    this.quickRun = _quickModeForAllPlays,
  });

  final ContinuousAttentionTempo tempo;
  final ContinuousAttentionClock Function() clockFactory;

  /// Mode rapide (lent + court, jamais soumis) : par défaut la valeur de
  /// [_quickModeForAllPlays]. Les tests forcent `false` pour dérouler le
  /// protocole complet.
  final bool quickRun;

  @override
  ConsumerState<ContinuousAttentionScreen> createState() =>
      _ContinuousAttentionScreenState();
}

class _ContinuousAttentionScreenState
    extends ConsumerState<ContinuousAttentionScreen>
    with WidgetsBindingObserver {
  _AttentionStage _stage = _AttentionStage.cover;
  GameSession? _session;
  List<ContinuousAttentionBlockSequence> _sequence = const [];
  final List<ContinuousAttentionBlockMetric> _completedBlocks = [];

  /// Raccourci de test manuel : tempo lent + une poignée d'essais par phase,
  /// jamais soumis au dépôt. Activable uniquement en build de debug.
  bool _quickRun = false;

  ContinuousAttentionPhase? _activePhase;
  List<ContinuousAttentionBlockSequence> _activePhaseBlocks = const [];
  List<_TrialReference> _phaseTrials = const [];
  Map<int, List<ContinuousAttentionTrialMetric>> _workingTrials = {};
  int _trialCursor = 0;
  _TrialDraft? _draft;
  ContinuousAttentionClock? _phaseClock;
  Timer? _timelineTimer;
  bool _stimulusVisible = false;
  String? _practiceFeedback;
  int _droppedFrameCount = 0;
  final Map<ContinuousAttentionPhase, int> _droppedFramesBeforePhase = {};
  String? _interruptionReason;

  Timer? _restTimer;
  ContinuousAttentionClock? _restClock;
  Duration _restRemaining =
      ContinuousAttentionTempo.production.scheduledRestDuration;

  bool _submitting = false;
  String? _errorMessage;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Tempo effectif : le raccourci de test manuel remplace le tempo injecté
  /// sans jamais toucher aux constantes de production.
  ContinuousAttentionTempo get _tempo =>
      _quickRun ? _quickTestTempo : widget.tempo;

  int get _cycleUs => _tempo.trialDuration.inMicroseconds;
  int get _stimulusUs => _tempo.stimulusDuration.inMicroseconds;

  /// Nombre d'essais réellement joués dans un bloc : intégral en production,
  /// plafonné en test rapide.
  int _playableTrialCount(int blockTrialCount) {
    if (!_quickRun) return blockTrialCount;
    return blockTrialCount < _quickTestTrialsPerPhase
        ? blockTrialCount
        : _quickTestTrialsPerPhase;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timelineTimer?.cancel();
    _restTimer?.cancel();
    _phaseClock?.stop();
    _restClock?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    final phase = _activePhase;
    if (_stage == _AttentionStage.playing && phase != null) {
      _interruptActivePhase(
        phase.isTest
            ? 'The app left the active screen during a measured round.'
            : 'Practice was interrupted when the app left the active screen.',
      );
    }
  }

  void _selectMainTab(int index) {
    ref.read(navTabProvider.notifier).select(index);
    context.go(AppRoutes.home);
  }

  void _setStage(_AttentionStage stage) {
    if (!mounted) return;
    setState(() => _stage = stage);
  }

  Future<void> _startJourney() async {
    setState(() {
      _quickRun = widget.quickRun;
      _stage = _AttentionStage.loading;
      _errorMessage = null;
      _submitting = false;
    });
    try {
      final session = await ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.continuousAttention);
      if (!mounted) return;
      _session = session;
      _sequence = ContinuousAttentionConfig.generateSequence(session.id);
      _completedBlocks.clear();
      _droppedFrameCount = 0;
      _droppedFramesBeforePhase.clear();
      _beginPhase(ContinuousAttentionPhase.xPractice);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _stage = _AttentionStage.error;
      });
    }
  }

  void _beginPhase(ContinuousAttentionPhase phase) {
    _timelineTimer?.cancel();
    _phaseClock?.stop();
    _completedBlocks.removeWhere((block) => block.phase == phase);
    final previousDroppedCount = _droppedFramesBeforePhase[phase];
    if (previousDroppedCount == null) {
      _droppedFramesBeforePhase[phase] = _droppedFrameCount;
    } else {
      // Un restart exclut les frames du run abandonné.
      _droppedFrameCount = previousDroppedCount;
    }

    final phaseBlocks = _sequence
        .where((block) => block.phase == phase)
        .toList();
    // En test rapide on ne joue que le premier bloc, tronqué à quelques essais.
    final blocks = _quickRun ? phaseBlocks.take(1).toList() : phaseBlocks;
    _activePhaseBlocks = blocks;
    _activePhase = phase;
    _phaseTrials = [
      for (final block in blocks)
        for (
          var trial = 0;
          trial < _playableTrialCount(block.trials.length);
          trial++
        )
          _TrialReference(
            blockIndex: block.blockIndex,
            trialIndex: trial + 1,
            stimulus: block.trials[trial],
          ),
    ];
    _workingTrials = {
      for (final block in blocks)
        block.blockIndex: <ContinuousAttentionTrialMetric>[],
    };
    _trialCursor = 0;
    _draft = null;
    _stimulusVisible = false;
    _practiceFeedback = null;
    _interruptionReason = null;
    _phaseClock = widget.clockFactory()
      ..reset()
      ..start();
    setState(() => _stage = _AttentionStage.playing);
    _scheduleAt(0, _showCurrentStimulus, countLateFrame: false);
  }

  void _scheduleAt(
    int targetUs,
    VoidCallback callback, {
    bool countLateFrame = true,
  }) {
    _timelineTimer?.cancel();
    final clock = _phaseClock;
    if (clock == null || !clock.isRunning) return;
    final remainingUs = targetUs - clock.elapsedMicroseconds;
    if (remainingUs <= 0) {
      if (countLateFrame &&
          -remainingUs > const Duration(milliseconds: 17).inMicroseconds) {
        _droppedFrameCount++;
      }
      _timelineTimer = Timer(Duration.zero, callback);
      return;
    }
    _timelineTimer = Timer(Duration(microseconds: remainingUs), callback);
  }

  void _showCurrentStimulus() {
    if (!mounted ||
        _stage != _AttentionStage.playing ||
        _trialCursor >= _phaseTrials.length) {
      return;
    }
    final clock = _phaseClock!;
    final reference = _phaseTrials[_trialCursor];
    final actualOnsetMs = clock.elapsedMicroseconds ~/ 1000;
    _finalizePreviousTrial(actualOnsetMs);

    _draft = _TrialDraft(
      reference: reference,
      scheduledOnsetMs: (_trialCursor * _cycleUs) ~/ 1000,
      actualOnsetMs: actualOnsetMs,
    );
    setState(() {
      _stimulusVisible = true;
      _practiceFeedback = null;
    });
    _scheduleAt((_trialCursor * _cycleUs) + _stimulusUs, _hideCurrentStimulus);
  }

  void _hideCurrentStimulus() {
    if (!mounted || _stage != _AttentionStage.playing) return;
    final draft = _draft;
    final clock = _phaseClock;
    if (draft == null || clock == null) return;
    draft.displayEndedAtMs = clock.elapsedMicroseconds ~/ 1000;

    final phase = _activePhase!;
    setState(() {
      _stimulusVisible = false;
      _practiceFeedback = phase.isPractice ? _practiceFeedbackFor(draft) : null;
    });
    _scheduleAt((_trialCursor + 1) * _cycleUs, _advanceAfterIsi);
  }

  void _advanceAfterIsi() {
    if (!mounted || _stage != _AttentionStage.playing) return;
    final nowMs = _phaseClock!.elapsedMicroseconds ~/ 1000;
    _finalizePreviousTrial(nowMs);
    _trialCursor++;
    if (_trialCursor >= _phaseTrials.length) {
      _completePhase();
      return;
    }
    _showCurrentStimulus();
  }

  void _finalizePreviousTrial(int nextOnsetMs) {
    final draft = _draft;
    if (draft == null || draft.recorded) return;
    final displayEnd = draft.displayEndedAtMs;
    if (displayEnd == null) return;
    final metric = draft.toMetric(
      actualIsiDurationMs: (nextOnsetMs - displayEnd).clamp(0, 1 << 31),
    );
    _workingTrials[draft.reference.blockIndex]!.add(metric);
    draft.recorded = true;
  }

  void _registerResponse(ContinuousAttentionInputSource source) {
    if (_stage != _AttentionStage.playing || !_stimulusVisible) return;
    final draft = _draft;
    final clock = _phaseClock;
    if (draft == null || clock == null) return;
    final responseTimestampMs = clock.elapsedMicroseconds ~/ 1000;
    final latencyMs = responseTimestampMs - draft.actualOnsetMs;
    if (!ContinuousAttentionConfig.acceptsResponseLatencyMs(latencyMs)) {
      // Toute réponse durant l'ISI est ignorée et n'est jamais reportée.
      return;
    }
    if (draft.responseTimestampMs != null) {
      draft.extraResponseCount++;
      return;
    }
    draft
      ..responseTimestampMs = responseTimestampMs
      ..latencyMs = latencyMs
      ..inputSource = source;
    setState(() {});
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _registerResponse(ContinuousAttentionInputSource.keyboard);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _practiceFeedbackFor(_TrialDraft draft) {
    final responded = draft.responseTimestampMs != null;
    if (draft.reference.stimulus.isTarget) {
      return responded ? 'Target captured' : 'Target missed';
    }
    return responded ? 'Wait for the target' : 'Good — keep watching';
  }

  void _completePhase() {
    final phase = _activePhase!;
    _timelineTimer?.cancel();
    _phaseClock?.stop();
    for (final source in _activePhaseBlocks) {
      _completedBlocks.add(
        ContinuousAttentionBlockMetric(
          phase: phase,
          blockIndex: source.blockIndex,
          trials: List.unmodifiable(_workingTrials[source.blockIndex]!),
        ),
      );
    }
    _activePhase = null;
    _activePhaseBlocks = const [];
    _phaseTrials = const [];
    _workingTrials = {};
    _draft = null;
    _stimulusVisible = false;
    _practiceFeedback = null;

    switch (phase) {
      case ContinuousAttentionPhase.xPractice:
        _setStage(_AttentionStage.xTestReady);
      case ContinuousAttentionPhase.xTest:
        _startRest();
      case ContinuousAttentionPhase.axPractice:
        _setStage(_AttentionStage.axTestReady);
      case ContinuousAttentionPhase.axTest:
        if (_quickRun) {
          _finishQuickRun();
        } else {
          unawaited(_submitCompletedJourney());
        }
    }
  }

  /// Termine un run de test rapide : la séquence tronquée n'est jamais soumise
  /// au dépôt, mais on la score localement (structure relâchée) pour afficher
  /// le vrai écran de résultats, comme les autres jeux.
  void _finishQuickRun() {
    final session = _session;
    if (!mounted || session == null) return;
    final orderedBlocks = [
      for (final phase in ContinuousAttentionPhase.values)
        ..._completedBlocks.where((block) => block.phase == phase).toList()
          ..sort((a, b) => a.blockIndex.compareTo(b.blockIndex)),
    ];
    final result = const ContinuousAttentionScoring().score(
      sessionId: session.id,
      metrics: ContinuousAttentionMetrics(
        blocks: List.unmodifiable(orderedBlocks),
        sessionCompleted: true,
        interrupted: false,
        backgroundEventCount: 0,
        droppedFrameCount: _droppedFrameCount,
      ),
      enforceStructure: false,
    );
    setState(() {
      _session = GameSession(
        id: session.id,
        gameType: session.gameType,
        status: 'COMPLETED',
        compositeRaw: session.compositeRaw,
        compositeMax: session.compositeMax,
        normalized: session.normalized,
        attempts: session.attempts,
        startedAt: session.startedAt,
        completedAt: DateTime.now(),
        scoreBreakdown: session.scoreBreakdown,
        reflectivePauseIndicators: session.reflectivePauseIndicators,
        continuousAttentionIndicators: result.indicators,
      );
      _stage = _AttentionStage.results;
    });
  }

  void _startRest() {
    _restTimer?.cancel();
    _restClock?.stop();
    _restClock = widget.clockFactory()
      ..reset()
      ..start();
    _restRemaining = _tempo.scheduledRestDuration;
    setState(() => _stage = _AttentionStage.rest);
    _restTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _stage != _AttentionStage.rest) return;
      final remaining =
          _tempo.scheduledRestDuration -
          Duration(microseconds: _restClock!.elapsedMicroseconds);
      if (remaining <= Duration.zero) {
        _restTimer?.cancel();
        _restClock?.stop();
        setState(() => _restRemaining = Duration.zero);
      } else {
        setState(() => _restRemaining = remaining);
      }
    });
  }

  Future<void> _submitCompletedJourney() async {
    final session = _session;
    if (session == null || _submitting) return;
    setState(() {
      _submitting = true;
      _stage = _AttentionStage.submitting;
    });
    try {
      final orderedBlocks = [
        for (final phase in ContinuousAttentionPhase.values)
          ..._completedBlocks.where((block) => block.phase == phase).toList()
            ..sort((a, b) => a.blockIndex.compareTo(b.blockIndex)),
      ];
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.continuousAttentionCore,
            metrics: ContinuousAttentionMetrics(
              blocks: List.unmodifiable(orderedBlocks),
              sessionCompleted: true,
              interrupted: false,
              backgroundEventCount: 0,
              droppedFrameCount: _droppedFrameCount,
            ),
          );
      if (!mounted) return;
      final indicators = updated.continuousAttentionIndicators;
      if (indicators == null || !indicators.sessionValid) {
        setState(() {
          _session = updated;
          _submitting = false;
          _interruptionReason =
              'The technical timing check could not validate this journey.';
          _stage = _AttentionStage.interrupted;
        });
        return;
      }
      setState(() {
        _session = updated;
        _submitting = false;
        _stage = _AttentionStage.results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = '$error';
        _stage = _AttentionStage.error;
      });
    }
  }

  void _interruptActivePhase(String reason) {
    final phase = _activePhase;
    if (_stage != _AttentionStage.playing || phase == null) return;
    _timelineTimer?.cancel();
    _phaseClock?.stop();
    _completedBlocks.removeWhere((block) => block.phase == phase);
    setState(() {
      _interruptionReason = reason;
      _stimulusVisible = false;
      _practiceFeedback = null;
      _stage = _AttentionStage.interrupted;
    });
  }

  void _restartInterruptedPhase() {
    final phase = _activePhase;
    if (phase != null) {
      _beginPhase(phase);
      return;
    }
    _retryAuditedJourney();
  }

  void _retryAuditedJourney() {
    final session = _session;
    if (session == null) {
      _restartJourney();
      return;
    }
    _timelineTimer?.cancel();
    _restTimer?.cancel();
    _phaseClock?.stop();
    _restClock?.stop();
    _sequence = ContinuousAttentionConfig.generateSequence(session.id);
    _completedBlocks.clear();
    _activePhase = null;
    _droppedFrameCount = 0;
    _droppedFramesBeforePhase.clear();
    _interruptionReason = null;
    _submitting = false;
    _errorMessage = null;
    _beginPhase(ContinuousAttentionPhase.xPractice);
  }

  void _restartJourney() {
    _timelineTimer?.cancel();
    _restTimer?.cancel();
    _phaseClock?.stop();
    _restClock?.stop();
    _session = null;
    _sequence = const [];
    _completedBlocks.clear();
    _activePhase = null;
    _droppedFrameCount = 0;
    _droppedFramesBeforePhase.clear();
    _interruptionReason = null;
    _setStage(_AttentionStage.xTutorial);
  }

  Future<void> _openPause() async {
    final phase = _activePhase;
    final measured = _stage == _AttentionStage.playing && phase?.isTest == true;
    if (measured) {
      _interruptActivePhase('Pause requested during a measured phase.');
    } else if (_stage == _AttentionStage.playing) {
      _timelineTimer?.cancel();
      _phaseClock?.stop();
    }

    ContinuousAttentionPauseAction? action;
    do {
      if (!mounted) return;
      action = await showDialog<ContinuousAttentionPauseAction>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xCC1B1B4B),
        builder: (_) => ContinuousAttentionPauseDialog(
          restartRequired: measured,
          canRestartPhase: phase != null,
        ),
      );
      if (action == ContinuousAttentionPauseAction.rules && mounted) {
        await _showRules(phase);
      }
    } while (action == ContinuousAttentionPauseAction.rules && mounted);

    if (!mounted) return;
    switch (action) {
      case ContinuousAttentionPauseAction.resume:
        _resumePracticeTimeline();
      case ContinuousAttentionPauseAction.restartPhase:
        if (phase != null) _beginPhase(phase);
      case ContinuousAttentionPauseAction.exit:
        context.go(AppRoutes.games);
      case ContinuousAttentionPauseAction.rules || null:
        break;
    }
  }

  void _resumePracticeTimeline() {
    if (_stage != _AttentionStage.playing || _activePhase?.isPractice != true) {
      return;
    }
    final clock = _phaseClock;
    if (clock == null) return;
    clock.start();
    if (_stimulusVisible) {
      _scheduleAt(
        (_trialCursor * _cycleUs) + _stimulusUs,
        _hideCurrentStimulus,
      );
    } else {
      _scheduleAt((_trialCursor + 1) * _cycleUs, _advanceAfterIsi);
    }
    setState(() {});
  }

  Future<void> _showRules([ContinuousAttentionPhase? phase]) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC1B1B4B),
      builder: (_) => _RulesDialog(phase: phase),
    );
  }

  void _back() {
    switch (_stage) {
      case _AttentionStage.cover:
        context.go(AppRoutes.games);
      case _AttentionStage.format:
        _setStage(_AttentionStage.cover);
      case _AttentionStage.xTutorial:
        _setStage(_AttentionStage.format);
      case _AttentionStage.axTutorial:
        _setStage(_AttentionStage.rest);
      case _AttentionStage.results:
        context.go(AppRoutes.games);
      case _AttentionStage.insights:
        _setStage(_AttentionStage.results);
      case _AttentionStage.error:
        _setStage(_AttentionStage.cover);
      case _AttentionStage.playing:
        unawaited(_openPause());
      case _AttentionStage.loading ||
          _AttentionStage.xTestReady ||
          _AttentionStage.rest ||
          _AttentionStage.axTestReady ||
          _AttentionStage.submitting ||
          _AttentionStage.interrupted:
        context.go(AppRoutes.games);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNav =
        _stage == _AttentionStage.cover ||
        _stage == _AttentionStage.format ||
        _stage == _AttentionStage.xTutorial;
    return Scaffold(
      backgroundColor: _stage == _AttentionStage.playing
          ? ZennytGamePalette.gameBlue
          : Colors.white,
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(selectedTab: 2, onSelect: _selectMainTab)
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: _reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: switch (_stage) {
            _AttentionStage.cover => _CoverView(
              key: const ValueKey('continuous-cover'),
              onBack: _back,
              onRules: _showRules,
              onStart: () => _setStage(_AttentionStage.format),
            ),
            _AttentionStage.format => _FormatView(
              key: const ValueKey('continuous-format'),
              onBack: _back,
              onContinue: () => _setStage(_AttentionStage.xTutorial),
            ),
            _AttentionStage.xTutorial => _TutorialView(
              key: const ValueKey('continuous-x-tutorial'),
              family: _TutorialFamily.x,
              onBack: _back,
              onStart: _startJourney,
            ),
            _AttentionStage.loading => const _LoadingView(
              key: ValueKey('continuous-loading'),
              label: 'Preparing your focus stream…',
            ),
            _AttentionStage.playing => Focus(
              // La clé reste stable pendant toute la phase : seul le stimulus
              // au centre apparaît/disparaît. Inclure le curseur d'essai
              // relançait la transition de l'AnimatedSwitcher à chaque lettre,
              // faisant clignoter tout l'écran.
              key: ValueKey('continuous-playing-${_activePhase?.wire}'),
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: _GameplayView(
                phase: _activePhase!,
                reference: _phaseTrials[_trialCursor],
                phaseTrialIndex: _trialCursor,
                phaseTrialCount: _phaseTrials.length,
                stimulusVisible: _stimulusVisible,
                practiceFeedback: _practiceFeedback,
                onRespond: () =>
                    _registerResponse(ContinuousAttentionInputSource.touch),
                onPause: _openPause,
              ),
            ),
            _AttentionStage.xTestReady => _ReadyView(
              key: const ValueKey('continuous-x-test-ready'),
              title: 'Practice complete',
              subtitle:
                  'The measured focus stream starts now. Keep the same calm rhythm.',
              accent: _cyan,
              rule: 'Respond whenever X appears.',
              buttonLabel: 'Start focused round',
              onStart: () => _beginPhase(ContinuousAttentionPhase.xTest),
              onBack: _back,
            ),
            _AttentionStage.rest => _RestView(
              key: const ValueKey('continuous-rest'),
              remaining: _restRemaining,
              onBack: _back,
              onContinue: _restRemaining == Duration.zero
                  ? () => _setStage(_AttentionStage.axTutorial)
                  : null,
            ),
            _AttentionStage.axTutorial => _TutorialView(
              key: const ValueKey('continuous-ax-tutorial'),
              family: _TutorialFamily.ax,
              onBack: _back,
              onStart: () => _beginPhase(ContinuousAttentionPhase.axPractice),
            ),
            _AttentionStage.axTestReady => _ReadyView(
              key: const ValueKey('continuous-ax-test-ready'),
              title: 'Second practice complete',
              subtitle:
                  'The final focus stream starts now. Watch the sequence, not a single letter.',
              accent: _magenta,
              rule: 'Respond only when X follows A.',
              buttonLabel: 'Start final round',
              onStart: () => _beginPhase(ContinuousAttentionPhase.axTest),
              onBack: _back,
            ),
            _AttentionStage.submitting => const _LoadingView(
              key: ValueKey('continuous-submitting'),
              label: 'Saving your focus journey…',
            ),
            _AttentionStage.results => _ResultsView(
              key: const ValueKey('continuous-results'),
              session: _session!,
              onBack: _back,
              onInsights: () => _setStage(_AttentionStage.insights),
            ),
            _AttentionStage.insights => _InsightsView(
              key: const ValueKey('continuous-insights'),
              session: _session!,
              onBack: _back,
              onFinish: () => context.go(AppRoutes.games),
            ),
            _AttentionStage.interrupted => _InterruptedView(
              key: const ValueKey('continuous-interrupted'),
              reason:
                  _interruptionReason ??
                  'This phase was interrupted before it finished.',
              fullJourney: _activePhase == null,
              onRules: () => _showRules(_activePhase),
              onRestart: _restartInterruptedPhase,
              onExit: () => context.go(AppRoutes.games),
            ),
            _AttentionStage.error => _ErrorView(
              key: const ValueKey('continuous-error'),
              message: _errorMessage ?? 'An unexpected error occurred.',
              onBack: _back,
              onRetry: _restartJourney,
            ),
          },
        ),
      ),
    );
  }
}

class _TrialReference {
  const _TrialReference({
    required this.blockIndex,
    required this.trialIndex,
    required this.stimulus,
  });

  final int blockIndex;
  final int trialIndex;
  final ContinuousAttentionStimulus stimulus;
}

class _TrialDraft {
  _TrialDraft({
    required this.reference,
    required this.scheduledOnsetMs,
    required this.actualOnsetMs,
  });

  final _TrialReference reference;
  final int scheduledOnsetMs;
  final int actualOnsetMs;
  int? responseTimestampMs;
  int? latencyMs;
  int? displayEndedAtMs;
  ContinuousAttentionInputSource? inputSource;
  int extraResponseCount = 0;
  bool recorded = false;

  ContinuousAttentionTrialMetric toMetric({required int actualIsiDurationMs}) {
    final responded = responseTimestampMs != null;
    return ContinuousAttentionTrialMetric(
      trialIndex: reference.trialIndex,
      previousLetter: reference.stimulus.previousLetter,
      currentLetter: reference.stimulus.currentLetter,
      responseCode: responded ? 57 : 0,
      correct: reference.stimulus.isTarget == responded ? 1 : 0,
      latencyMs: latencyMs,
      scheduledOnsetMs: scheduledOnsetMs,
      actualOnsetMs: actualOnsetMs,
      responseTimestampMs: responseTimestampMs,
      actualDisplayDurationMs: (displayEndedAtMs! - actualOnsetMs).clamp(
        0,
        1 << 31,
      ),
      actualIsiDurationMs: actualIsiDurationMs,
      inputSource: inputSource,
      extraResponseCount: extraResponseCount,
      interrupted: false,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.title,
    this.eyebrow = 'Zennyt Games',
    this.onMore,
  });

  final VoidCallback onBack;
  final String title;
  final String eyebrow;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareButton(
          tooltip: 'Back',
          icon: Icons.chevron_left_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onMore != null) ...[
          const SizedBox(width: 12),
          _SquareButton(
            tooltip: 'Rules and help',
            icon: Icons.more_horiz_rounded,
            onTap: onMore!,
          ),
        ],
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.onDark = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  /// Variante posée sur le fond violet du gameplay : contours et icône clairs.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          foregroundColor: onDark ? Colors.white : _navy,
          side: BorderSide(
            color: onDark ? Colors.white.withValues(alpha: .45) : _border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 26),
      ),
    );
  }
}

class _CoverView extends StatelessWidget {
  const _CoverView({
    super.key,
    required this.onBack,
    required this.onRules,
    required this.onStart,
  });

  final VoidCallback onBack;
  final VoidCallback onRules;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            children: [
              _TopBar(
                onBack: onBack,
                title: 'Je continue',
                eyebrow: 'Focus journey',
                onMore: onRules,
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_indigo, Color(0xFF3830B8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x285146E8),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Je continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Stay with the stream.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Follow a steady sequence and respond only when the moment is right.',
                            style: TextStyle(
                              color: Color(0xFFE5E4FF),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      _logoAsset,
                      width: 132,
                      height: 132,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.all_inclusive_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _SummaryPanel(),
              const SizedBox(height: 18),
              const Text(
                'How it works',
                style: TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const _StepTile(
                number: 1,
                title: 'Watch one letter at a time',
                color: _indigo,
              ),
              const SizedBox(height: 9),
              const _StepTile(
                number: 2,
                title: 'Respond to the active pattern',
                color: _cyan,
              ),
              const SizedBox(height: 9),
              const _StepTile(
                number: 3,
                title: 'Keep a calm, steady rhythm',
                color: _magenta,
              ),
              const SizedBox(height: 18),
              const _PrivacyNote(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              GameOutlineButton(
                label: 'View rules',
                icon: Icons.help_outline_rounded,
                onPressed: onRules,
              ),
              const SizedBox(height: 10),
              GamePrimaryButton(
                key: const ValueKey('continuous-start-journey'),
                label: 'Start the journey',
                onPressed: onStart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel();

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: const Column(
        children: [
          _SummaryRow(label: 'Goal', value: 'Sustained, selective focus'),
          Divider(color: _border, height: 18),
          _SummaryRow(label: 'Duration', value: 'About 25 minutes'),
          Divider(color: _border, height: 18),
          _SummaryRow(label: 'Format', value: '2 rounds + guided practice'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.color,
  });

  final int number;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2CDE0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: _magenta, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your individual responses stay private.',
              style: TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatView extends StatelessWidget {
  const _FormatView({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _InfoShell(
      topBar: _TopBar(onBack: onBack, title: 'Journey format'),
      title: 'A steady focus journey',
      subtitle:
          'The rhythm stays simple on purpose. Mental fatigue is part of the effort, so plan a quiet 25-minute window.',
      illustration: const _StreamIllustration(),
      buttonLabel: 'Learn the first rule',
      onButton: onContinue,
      children: const [
        _DetailCard(
          icon: Icons.looks_one_rounded,
          color: _cyan,
          title: 'First round',
          description: 'Respond to one target letter.',
        ),
        _DetailCard(
          icon: Icons.coffee_rounded,
          color: _indigo,
          title: 'Scheduled recovery',
          description: 'A calm two-minute break separates the rounds.',
        ),
        _DetailCard(
          icon: Icons.looks_two_rounded,
          color: _magenta,
          title: 'Second round',
          description: 'Respond to a target sequence of two letters.',
        ),
        _PrivacyNote(),
      ],
    );
  }
}

enum _TutorialFamily { x, ax }

class _TutorialView extends StatelessWidget {
  const _TutorialView({
    super.key,
    required this.family,
    required this.onBack,
    required this.onStart,
  });

  final _TutorialFamily family;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ax = family == _TutorialFamily.ax;
    return _InfoShell(
      topBar: _TopBar(onBack: onBack, title: ax ? 'Second rule' : 'First rule'),
      title: ax ? 'Watch for A, then X' : 'Respond whenever X appears',
      subtitle: ax
          ? 'Keep the previous letter in mind. Respond only when X comes immediately after A.'
          : 'Tap the response button — or press Space on a keyboard — whenever the current letter is X.',
      illustration: _RuleIllustration(ax: ax),
      footnote:
          'Two guided practice blocks come first. You can pause freely during practice.',
      buttonLabel: ax ? 'Start second practice' : 'Start practice',
      onButton: onStart,
      children: [
        _DetailCard(
          icon: Icons.visibility_outlined,
          color: _indigo,
          title: 'Watch the center',
          description: 'Each letter appears briefly, followed by a blank beat.',
        ),
        _DetailCard(
          icon: Icons.touch_app_outlined,
          color: ax ? _magenta : _cyan,
          title: ax ? 'Respond only to A → X' : 'Respond only to X',
          description:
              'A tap and the Space key mean the same thing. One response is enough.',
        ),
        const _DetailCard(
          icon: Icons.feedback_outlined,
          color: _magenta,
          title: 'Practice gives feedback',
          description:
              'The measured round stays neutral: no correct/wrong signal, score, sound or vibration.',
        ),
      ],
    );
  }
}

class _InfoShell extends StatelessWidget {
  const _InfoShell({
    required this.topBar,
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.children,
    required this.buttonLabel,
    required this.onButton,
    this.footnote,
  });

  final Widget topBar;
  final String title;
  final String subtitle;
  final Widget illustration;
  final List<Widget> children;
  final String? footnote;
  final String buttonLabel;
  final VoidCallback onButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            children: [
              topBar,
              const SizedBox(height: 28),
              illustration,
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 11),
              ],
              if (footnote != null) ...[
                const SizedBox(height: 18),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: GamePrimaryButton(label: buttonLabel, onPressed: onButton),
        ),
      ],
    );
  }
}

class _StreamIllustration extends StatelessWidget {
  const _StreamIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        _logoAsset,
        width: 168,
        height: 168,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.all_inclusive_rounded, color: _indigo, size: 96),
      ),
    );
  }
}

class _RuleIllustration extends StatelessWidget {
  const _RuleIllustration({required this.ax});

  final bool ax;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _canvas,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ax) ...[
              const _LetterCard(letter: 'A', borderColor: _cyan),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _indigo,
                  size: 30,
                ),
              ),
            ],
            _LetterCard(letter: 'X', borderColor: ax ? _magenta : _cyan),
          ],
        ),
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.letter, required this.borderColor});

  final String letter;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: _navy,
          fontSize: 48,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    required this.phase,
    required this.reference,
    required this.phaseTrialIndex,
    required this.phaseTrialCount,
    required this.stimulusVisible,
    required this.practiceFeedback,
    required this.onRespond,
    required this.onPause,
  });

  final ContinuousAttentionPhase phase;
  final _TrialReference reference;
  final int phaseTrialIndex;
  final int phaseTrialCount;
  final bool stimulusVisible;
  final String? practiceFeedback;
  final VoidCallback onRespond;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final totalBlocks = phase.isPractice
        ? ContinuousAttentionConfig.practiceBlocksPerFamily
        : ContinuousAttentionConfig.testBlocksPerFamily;
    final label = switch (phase) {
      ContinuousAttentionPhase.xPractice => 'First rule · Practice',
      ContinuousAttentionPhase.xTest => 'First focus round',
      ContinuousAttentionPhase.axPractice => 'Second rule · Practice',
      ContinuousAttentionPhase.axTest => 'Final focus round',
    };
    final rule = phase.isAx ? 'A → X' : 'X';
    final accent = phase.isAx ? _magenta : _cyan;

    return ColoredBox(
      color: ZennytGamePalette.gameBlue,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Block ${reference.blockIndex} / $totalBlocks',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .70),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .38),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .55),
                        ),
                      ),
                      child: Text(
                        rule,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SquareButton(
                      tooltip: phase.isTest
                          ? 'Pause and restart phase'
                          : 'Pause',
                      icon: Icons.pause_rounded,
                      onTap: onPause,
                      onDark: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: phaseTrialCount == 0
                        ? 0
                        : (phaseTrialIndex / phaseTrialCount).clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: .22),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Semantics(
                // Protocole visuel : ne pas déclencher une rafale VoiceOver
                // toutes les 920 ms. Une adaptation audio reste à valider
                // séparément comme décision produit.
                container: true,
                excludeSemantics: true,
                label: stimulusVisible
                    ? 'Letter ${reference.stimulus.currentLetter}'
                    : 'Blank interval',
                child: Container(
                  width: 246,
                  height: 286,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ZennytGamePalette.gamePanel,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33071333),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: stimulusVisible
                      ? Text(
                          reference.stimulus.currentLetter,
                          key: const ValueKey('continuous-stimulus-letter'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 112,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        )
                      : phase.isPractice && practiceFeedback != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            practiceFeedback!,
                            key: const ValueKey('continuous-practice-feedback'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  practiceFeedback!.contains('missed') ||
                                      practiceFeedback!.contains('Wait')
                                  ? const Color(0xFFFFC2DD)
                                  : const Color(0xFFB9F5E6),
                              fontSize: 18,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              children: [
                if (phase.isTest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'No correct or wrong feedback is shown in this round.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .70),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                // Le bouton reste identique d'un essai à l'autre pour ne pas
                // clignoter au rythme des lettres. Les appuis hors fenêtre de
                // réponse sont simplement ignorés par _registerResponse.
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    key: const ValueKey('continuous-response-button'),
                    onPressed: onRespond,
                    icon: const Icon(Icons.touch_app_rounded),
                    label: const Text('Tap or press Space'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ZennytGamePalette.gameBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.rule,
    required this.buttonLabel,
    required this.onStart,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String rule;
  final String buttonLabel;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _InfoShell(
      topBar: _TopBar(onBack: onBack, title: 'Ready'),
      title: title,
      subtitle: subtitle,
      illustration: Center(
        child: Container(
          width: 118,
          height: 118,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.track_changes_rounded, color: accent, size: 62),
        ),
      ),
      buttonLabel: buttonLabel,
      onButton: onStart,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent),
          ),
          child: Column(
            children: [
              const Text(
                'ACTIVE RULE',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                rule,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const _DetailCard(
          icon: Icons.do_not_disturb_on_outlined,
          color: _magenta,
          title: 'Stay on this screen',
          description:
              'A pause, interruption or app switch restarts this measured round from the beginning.',
        ),
        const _DetailCard(
          icon: Icons.notifications_off_outlined,
          color: _indigo,
          title: 'Protect your focus',
          description:
              'Silence notifications and keep the device stable before starting.',
        ),
      ],
    );
  }
}

class _RestView extends StatelessWidget {
  const _RestView({
    super.key,
    required this.remaining,
    required this.onBack,
    required this.onContinue,
  });

  final Duration remaining;
  final VoidCallback onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final minutesPart = seconds ~/ 60;
    final secondsPart = seconds % 60;
    final timer =
        '${minutesPart.toString().padLeft(2, '0')}:'
        '${secondsPart.toString().padLeft(2, '0')}';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            children: [
              _TopBar(onBack: onBack, title: 'Scheduled break'),
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 188,
                  height: 188,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: _indigo, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            onContinue == null
                                ? Icons.self_improvement_rounded
                                : Icons.check_circle_rounded,
                            color: onContinue == null ? _indigo : _cyan,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            timer,
                            key: const ValueKey('continuous-rest-timer'),
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                onContinue == null
                    ? 'Let your attention reset'
                    : 'Break complete',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Look away from the screen, relax your shoulders and breathe naturally. The next rule appears after the break.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 28),
              const _DetailCard(
                icon: Icons.visibility_off_outlined,
                color: _cyan,
                title: 'Rest your eyes',
                description:
                    'Choose a distant point instead of another screen.',
              ),
              const SizedBox(height: 11),
              const _DetailCard(
                icon: Icons.water_drop_outlined,
                color: _indigo,
                title: 'Stay nearby',
                description: 'You can take a sip of water and continue calmly.',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: GamePrimaryButton(
            label: onContinue == null
                ? 'Rest in progress'
                : 'Learn the second rule',
            onPressed: onContinue,
            color: onContinue == null ? _muted : _magenta,
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(color: _indigo, strokeWidth: 5),
            ),
            const SizedBox(height: 22),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.session,
    required this.onBack,
    required this.onInsights,
  });

  final GameSession session;
  final VoidCallback onBack;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    final report = session.continuousAttentionIndicators!;
    final score = report.provisionalAccuracyScore;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            children: [
              _TopBar(onBack: onBack, title: 'Journey complete'),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 154,
                  height: 154,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_indigo, Color(0xFF3730B3)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x305146E8),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 7),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            key: const ValueKey('continuous-result-score'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 49,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '/ 100',
                            style: TextStyle(
                              color: Color(0xFFE4E2FF),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Provisional accuracy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A descriptive summary of response accuracy across both focus rules.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 26),
              _PhaseResultCard(
                label: 'Single-letter rule',
                rule: 'X',
                color: _cyan,
                indicators: report.xPhase,
              ),
              const SizedBox(height: 14),
              _PhaseResultCard(
                label: 'Sequence rule',
                rule: 'A → X',
                color: _magenta,
                indicators: report.axPhase,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ResultStatTile(
                      label: 'Extra taps',
                      value: '${report.extraResponseCount}',
                      valueColor: _indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ResultStatTile(
                      label: 'Timing flags',
                      value: '${report.timingDeviationCount}',
                      valueColor: report.timingDeviationCount == 0
                          ? _cyan
                          : _magenta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _ResultDisclaimer(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: GamePrimaryButton(
            label: 'View descriptive insights',
            onPressed: onInsights,
          ),
        ),
      ],
    );
  }
}

class _PhaseResultCard extends StatelessWidget {
  const _PhaseResultCard({
    required this.label,
    required this.rule,
    required this.color,
    required this.indicators,
  });

  final String label;
  final String rule;
  final Color color;
  final ContinuousAttentionPhaseIndicators indicators;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rule,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${indicators.balancedAccuracyPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MetricLine(
            label: 'Target responses',
            value: '${indicators.hitRatePercent.toStringAsFixed(1)}%',
            color: color,
          ),
          const SizedBox(height: 12),
          _MetricLine(
            label: 'Non-target control',
            value:
                '${indicators.correctRejectionRatePercent.toStringAsFixed(1)}%',
            color: _indigo,
          ),
          const SizedBox(height: 12),
          _MetricLine(
            label: 'Average response time',
            value: indicators.averageHitReactionTimeMs == null
                ? '—'
                : '${indicators.averageHitReactionTimeMs!.round()} ms',
            color: _navy,
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ResultDisclaimer extends StatelessWidget {
  const _ResultDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _indigo, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This provisional result is descriptive only. It is not a diagnosis, percentile, ranking or clinical interpretation.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({
    super.key,
    required this.session,
    required this.onBack,
    required this.onFinish,
  });

  final GameSession session;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final report = session.continuousAttentionIndicators!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            children: [
              _TopBar(onBack: onBack, title: 'Descriptive insights'),
              const SizedBox(height: 26),
              const Text(
                'Read the signals, not a label',
                style: TextStyle(
                  color: _navy,
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'These measures describe what happened during this journey. They do not define your ability.',
                style: TextStyle(color: _muted, fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 24),
              _InsightCard(
                icon: Icons.gps_fixed_rounded,
                color: _cyan,
                title: 'Target accuracy',
                value:
                    'X ${report.xPhase.hitRatePercent.toStringAsFixed(1)}% · '
                    'A→X ${report.axPhase.hitRatePercent.toStringAsFixed(1)}%',
                description:
                    'How often a response was made while the requested target was visible.',
              ),
              const SizedBox(height: 13),
              _InsightCard(
                icon: Icons.pan_tool_alt_outlined,
                color: _magenta,
                title: 'Response control',
                value:
                    'X ${report.xPhase.falseAlarmRatePercent.toStringAsFixed(1)}% · '
                    'A→X ${report.axPhase.falseAlarmRatePercent.toStringAsFixed(1)}% false alarms',
                description:
                    'How often a response occurred when the active target was absent.',
              ),
              const SizedBox(height: 13),
              _InsightCard(
                icon: Icons.speed_rounded,
                color: _indigo,
                title: 'Response timing',
                value:
                    'X ${_milliseconds(report.xPhase.averageHitReactionTimeMs)} · '
                    'A→X ${_milliseconds(report.axPhase.averageHitReactionTimeMs)}',
                description:
                    'Average latency for correct target responses. Timing is descriptive and does not change the score.',
              ),
              const SizedBox(height: 13),
              _InsightCard(
                icon: Icons.show_chart_rounded,
                color: _cyan,
                title: 'Signal separation (d′)',
                value:
                    'X ${report.xPhase.dPrime.toStringAsFixed(2)} · '
                    'A→X ${report.axPhase.dPrime.toStringAsFixed(2)}',
                description:
                    'A descriptive separation between target and non-target responses, calculated with log-linear correction.',
              ),
              const SizedBox(height: 13),
              _InsightCard(
                icon: Icons.balance_rounded,
                color: _magenta,
                title: 'Response tendency (c)',
                value:
                    'X ${report.xPhase.responseBiasC.toStringAsFixed(2)} · '
                    'A→X ${report.axPhase.responseBiasC.toStringAsFixed(2)}',
                description:
                    'A descriptive tendency to respond more or less readily. It is excluded from the score.',
              ),
              const SizedBox(height: 20),
              const _ResultDisclaimer(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: GamePrimaryButton(label: 'Back to games', onPressed: onFinish),
        ),
      ],
    );
  }

  static String _milliseconds(double? value) =>
      value == null ? '—' : '${value.round()} ms';
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterruptedView extends StatelessWidget {
  const _InterruptedView({
    super.key,
    required this.reason,
    required this.fullJourney,
    required this.onRules,
    required this.onRestart,
    required this.onExit,
  });

  final String reason;
  final bool fullJourney;
  final VoidCallback onRules;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _CenteredActionView(
      icon: Icons.restart_alt_rounded,
      iconColor: _magenta,
      title: fullJourney ? 'Restart the journey' : 'Restart this focus round',
      message:
          '$reason\n\nTo keep the result comparable, the interrupted timing is discarded and must be recorded again.',
      primaryLabel: fullJourney ? 'Restart journey' : 'Restart phase',
      onPrimary: onRestart,
      secondaryLabel: 'View rules / Help',
      onSecondary: onRules,
      tertiaryLabel: 'Exit to games',
      onTertiary: onExit,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredActionView(
      icon: Icons.cloud_off_rounded,
      iconColor: _magenta,
      title: 'We could not save the journey',
      message: message,
      primaryLabel: 'Try again',
      onPrimary: onRetry,
      secondaryLabel: 'Back to games',
      onSecondary: onBack,
    );
  }
}

class _CenteredActionView extends StatelessWidget {
  const _CenteredActionView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _navy,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 28),
            GamePrimaryButton(label: primaryLabel, onPressed: onPrimary),
            const SizedBox(height: 11),
            GameOutlineButton(label: secondaryLabel, onPressed: onSecondary),
            if (tertiaryLabel != null && onTertiary != null) ...[
              const SizedBox(height: 11),
              TextButton(
                onPressed: onTertiary,
                child: Text(
                  tertiaryLabel!,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RulesDialog extends StatelessWidget {
  const _RulesDialog({required this.phase});

  final ContinuousAttentionPhase? phase;

  @override
  Widget build(BuildContext context) {
    final showX = phase == null || !phase!.isAx;
    final showAx = phase == null || phase!.isAx;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule_rounded, color: _indigo, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rules / Help',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (showX)
              const _RuleHelpCard(
                badge: 'X',
                color: _cyan,
                title: 'First rule',
                description: 'Respond whenever the current letter is X.',
              ),
            if (showX && showAx) const SizedBox(height: 12),
            if (showAx)
              const _RuleHelpCard(
                badge: 'A→X',
                color: _magenta,
                title: 'Second rule',
                description: 'Respond only when X appears immediately after A.',
              ),
            const SizedBox(height: 14),
            const _RuleBullet(
              icon: Icons.touch_app_outlined,
              text: 'Tap the response button or press Space.',
            ),
            const _RuleBullet(
              icon: Icons.filter_1_rounded,
              text: 'Only the first response in a letter window is used.',
            ),
            const _RuleBullet(
              icon: Icons.hourglass_bottom_rounded,
              text: 'Responses during the blank interval are ignored.',
            ),
            const _RuleBullet(
              icon: Icons.restart_alt_rounded,
              text:
                  'Pausing or leaving a measured round restarts that round from the beginning.',
            ),
            const SizedBox(height: 18),
            GamePrimaryButton(
              label: 'Got it',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleHelpCard extends StatelessWidget {
  const _RuleHelpCard({
    required this.badge,
    required this.color,
    required this.title,
    required this.description,
  });

  final String badge;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleBullet extends StatelessWidget {
  const _RuleBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _indigo, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _navy,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
