import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/config/object_location_config.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/object_location_metrics.dart';
import '../games_providers.dart';
import '../widgets/game_system_components.dart';
import '../widgets/je_place_pause_dialog.dart';

const _logoAsset = 'assets/games icons/Je Place.png';
const _canvas = ZennytGamePalette.mist;
const _ink = ZennytGamePalette.blue;
const _violet = ZennytGamePalette.gameBlue;
const _panel = ZennytGamePalette.gamePanel;
const _pink = ZennytGamePalette.magenta;
const _muted = ZennytGamePalette.muted;
const _border = ZennytGamePalette.border;

enum _JePlaceStage {
  cover,
  starting,
  onboarding,
  encoding,
  retention,
  recall,
  practiceFeedback,
  measuredReady,
  levelTransition,
  submitting,
  results,
  invalid,
  error,
}

enum _InterruptedRunContinuation { restart, exit }

abstract interface class ObjectLocationClock {
  int get elapsedMilliseconds;
  bool get isRunning;
  void start();
  void stop();
  void reset();
}

class StopwatchObjectLocationClock implements ObjectLocationClock {
  StopwatchObjectLocationClock() : _stopwatch = Stopwatch();
  final Stopwatch _stopwatch;

  @override
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
  @override
  bool get isRunning => _stopwatch.isRunning;
  @override
  void reset() => _stopwatch.reset();
  @override
  void start() => _stopwatch.start();
  @override
  void stop() => _stopwatch.stop();
}

ObjectLocationClock _productionClockFactory() => StopwatchObjectLocationClock();

/// Full « Je place » journey. Timings use one monotonic stopwatch per phase;
/// callbacks are scheduled against absolute phase deadlines.
class JePlaceScreen extends ConsumerStatefulWidget {
  const JePlaceScreen({super.key, this.clockFactory = _productionClockFactory});

  final ObjectLocationClock Function() clockFactory;

  @override
  ConsumerState<JePlaceScreen> createState() => _JePlaceScreenState();
}

class _JePlaceScreenState extends ConsumerState<JePlaceScreen>
    with WidgetsBindingObserver {
  _JePlaceStage _stage = _JePlaceStage.cover;
  int _onboardingPage = 0;
  GameSession? _session;
  List<ObjectLocationLevelLayout> _layouts = const [];
  int _layoutCursor = 0;
  _MutableLevel? _level;
  final List<ObjectLocationLevelMetric> _completedLevels = [];
  final Map<String, int> _placements = {};
  final List<ObjectLocationPlacementAction> _actions = [];
  String? _selectedObjectId;
  int _consecutiveFailures = 0;

  late final ObjectLocationClock _phaseClock;
  Timer? _deadlineTimer;
  Timer? _displayTicker;
  int _phaseBudgetMs = 0;
  int _remainingMs = 0;
  bool _practiceFrozen = false;
  bool _pauseOpen = false;
  bool _measuredInterrupted = false;
  bool _interruptionSnapshotAdded = false;

  int _backgroundEventCount = 0;
  int _focusLossCount = 0;
  int _orientationChangeCount = 0;
  int _droppedFrameCount = 0;
  Size? _measuredViewSize;

  ObjectLocationIndicators? _indicators;
  ObjectLocationMetrics? _pendingMetrics;
  String? _invalidReason;
  String? _errorMessage;
  bool _submitting = false;
  _InterruptedRunContinuation? _pendingInterruptedRunContinuation;

  bool get _isGameplay =>
      _stage == _JePlaceStage.encoding ||
      _stage == _JePlaceStage.retention ||
      _stage == _JePlaceStage.recall;

  bool get _isPractice => _layoutCursor == 0;
  bool get _isMeasuredGameplay => _isGameplay && !_isPractice;

  @override
  void initState() {
    super.initState();
    _phaseClock = widget.clockFactory();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimeline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isGameplay || state == AppLifecycleState.resumed) return;
    if (_isPractice) {
      _freezePractice();
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _practiceFrozen && !_pauseOpen) {
            unawaited(_openPause());
          }
        });
      }
      return;
    }
    if (!_measuredInterrupted) {
      _backgroundEventCount++;
      _focusLossCount++;
      _interruptMeasured(
        'The app left the active screen during a measured memory phase.',
        submitAudit: true,
      );
    }
  }

  @override
  void didChangeMetrics() {
    if (!_isMeasuredGameplay || _measuredInterrupted) return;
    final size = View.of(context).physicalSize;
    if (_measuredViewSize != null && size != _measuredViewSize) {
      _orientationChangeCount++;
      _interruptMeasured(
        'The play area changed during a measured memory phase.',
        submitAudit: true,
      );
    }
  }

  void _exitToGames() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/games');
    }
  }

  Future<void> _startJourney() async {
    _cancelTimeline();
    setState(() {
      _stage = _JePlaceStage.starting;
      _errorMessage = null;
      _invalidReason = null;
      _indicators = null;
      _pendingMetrics = null;
      _completedLevels.clear();
      _layoutCursor = 0;
      _onboardingPage = 0;
    });
    try {
      final session = await ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.visuospatialMemory);
      if (!mounted) return;
      setState(() {
        _session = session;
        _layouts = ObjectLocationConfig.generateLayouts(session.id);
        _stage = _JePlaceStage.onboarding;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _stage = _JePlaceStage.error;
      });
    }
  }

  void _nextOnboarding() {
    if (_onboardingPage < _onboarding.length - 1) {
      setState(() => _onboardingPage++);
    } else {
      _beginLevel(0);
    }
  }

  void _beginLevel(int layoutCursor) {
    _cancelTimeline();
    _layoutCursor = layoutCursor;
    final layout = _layouts[layoutCursor];
    _level = _MutableLevel(layout);
    _placements.clear();
    _actions.clear();
    _selectedObjectId = null;
    _practiceFrozen = false;
    _measuredInterrupted = false;
    _interruptionSnapshotAdded = false;
    if (layoutCursor > 0) {
      _measuredViewSize = View.of(context).physicalSize;
    }
    _startPhase(
      _JePlaceStage.encoding,
      ObjectLocationConfig.encodingDurationMs(layout.objectCount),
      _finishEncoding,
    );
  }

  void _startPhase(_JePlaceStage stage, int budgetMs, VoidCallback onDeadline) {
    _deadlineTimer?.cancel();
    _displayTicker?.cancel();
    _phaseClock
      ..stop()
      ..reset()
      ..start();
    _phaseBudgetMs = budgetMs;
    _remainingMs = budgetMs;
    setState(() => _stage = stage);
    _scheduleDeadline(onDeadline, budgetMs);
  }

  void _scheduleDeadline(VoidCallback onDeadline, int remainingMs) {
    _deadlineTimer = Timer(
      Duration(milliseconds: math.max(0, remainingMs)),
      () {
        if (!mounted) return;
        onDeadline();
      },
    );
    _displayTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !_phaseClock.isRunning) return;
      final next = math.max(
        0,
        _phaseBudgetMs - _phaseClock.elapsedMilliseconds,
      );
      if (next != _remainingMs) setState(() => _remainingMs = next);
    });
  }

  void _finishEncoding() {
    final level = _level!;
    level.actualEncodingDurationMs = _phaseClock.elapsedMilliseconds;
    _startPhase(
      _JePlaceStage.retention,
      ObjectLocationConfig.retentionDurationMs,
      _finishRetention,
    );
  }

  void _finishRetention() {
    final level = _level!;
    level.actualRetentionDurationMs = _phaseClock.elapsedMilliseconds;
    _placements.clear();
    _actions.clear();
    _selectedObjectId = null;
    _startPhase(
      _JePlaceStage.recall,
      ObjectLocationConfig.recallDurationMs(level.layout.objectCount),
      () => _completeRecall(timedOut: true),
    );
  }

  void _selectObject(String objectId) {
    if (_stage != _JePlaceStage.recall) return;
    setState(() => _selectedObjectId = objectId);
  }

  void _placeSelected(int cellIndex) {
    final objectId = _selectedObjectId;
    if (objectId == null || _stage != _JePlaceStage.recall) return;
    _placeObject(objectId, cellIndex);
  }

  void _placeObject(String objectId, int cellIndex) {
    if (_stage != _JePlaceStage.recall ||
        _actions.length >= ObjectLocationConfig.maxActionsPerLevel) {
      return;
    }
    final ejected = _placements.entries
        .where((entry) => entry.value == cellIndex && entry.key != objectId)
        .map((entry) => entry.key)
        .firstOrNull;
    _placements.remove(objectId);
    if (ejected != null) _placements.remove(ejected);
    _placements[objectId] = cellIndex;
    _actions.add(
      ObjectLocationPlacementAction(
        actionIndex: _actions.length + 1,
        actionType: ObjectLocationActionType.place,
        objectId: objectId,
        targetCellIndex: cellIndex,
        timestampMs: _phaseClock.elapsedMilliseconds,
      ),
    );
    setState(() => _selectedObjectId = ejected);
  }

  void _returnSelectedToReserve() {
    final objectId = _selectedObjectId;
    if (objectId == null || !_placements.containsKey(objectId)) return;
    _placements.remove(objectId);
    _actions.add(
      ObjectLocationPlacementAction(
        actionIndex: _actions.length + 1,
        actionType: ObjectLocationActionType.returnToReserve,
        objectId: objectId,
        targetCellIndex: null,
        timestampMs: _phaseClock.elapsedMilliseconds,
      ),
    );
    setState(() {});
  }

  void _completeRecall({required bool timedOut}) {
    if (_stage != _JePlaceStage.recall) return;
    _deadlineTimer?.cancel();
    _displayTicker?.cancel();
    _phaseClock.stop();
    final level = _level!;
    level
      ..actualRecallDurationMs = _phaseClock.elapsedMilliseconds
      ..timedOut = timedOut
      ..completed = true;
    final metric = level.toMetric(_actions);
    _completedLevels.add(metric);

    final exact = level.layout.originalCells.entries
        .where((entry) => _placements[entry.key] == entry.value)
        .length;
    final passed =
        exact >=
        ObjectLocationConfig.exactPlacementsToAdvance(level.layout.objectCount);
    if (_isPractice) {
      setState(() => _stage = _JePlaceStage.practiceFeedback);
      return;
    }
    _consecutiveFailures = passed ? 0 : _consecutiveFailures + 1;
    final measuredCompleted = _layoutCursor;
    final stop =
        measuredCompleted >= ObjectLocationConfig.minimumValidMeasuredLevels &&
        _consecutiveFailures >= 2;
    final last = _layoutCursor == _layouts.length - 1;
    if (stop || last) {
      unawaited(
        _submitCompleted(
          stop
              ? ObjectLocationCompletionReason.stopRule
              : ObjectLocationCompletionReason.maxLevels,
        ),
      );
      return;
    }
    setState(() => _stage = _JePlaceStage.levelTransition);
  }

  void _startMeasuredRun() {
    _completedLevels.removeWhere(
      (level) => level.phase == ObjectLocationPhase.test,
    );
    _consecutiveFailures = 0;
    _backgroundEventCount = 0;
    _focusLossCount = 0;
    _orientationChangeCount = 0;
    _droppedFrameCount = 0;
    _pendingMetrics = null;
    _pendingInterruptedRunContinuation = null;
    _invalidReason = null;
    _errorMessage = null;
    _beginLevel(1);
  }

  void _nextMeasuredLevel() => _beginLevel(_layoutCursor + 1);

  ObjectLocationMetrics _buildMetrics({
    required ObjectLocationCompletionReason completionReason,
    required bool sessionCompleted,
    required bool interrupted,
  }) {
    return ObjectLocationMetrics(
      completionReason: completionReason,
      objectLocationLevels: _completedLevels,
      sessionCompleted: sessionCompleted,
      interrupted: interrupted,
      backgroundEventCount: _backgroundEventCount,
      focusLossCount: _focusLossCount,
      orientationChangeCount: _orientationChangeCount,
      droppedFrameCount: _droppedFrameCount,
    );
  }

  Future<void> _submitCompleted(ObjectLocationCompletionReason reason) async {
    final metrics = _buildMetrics(
      completionReason: reason,
      sessionCompleted: true,
      interrupted: false,
    );
    await _submit(metrics);
  }

  Future<bool> _submit(ObjectLocationMetrics metrics) async {
    final session = _session;
    if (session == null || _submitting) return false;
    _cancelTimeline();
    setState(() {
      _submitting = true;
      _pendingMetrics = metrics;
      _stage = _JePlaceStage.submitting;
    });
    try {
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.objectLocationBindingCore,
            metrics: metrics,
          );
      if (!mounted) return false;
      setState(() {
        _session = updated;
        _indicators = updated.objectLocationIndicators;
        _submitting = false;
        _stage =
            metrics.sessionCompleted &&
                (updated.objectLocationIndicators?.sessionValid ?? false)
            ? _JePlaceStage.results
            : _JePlaceStage.invalid;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _submitting = false;
        _errorMessage = '$error';
        _stage = _JePlaceStage.error;
      });
      return false;
    }
  }

  /// A measured pause is a technical interruption, never a local reset.
  /// Persist its partial trace as audit-only before reusing the session for a
  /// clean run or leaving the journey. The backend/mock therefore has an
  /// observable interrupted run while attempts and scores remain unchanged.
  Future<void> _persistInterruptedRunAndContinue(
    _InterruptedRunContinuation continuation,
  ) async {
    _pendingInterruptedRunContinuation = continuation;
    _invalidReason = 'The measured run was interrupted from the pause menu.';
    _appendInterruptionSnapshot();
    final metrics =
        _pendingMetrics ??
        _buildMetrics(
          completionReason:
              ObjectLocationCompletionReason.technicalInterruption,
          sessionCompleted: false,
          interrupted: true,
        );
    final saved = await _submit(metrics);
    if (!mounted || !saved) return;

    final pending = _pendingInterruptedRunContinuation;
    _pendingInterruptedRunContinuation = null;
    _pendingMetrics = null;
    switch (pending) {
      case _InterruptedRunContinuation.restart:
        _startMeasuredRun();
      case _InterruptedRunContinuation.exit:
        _exitToGames();
      case null:
        break;
    }
  }

  void _retryPendingSubmission() {
    final continuation = _pendingInterruptedRunContinuation;
    if (continuation != null) {
      unawaited(_persistInterruptedRunAndContinue(continuation));
      return;
    }
    final metrics = _pendingMetrics;
    if (metrics != null) unawaited(_submit(metrics));
  }

  void _cancelTimeline() {
    _deadlineTimer?.cancel();
    _displayTicker?.cancel();
    _phaseClock.stop();
  }

  void _freezePractice() {
    if (!_isPractice || !_isGameplay || !_phaseClock.isRunning) return;
    _deadlineTimer?.cancel();
    _displayTicker?.cancel();
    _phaseClock.stop();
    _remainingMs = math.max(
      0,
      _phaseBudgetMs - _phaseClock.elapsedMilliseconds,
    );
    _practiceFrozen = true;
  }

  void _resumePractice() {
    if (!_practiceFrozen || !_isPractice) return;
    _practiceFrozen = false;
    _phaseClock.start();
    final callback = switch (_stage) {
      _JePlaceStage.encoding => _finishEncoding,
      _JePlaceStage.retention => _finishRetention,
      _JePlaceStage.recall => () => _completeRecall(timedOut: true),
      _ => () {},
    };
    _scheduleDeadline(callback, _remainingMs);
    setState(() {});
  }

  Future<void> _openPause() async {
    if (_pauseOpen) return;
    if (!_isGameplay) {
      _exitToGames();
      return;
    }
    _pauseOpen = true;
    if (_isPractice) {
      _freezePractice();
    } else {
      _cancelTimeline();
      _measuredInterrupted = true;
    }
    if (!mounted) return;
    var showAgain = true;
    while (mounted && showAgain) {
      showAgain = false;
      if (!mounted) break;
      final action = await showDialog<JePlacePauseAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            JePlacePauseDialog(measuredRunInterrupted: !_isPractice),
      );
      if (!mounted) break;
      switch (action) {
        case JePlacePauseAction.resume:
          _resumePractice();
        case JePlacePauseAction.rules:
          await _showRules();
          showAgain = true;
        case JePlacePauseAction.restartRun:
          await _persistInterruptedRunAndContinue(
            _InterruptedRunContinuation.restart,
          );
        case JePlacePauseAction.exit:
        case null:
          if (_isPractice) {
            _exitToGames();
          } else {
            await _persistInterruptedRunAndContinue(
              _InterruptedRunContinuation.exit,
            );
          }
      }
    }
    _pauseOpen = false;
  }

  Future<void> _showRules() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rules / Help'),
        content: const Text(
          'Memorize what appears and where it sits. After the blank pause, place every object back on the 4 × 4 board. You may move objects until you validate. No correctness feedback appears during measured levels.',
        ),
        actions: [
          TextButton(
            onPressed: () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  Navigator.of(context).pop();
                },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _interruptMeasured(String reason, {required bool submitAudit}) {
    if (_measuredInterrupted && _stage == _JePlaceStage.invalid) return;
    _cancelTimeline();
    _measuredInterrupted = true;
    _invalidReason = reason;
    _appendInterruptionSnapshot();
    setState(() => _stage = _JePlaceStage.invalid);
    if (submitAudit) {
      final metrics = _buildMetrics(
        completionReason: ObjectLocationCompletionReason.technicalInterruption,
        sessionCompleted: false,
        interrupted: true,
      );
      unawaited(_submit(metrics));
    }
  }

  void _appendInterruptionSnapshot() {
    if (_interruptionSnapshotAdded || _level == null) return;
    final draft = _level!;
    final elapsed = _phaseClock.elapsedMilliseconds;
    switch (_stage) {
      case _JePlaceStage.encoding:
        draft.actualEncodingDurationMs = elapsed;
      case _JePlaceStage.retention:
        draft.actualRetentionDurationMs = elapsed;
      case _JePlaceStage.recall:
        draft.actualRecallDurationMs = elapsed;
      default:
        break;
    }
    draft.completed = false;
    _completedLevels.add(draft.toMetric(_actions));
    _interruptionSnapshotAdded = true;
  }

  void _handleBack() {
    if (_isGameplay) {
      unawaited(_openPause());
    } else {
      _exitToGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _handleBack(),
      child: Scaffold(
        backgroundColor: _isGameplay ? _violet : _canvas,
        body: SafeArea(child: _buildStage()),
      ),
    );
  }

  Widget _buildStage() => switch (_stage) {
    _JePlaceStage.cover => _buildCover(),
    _JePlaceStage.starting => const _CenteredStatus(
      label: 'Preparing your memory board…',
    ),
    _JePlaceStage.onboarding => _buildOnboarding(),
    _JePlaceStage.encoding ||
    _JePlaceStage.retention ||
    _JePlaceStage.recall => GameplayMusic(child: _buildGameplay()),
    _JePlaceStage.practiceFeedback => _buildPracticeFeedback(),
    _JePlaceStage.measuredReady => _buildMeasuredReady(),
    _JePlaceStage.levelTransition => _buildLevelTransition(),
    _JePlaceStage.submitting => const _CenteredStatus(
      label: 'Saving your journey…',
    ),
    _JePlaceStage.results => _buildResults(),
    _JePlaceStage.invalid => _buildInvalid(),
    _JePlaceStage.error => _buildError(),
  };

  Widget _buildCover() {
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Zennyt Games',
        title: 'Je place',
        onBack: _exitToGames,
      ),
      content: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_violet, Color(0xFF6F64ED)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x285146E8),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const _CoverHero(),
        ),
        const SizedBox(height: 18),
        const GamePanel(
          child: Column(
            children: [
              _InfoRow(label: 'Goal', value: 'Remember what belongs where'),
              Divider(color: _border),
              _InfoRow(label: 'Duration', value: 'Up to 5 minutes'),
              Divider(color: _border),
              _InfoRow(label: 'Format', value: 'Practice + 6 levels'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works',
                style: TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14),
              _StepLine(number: '1', label: 'Observe every object and place'),
              SizedBox(height: 10),
              _StepLine(number: '2', label: 'Hold the picture in your mind'),
              SizedBox(height: 10),
              _StepLine(number: '3', label: 'Restore the complete board'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _PrivacyNote(),
      ],
      bottom: GamePrimaryButton(
        key: const ValueKey('je-place-start'),
        label: 'Start the journey',
        onPressed: _startJourney,
      ),
    );
  }

  Widget _buildOnboarding() {
    final page = _onboarding[_onboardingPage];
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Onboarding',
        onBack: _onboardingPage == 0
            ? () => setState(() => _stage = _JePlaceStage.cover)
            : () => setState(() => _onboardingPage--),
      ),
      content: [
        GamePanel(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            children: [
              _TutorialIllustration(kind: page.kind),
              const SizedBox(height: 20),
              Text(
                'STEP ${_onboardingPage + 1} OF ${_onboarding.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: _violet,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: _muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              _PageDots(current: _onboardingPage, count: _onboarding.length),
            ],
          ),
        ),
      ],
      bottom: GamePrimaryButton(
        label: _onboardingPage == _onboarding.length - 1
            ? 'Begin practice'
            : 'Next',
        onPressed: _nextOnboarding,
      ),
    );
  }

  Widget _buildGameplay() {
    final layout = _level!.layout;
    final progress = _phaseBudgetMs == 0
        ? 0.0
        : 1 - _remainingMs / _phaseBudgetMs;
    final seconds = (_remainingMs / 1000).ceil();
    final stageLabel = switch (_stage) {
      _JePlaceStage.encoding => 'Observe',
      _JePlaceStage.retention => 'Remember',
      _ => 'Restore',
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
          child: _JePlaceHeader(
            eyebrow: _isPractice
                ? 'Je place · Practice'
                : 'Je place · Level $_layoutCursor',
            title: stageLabel,
            onBack: _openPause,
            onMenu: _openPause,
            onDark: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _MemoryHud(
            stage: stageLabel,
            level: _isPractice ? 'Practice' : '$_layoutCursor / 6',
            objectCount: layout.objectCount,
            seconds: seconds,
            progress: progress,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Column(
              children: [
                Text(
                  switch (_stage) {
                    _JePlaceStage.encoding =>
                      'Take in the full picture. Every place matters.',
                    _JePlaceStage.retention =>
                      'Keep the board in mind. The objects return next.',
                    _ =>
                      _placements.length == layout.objectCount
                          ? 'Everything is placed. You can still adjust.'
                          : 'Select an object, then choose its place.',
                  },
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                if (_stage == _JePlaceStage.encoding)
                  _EncodingBoard(layout: layout)
                else if (_stage == _JePlaceStage.retention)
                  const _RetentionBoard()
                else
                  _RecallBoard(
                    key: const ValueKey('je-place-recall-board'),
                    layout: layout,
                    placements: _placements,
                    selectedObjectId: _selectedObjectId,
                    onSelect: _selectObject,
                    onPlace: _placeObject,
                    onCellTap: _placeSelected,
                    onReturn: _returnSelectedToReserve,
                  ),
              ],
            ),
          ),
        ),
        if (_stage == _JePlaceStage.recall)
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            decoration: BoxDecoration(
              color: _panel,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: .18)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: GamePrimaryButton(
                key: const ValueKey('je-place-validate'),
                label: 'Validate placement',
                onPressed:
                    _placements.length == layout.objectCount &&
                        _phaseClock.elapsedMilliseconds >=
                            layout.objectCount *
                                ObjectLocationConfig.minimumRecallPerObjectMs
                    ? () => _completeRecall(timedOut: false)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPracticeFeedback() {
    final level = _level!;
    final exact = level.layout.originalCells.entries
        .where((entry) => _placements[entry.key] == entry.value)
        .length;
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Practice complete',
        onBack: _handleBack,
      ),
      content: [
        const _StateIcon(
          icon: Icons.auto_awesome_rounded,
          color: _violet,
          background: Color(0xFFF0F2FF),
        ),
        const SizedBox(height: 20),
        Text(
          exact == level.layout.objectCount
              ? 'You restored the practice board'
              : 'You now know the rhythm',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Practice feedback ends here. Measured levels stay neutral and never reveal right or wrong placements.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: _muted, height: 1.5),
        ),
      ],
      bottom: GamePrimaryButton(
        label: 'Continue',
        onPressed: () => setState(() => _stage = _JePlaceStage.measuredReady),
      ),
    );
  }

  Widget _buildMeasuredReady() {
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Ready',
        onBack: _handleBack,
      ),
      content: [
        const _StateIcon(
          icon: Icons.grid_view_rounded,
          color: _pink,
          background: Color(0xFFFFEDF6),
        ),
        const SizedBox(height: 20),
        Text(
          'Build the picture, one level at a time',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The board grows from 3 to 8 objects. There is no live score and no correctness feedback.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 22),
        const GamePanel(
          backgroundColor: Color(0xFFF0F2FF),
          borderColor: Color(0xFFD7DBFF),
          child: Column(
            children: [
              _ReadyLine(
                icon: Icons.layers_outlined,
                text: '6 possible levels',
              ),
              SizedBox(height: 12),
              _ReadyLine(
                icon: Icons.visibility_off_outlined,
                text: 'No live score',
              ),
              SizedBox(height: 12),
              _ReadyLine(
                icon: Icons.replay_rounded,
                text: 'A pause restarts the measured run',
              ),
            ],
          ),
        ),
      ],
      bottom: GamePrimaryButton(
        key: const ValueKey('je-place-start-measured'),
        label: 'Start level 1',
        onPressed: _startMeasuredRun,
      ),
    );
  }

  Widget _buildLevelTransition() {
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Level saved',
        onBack: _handleBack,
      ),
      content: [
        const _StateIcon(
          icon: Icons.check_rounded,
          color: ZennytGamePalette.success,
          background: Color(0xFFEAFBF1),
        ),
        const SizedBox(height: 22),
        Text(
          'Your choices are saved',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No correct or incorrect answer is shown here. The next board adds one object.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: _muted, height: 1.5),
        ),
      ],
      bottom: GamePrimaryButton(
        label: 'Continue to level ${_layoutCursor + 1}',
        onPressed: _nextMeasuredLevel,
      ),
    );
  }

  Widget _buildResults() {
    final report = _indicators!;
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Journey complete',
        onBack: _exitToGames,
      ),
      content: [
        _ResultRing(value: report.provisionalAccuracyScore),
        const SizedBox(height: 18),
        Text(
          'A snapshot of object-location memory',
          textAlign: TextAlign.center,
          style: AppTypography.headlineSmall.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descriptive and provisional. This is not a diagnosis, ranking, or recruitment decision.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        GamePanel(
          child: Column(
            children: [
              _MetricLine(
                label: 'Exact placement',
                value: '${report.exactAccuracyPercent.toStringAsFixed(1)}%',
              ),
              const Divider(color: _border),
              _MetricLine(
                label: 'Memory span',
                value: '${report.span} objects',
              ),
              const Divider(color: _border),
              _MetricLine(
                label: 'Mean displacement',
                value: report.averageDisplacementCells.toStringAsFixed(2),
              ),
              const Divider(color: _border),
              _MetricLine(
                label: 'Levels completed',
                value: '${report.completedLevelCount}',
              ),
            ],
          ),
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GamePrimaryButton(label: 'Back to games', onPressed: _exitToGames),
          const SizedBox(height: 10),
          GameOutlineButton(label: 'Play again', onPressed: _startJourney),
        ],
      ),
    );
  }

  Widget _buildInvalid() {
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Journey interrupted',
        onBack: _exitToGames,
      ),
      content: [
        const _StateIcon(
          icon: Icons.replay_rounded,
          color: ZennytGamePalette.ruleOrange,
          background: Color(0xFFFFF3E8),
        ),
        const SizedBox(height: 22),
        Text(
          'Let’s restart from level 1',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _invalidReason ??
              'This run could not be compared because its timing was interrupted.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 18),
        const GamePanel(
          backgroundColor: Color(0xFFFFFAF5),
          borderColor: Color(0xFFFFDFC1),
          child: Text(
            'No score or result was recorded for this run.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _ink, height: 1.45),
          ),
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GamePrimaryButton(
            key: const ValueKey('je-place-restart-run'),
            label: 'Restart run',
            icon: Icons.replay_rounded,
            onPressed: _startMeasuredRun,
          ),
          const SizedBox(height: 10),
          GameOutlineButton(label: 'Exit journey', onPressed: _exitToGames),
        ],
      ),
    );
  }

  Widget _buildError() {
    return _JourneyPage(
      header: _JePlaceHeader(
        eyebrow: 'Je place',
        title: 'Something went wrong',
        onBack: _exitToGames,
      ),
      content: [
        const _StateIcon(
          icon: Icons.cloud_off_rounded,
          color: ZennytGamePalette.error,
          background: Color(0xFFFFEEEE),
        ),
        const SizedBox(height: 22),
        Text(
          'Your journey could not be saved',
          textAlign: TextAlign.center,
          style: AppTypography.headlineSmall.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Please try again.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _muted),
        ),
      ],
      bottom: GamePrimaryButton(
        label: 'Try again',
        onPressed: _pendingMetrics == null
            ? _startJourney
            : _retryPendingSubmission,
      ),
    );
  }
}

class _MutableLevel {
  _MutableLevel(this.layout);

  final ObjectLocationLevelLayout layout;
  int actualEncodingDurationMs = 0;
  int actualRetentionDurationMs = 0;
  int actualRecallDurationMs = 0;
  bool timedOut = false;
  bool completed = false;

  ObjectLocationLevelMetric toMetric(
    List<ObjectLocationPlacementAction> actions,
  ) {
    return ObjectLocationLevelMetric(
      phase: layout.levelIndex == 0
          ? ObjectLocationPhase.practice
          : ObjectLocationPhase.test,
      levelIndex: layout.levelIndex,
      objectCount: layout.objectCount,
      actualEncodingDurationMs: actualEncodingDurationMs,
      actualRetentionDurationMs: actualRetentionDurationMs,
      actualRecallDurationMs: actualRecallDurationMs,
      timedOut: timedOut,
      completed: completed,
      actions: actions,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class _OnboardingData {
  const _OnboardingData(this.title, this.body, this.kind);
  final String title;
  final String body;
  final int kind;
}

const _onboarding = <_OnboardingData>[
  _OnboardingData(
    'See the whole board',
    'Modern objects appear on a 4 × 4 grid. Notice both the object and its exact place.',
    0,
  ),
  _OnboardingData(
    'Hold the picture',
    'The board becomes empty for a short moment. Keep the complete arrangement in mind.',
    1,
  ),
  _OnboardingData(
    'Put everything back',
    'Select an object, then a cell. Move any object again before validating the complete board.',
    2,
  ),
];

class _JourneyPage extends StatelessWidget {
  const _JourneyPage({
    required this.header,
    required this.content,
    required this.bottom,
  });

  final Widget header;
  final List<Widget> content;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: header,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            children: content,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: SafeArea(top: false, child: bottom),
        ),
      ],
    );
  }
}

class _JePlaceHeader extends StatelessWidget {
  const _JePlaceHeader({
    required this.eyebrow,
    required this.title,
    required this.onBack,
    this.onMenu,
    this.onDark = false,
  });

  final String eyebrow;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMenu;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : _ink;
    return Row(
      children: [
        _HeaderButton(
          tooltip: 'Back',
          icon: Icons.chevron_left_rounded,
          onPressed: onBack,
          onDark: onDark,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: onDark ? Colors.white70 : _muted,
                ),
              ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleLarge.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (onMenu == null)
          const SizedBox(width: 50, height: 50)
        else
          _HeaderButton(
            tooltip: 'Pause',
            icon: Icons.pause_rounded,
            onPressed: onMenu!,
            onDark: onDark,
          ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.onDark,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: onDark ? Colors.white : _ink,
          backgroundColor: onDark
              ? Colors.white.withValues(alpha: .14)
              : Colors.white,
          side: BorderSide(color: onDark ? Colors.white30 : _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(icon, size: 27),
      ),
    );
  }
}

class _CoverHero extends StatelessWidget {
  const _CoverHero();

  @override
  Widget build(BuildContext context) {
    final narrow =
        MediaQuery.sizeOf(context).width < 350 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.35;
    final copy = Column(
      crossAxisAlignment: narrow
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Remember the scene.\nRestore every place.',
          textAlign: narrow ? TextAlign.center : TextAlign.start,
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'A calm object-location journey that grows one piece at a time.',
          textAlign: narrow ? TextAlign.center : TextAlign.start,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: .9),
            height: 1.4,
          ),
        ),
      ],
    );
    final logo = Semantics(
      image: true,
      label: 'Je place game logo',
      child: SizedBox(
        key: const ValueKey('je-place-cover-logo'),
        width: narrow ? 160 : 136,
        height: narrow ? 160 : 136,
        child: Image.asset(
          _logoAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => const _LogoFallback(),
        ),
      ),
    );
    if (narrow) {
      return Column(children: [logo, const SizedBox(height: 8), copy]);
    }
    return Row(
      children: [
        Expanded(child: copy),
        const SizedBox(width: 8),
        logo,
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const Icon(Icons.grid_view_rounded, color: Colors.white, size: 76),
        const Positioned(
          right: 17,
          bottom: 19,
          child: Icon(Icons.place_rounded, color: _pink, size: 34),
        ),
      ],
    );
  }
}

class _MemoryHud extends StatelessWidget {
  const _MemoryHud({
    required this.stage,
    required this.level,
    required this.objectCount,
    required this.seconds,
    required this.progress,
  });

  final String stage;
  final String level;
  final int objectCount;
  final int seconds;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HudValue(label: 'Phase', value: stage),
              ),
              const _HudDivider(),
              Expanded(
                child: _HudValue(label: 'Level', value: level),
              ),
              const _HudDivider(),
              Expanded(
                child: _HudValue(
                  label: '$objectCount objects',
                  value: '${seconds}s',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress.clamp(0, 1),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(_pink),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: Colors.white24);
}

class _EncodingBoard extends StatelessWidget {
  const _EncodingBoard({required this.layout});
  final ObjectLocationLevelLayout layout;

  @override
  Widget build(BuildContext context) {
    return _GridBoard(
      cellBuilder: (cell) {
        final objectId = layout.originalCells.entries
            .where((entry) => entry.value == cell)
            .map((entry) => entry.key)
            .firstOrNull;
        return objectId == null
            ? const SizedBox.shrink()
            : _ObjectToken(objectId: objectId);
      },
    );
  }
}

class _RetentionBoard extends StatelessWidget {
  const _RetentionBoard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Opacity(opacity: .42, child: _GridBoard()),
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.visibility_off_outlined,
            color: Colors.white,
            size: 52,
          ),
        ),
      ],
    );
  }
}

class _RecallBoard extends StatelessWidget {
  const _RecallBoard({
    super.key,
    required this.layout,
    required this.placements,
    required this.selectedObjectId,
    required this.onSelect,
    required this.onPlace,
    required this.onCellTap,
    required this.onReturn,
  });

  final ObjectLocationLevelLayout layout;
  final Map<String, int> placements;
  final String? selectedObjectId;
  final ValueChanged<String> onSelect;
  final void Function(String objectId, int cell) onPlace;
  final ValueChanged<int> onCellTap;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final reserve = layout.reserveOrder
        .where((objectId) => !placements.containsKey(objectId))
        .toList();
    final board = _GridBoard(
      cellBuilder: (cell) {
        final objectId = placements.entries
            .where((entry) => entry.value == cell)
            .map((entry) => entry.key)
            .firstOrNull;
        return DragTarget<String>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) => onPlace(details.data, cell),
          builder: (context, candidates, _) => Semantics(
            button: true,
            enabled: selectedObjectId != null || objectId != null,
            label: objectId == null
                ? 'Grid cell ${cell + 1}, empty. Place the selected object here.'
                : 'Grid cell ${cell + 1}, occupied by ${ObjectLocationConfig.item(objectId).accessibleName}. Select or replace it.',
            child: InkWell(
              key: ValueKey('je-place-cell-$cell'),
              onTap: () => onCellTap(cell),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: candidates.isNotEmpty
                      ? Colors.white.withValues(alpha: .23)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: objectId == null
                    ? const SizedBox.shrink()
                    : _DraggableObject(
                        objectId: objectId,
                        selected: selectedObjectId == objectId,
                        onTap: () => onSelect(objectId),
                      ),
              ),
            ),
          ),
        );
      },
    );

    Widget reserveWidget(List<String> ids, {required bool vertical}) {
      return _Reserve(
        objectIds: ids,
        selectedObjectId: selectedObjectId,
        vertical: vertical,
        onSelect: onSelect,
        onReturn: onReturn,
      );
    }

    switch (layout.reserveZone) {
      case ObjectLocationReserveZone.below:
        return Column(
          children: [
            board,
            const SizedBox(height: 10),
            reserveWidget(reserve, vertical: false),
          ],
        );
      case ObjectLocationReserveZone.left:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 72, child: reserveWidget(reserve, vertical: true)),
            const SizedBox(width: 8),
            Expanded(child: board),
          ],
        );
      case ObjectLocationReserveZone.right:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: board),
            const SizedBox(width: 8),
            SizedBox(width: 72, child: reserveWidget(reserve, vertical: true)),
          ],
        );
      case ObjectLocationReserveZone.both:
        final left = reserve
            .where(
              (id) => layout.reserveSides[id] == ObjectLocationReserveSide.left,
            )
            .toList();
        final right = reserve
            .where(
              (id) =>
                  layout.reserveSides[id] == ObjectLocationReserveSide.right,
            )
            .toList();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 62, child: reserveWidget(left, vertical: true)),
            const SizedBox(width: 6),
            Expanded(child: board),
            const SizedBox(width: 6),
            SizedBox(width: 62, child: reserveWidget(right, vertical: true)),
          ],
        );
    }
  }
}

class _GridBoard extends StatelessWidget {
  const _GridBoard({this.cellBuilder});
  final Widget Function(int cell)? cellBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final max = math.min(constraints.maxWidth, 332.0);
        return Center(
          child: Container(
            key: const ValueKey('je-place-grid'),
            width: max,
            height: max,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white24, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33071333),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ObjectLocationConfig.cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ObjectLocationConfig.gridSize,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (_, cell) {
                final content = cellBuilder?.call(cell);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: content == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox.square(dimension: 58, child: content),
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Reserve extends StatelessWidget {
  const _Reserve({
    required this.objectIds,
    required this.selectedObjectId,
    required this.vertical,
    required this.onSelect,
    required this.onReturn,
  });

  final List<String> objectIds;
  final String? selectedObjectId;
  final bool vertical;
  final ValueChanged<String> onSelect;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        onSelect(details.data);
        onReturn();
      },
      builder: (context, candidates, _) => Container(
        key: const ValueKey('je-place-reserve'),
        constraints: BoxConstraints(minHeight: vertical ? 286 : 78),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? Colors.white.withValues(alpha: .24)
              : Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: objectIds.isEmpty
            ? Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: .8),
                ),
              )
            : Wrap(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final objectId in objectIds)
                    _DraggableObject(
                      objectId: objectId,
                      selected: selectedObjectId == objectId,
                      onTap: () => onSelect(objectId),
                    ),
                ],
              ),
      ),
    );
  }
}

class _DraggableObject extends StatelessWidget {
  const _DraggableObject({
    required this.objectId,
    required this.selected,
    required this.onTap,
  });
  final String objectId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final token = _ObjectToken(objectId: objectId, selected: selected);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Select ${ObjectLocationConfig.item(objectId).accessibleName}',
      child: GestureDetector(
        onTap: onTap,
        child: Draggable<String>(
          data: objectId,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 62, height: 62, child: token),
          ),
          childWhenDragging: Opacity(opacity: .35, child: token),
          child: token,
        ),
      ),
    );
  }
}

class _ObjectToken extends StatelessWidget {
  const _ObjectToken({required this.objectId, this.selected = false});
  final String objectId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final item = ObjectLocationConfig.item(objectId);
    return AnimatedContainer(
      duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : const Duration(milliseconds: 180),
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: .22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Image.asset(
        item.assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _ObjectFallback(item: item),
      ),
    );
  }
}

class _ObjectFallback extends StatelessWidget {
  const _ObjectFallback({required this.item});
  final ObjectLocationCatalogItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.id) {
      'SMARTPHONE' => Icons.smartphone_rounded,
      'WIRELESS_EARBUDS' => Icons.earbuds_rounded,
      'SMARTWATCH' => Icons.watch_rounded,
      'REUSABLE_BOTTLE' => Icons.water_drop_rounded,
      'INSTANT_CAMERA' => Icons.camera_alt_rounded,
      'SNEAKER' => Icons.directions_run_rounded,
      'SUCCULENT' => Icons.local_florist_rounded,
      'CERAMIC_MUG' => Icons.coffee_rounded,
      'BACKPACK' => Icons.backpack_rounded,
      'GAME_CONTROLLER' => Icons.sports_esports_rounded,
      'BICYCLE_HELMET' => Icons.directions_bike_rounded,
      'DESK_LAMP' => Icons.light_rounded,
      'NOTEBOOK' => Icons.menu_book_rounded,
      'SUNGLASSES' => Icons.visibility_rounded,
      'KEYCARD' => Icons.badge_rounded,
      'COMPACT_DRONE' => Icons.flight_rounded,
      'PORTABLE_SPEAKER' => Icons.speaker_rounded,
      'POWER_BANK' => Icons.battery_charging_full_rounded,
      'STYLUS_TABLET' => Icons.draw_rounded,
      _ => Icons.luggage_rounded,
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: _pink, size: 31),
    );
  }
}

class _TutorialIllustration extends StatelessWidget {
  const _TutorialIllustration({required this.kind});
  final int kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('je-place-tutorial-$kind'),
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: switch (kind) {
          0 => const _MiniBoard(showObjects: true),
          1 => const Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: .26, child: _MiniBoard(showObjects: false)),
              Icon(Icons.visibility_off_outlined, color: _violet, size: 62),
            ],
          ),
          _ => const Stack(
            alignment: Alignment.center,
            children: [
              _MiniBoard(showObjects: false),
              Positioned(
                right: 24,
                bottom: 20,
                child: Icon(Icons.touch_app_rounded, color: _pink, size: 50),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.showObjects});
  final bool showObjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 16,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (_, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: showObjects && const [2, 9, 15].contains(index)
              ? Icon(
                  index == 2
                      ? Icons.smartphone_rounded
                      : index == 9
                      ? Icons.coffee_rounded
                      : Icons.headphones_rounded,
                  color: index == 9 ? _pink : Colors.white,
                  size: 22,
                )
              : null,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: _pink,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: _pink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your choices stay private.',
              style: AppTypography.bodyMedium.copyWith(color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: index == current ? 30 : 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: index == current ? _pink : const Color(0xFFD8DEED),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ReadyLine extends StatelessWidget {
  const _ReadyLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _violet, size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({
    required this.icon,
    required this.color,
    required this.background,
  });
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 48),
      ),
    );
  }
}

class _ResultRing extends StatelessWidget {
  const _ResultRing({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        key: const ValueKey('je-place-result-score'),
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 13,
                backgroundColor: const Color(0xFFE8EAF7),
                valueColor: const AlwaysStoppedAnimation<Color>(_pink),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'descriptive / 100',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _pink),
          const SizedBox(height: 18),
          Text(label, style: const TextStyle(color: _ink)),
        ],
      ),
    );
  }
}
