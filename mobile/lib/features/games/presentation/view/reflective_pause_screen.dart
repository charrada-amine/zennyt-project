import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../../navigation/presentation/widgets/app_bottom_nav.dart';
import '../../domain/config/reflective_pause_config.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/reflective_pause_metrics.dart';
import '../emotional_regulation_session_provider.dart';
import '../games_providers.dart';
import '../widgets/emotional_game_pause_dialog.dart';
import '../widgets/game_system_components.dart';

const _ink = Color(0xFF28234F);
const _muted = Color(0xFF607095);
const _border = Color(0xFFDCE5F5);
const _canvas = Color(0xFFF7F9FE);
const _magenta = Color(0xFFD72C83);
const _violet = Color(0xFF5146E8);
const _green = Color(0xFF20B978);
const _navy = Color(0xFF071B3A);
const _logoAsset = 'assets/games icons/Reflective Pause.png';

enum _ReflectiveStage {
  cover,
  intro,
  tutorial,
  loading,
  gameplay,
  saved,
  results,
  insights,
  error,
}

class _PressureMoment {
  const _PressureMoment({
    required this.id,
    required this.context,
    required this.message,
  });

  final String id;
  final String context;
  final String message;
}

const _moments = <_PressureMoment>[
  _PressureMoment(
    id: 'PRESSURE_01',
    context: 'Your manager sends a tense message before a deadline.',
    message: 'Why is this still not finished?\nThis is unacceptable.',
  ),
  _PressureMoment(
    id: 'PRESSURE_02',
    context: 'You receive unexpected criticism about your work.',
    message: 'This does not meet the standard I expected.',
  ),
  _PressureMoment(
    id: 'PRESSURE_03',
    context: 'A last-minute problem changes your priorities.',
    message: 'We need a new solution right now.',
  ),
  _PressureMoment(
    id: 'PRESSURE_04',
    context: 'A misunderstanding makes a conversation tense.',
    message: 'That is not what I said. Why did you do that?',
  ),
  _PressureMoment(
    id: 'PRESSURE_05',
    context: 'A stressful request arrives while you are already busy.',
    message: 'Can you handle this immediately?',
  ),
  _PressureMoment(
    id: 'PRESSURE_06',
    context: 'A client sends a direct complaint.',
    message: 'I am unhappy with what was delivered.',
  ),
  _PressureMoment(
    id: 'PRESSURE_07',
    context: 'Someone interrupts you repeatedly in a meeting.',
    message: 'Let me finish — I already know what you are going to say.',
  ),
  _PressureMoment(
    id: 'PRESSURE_08',
    context: 'You are blamed publicly for a shared problem.',
    message: 'This delay is your responsibility.',
  ),
  _PressureMoment(
    id: 'PRESSURE_09',
    context: 'A plan changes suddenly just before execution.',
    message: 'We are changing direction. Start over.',
  ),
  _PressureMoment(
    id: 'PRESSURE_10',
    context: 'Someone questions your competence under pressure.',
    message: 'Are you sure you can manage this?',
  ),
];

const _responses = <ReflectivePauseResponseType>[
  ReflectivePauseResponseType.respondImpulsively,
  ReflectivePauseResponseType.breatheAnalyze,
  ReflectivePauseResponseType.wait,
  ReflectivePauseResponseType.askForMoreInformation,
  ReflectivePauseResponseType.reformulateCalmly,
];

extension on ReflectivePauseResponseType {
  String get label => switch (this) {
    ReflectivePauseResponseType.respondImpulsively => 'Respond immediately',
    ReflectivePauseResponseType.breatheAnalyze => 'Breathe and analyze',
    ReflectivePauseResponseType.wait => 'Wait before answering',
    ReflectivePauseResponseType.askForMoreInformation =>
      'Ask for more information',
    ReflectivePauseResponseType.reformulateCalmly => 'Reformulate calmly',
  };
}

/// Parcours complet « Reflective Pause ».
///
/// Le client mesure le temps de réponse et le choix brut. Le score et les trois
/// indicateurs affichés aux résultats sont exclusivement renvoyés par le
/// backend (ou par son miroir exact en mode mock).
class ReflectivePauseScreen extends ConsumerStatefulWidget {
  const ReflectivePauseScreen({super.key, this.now});

  /// Horloge injectable pour rendre le timer déterministe en test.
  final DateTime Function()? now;

  @override
  ConsumerState<ReflectivePauseScreen> createState() =>
      _ReflectivePauseScreenState();
}

class _ReflectivePauseScreenState extends ConsumerState<ReflectivePauseScreen>
    with GameMusicMixin {
  _ReflectiveStage _stage = _ReflectiveStage.cover;
  GameSession? _session;
  int _momentIndex = 0;
  ReflectivePauseResponseType? _selectedResponse;
  final List<ReflectivePauseMomentMetric> _metrics = [];
  Timer? _clock;
  int _elapsedMs = 0;
  int _elapsedBeforeStartMs = 0;
  DateTime? _clockStartedAt;
  bool _submitting = false;
  String? _errorMessage;

  bool _buttonsInput = true;

  bool get _minimumReached =>
      _elapsedMs >= ReflectivePauseConfig.minimumPauseMs;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _selectMainTab(int index) {
    ref.read(navTabProvider.notifier).select(index);
    context.go(AppRoutes.home);
  }

  void _setStage(_ReflectiveStage stage) {
    setState(() => _stage = stage);
  }

  Future<void> _startGame() async {
    setState(() {
      _stage = _ReflectiveStage.loading;
      _errorMessage = null;
    });
    try {
      final sessionStore = ref.read(
        emotionalRegulationSessionProvider.notifier,
      );
      final session =
          sessionStore.reusableFor(MiniGame.reflectivePauseCore) ??
          await ref
              .read(gamesRepositoryProvider)
              .startSession(GameType.emotionalRegulation);
      sessionStore.keep(session);
      if (!mounted) return;
      setState(() {
        _session = session;
        _momentIndex = 0;
        _metrics.clear();
        _stage = _ReflectiveStage.gameplay;
      });
      _beginMoment();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _stage = _ReflectiveStage.error;
      });
    }
  }

  void _beginMoment() {
    _clock?.cancel();
    _elapsedBeforeStartMs = 0;
    _clockStartedAt = null;
    setState(() {
      _selectedResponse = null;
      _elapsedMs = 0;
    });
    _startClock();
  }

  void _startClock() {
    _clockStartedAt = _now();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _stage != _ReflectiveStage.gameplay) return;
      _refreshElapsed();
    });
  }

  void _refreshElapsed() {
    final startedAt = _clockStartedAt;
    if (startedAt == null) return;
    final measured =
        _elapsedBeforeStartMs + _now().difference(startedAt).inMilliseconds;
    if (measured != _elapsedMs) setState(() => _elapsedMs = measured);
  }

  void _freezeClock() {
    _refreshElapsed();
    _clock?.cancel();
    _elapsedBeforeStartMs = _elapsedMs;
    _clockStartedAt = null;
  }

  void _resumeClockIfNeeded() {
    if (_stage != _ReflectiveStage.gameplay) return;
    _startClock();
  }

  Future<void> _openPause() async {
    _freezeClock();
    final action = await showDialog<EmotionalGamePauseAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xCC1B1B4B),
      builder: (_) => EmotionalGamePauseDialog(
        buttonsInput: _buttonsInput,
        onInputMode: (value) => setState(() => _buttonsInput = value),
      ),
    );
    if (!mounted) return;
    if (action == EmotionalGamePauseAction.rules) {
      await showDialog<void>(
        context: context,
        barrierColor: const Color(0xCC1B1B4B),
        builder: (_) => const _ReflectiveRulesDialog(),
      );
    } else if (action == EmotionalGamePauseAction.exit) {
      context.go(AppRoutes.games);
      return;
    }
    if (mounted) _resumeClockIfNeeded();
  }

  Future<void> _validateResponse() async {
    final response = _selectedResponse;
    if (!_minimumReached || response == null || _submitting) return;
    _freezeClock();
    final moment = _moments[_momentIndex];
    _metrics.add(
      ReflectivePauseMomentMetric(
        momentId: moment.id,
        selectedResponse: response,
        responseTimeMs: _elapsedMs,
        minimumTimerReached: _minimumReached,
      ),
    );
    setState(() => _stage = _ReflectiveStage.saved);

    if (!_reducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    if (!mounted) return;
    if (_momentIndex == _moments.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _momentIndex += 1;
      _stage = _ReflectiveStage.gameplay;
    });
    _beginMoment();
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    setState(() {
      _submitting = true;
      _stage = _ReflectiveStage.loading;
    });
    try {
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.reflectivePauseCore,
            metrics: ReflectivePauseMetrics(moments: List.of(_metrics)),
          );
      ref.read(emotionalRegulationSessionProvider.notifier).keep(updated);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _submitting = false;
        _stage = _ReflectiveStage.results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = '$error';
        _stage = _ReflectiveStage.error;
      });
    }
  }

  void _back() {
    switch (_stage) {
      case _ReflectiveStage.cover:
        context.go(AppRoutes.games);
      case _ReflectiveStage.intro:
        _setStage(_ReflectiveStage.cover);
      case _ReflectiveStage.tutorial:
        _setStage(_ReflectiveStage.intro);
      case _ReflectiveStage.results:
        context.go(AppRoutes.games);
      case _ReflectiveStage.insights:
        _setStage(_ReflectiveStage.results);
      case _ReflectiveStage.error:
        _setStage(_ReflectiveStage.cover);
      case _ReflectiveStage.loading ||
          _ReflectiveStage.gameplay ||
          _ReflectiveStage.saved:
        _openPause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNav = switch (_stage) {
      _ReflectiveStage.cover ||
      _ReflectiveStage.intro ||
      _ReflectiveStage.tutorial => true,
      _ => false,
    };
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(selectedTab: 2, onSelect: _selectMainTab)
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: _reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: switch (_stage) {
            _ReflectiveStage.cover => _CoverView(
              key: const ValueKey('reflective-cover'),
              onBack: _back,
              onTutorial: () => _setStage(_ReflectiveStage.intro),
              onStart: () => _setStage(_ReflectiveStage.intro),
            ),
            _ReflectiveStage.intro => _IntroView(
              key: const ValueKey('reflective-intro'),
              onBack: _back,
              onContinue: () => _setStage(_ReflectiveStage.tutorial),
            ),
            _ReflectiveStage.tutorial => _TutorialView(
              key: const ValueKey('reflective-tutorial'),
              onBack: _back,
              onStart: _startGame,
            ),
            _ReflectiveStage.loading => const _LoadingView(
              key: ValueKey('reflective-loading'),
            ),
            _ReflectiveStage.gameplay => _GameplayView(
              key: ValueKey('reflective-gameplay-$_momentIndex'),
              moment: _moments[_momentIndex],
              momentNumber: _momentIndex + 1,
              elapsedMs: _elapsedMs,
              minimumReached: _minimumReached,
              selectedResponse: _selectedResponse,
              onSelect: (response) =>
                  setState(() => _selectedResponse = response),
              onValidate: _validateResponse,
              onPause: _openPause,
            ),
            _ReflectiveStage.saved => _SavedView(
              key: ValueKey('reflective-saved-$_momentIndex'),
              momentNumber: _momentIndex + 1,
            ),
            _ReflectiveStage.results => _ResultsView(
              key: const ValueKey('reflective-results'),
              session: _session,
              onBack: _back,
              onInsights: () => _setStage(_ReflectiveStage.insights),
            ),
            _ReflectiveStage.insights => _InsightsView(
              key: const ValueKey('reflective-insights'),
              session: _session,
              onBack: _back,
              onFinish: () => context.go(AppRoutes.games),
            ),
            _ReflectiveStage.error => _ErrorView(
              key: const ValueKey('reflective-error'),
              message: _errorMessage ?? 'An unexpected error occurred.',
              onBack: _back,
              onRetry: _startGame,
            ),
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.title, this.onPause});

  final VoidCallback onBack;
  final String? title;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Back',
          onTap: onBack,
        ),
        if (title != null) ...[
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title!,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ] else
          const Spacer(),
        if (onPause != null)
          _SquareIconButton(
            icon: Icons.pause_rounded,
            tooltip: 'Pause',
            onTap: onPause!,
          ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Icon(icon, color: _ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverView extends StatelessWidget {
  const _CoverView({
    super.key,
    required this.onBack,
    required this.onTutorial,
    required this.onStart,
  });

  final VoidCallback onBack;
  final VoidCallback onTutorial;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            children: [
              _TopBar(onBack: onBack),
              const SizedBox(height: 8),
              Container(
                height: 262,
                padding: const EdgeInsets.fromLTRB(26, 28, 18, 22),
                decoration: BoxDecoration(
                  color: _violet,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Impulse Control',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 34),
                        Text(
                          'Reflective\nPause',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 39,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Le Temps Réflexif',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    Align(
                      alignment: const Alignment(1.1, 0.35),
                      child: Image.asset(
                        _logoAsset,
                        width: 145,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reflective Pause',
                style: TextStyle(
                  color: _ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Impulse Control',
                style: TextStyle(
                  color: _magenta,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Face pressure moments, pause before reacting, and choose a calm response.',
                style: TextStyle(color: _muted, fontSize: 17, height: 1.45),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(label: 'Impulse Control', color: Color(0xFF2871FF)),
                  _Tag(label: 'Pressure moments', color: _magenta),
                  _Tag(label: 'Journey patterns', color: _green),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
          child: Column(
            children: [
              GameOutlineButton(
                key: const ValueKey('reflective-view-tutorial'),
                label: 'View tutorial',
                onPressed: onTutorial,
              ),
              const SizedBox(height: 12),
              GamePrimaryButton(
                key: const ValueKey('reflective-start-mission'),
                label: 'Start mission',
                onPressed: onStart,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({super.key, required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _InfoPage(
      onBack: onBack,
      title: 'Train calm responses\nunder pressure',
      subtitle:
          'You will move through short moments that can trigger an immediate reaction.',
      icon: Icons.timer_outlined,
      items: const [
        ('Pause first', 'Give yourself one calm moment before acting.'),
        ('Choose naturally', 'Select the response that feels most like you.'),
        (
          'Notice patterns',
          'Your final indicators reveal your response habits.',
        ),
      ],
      buttonLabel: 'Continue',
      onButton: onContinue,
    );
  }
}

class _TutorialView extends StatelessWidget {
  const _TutorialView({super.key, required this.onBack, required this.onStart});

  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _InfoPage(
      onBack: onBack,
      title: 'How it works',
      subtitle: 'Each pressure moment follows the same calm four-step rhythm.',
      icon: Icons.self_improvement_rounded,
      items: const [
        ('Pause', 'Wait for the short timer before choosing.'),
        ('Think', 'Read the moment without rushing.'),
        ('Choose', 'Pick the response that feels most natural.'),
        ('Respond', 'Validate once your choice is selected.'),
      ],
      footnote:
          'There is no immediate correction. Your pattern is revealed only at the end.',
      buttonLabel: 'Start mission',
      onButton: onStart,
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.buttonLabel,
    required this.onButton,
    this.footnote,
  });

  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<(String, String)> items;
  final String? footnote;
  final String buttonLabel;
  final VoidCallback onButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              _TopBar(onBack: onBack, title: 'Reflective Pause'),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 54, color: _violet),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 29,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              for (var index = 0; index < items.length; index++) ...[
                _InstructionCard(
                  number: index + 1,
                  title: items[index].$1,
                  description: items[index].$2,
                ),
                const SizedBox(height: 12),
              ],
              if (footnote != null) ...[
                const SizedBox(height: 8),
                Text(
                  footnote!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: GamePrimaryButton(label: buttonLabel, onPressed: onButton),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _magenta,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
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
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.3,
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
    super.key,
    required this.moment,
    required this.momentNumber,
    required this.elapsedMs,
    required this.minimumReached,
    required this.selectedResponse,
    required this.onSelect,
    required this.onValidate,
    required this.onPause,
  });

  final _PressureMoment moment;
  final int momentNumber;
  final int elapsedMs;
  final bool minimumReached;
  final ReflectivePauseResponseType? selectedResponse;
  final ValueChanged<ReflectivePauseResponseType> onSelect;
  final VoidCallback onValidate;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final remainingMs = math.max(
      0,
      ReflectivePauseConfig.minimumPauseMs - elapsedMs,
    );
    final remainingSeconds = (remainingMs / 1000).ceil();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: _TopBar(
            onBack: onPause,
            title: 'Moment $momentNumber / ${_moments.length}',
            onPause: onPause,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: momentNumber / _moments.length,
              minHeight: 7,
              backgroundColor: const Color(0xFFE9EDF6),
              color: _magenta,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _canvas,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.context,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      moment.message,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                label: minimumReached
                    ? 'Response choices are now available'
                    : '$remainingSeconds seconds before choices become available',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: minimumReached
                        ? const Color(0xFFEAFBF5)
                        : const Color(0xFFFFF1F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        minimumReached
                            ? Icons.check_circle_outline_rounded
                            : Icons.timer_outlined,
                        color: minimumReached ? _green : _magenta,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          minimumReached
                              ? 'Take the response that feels most natural.'
                              : 'Pause for $remainingSeconds…',
                          style: TextStyle(
                            color: minimumReached ? _green : _magenta,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final response in _responses) ...[
                _ResponseCard(
                  response: response,
                  enabled: minimumReached,
                  selected: selectedResponse == response,
                  onTap: () => onSelect(response),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: GamePrimaryButton(
            label: 'Validate response',
            onPressed: minimumReached && selectedResponse != null
                ? onValidate
                : null,
          ),
        ),
      ],
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final ReflectivePauseResponseType response;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: response.label,
      child: Material(
        color: selected ? const Color(0xFFFFF1F7) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? _magenta : _border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    response.label,
                    style: TextStyle(
                      color: enabled ? _ink : _muted.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: _magenta)
                else
                  Icon(
                    Icons.circle_outlined,
                    color: enabled ? _border : _border.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({super.key, required this.momentNumber});

  final int momentNumber;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Answer saved',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFEAFBF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _green, size: 52),
            ),
            const SizedBox(height: 22),
            const Text(
              'Answer saved',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              momentNumber < _moments.length
                  ? 'Moving calmly to the next moment.'
                  : 'Your response pattern is ready.',
              style: const TextStyle(color: _muted, fontSize: 16),
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

  final GameSession? session;
  final VoidCallback onBack;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    final score = session?.lastAttempt?.score;
    final indicators = session?.reflectivePauseIndicators;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            children: [
              _TopBar(onBack: onBack, title: 'Results preview'),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _canvas,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Score',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${score?.rawPoints ?? 0} / ${score?.maxPoints ?? 10}',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF9EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Level: ${indicators?.level ?? score?.level ?? ''}',
                        style: const TextStyle(
                          color: Color(0xFF087A50),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You stayed calm across pressure moments and avoided repeated impulsive reactions.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Indicators',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _IndicatorBar(
                icon: Icons.timer_outlined,
                label: 'Controlled reaction time',
                value: indicators?.controlledReactionTimeScore ?? 0,
                max: 3,
                color: _magenta,
              ),
              _IndicatorBar(
                icon: Icons.pause_circle_outline_rounded,
                label: 'Non-impulsive responses',
                value: indicators?.nonImpulsiveResponsesScore ?? 0,
                max: 4,
                color: _violet,
              ),
              _IndicatorBar(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Ability to step back',
                value: indicators?.abilityToStepBackScore ?? 0,
                max: 3,
                color: _green,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: const Text(
                  'Score interpretation\n\n'
                  '0–4: Strong impulsivity\n'
                  '5–7: Good stress management\n'
                  '8–10: Very good self-control',
                  style: TextStyle(color: _muted, fontSize: 14, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: GamePrimaryButton(
            label: 'View learning insights',
            onPressed: onInsights,
          ),
        ),
      ],
    );
  }
}

class _IndicatorBar extends StatelessWidget {
  const _IndicatorBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${_format(value)} / ${_format(max)}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : (value / max).clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EDF5),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(double value) => value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(1);
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({
    super.key,
    required this.session,
    required this.onBack,
    required this.onFinish,
  });

  final GameSession? session;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final indicators = session?.reflectivePauseIndicators;
    final controlled = indicators?.controlledReactionTimeScore ?? 0;
    final nonImpulsive = indicators?.nonImpulsiveResponsesScore ?? 0;
    final stepBack = indicators?.abilityToStepBackScore ?? 0;
    final strongest = _strongestInsight(controlled, nonImpulsive, stepBack);
    final risk = (indicators?.impulsiveChoiceCount ?? 0) == 0
        ? 'You avoided impulsive answers across all pressure moments.'
        : 'Watch for moments where speed pushes you toward defensive answers.';
    final pressure = controlled >= 1.5
        ? 'You often paused before reacting, which supports better emotional control.'
        : 'A slightly longer pause can help you regain control under pressure.';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            children: [
              _TopBar(onBack: onBack, title: 'Learning insights'),
              const SizedBox(height: 28),
              _InsightCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: _violet,
                title: 'Strongest area',
                description: strongest,
              ),
              const SizedBox(height: 20),
              _InsightCard(
                icon: Icons.bolt_rounded,
                iconColor: _magenta,
                title: 'Impulsivity risk',
                description: risk,
              ),
              const SizedBox(height: 20),
              _InsightCard(
                icon: Icons.pause_circle_outline_rounded,
                iconColor: _green,
                title: 'Pressure pattern',
                description: pressure,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: _violet),
                        SizedBox(width: 12),
                        Text(
                          'Recommendation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Before responding, ask: Do I need to reply now, or do I need one moment to regulate first?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: GamePrimaryButton(label: 'Back to games', onPressed: onFinish),
        ),
      ],
    );
  }

  static String _strongestInsight(
    double controlled,
    double nonImpulsive,
    double stepBack,
  ) {
    final controlledRate = controlled / 3;
    final nonImpulsiveRate = nonImpulsive / 4;
    final stepBackRate = stepBack / 3;
    if (stepBackRate >= controlledRate && stepBackRate >= nonImpulsiveRate) {
      return 'Your strongest pattern is creating distance before reacting.';
    }
    if (nonImpulsiveRate >= controlledRate) {
      return 'Your strongest pattern is choosing deliberate responses under pressure.';
    }
    return 'Your strongest pattern is pausing before reacting.';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10071433),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
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

class _ReflectiveRulesDialog extends StatelessWidget {
  const _ReflectiveRulesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reflective Pause rules',
              style: TextStyle(
                color: _ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pause, read, choose, then validate. There is no correct or wrong message during the journey.',
              style: TextStyle(color: _muted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            const _InstructionCard(
              number: 1,
              title: 'Pause',
              description: 'Wait for the three-second timer.',
            ),
            const SizedBox(height: 10),
            const _InstructionCard(
              number: 2,
              title: 'Choose',
              description: 'Pick only one natural response.',
            ),
            const SizedBox(height: 10),
            const _InstructionCard(
              number: 3,
              title: 'Continue',
              description: 'Your answer is saved without immediate correction.',
            ),
            const SizedBox(height: 20),
            GamePrimaryButton(
              label: 'Resume',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: _magenta));
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _TopBar(onBack: onBack),
          const Spacer(),
          const Icon(Icons.error_outline_rounded, color: _magenta, size: 56),
          const SizedBox(height: 18),
          const Text(
            'Unable to continue',
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const Spacer(),
          GamePrimaryButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
