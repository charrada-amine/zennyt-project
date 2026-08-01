import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/config/coordination_tracking_config.dart';
import '../../domain/entities/coordination_tracking_metrics.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../games_providers.dart';
import '../widgets/continuous_attention_pause_dialog.dart';
import '../widgets/game_system_components.dart';

const _logoAsset = 'assets/games icons/Je Coordonne.png';
// Reuse the Games design system instead of maintaining a parallel palette.
const _navy = ZennytGamePalette.blue;
const _violet = ZennytGamePalette.gameBlue;
const _cyan = ZennytGamePalette.cyan;
const _orange = ZennytGamePalette.ruleOrange;
const _pink = ZennytGamePalette.magenta;
const _canvas = ZennytGamePalette.mist;
const _muted = ZennytGamePalette.muted;
const _border = ZennytGamePalette.border;

enum _CoordinationStage {
  cover,
  starting,
  tutorial,
  practice,
  ready,
  test,
  submitting,
  results,
  invalid,
  error,
}

enum _TargetFeedback { waiting, centered, edge, outside }

/// Complete « Je coordonne » journey.
///
/// Gameplay is driven by a [Ticker] absolute timestamp. The renderer never
/// accumulates frame deltas, and only normalized raw pointer samples are sent
/// to the repository. No live score is computed or displayed.
class CoordinationTrackingScreen extends ConsumerStatefulWidget {
  const CoordinationTrackingScreen({super.key});

  @override
  ConsumerState<CoordinationTrackingScreen> createState() =>
      _CoordinationTrackingScreenState();
}

class _CoordinationTrackingScreenState
    extends ConsumerState<CoordinationTrackingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  _CoordinationStage _stage = _CoordinationStage.cover;
  int _tutorialPage = 0;
  GameSession? _session;
  CoordinationTrackingMetrics? _pendingMetrics;
  CoordinationTrackingIndicators? _indicators;
  String? _errorMessage;
  String? _invalidReason;

  int _elapsedUs = 0;
  int _tickerBaseUs = 0;
  int _lastTickUs = 0;
  int _droppedFrameCount = 0;
  int _backgroundEventCount = 0;
  int? _measuredActualEndMs;
  Size? _measuredViewSize;
  bool _running = false;
  bool _finishing = false;
  bool _pauseOpen = false;
  bool _practicePausedByLifecycle = false;

  CoordinationPoint? _pointer;
  int? _activePointerId;
  CoordinationInputSource? _inputSource;
  final List<_MutableSegmentTrace> _segmentTraces = [];

  bool get _isPractice => _stage == _CoordinationStage.practice;
  bool get _isTest => _stage == _CoordinationStage.test;
  bool get _isGameplay => _isPractice || _isTest;

  int get _runStartUs =>
      _isTest ? CoordinationTrackingConfig.practiceDurationMs * 1000 : 0;

  int get _runEndUs =>
      (_isPractice
          ? CoordinationTrackingConfig.practiceDurationMs
          : CoordinationTrackingConfig.totalDurationMs) *
      1000;

  CoordinationPoint get _target => CoordinationTrackingConfig.targetAtMs(
    _running
        ? _elapsedUs ~/ 1000
        : (_isTest ? CoordinationTrackingConfig.practiceDurationMs : 0),
  );

  _TargetFeedback get _feedback {
    if (!_running) return _TargetFeedback.waiting;
    final pointer = _pointer;
    if (pointer == null) return _TargetFeedback.outside;
    final distance = pointer.distanceTo(_target);
    if (distance <= CoordinationTrackingConfig.targetRadiusRatio / 2) {
      return _TargetFeedback.centered;
    }
    if (distance <= CoordinationTrackingConfig.targetRadiusRatio) {
      return _TargetFeedback.edge;
    }
    return _TargetFeedback.outside;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isGameplay || state == AppLifecycleState.resumed) {
      if (state == AppLifecycleState.resumed && _practicePausedByLifecycle) {
        _practicePausedByLifecycle = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isPractice) {
            unawaited(_openPause(resumeFrozenPractice: true));
          }
        });
      }
      return;
    }
    if (_isTest && _running) {
      _backgroundEventCount++;
      _invalidateMeasured('The app left the foreground during the test.');
      return;
    }
    if (_isPractice && _running) {
      _freezeTicker();
      _practicePausedByLifecycle = true;
    }
  }

  @override
  void didChangeMetrics() {
    if (_isTest && _running) {
      final currentSize = View.of(context).physicalSize;
      if (_measuredViewSize != null && currentSize != _measuredViewSize) {
        _invalidateMeasured('The play area changed during the test.');
      }
    }
  }

  Future<void> _startJourney() async {
    _stopAndResetTimeline();
    setState(() {
      _stage = _CoordinationStage.starting;
      _errorMessage = null;
      _invalidReason = null;
      _indicators = null;
      _pendingMetrics = null;
    });
    try {
      final session = await ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.visuomotorCoordination);
      if (!mounted) return;
      setState(() {
        _session = session;
        _tutorialPage = 0;
        _stage = _CoordinationStage.tutorial;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _stage = _CoordinationStage.error;
      });
    }
  }

  void _nextTutorial() {
    if (_tutorialPage < 2) {
      setState(() => _tutorialPage++);
      return;
    }
    _preparePractice();
  }

  void _preparePractice() {
    _stopAndResetTimeline();
    _segmentTraces
      ..clear()
      ..addAll(
        CoordinationTrackingConfig.segments.map(_MutableSegmentTrace.new),
      );
    setState(() {
      _stage = _CoordinationStage.practice;
      _inputSource = null;
      _droppedFrameCount = 0;
      _backgroundEventCount = 0;
      _measuredActualEndMs = null;
      _measuredViewSize = null;
      _invalidReason = null;
      _finishing = false;
    });
  }

  void _prepareMeasured() {
    if (_segmentTraces.isEmpty) {
      _segmentTraces.addAll(
        CoordinationTrackingConfig.segments.map(_MutableSegmentTrace.new),
      );
    }
    for (
      var index = CoordinationTrackingConfig.practiceSegmentCount;
      index < _segmentTraces.length;
      index++
    ) {
      _segmentTraces[index].samples.clear();
    }
    if (_ticker.isActive) _ticker.stop(canceled: true);
    _pendingMetrics = null;
    _indicators = null;
    _droppedFrameCount = 0;
    _backgroundEventCount = 0;
    _measuredActualEndMs = null;
    _measuredViewSize = null;
    _invalidReason = null;
    setState(() {
      _stage = _CoordinationStage.test;
      _elapsedUs = CoordinationTrackingConfig.practiceDurationMs * 1000;
      _tickerBaseUs = _elapsedUs;
      _lastTickUs = _elapsedUs;
      _pointer = null;
      _activePointerId = null;
      _running = false;
      _finishing = false;
    });
  }

  void _startRun() {
    if (_running) return;
    _tickerBaseUs = _elapsedUs;
    _lastTickUs = _elapsedUs;
    _running = true;
    if (_isTest) _measuredViewSize = View.of(context).physicalSize;
    _recordSampleAt(_elapsedUs ~/ 1000, force: true);
    _ticker.start();
    setState(() {});
  }

  void _freezeTicker() {
    if (!_running) return;
    _ticker.stop(canceled: true);
    _tickerBaseUs = _elapsedUs;
    _running = false;
    if (mounted) setState(() {});
  }

  void _stopAndResetTimeline() {
    if (_ticker.isActive) _ticker.stop(canceled: true);
    _elapsedUs = 0;
    _tickerBaseUs = 0;
    _lastTickUs = 0;
    _running = false;
    _pointer = null;
    _activePointerId = null;
  }

  void _onTick(Duration elapsed) {
    if (!_running || !_isGameplay) return;
    final observedUs = _tickerBaseUs + elapsed.inMicroseconds;
    final nextUs = observedUs.clamp(0, _runEndUs);
    final deltaUs = observedUs - _lastTickUs;
    if (_isTest && deltaUs > 50000) _droppedFrameCount++;
    _recordThrough(nextUs ~/ 1000);
    _elapsedUs = nextUs;
    _lastTickUs = nextUs;

    if (nextUs >= _runEndUs) {
      _ticker.stop(canceled: true);
      _running = false;
      if (_isPractice) {
        setState(() => _stage = _CoordinationStage.ready);
      } else {
        _measuredActualEndMs = math.max(
          CoordinationTrackingConfig.totalDurationMs,
          observedUs ~/ 1000,
        );
        unawaited(_finishMeasured());
      }
      return;
    }
    setState(() {});
  }

  void _recordSampleAt(int timestampMs, {bool force = false}) {
    if (timestampMs < 0 ||
        timestampMs >= CoordinationTrackingConfig.totalDurationMs) {
      return;
    }
    final spec = CoordinationTrackingConfig.segmentAtMs(timestampMs);
    final trace = _segmentTraces[spec.index - 1];
    if (trace.samples.isNotEmpty &&
        trace.samples.last.timestampMs >= timestampMs) {
      return;
    }
    // Retain all 60/90/120/240 Hz frames while keeping a seven-second
    // segment below the contract cap on even faster displays.
    if (!force &&
        trace.samples.isNotEmpty &&
        timestampMs - trace.samples.last.timestampMs < 4) {
      return;
    }
    final pointer = _pointer;
    trace.samples.add(
      CoordinationTrackingSample(
        sampleIndex: trace.samples.length + 1,
        timestampMs: timestampMs,
        pointerPresent: pointer != null,
        pointerX: pointer == null
            ? null
            : CoordinationTrackingConfig.normalizedToUnits(pointer.x),
        pointerY: pointer == null
            ? null
            : CoordinationTrackingConfig.normalizedToUnits(pointer.y),
      ),
    );
  }

  void _recordThrough(int timestampMs) {
    final previousMs = _elapsedUs ~/ 1000;
    for (final spec in CoordinationTrackingConfig.segments) {
      if (spec.scheduledEndMs > previousMs &&
          spec.scheduledEndMs <= timestampMs) {
        if (_segmentTraces[spec.index - 1].samples.isEmpty) {
          _recordSampleAt(spec.scheduledStartMs, force: true);
        }
        _recordSampleAt(spec.scheduledEndMs - 1, force: true);
        if (spec.scheduledEndMs < CoordinationTrackingConfig.totalDurationMs) {
          _recordSampleAt(spec.scheduledEndMs, force: true);
        }
      }
    }
    _recordSampleAt(timestampMs);
  }

  Future<void> _finishMeasured() async {
    if (_finishing || !mounted) return;
    _finishing = true;
    final source = _inputSource;
    if (source == null) {
      _finishing = false;
      _invalidateMeasured('No pointer modality was captured.');
      return;
    }
    final metrics = CoordinationTrackingMetrics(
      inputSource: source,
      coordinationSegments: _segmentTraces.map((trace) {
        final spec = trace.spec;
        return CoordinationSegmentMetric(
          phase: spec.phase,
          segmentIndex: spec.index,
          speed: spec.speed,
          nominalDurationMs: spec.durationMs,
          actualStartMs: spec.scheduledStartMs,
          actualEndMs:
              spec.index == CoordinationTrackingConfig.totalSegmentCount
              ? (_measuredActualEndMs ?? spec.scheduledEndMs)
              : spec.scheduledEndMs,
          samples: trace.samples,
        );
      }).toList(),
      sessionCompleted: true,
      interrupted: false,
      backgroundEventCount: _backgroundEventCount,
      droppedFrameCount: _droppedFrameCount,
    );
    _pendingMetrics = metrics;
    await _submitMetrics(metrics);
  }

  Future<void> _submitMetrics(CoordinationTrackingMetrics metrics) async {
    final session = _session;
    if (session == null) return;
    setState(() {
      _stage = _CoordinationStage.submitting;
      _errorMessage = null;
    });
    try {
      final completed = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.coordinationTrackingCore,
            metrics: metrics,
          );
      if (!mounted) return;
      final indicators = completed.coordinationIndicators;
      if (indicators == null) {
        throw StateError(
          'The coordination audit is missing from the response.',
        );
      }
      setState(() {
        _session = completed;
        _indicators = indicators;
        _finishing = false;
        if (indicators.sessionValid) {
          _stage = _CoordinationStage.results;
        } else {
          _invalidReason = indicators.validityIssues.join(', ');
          _stage = _CoordinationStage.invalid;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _errorMessage = '$error';
        _stage = _CoordinationStage.error;
      });
    }
  }

  void _invalidateMeasured(String reason) {
    if (!_isTest) return;
    if (_ticker.isActive) _ticker.stop(canceled: true);
    setState(() {
      _running = false;
      _finishing = false;
      _invalidReason = reason;
      _stage = _CoordinationStage.invalid;
    });
  }

  CoordinationInputSource _sourceFor(PointerDeviceKind kind) => switch (kind) {
    PointerDeviceKind.mouse ||
    PointerDeviceKind.trackpad => CoordinationInputSource.mouse,
    PointerDeviceKind.stylus ||
    PointerDeviceKind.invertedStylus => CoordinationInputSource.stylus,
    _ => CoordinationInputSource.touch,
  };

  void _updatePointer({
    required int pointerId,
    required PointerDeviceKind kind,
    required Offset localPosition,
    required Size boardSize,
    required bool hover,
  }) {
    if (!_isGameplay || boardSize.shortestSide <= 0) return;
    final source = _sourceFor(kind);
    if (_inputSource != null && _inputSource != source) return;
    if (!hover && _activePointerId != null && _activePointerId != pointerId) {
      return;
    }
    if (!hover) _activePointerId = pointerId;
    final point = CoordinationPoint(
      (localPosition.dx / boardSize.width).clamp(0, 1).toDouble(),
      (localPosition.dy / boardSize.height).clamp(0, 1).toDouble(),
    );
    _pointer = point;
    final pointerX = CoordinationTrackingConfig.normalizedToUnits(point.x);
    final pointerY = CoordinationTrackingConfig.normalizedToUnits(point.y);
    final target = CoordinationTrackingConfig.targetUnitsAtMs(
      _isTest ? CoordinationTrackingConfig.practiceDurationMs : 0,
    );
    final activationDx = pointerX - target.x;
    final activationDy = pointerY - target.y;
    final activationRadius = CoordinationTrackingConfig.activationRadiusUnits;
    if (!_running &&
        activationDx * activationDx + activationDy * activationDy <=
            activationRadius * activationRadius) {
      // An incidental hover/touch outside the target must not lock a hybrid
      // device to the wrong modality. Lock only on successful activation.
      _inputSource ??= source;
      _activePointerId = hover ? null : pointerId;
      _startRun();
      return;
    }
    setState(() {});
  }

  void _releasePointer(int pointerId) {
    if (_activePointerId != pointerId) return;
    setState(() {
      _activePointerId = null;
      _pointer = null;
    });
  }

  void _pointerExited() {
    if (!_isGameplay) return;
    setState(() {
      _activePointerId = null;
      _pointer = null;
    });
  }

  Future<void> _openPause({bool resumeFrozenPractice = false}) async {
    if (_pauseOpen || !_isGameplay) return;
    _pauseOpen = true;
    final wasRunning = _running || resumeFrozenPractice;
    final measuredInterrupted = _isTest && _running;
    if (_running) _freezeTicker();
    if (measuredInterrupted) _invalidReason = 'The measured test was paused.';

    var showAgain = true;
    var interruptionResolved = false;
    while (mounted && showAgain) {
      if (!mounted) return;
      final action = await showDialog<ContinuousAttentionPauseAction>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xCC171642),
        builder: (_) => ContinuousAttentionPauseDialog(
          restartRequired: measuredInterrupted,
        ),
      );
      if (!mounted) break;
      switch (action) {
        case ContinuousAttentionPauseAction.resume:
          if (wasRunning && !measuredInterrupted) {
            _tickerBaseUs = _elapsedUs;
            _lastTickUs = _elapsedUs;
            _running = true;
            _ticker.start();
            setState(() {});
          }
          showAgain = false;
        case ContinuousAttentionPauseAction.restartPhase:
          if (_isTest || measuredInterrupted) {
            _prepareMeasured();
          } else {
            _preparePractice();
          }
          interruptionResolved = true;
          showAgain = false;
        case ContinuousAttentionPauseAction.rules:
          await showDialog<void>(
            context: context,
            barrierColor: const Color(0xCC171642),
            builder: (_) => const _CoordinationRulesDialog(),
          );
        case ContinuousAttentionPauseAction.exit:
          interruptionResolved = true;
          context.go(AppRoutes.games);
          showAgain = false;
        case null:
          showAgain = false;
      }
    }
    _pauseOpen = false;
    if (mounted &&
        measuredInterrupted &&
        !interruptionResolved &&
        _stage == _CoordinationStage.test) {
      _invalidateMeasured('The measured test was interrupted.');
    }
  }

  void _handleBack() {
    if (_isGameplay) {
      unawaited(_openPause());
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.games);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _handleBack(),
      child: Scaffold(
        backgroundColor: _isGameplay ? ZennytGamePalette.gameBlue : _canvas,
        body: SafeArea(child: _buildStage()),
      ),
    );
  }

  Widget _buildStage() => switch (_stage) {
    _CoordinationStage.cover => _buildCover(),
    _CoordinationStage.starting => const _CenteredProgress(
      label: 'Preparing your journey…',
    ),
    _CoordinationStage.tutorial => _buildTutorial(),
    _CoordinationStage.practice || _CoordinationStage.test => _buildGameplay(),
    _CoordinationStage.ready => _buildReady(),
    _CoordinationStage.submitting => const _CenteredProgress(
      label: 'Saving your movement…',
    ),
    _CoordinationStage.results => _buildResults(),
    _CoordinationStage.invalid => _buildInvalid(),
    _CoordinationStage.error => _buildError(),
  };

  Widget _buildCover() {
    return _JourneyPage(
      header: _CoordinationHeader(
        eyebrow: 'Zennyt Games',
        title: 'Je coordonne',
        onBack: _handleBack,
      ),
      content: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_violet, Color(0xFF6A5EEA)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x245146E8),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const _CoordinationCoverHero(),
        ),
        const SizedBox(height: 18),
        const GamePanel(
          child: Column(
            children: [
              _InfoRow(label: 'Goal', value: 'Coordinate vision and movement'),
              Divider(color: _border),
              _InfoRow(label: 'Duration', value: 'About 3 minutes'),
              Divider(color: _border),
              _InfoRow(label: 'Format', value: 'Practice + 12 segments'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GamePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works',
                style: AppTypography.titleLarge.copyWith(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const _StepLine(number: '1', label: 'Enter the center to begin'),
              const SizedBox(height: 10),
              const _StepLine(number: '2', label: 'Follow clockwise'),
              const SizedBox(height: 10),
              const _StepLine(
                number: '3',
                label: 'Stay precise as speed changes',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _PrivacyNote(),
      ],
      bottom: GamePrimaryButton(
        key: const ValueKey('coordination-start-journey'),
        label: 'Start the journey',
        onPressed: _startJourney,
      ),
    );
  }

  Widget _buildTutorial() {
    final page = _tutorials[_tutorialPage];
    return _JourneyPage(
      header: _CoordinationHeader(
        eyebrow: 'Je coordonne',
        title: 'Onboarding',
        onBack: _tutorialPage == 0
            ? () => setState(() => _stage = _CoordinationStage.cover)
            : () => setState(() => _tutorialPage--),
      ),
      content: [
        GamePanel(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _TutorialIllustration(kind: page.kind),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _violet.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'STEP ${_tutorialPage + 1} OF ${_tutorials.length}',
                  style: AppTypography.labelSmall.copyWith(
                    color: _violet,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.body,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: _muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              _PageDots(current: _tutorialPage, count: _tutorials.length),
            ],
          ),
        ),
      ],
      bottom: GamePrimaryButton(
        label: _tutorialPage == 2 ? 'Begin practice' : 'Next',
        onPressed: _nextTutorial,
      ),
    );
  }

  Widget _buildReady() {
    return _JourneyPage(
      header: _CoordinationHeader(
        eyebrow: 'Je coordonne',
        title: 'Practice complete',
        onBack: _handleBack,
      ),
      content: [
        const SizedBox(height: 12),
        const _CompletionBadge(),
        const SizedBox(height: 24),
        Text(
          'Ready for the measured round',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You will follow 12 consecutive segments. The speed alternates, but the path remains predictable.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        const GamePanel(
          backgroundColor: Color(0xFFF0F2FF),
          borderColor: Color(0xFFD6DAFF),
          child: Column(
            children: [
              _ReadyLine(icon: Icons.timer_outlined, text: 'About 56 seconds'),
              SizedBox(height: 12),
              _ReadyLine(
                icon: Icons.visibility_off_outlined,
                text: 'No live score',
              ),
              SizedBox(height: 12),
              _ReadyLine(
                icon: Icons.replay_rounded,
                text: 'An interruption restarts the test',
              ),
            ],
          ),
        ),
      ],
      bottom: GamePrimaryButton(
        key: const ValueKey('coordination-start-test'),
        label: 'Start measured round',
        onPressed: _prepareMeasured,
      ),
    );
  }

  Widget _buildGameplay() {
    final segment = CoordinationTrackingConfig.segmentAtMs(_elapsedUs ~/ 1000);
    final remainingUs = math.max(0, _runEndUs - _elapsedUs);
    final seconds = (remainingUs / Duration.microsecondsPerSecond).ceil();
    final progress = (_elapsedUs - _runStartUs) / (_runEndUs - _runStartUs);
    final title = _isPractice ? 'Practice round' : 'Focused round';
    final compact =
        MediaQuery.sizeOf(context).height < 720 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: _CoordinationHeader(
            eyebrow: _isPractice
                ? 'Je coordonne · Practice'
                : 'Je coordonne · Test',
            title: title,
            onBack: _openPause,
            onDark: true,
            menuIcon: Icons.pause_rounded,
            menuTooltip: 'Pause',
            onMenu: _openPause,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _TrackingHud(
            segment: segment,
            displayedSegmentIndex: _isTest
                ? segment.index -
                      CoordinationTrackingConfig.practiceSegmentCount
                : segment.index,
            segmentCount: _isTest
                ? CoordinationTrackingConfig.testSegmentCount
                : CoordinationTrackingConfig.practiceSegmentCount,
            seconds: seconds,
            progress: progress,
          ),
        ),
        SizedBox(height: compact ? 8 : 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardExtent = math
                  .min(
                    constraints.maxWidth - 32,
                    constraints.maxHeight - (compact ? 50 : 92),
                  )
                  .clamp(220.0, 520.0);
              final boardSize = Size.square(boardExtent);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Semantics(
                        container: true,
                        label:
                            'Coordination board. Follow the target clockwise. The status is not announced every frame.',
                        child: MouseRegion(
                          onExit: (_) => _pointerExited(),
                          child: Listener(
                            key: const ValueKey('coordination-board'),
                            behavior: HitTestBehavior.opaque,
                            onPointerHover: (event) => _updatePointer(
                              pointerId: event.pointer,
                              kind: event.kind,
                              localPosition: event.localPosition,
                              boardSize: boardSize,
                              hover: true,
                            ),
                            onPointerDown: (event) => _updatePointer(
                              pointerId: event.pointer,
                              kind: event.kind,
                              localPosition: event.localPosition,
                              boardSize: boardSize,
                              hover: false,
                            ),
                            onPointerMove: (event) => _updatePointer(
                              pointerId: event.pointer,
                              kind: event.kind,
                              localPosition: event.localPosition,
                              boardSize: boardSize,
                              hover: false,
                            ),
                            onPointerUp: (event) =>
                                _releasePointer(event.pointer),
                            onPointerCancel: (event) =>
                                _releasePointer(event.pointer),
                            child: DecoratedBox(
                              key: const ValueKey('coordination-board-surface'),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: CustomPaint(
                                  size: boardSize,
                                  painter: _CoordinationBoardPainter(
                                    target: _target,
                                    pointer: _pointer,
                                    feedback: _feedback,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TrackingStatus(
                      running: _running,
                      feedback: _feedback,
                      speed: segment.speed,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 12),
                      const _FeedbackLegend(compact: true),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final report = _indicators!;
    final score =
        _session?.lastAttempt?.score.rawPoints ??
        report.provisionalAccuracyScore;
    return _JourneyPage(
      header: _CoordinationHeader(
        eyebrow: 'Je coordonne',
        title: 'Journey complete',
        onBack: () => context.go(AppRoutes.games),
      ),
      content: [
        Center(child: _ResultDial(score: score)),
        const SizedBox(height: 18),
        Text(
          'A steady coordination snapshot',
          textAlign: TextAlign.center,
          style: AppTypography.headlineSmall.copyWith(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is a descriptive result, not a diagnosis or ranking.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        GamePanel(
          child: Column(
            children: [
              _MetricLine(
                label: 'Overall accuracy',
                value: '${report.overallAccuracyPercent.toStringAsFixed(1)}%',
              ),
              const Divider(color: _border),
              _MetricLine(
                label: 'Slow / fast',
                value:
                    '${report.slowAccuracyPercent.toStringAsFixed(1)}% / ${report.fastAccuracyPercent.toStringAsFixed(1)}%',
              ),
              const Divider(color: _border),
              _MetricLine(
                label: 'Long / short',
                value:
                    '${report.longSegmentAccuracyPercent.toStringAsFixed(1)}% / ${report.shortSegmentAccuracyPercent.toStringAsFixed(1)}%',
              ),
              const Divider(color: _border),
              _MetricLine(
                label: 'Mean center distance',
                value: report.averageCenterDistance.toStringAsFixed(1),
              ),
            ],
          ),
        ),
      ],
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GamePrimaryButton(
            label: 'Back to games',
            onPressed: () => context.go(AppRoutes.games),
          ),
          const SizedBox(height: 10),
          GameOutlineButton(label: 'Play again', onPressed: _startJourney),
        ],
      ),
    );
  }

  Widget _buildInvalid() {
    return _JourneyPage(
      header: _CoordinationHeader(
        eyebrow: 'Je coordonne',
        title: 'Test interrupted',
        onBack: () => context.go(AppRoutes.games),
      ),
      content: [
        const SizedBox(height: 20),
        const _StateIcon(
          icon: Icons.replay_rounded,
          color: _orange,
          background: Color(0xFFFFF3E8),
        ),
        const SizedBox(height: 22),
        Text(
          'Let’s restart the measured round',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _invalidReason ?? 'The measurement could not be validated.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 20),
        const GamePanel(
          backgroundColor: Color(0xFFFFFAF5),
          borderColor: Color(0xFFFFDFC1),
          child: Text(
            'Your previous attempt is not scored. Restarting keeps the same journey session and begins from segment 1.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _navy, height: 1.45),
          ),
        ),
      ],
      bottom: GamePrimaryButton(
        key: const ValueKey('coordination-restart-test'),
        label: 'Restart the test',
        icon: Icons.replay_rounded,
        onPressed: _prepareMeasured,
      ),
    );
  }

  Widget _buildError() {
    final canRetrySubmit = _pendingMetrics != null;
    return _JourneyPage(
      header: _CoordinationHeader(
        eyebrow: 'Je coordonne',
        title: 'Something went wrong',
        onBack: () => context.go(AppRoutes.games),
      ),
      content: [
        const SizedBox(height: 24),
        const _StateIcon(
          icon: Icons.cloud_off_rounded,
          color: ZennytGamePalette.error,
          background: Color(0xFFFFEEEE),
        ),
        const SizedBox(height: 22),
        Text(
          'Your movement is safe on this screen.',
          textAlign: TextAlign.center,
          style: AppTypography.headlineSmall.copyWith(
            color: _navy,
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
        onPressed: canRetrySubmit
            ? () => _submitMetrics(_pendingMetrics!)
            : _startJourney,
      ),
    );
  }
}

class _CoordinationCoverHero extends StatelessWidget {
  const _CoordinationCoverHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.35;
        final logo = Semantics(
          image: true,
          label: 'Je coordonne game logo',
          child: SizedBox(
            key: const ValueKey('coordination-cover-logo'),
            width: stacked ? 166 : 144,
            height: stacked ? 166 : 144,
            child: Transform.scale(
              scale: 1.1,
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        );

        if (stacked) {
          return Column(
            children: [
              logo,
              const SizedBox(height: 8),
              const _CoordinationCoverCopy(centered: true),
            ],
          );
        }
        return Row(
          children: [
            const Expanded(child: _CoordinationCoverCopy()),
            const SizedBox(width: 8),
            logo,
          ],
        );
      },
    );
  }
}

class _CoordinationCoverCopy extends StatelessWidget {
  const _CoordinationCoverCopy({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Follow the motion.\nFind your rhythm.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Guide the cursor around a predictable path with calm, precise movement.',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TutorialData {
  const _TutorialData(this.title, this.body, this.kind);

  final String title;
  final String body;
  final int kind;
}

class _MutableSegmentTrace {
  _MutableSegmentTrace(this.spec);

  final CoordinationSegmentSpec spec;
  final List<CoordinationTrackingSample> samples = [];
}

const _tutorials = <_TutorialData>[
  _TutorialData(
    'Meet the moving guide',
    'Enter the center of the orange target. It will then travel clockwise around the fixed square.',
    0,
  ),
  _TutorialData(
    'Let the target guide you',
    'White with a check means centered. Orange means still inside. Red with an X means outside.',
    1,
  ),
  _TutorialData(
    'Keep one continuous rhythm',
    'The speed changes between slow and fast. Follow naturally; no result is shown while you play.',
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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

class _CoordinationHeader extends StatelessWidget {
  const _CoordinationHeader({
    required this.eyebrow,
    required this.title,
    required this.onBack,
    this.onMenu,
    this.menuIcon = Icons.more_horiz_rounded,
    this.menuTooltip = 'More options',
    this.onDark = false,
  });

  final String eyebrow;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMenu;
  final IconData menuIcon;
  final String menuTooltip;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          tooltip: 'Back',
          icon: Icons.chevron_left_rounded,
          onTap: onBack,
          onDark: onDark,
        ),
        const SizedBox(width: 14),
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
                  color: onDark ? Colors.white : _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (onMenu == null)
          const SizedBox(width: 52, height: 52)
        else
          _HeaderIconButton(
            tooltip: menuTooltip,
            icon: menuIcon,
            onTap: onMenu!,
            onDark: onDark,
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.onDark = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton.outlined(
        tooltip: tooltip,
        onPressed: onTap,
        style: IconButton.styleFrom(
          foregroundColor: onDark ? Colors.white : _navy,
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

class _TrackingHud extends StatelessWidget {
  const _TrackingHud({
    required this.segment,
    required this.displayedSegmentIndex,
    required this.segmentCount,
    required this.seconds,
    required this.progress,
  });

  final CoordinationSegmentSpec segment;
  final int displayedSegmentIndex;
  final int segmentCount;
  final int seconds;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
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
                child: _HudValue(
                  label: 'Segment',
                  value: '$displayedSegmentIndex / $segmentCount',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _HudValue(
                  label: 'Pace',
                  value: segment.speed == CoordinationTrackingSpeed.slow
                      ? 'Steady'
                      : 'Quick',
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: _HudValue(label: 'Time', value: '${seconds}s'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(_cyan),
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
          style: AppTypography.labelSmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CoordinationBoardPainter extends CustomPainter {
  const _CoordinationBoardPainter({
    required this.target,
    required this.pointer,
    required this.feedback,
  });

  final CoordinationPoint target;
  final CoordinationPoint? pointer;
  final _TargetFeedback feedback;

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(
      size.width * .115,
      size.height * .115,
      size.width * .77,
      size.height * .77,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, Radius.circular(size.width * .06)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.38),
    );
    final inset = size.width * CoordinationTrackingConfig.traceInsetRatio;
    final innerRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - 2 * inset,
      size.height - 2 * inset,
    );
    canvas.drawRect(
      innerRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.9),
    );

    final targetOffset = Offset(target.x * size.width, target.y * size.height);
    final radius =
        size.shortestSide * CoordinationTrackingConfig.targetRadiusRatio;
    final targetColor = switch (feedback) {
      _TargetFeedback.waiting || _TargetFeedback.edge => _orange,
      _TargetFeedback.centered => Colors.white,
      _TargetFeedback.outside => ZennytGamePalette.error,
    };
    canvas.drawCircle(
      targetOffset.translate(0, 3),
      radius + 3,
      Paint()..color = _navy.withValues(alpha: .22),
    );
    canvas.drawCircle(
      targetOffset,
      radius + 9,
      Paint()..color = targetColor.withValues(alpha: 0.24),
    );
    canvas.drawCircle(targetOffset, radius, Paint()..color = targetColor);
    canvas.drawCircle(
      targetOffset,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    if (feedback == _TargetFeedback.centered) {
      final path = Path()
        ..moveTo(targetOffset.dx - radius * .38, targetOffset.dy)
        ..lineTo(targetOffset.dx - radius * .08, targetOffset.dy + radius * .3)
        ..lineTo(
          targetOffset.dx + radius * .42,
          targetOffset.dy - radius * .32,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = ZennytGamePalette.success
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 4,
      );
    } else if (feedback == _TargetFeedback.outside) {
      final mark = radius * .3;
      final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(
          targetOffset.translate(-mark, -mark),
          targetOffset.translate(mark, mark),
          paint,
        )
        ..drawLine(
          targetOffset.translate(mark, -mark),
          targetOffset.translate(-mark, mark),
          paint,
        );
    }

    final cursor = pointer;
    if (cursor != null) {
      final center = Offset(cursor.x * size.width, cursor.y * size.height);
      final cursorPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round;
      const innerGap = 7.0;
      const outer = 19.0;
      canvas
        ..drawLine(
          center.translate(0, -outer),
          center.translate(0, -innerGap),
          cursorPaint,
        )
        ..drawLine(
          center.translate(0, innerGap),
          center.translate(0, outer),
          cursorPaint,
        )
        ..drawLine(
          center.translate(-outer, 0),
          center.translate(-innerGap, 0),
          cursorPaint,
        )
        ..drawLine(
          center.translate(innerGap, 0),
          center.translate(outer, 0),
          cursorPaint,
        )
        ..drawCircle(center, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CoordinationBoardPainter oldDelegate) =>
      oldDelegate.target.x != target.x ||
      oldDelegate.target.y != target.y ||
      oldDelegate.pointer?.x != pointer?.x ||
      oldDelegate.pointer?.y != pointer?.y ||
      oldDelegate.feedback != feedback;
}

class _TrackingStatus extends StatelessWidget {
  const _TrackingStatus({
    required this.running,
    required this.feedback,
    required this.speed,
  });

  final bool running;
  final _TargetFeedback feedback;
  final CoordinationTrackingSpeed speed;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = !running
        ? (Icons.ads_click_rounded, _orange, 'Enter the center to begin')
        : switch (feedback) {
            _TargetFeedback.centered => (
              Icons.check_circle_rounded,
              ZennytGamePalette.success,
              'Centered · keep the rhythm',
            ),
            _TargetFeedback.edge => (
              Icons.radio_button_checked_rounded,
              _orange,
              'Inside · move toward the center',
            ),
            _TargetFeedback.outside => (
              Icons.cancel_rounded,
              ZennytGamePalette.error,
              'Outside · reconnect calmly',
            ),
            _TargetFeedback.waiting => (
              Icons.ads_click_rounded,
              _orange,
              'Enter the center to begin',
            ),
          };
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: _navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            speed == CoordinationTrackingSpeed.slow ? 'SLOW' : 'FAST',
            style: AppTypography.labelSmall.copyWith(
              color: speed == CoordinationTrackingSpeed.slow ? _cyan : _pink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackLegend extends StatelessWidget {
  const _FeedbackLegend({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: compact ? 8 : 12,
      runSpacing: 8,
      children: const [
        _LegendItem(
          color: Colors.white,
          icon: Icons.check_rounded,
          iconColor: ZennytGamePalette.success,
          label: 'Centered',
        ),
        _LegendItem(
          color: _orange,
          icon: Icons.circle,
          iconColor: Colors.white,
          label: 'Inside',
        ),
        _LegendItem(
          color: ZennytGamePalette.error,
          icon: Icons.close_rounded,
          iconColor: Colors.white,
          label: 'Outside',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: _navy)),
        ],
      ),
    );
  }
}

class _TutorialIllustration extends StatelessWidget {
  const _TutorialIllustration({required this.kind});

  final int kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('coordination-tutorial-illustration-$kind'),
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ZennytGamePalette.gameBlue, ZennytGamePalette.gamePanel],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: switch (kind) {
        1 => const _TutorialFeedbackDemo(),
        2 => const _TutorialSpeedDemo(),
        _ => Column(
          children: [
            const Expanded(
              child: SizedBox(
                width: 180,
                child: CustomPaint(painter: _TutorialPathPainter()),
              ),
            ),
            const SizedBox(height: 8),
            _TutorialDarkHint(
              icon: Icons.ads_click_rounded,
              label: 'Enter the center to begin',
            ),
          ],
        ),
      },
    );
  }
}

class _TutorialDarkHint extends StatelessWidget {
  const _TutorialDarkHint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialFeedbackDemo extends StatelessWidget {
  const _TutorialFeedbackDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'READ THE CIRCLE',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 14),
        const Expanded(
          child: Row(
            children: [
              Expanded(
                child: _TutorialTargetState(
                  fill: Colors.white,
                  icon: Icons.check_rounded,
                  iconColor: ZennytGamePalette.success,
                  label: 'Centered',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _TutorialTargetState(
                  fill: ZennytGamePalette.ruleOrange,
                  icon: Icons.circle,
                  iconColor: Colors.white,
                  label: 'Inside',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _TutorialTargetState(
                  fill: ZennytGamePalette.error,
                  icon: Icons.close_rounded,
                  iconColor: Colors.white,
                  label: 'Outside',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _TutorialDarkHint(
          icon: Icons.center_focus_strong_rounded,
          label: 'Move calmly back toward the center',
        ),
      ],
    );
  }
}

class _TutorialTargetState extends StatelessWidget {
  const _TutorialTargetState({
    required this.fill,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final Color fill;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x26071333), blurRadius: 12),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 27),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialSpeedDemo extends StatelessWidget {
  const _TutorialSpeedDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'SAME PATH · TWO PACES',
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 7),
        const Expanded(child: CustomPaint(painter: _TutorialSpeedPainter())),
        const SizedBox(height: 7),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PacePill(label: 'STEADY', color: ZennytGamePalette.cyan),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                Icons.sync_alt_rounded,
                color: Colors.white70,
                size: 21,
              ),
            ),
            _PacePill(label: 'QUICK', color: ZennytGamePalette.magenta),
          ],
        ),
      ],
    );
  }
}

class _PacePill extends StatelessWidget {
  const _PacePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TutorialPathPainter extends CustomPainter {
  const _TutorialPathPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(30, 15, size.width - 60, size.height - 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(9), const Radius.circular(16)),
      Paint()
        ..color = Colors.white.withValues(alpha: .34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final ball = Offset(rect.left, rect.top);
    canvas.drawCircle(ball, 22, Paint()..color = _orange.withValues(alpha: .2));
    canvas.drawCircle(ball, 16, Paint()..color = _orange);
    canvas.drawCircle(
      ball,
      16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    final cursorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(ball.translate(0, -25), ball.translate(0, -8), cursorPaint)
      ..drawLine(ball.translate(0, 8), ball.translate(0, 25), cursorPaint)
      ..drawLine(ball.translate(-25, 0), ball.translate(-8, 0), cursorPaint)
      ..drawLine(ball.translate(8, 0), ball.translate(25, 0), cursorPaint)
      ..drawCircle(ball, 2.5, Paint()..color = Colors.white);
    final arrow = Path()
      ..moveTo(rect.center.dx - 20, rect.top - 9)
      ..lineTo(rect.center.dx + 22, rect.top - 9)
      ..lineTo(rect.center.dx + 12, rect.top - 17)
      ..moveTo(rect.center.dx + 22, rect.top - 9)
      ..lineTo(rect.center.dx + 12, rect.top - 1);
    canvas.drawPath(
      arrow,
      Paint()
        ..color = _cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TutorialSpeedPainter extends CustomPainter {
  const _TutorialSpeedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(42, 10, size.width - 84, size.height - 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(7), const Radius.circular(14)),
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: .88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final first = Offset(rect.left + rect.width * .28, rect.top);
    final second = Offset(rect.left + rect.width * .72, rect.top);
    canvas
      ..drawCircle(first, 11, Paint()..color = _cyan)
      ..drawCircle(second, 11, Paint()..color = _pink);

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      first.translate(15, 0),
      second.translate(-18, 0),
      arrowPaint,
    );
    canvas
      ..drawLine(
        second.translate(-18, 0),
        second.translate(-26, -7),
        arrowPaint,
      )
      ..drawLine(
        second.translate(-18, 0),
        second.translate(-26, 7),
        arrowPaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
                ? Duration.zero
                : const Duration(milliseconds: 180),
            width: index == current ? 30 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == current ? _pink : _border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
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
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: _muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _pink,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: _navy,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: _pink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your movement data stays private.',
              style: AppTypography.bodyMedium.copyWith(color: _navy),
            ),
          ),
        ],
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
        Icon(icon, color: _violet, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          color: const Color(0xFFE9FBF3),
          shape: BoxShape.circle,
          border: Border.all(color: ZennytGamePalette.success, width: 2),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 58,
          color: ZennytGamePalette.success,
        ),
      ),
    );
  }
}

class _ResultDial extends StatelessWidget {
  const _ResultDial({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Provisional descriptive accuracy score $score out of 100',
      child: Container(
        key: const ValueKey('coordination-result-score'),
        width: 164,
        height: 164,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_violet, _cyan]),
          boxShadow: const [
            BoxShadow(
              color: Color(0x334E46E8),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
          border: Border.all(color: Colors.white, width: 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score',
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'PROVISIONAL / 100',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
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
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: _muted),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: _navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
        width: 104,
        height: 104,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 54),
      ),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _pink),
          const SizedBox(height: 18),
          Text(label, style: AppTypography.bodyLarge.copyWith(color: _navy)),
        ],
      ),
    );
  }
}

class _CoordinationRulesDialog extends StatelessWidget {
  const _CoordinationRulesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rules / Help',
              style: AppTypography.headlineSmall.copyWith(
                color: _navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const _ReadyLine(
              icon: Icons.ads_click_rounded,
              text: 'Enter the inner half of the orange target to start.',
            ),
            const SizedBox(height: 12),
            const _ReadyLine(
              icon: Icons.rotate_right_rounded,
              text: 'Follow clockwise around the fixed square.',
            ),
            const SizedBox(height: 12),
            const _ReadyLine(
              icon: Icons.speed_rounded,
              text: 'Keep following when the pace changes.',
            ),
            const SizedBox(height: 12),
            const _ReadyLine(
              icon: Icons.restart_alt_rounded,
              text: 'Leaving or pausing a measured round restarts the test.',
            ),
            const SizedBox(height: 22),
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
