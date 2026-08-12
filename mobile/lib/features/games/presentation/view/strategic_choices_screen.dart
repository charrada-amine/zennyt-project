import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../../navigation/presentation/widgets/app_bottom_nav.dart';
import '../../domain/config/strategic_choices_content.dart';
import '../widgets/emotional_game_pause_dialog.dart';
import '../widgets/game_system_components.dart';

const _ink = Color(0xFF26224D);
const _navy = Color(0xFF071333);
const _muted = Color(0xFF71809A);
const _violet = Color(0xFF4F46E5);
const _magenta = Color(0xFFD12E7D);
const _green = Color(0xFF22B573);
const _blue = Color(0xFF2563EB);
const _surface = Color(0xFFF6F8FF);
const _border = Color(0xFFE2E8F4);

const _purpleLogo = 'assets/games icons/Strategic Choices Purple.png';

enum _StrategicStage {
  cover,
  intro,
  tutorial,
  gameplay,
  saved,
  results,
  insights,
}

enum _ScenarioPhase { reading, reflecting, ready }

/// Front-only implementation of the Strategic Choices handoff.
///
/// The supplied material does not include videos or a validated scoring model.
/// Situations are therefore presented as text cards, choices remain local to
/// this screen, and the result deliberately exposes no calculated score. This
/// boundary prevents a visual preview from being mistaken for a psychometric
/// result or reaching the Games backend/Fit Score pipeline.
class StrategicChoicesScreen extends ConsumerStatefulWidget {
  const StrategicChoicesScreen({
    super.key,
    this.reflectionDuration = StrategicChoicesContent.reflectionDuration,
    this.savedTransitionDuration =
        StrategicChoicesContent.savedTransitionDuration,
  });

  final Duration reflectionDuration;
  final Duration savedTransitionDuration;

  @override
  ConsumerState<StrategicChoicesScreen> createState() =>
      _StrategicChoicesScreenState();
}

class _StrategicChoicesScreenState extends ConsumerState<StrategicChoicesScreen>
    with WidgetsBindingObserver {
  _StrategicStage _stage = _StrategicStage.cover;
  _ScenarioPhase _scenarioPhase = _ScenarioPhase.reading;
  int _situationIndex = 0;
  Duration _reflectionRemaining = Duration.zero;
  StrategicChoiceStrategy? _selectedStrategy;
  final List<StrategicChoiceStrategy> _answers = [];

  Timer? _reflectionTimer;
  Timer? _savedTimer;
  bool _pauseOpen = false;
  bool _resumePauseAfterLifecycle = false;
  bool _soundEffects = true;
  bool _music = false;
  bool _buttonsInput = true;

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reflectionTimer?.cancel();
    _savedTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_stage != _StrategicStage.gameplay) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseReflectionTimer();
      _resumePauseAfterLifecycle = true;
      return;
    }
    if (state == AppLifecycleState.resumed &&
        _resumePauseAfterLifecycle &&
        !_pauseOpen) {
      _resumePauseAfterLifecycle = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openPause();
      });
    }
  }

  void _selectMainTab(int index) {
    ref.read(navTabProvider.notifier).select(index);
    if (index == 2) {
      context.go(AppRoutes.games);
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _setStage(_StrategicStage stage) {
    _reflectionTimer?.cancel();
    _savedTimer?.cancel();
    setState(() => _stage = stage);
  }

  void _startJourney() {
    _reflectionTimer?.cancel();
    _savedTimer?.cancel();
    setState(() {
      _stage = _StrategicStage.gameplay;
      _scenarioPhase = _ScenarioPhase.reading;
      _situationIndex = 0;
      _reflectionRemaining = widget.reflectionDuration;
      _selectedStrategy = null;
      _answers.clear();
    });
  }

  void _startReflection() {
    if (_stage != _StrategicStage.gameplay ||
        _scenarioPhase != _ScenarioPhase.reading) {
      return;
    }
    setState(() {
      _scenarioPhase = _ScenarioPhase.reflecting;
      _reflectionRemaining = widget.reflectionDuration;
    });
    _scheduleReflectionTimer();
  }

  void _scheduleReflectionTimer() {
    _reflectionTimer?.cancel();
    if (_scenarioPhase != _ScenarioPhase.reflecting) return;
    if (_reflectionRemaining <= Duration.zero) {
      setState(() => _scenarioPhase = _ScenarioPhase.ready);
      return;
    }
    const tick = Duration(milliseconds: 100);
    _reflectionTimer = Timer.periodic(tick, (timer) {
      if (!mounted || _stage != _StrategicStage.gameplay) {
        timer.cancel();
        return;
      }
      final next = _reflectionRemaining - tick;
      if (next <= Duration.zero) {
        timer.cancel();
        setState(() {
          _reflectionRemaining = Duration.zero;
          _scenarioPhase = _ScenarioPhase.ready;
        });
      } else {
        setState(() => _reflectionRemaining = next);
      }
    });
  }

  void _pauseReflectionTimer() {
    _reflectionTimer?.cancel();
    _reflectionTimer = null;
  }

  void _resumeReflectionTimer() {
    if (_stage == _StrategicStage.gameplay &&
        _scenarioPhase == _ScenarioPhase.reflecting) {
      _scheduleReflectionTimer();
    }
  }

  void _selectStrategy(StrategicChoiceStrategy strategy) {
    if (_scenarioPhase == _ScenarioPhase.reading) return;
    setState(() => _selectedStrategy = strategy);
  }

  void _validateChoice() {
    final selected = _selectedStrategy;
    if (_scenarioPhase != _ScenarioPhase.ready || selected == null) return;
    _reflectionTimer?.cancel();
    if (_answers.length == _situationIndex) {
      _answers.add(selected);
    } else {
      _answers[_situationIndex] = selected;
    }
    setState(() => _stage = _StrategicStage.saved);

    final delay = _reducedMotion
        ? Duration.zero
        : widget.savedTransitionDuration;
    _savedTimer = Timer(delay, () {
      if (!mounted) return;
      if (_situationIndex + 1 >= StrategicChoicesContent.situations.length) {
        setState(() => _stage = _StrategicStage.results);
        return;
      }
      setState(() {
        _situationIndex += 1;
        _selectedStrategy = null;
        _reflectionRemaining = widget.reflectionDuration;
        _scenarioPhase = _ScenarioPhase.reading;
        _stage = _StrategicStage.gameplay;
      });
    });
  }

  Future<void> _openPause() async {
    if (_stage != _StrategicStage.gameplay || _pauseOpen) return;
    _pauseReflectionTimer();
    _pauseOpen = true;
    final action = await showDialog<EmotionalGamePauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmotionalGamePauseDialog(
        soundEffects: _soundEffects,
        music: _music,
        buttonsInput: _buttonsInput,
        onSoundEffects: (value) => _soundEffects = value,
        onMusic: (value) => _music = value,
        onInputMode: (value) => _buttonsInput = value,
      ),
    );
    _pauseOpen = false;
    if (!mounted) return;
    switch (action) {
      case EmotionalGamePauseAction.rules:
        await _showRules();
        if (mounted) _resumeReflectionTimer();
      case EmotionalGamePauseAction.exit:
        context.go(AppRoutes.games);
      case EmotionalGamePauseAction.resume:
      case null:
        _resumeReflectionTimer();
    }
  }

  Future<void> _showRules() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Strategic Choices rules'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _RuleLine('1', 'Read the complete situation.'),
            _RuleLine('2', 'Let the 3-second reflection timer finish.'),
            _RuleLine('3', 'Choose exactly one coping strategy.'),
            _RuleLine('4', 'Save your answer and continue.'),
            SizedBox(height: 12),
            Text(
              'There is no immediate right/wrong correction. This front-only preview does not calculate a score.',
              style: TextStyle(color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to mission'),
        ),
      ],
    ),
  );

  void _handleBack() {
    switch (_stage) {
      case _StrategicStage.cover:
        context.go(AppRoutes.games);
      case _StrategicStage.intro:
        _setStage(_StrategicStage.cover);
      case _StrategicStage.tutorial:
        _setStage(_StrategicStage.intro);
      case _StrategicStage.gameplay:
        _openPause();
      case _StrategicStage.saved:
        break;
      case _StrategicStage.results:
        context.go(AppRoutes.games);
      case _StrategicStage.insights:
        _setStage(_StrategicStage.results);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBottomNav = switch (_stage) {
      _StrategicStage.cover ||
      _StrategicStage.intro ||
      _StrategicStage.tutorial => true,
      _ => false,
    };
    final purpleStage = switch (_stage) {
      _StrategicStage.gameplay || _StrategicStage.saved => true,
      _ => false,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: purpleStage ? _violet : Colors.white,
        bottomNavigationBar: showBottomNav
            ? MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1,
                child: AppBottomNav(selectedTab: 2, onSelect: _selectMainTab),
              )
            : null,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: _reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: switch (_stage) {
              _StrategicStage.cover => _CoverView(
                key: const ValueKey('strategic-cover'),
                onBack: _handleBack,
                onTutorial: () => _setStage(_StrategicStage.intro),
                onStart: () => _setStage(_StrategicStage.intro),
              ),
              _StrategicStage.intro => _IntroView(
                key: const ValueKey('strategic-intro'),
                onBack: _handleBack,
                onContinue: () => _setStage(_StrategicStage.tutorial),
              ),
              _StrategicStage.tutorial => _TutorialView(
                key: const ValueKey('strategic-tutorial'),
                onBack: _handleBack,
                onStart: _startJourney,
              ),
              _StrategicStage.gameplay => _GameplayView(
                key: ValueKey('strategic-gameplay-$_situationIndex'),
                situation: StrategicChoicesContent.situations[_situationIndex],
                situationNumber: _situationIndex + 1,
                phase: _scenarioPhase,
                reflectionRemaining: _reflectionRemaining,
                selected: _selectedStrategy,
                onStartReflection: _startReflection,
                onSelect: _selectStrategy,
                onValidate: _validateChoice,
                onPause: _openPause,
              ),
              _StrategicStage.saved => _SavedView(
                key: ValueKey('strategic-saved-$_situationIndex'),
                situationNumber: _situationIndex + 1,
              ),
              _StrategicStage.results => _ResultsView(
                key: const ValueKey('strategic-results'),
                answerCount: _answers.length,
                onBack: _handleBack,
                onInsights: () => _setStage(_StrategicStage.insights),
              ),
              _StrategicStage.insights => _InsightsView(
                key: const ValueKey('strategic-insights'),
                answers: List.unmodifiable(_answers),
                onBack: _handleBack,
                onFinish: () => context.go(AppRoutes.games),
              ),
            },
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
    const heroCopy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotional Regulation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 30),
        Text(
          'Strategic\nChoices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            height: 1.05,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 40),
        Text(
          'Le Choix stratégique',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    final heroLogo = Semantics(
      image: true,
      label: 'Strategic Choices decision compass',
      child: Image.asset(
        _purpleLogo,
        key: const ValueKey('strategic-purple-logo'),
        width: 132,
        height: 132,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      children: [
        _TopBar(onBack: onBack),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 14, 22),
          decoration: BoxDecoration(
            color: _violet,
            borderRadius: BorderRadius.circular(24),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heroCopy,
                    const SizedBox(height: 18),
                    Align(alignment: Alignment.center, child: heroLogo),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heroCopy),
                  heroLogo,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Strategic Choices',
          style: TextStyle(
            color: _ink,
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Emotional Regulation',
          style: TextStyle(
            color: _magenta,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Read stressful situations, pause before reacting, and choose the coping strategy that feels most appropriate.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 18),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FeatureChip(label: '10 situations', color: _blue),
            _FeatureChip(label: 'Text preview', color: _magenta),
            _FeatureChip(label: 'Final insights', color: _green),
          ],
        ),
        const SizedBox(height: 26),
        GameOutlineButton(label: 'View tutorial', onPressed: onTutorial),
        const SizedBox(height: 12),
        GamePrimaryButton(label: 'Start mission', onPressed: onStart),
      ],
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({super.key, required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _PreGamePage(
      onBack: onBack,
      title: 'Train the pause before action',
      subtitle:
          'You will face 10 realistic stressful situations. Choose the coping strategy that best supports thoughtful emotional regulation.',
      buttonLabel: 'Continue',
      onButton: onContinue,
      children: const [
        _AccentInfoCard(
          color: _magenta,
          title: '10 situations',
          description: 'Conflict, failure, delay, criticism, and overload.',
        ),
        _AccentInfoCard(
          color: _blue,
          title: 'Reflection first',
          description: 'A brief delay helps prevent impulsive reaction.',
        ),
        _AccentInfoCard(
          color: _green,
          title: 'Strategic coping',
          description: 'Match the response to what the situation needs.',
        ),
        _NoticePanel(
          title: 'Text scenarios for now',
          description:
              'The video phase is temporarily represented by the complete written situation. Your learning summary appears only at the end.',
        ),
      ],
    );
  }
}

class _TutorialView extends StatelessWidget {
  const _TutorialView({super.key, required this.onBack, required this.onStart});

  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _PreGamePage(
      onBack: onBack,
      title: 'How the mission works',
      subtitle:
          'Each situation follows the same rhythm. Read, pause, choose, then save your answer.',
      buttonLabel: 'Start situation',
      onButton: onStart,
      children: const [
        _TutorialGrid(),
        _NoticePanel(
          title: 'No immediate correction',
          description:
              'No right/wrong feedback appears during the journey. This front-only preview also leaves scoring uncalculated.',
          outlined: true,
        ),
      ],
    );
  }
}

class _PreGamePage extends StatelessWidget {
  const _PreGamePage({
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.buttonLabel,
    required this.onButton,
  });

  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback onButton;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      children: [
        _TopBar(onBack: onBack),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 31,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 20),
        for (final child in children) ...[child, const SizedBox(height: 12)],
        const SizedBox(height: 8),
        GamePrimaryButton(label: buttonLabel, onPressed: onButton),
      ],
    );
  }
}

class _TutorialGrid extends StatelessWidget {
  const _TutorialGrid();

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 330 || textScale > 1.35;
        const cards = <Widget>[
          _TutorialCard(
            color: _magenta,
            icon: Icons.article_outlined,
            title: 'Read',
            description: 'Take in the complete situation.',
          ),
          _TutorialCard(
            color: _blue,
            icon: Icons.timer_outlined,
            title: 'Reflect',
            description: 'Let the timer finish.',
          ),
          _TutorialCard(
            color: _green,
            icon: Icons.checklist_rounded,
            title: 'Choose',
            description: 'Pick one strategy.',
          ),
          _TutorialCard(
            color: _navy,
            icon: Icons.check_rounded,
            title: 'Validate',
            description: 'Save and continue.',
          ),
        ];
        if (singleColumn) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                if (card != cards.last) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }
}

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    super.key,
    required this.situation,
    required this.situationNumber,
    required this.phase,
    required this.reflectionRemaining,
    required this.selected,
    required this.onStartReflection,
    required this.onSelect,
    required this.onValidate,
    required this.onPause,
  });

  final StrategicChoiceSituation situation;
  final int situationNumber;
  final _ScenarioPhase phase;
  final Duration reflectionRemaining;
  final StrategicChoiceStrategy? selected;
  final VoidCallback onStartReflection;
  final ValueChanged<StrategicChoiceStrategy> onSelect;
  final VoidCallback onValidate;
  final VoidCallback onPause;

  String get _modeLabel => switch (phase) {
    _ScenarioPhase.reading => 'Read the situation',
    _ScenarioPhase.reflecting => 'Reflect, then choose',
    _ScenarioPhase.ready => 'Choose, then save',
  };

  String get _statusLabel => switch (phase) {
    _ScenarioPhase.reading => 'Read first · choices locked',
    _ScenarioPhase.reflecting =>
      'Reflection time · choices available · validate waits',
    _ScenarioPhase.ready when selected == null =>
      'Reflection complete · choose one strategy',
    _ScenarioPhase.ready => 'Ready to validate · one strategy selected',
  };

  String get _timerLabel {
    final seconds = (reflectionRemaining.inMilliseconds / 1000).ceil();
    return '00:${seconds.clamp(0, 99).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 18, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Situation $situationNumber / ${StrategicChoicesContent.situations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _modeLabel,
                      style: const TextStyle(
                        color: Color(0xFFD8D6FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _PurpleIconButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause',
                onTap: onPause,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value:
                  situationNumber / StrategicChoicesContent.situations.length,
              color: _magenta,
              backgroundColor: const Color(0xFF817AEC),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            children: [
              GamePanel(
                padding: const EdgeInsets.all(16),
                borderColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _FeatureChip(label: situation.type, color: _blue),
                        const Spacer(),
                        if (phase == _ScenarioPhase.reflecting)
                          Semantics(
                            liveRegion: true,
                            label: 'Reflection time $_timerLabel remaining',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F5FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _blue),
                              ),
                              child: Text(
                                _timerLabel,
                                key: const ValueKey(
                                  'strategic-reflection-timer',
                                ),
                                style: const TextStyle(
                                  color: _blue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 154),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            phase == _ScenarioPhase.reading
                                ? 'TEXT SCENARIO'
                                : 'SITUATION READ',
                            style: const TextStyle(
                              color: Color(0xFFB8F3D6),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            situation.prompt,
                            key: const ValueKey('strategic-situation-prompt'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      phase == _ScenarioPhase.reading
                          ? 'Take a moment to read the complete situation.'
                          : 'Take a moment before responding.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GamePanel(
                padding: const EdgeInsets.all(12),
                borderColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Choose one strategy',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          phase == _ScenarioPhase.reading
                              ? 'Locked'
                              : phase == _ScenarioPhase.reflecting
                              ? 'Timer must finish'
                              : 'One choice',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale = MediaQuery.textScalerOf(
                          context,
                        ).scale(1);
                        final oneColumn =
                            constraints.maxWidth < 300 || textScale > 1.35;
                        if (oneColumn) {
                          return Column(
                            children: [
                              for (final strategy
                                  in StrategicChoicesContent.strategies) ...[
                                _StrategyCard(
                                  strategy: strategy,
                                  enabled: phase != _ScenarioPhase.reading,
                                  selected: selected == strategy,
                                  onTap: () => onSelect(strategy),
                                ),
                                if (strategy !=
                                    StrategicChoicesContent.strategies.last)
                                  const SizedBox(height: 8),
                              ],
                            ],
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: StrategicChoicesContent.strategies.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.28,
                              ),
                          itemBuilder: (context, index) {
                            final strategy =
                                StrategicChoicesContent.strategies[index];
                            return _StrategyCard(
                              strategy: strategy,
                              enabled: phase != _ScenarioPhase.reading,
                              selected: selected == strategy,
                              onTap: () => onSelect(strategy),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _statusLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (phase == _ScenarioPhase.reading)
                GamePrimaryButton(
                  key: const ValueKey('strategic-start-reflection'),
                  label: 'Start reflection',
                  onPressed: onStartReflection,
                )
              else
                GamePrimaryButton(
                  key: const ValueKey('strategic-validate'),
                  label: 'Validate my answer',
                  onPressed: phase == _ScenarioPhase.ready && selected != null
                      ? onValidate
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.strategy,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final StrategicChoiceStrategy strategy;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: strategy.label,
      child: Material(
        color: selected
            ? const Color(0xFFFFF0F7)
            : enabled
            ? Colors.white
            : const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('strategic-choice-${strategy.name}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _magenta : _border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? _magenta
                        : enabled
                        ? const Color(0xFFFFF4F9)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? _magenta : _border),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : strategy.icon,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : enabled
                        ? _magenta
                        : _muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strategy.label,
                    style: TextStyle(
                      color: enabled ? _ink : _muted,
                      fontSize: 13,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!enabled)
                  const Icon(Icons.lock_outline, size: 16, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({super.key, required this.situationNumber});

  final int situationNumber;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: GamePanel(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          borderColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F8),
                  shape: BoxShape.circle,
                  border: Border.all(color: _magenta, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _magenta,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Answer saved',
                style: TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                situationNumber < StrategicChoicesContent.situations.length
                    ? 'Moving to the next situation...'
                    : 'Preparing your journey recap...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.answerCount,
    required this.onBack,
    required this.onInsights,
  });

  final int answerCount;
  final VoidCallback onBack;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        _TopBar(onBack: onBack),
        const SizedBox(height: 14),
        const Text(
          'Final summary',
          style: TextStyle(
            color: _ink,
            fontSize: 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A front-only journey recap. No psychometric score is calculated from your choices yet.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Journey completion',
                style: TextStyle(
                  color: Color(0xFFC9D3EA),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '$answerCount / ${StrategicChoicesContent.situations.length}',
                    key: const ValueKey('strategic-answer-count'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _magenta,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Scoring remains unavailable until the calibration rules are validated and connected to the backend.',
                style: TextStyle(
                  color: Color(0xFFC9D3EA),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Learning profile',
          style: TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _PendingMetricTile(
                color: _green,
                letter: 'A',
                label: 'Adaptive\nchoice',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _PendingMetricTile(
                color: _magenta,
                letter: 'F',
                label: 'Emotional\nflexibility',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _PendingMetricTile(
                color: _violet,
                letter: 'I',
                label: 'Inhibition\ncapacity',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _PendingMetricBar(
          label: 'Adaptive choice capacity',
          color: _green,
        ),
        const SizedBox(height: 14),
        const _PendingMetricBar(
          label: 'Emotional flexibility',
          color: _magenta,
        ),
        const SizedBox(height: 14),
        const _PendingMetricBar(label: 'Inhibition capacity', color: _violet),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'See detailed insights',
          onPressed: onInsights,
        ),
      ],
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({
    super.key,
    required this.answers,
    required this.onBack,
    required this.onFinish,
  });

  final List<StrategicChoiceStrategy> answers;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  StrategicChoiceStrategy? get _mostUsed {
    if (answers.isEmpty) return null;
    final counts = <StrategicChoiceStrategy, int>{};
    for (final answer in answers) {
      counts.update(answer, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        _TopBar(onBack: onBack),
        const SizedBox(height: 14),
        const Text(
          'Learning insights',
          style: TextStyle(
            color: _ink,
            fontSize: 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Descriptive observations only. They do not diagnose, rank, or score your emotional regulation.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 18),
        _InsightCard(
          color: _blue,
          title: 'Most used strategy',
          description: _mostUsed?.label ?? 'No strategy recorded',
        ),
        const SizedBox(height: 12),
        const _InsightCard(
          color: _green,
          title: 'Current scope',
          description:
              'Your choices were kept only for this on-screen recap. No strength is inferred without a validated scoring model.',
        ),
        const SizedBox(height: 12),
        const _InsightCard(
          color: _magenta,
          title: 'Trap tendencies',
          description:
              'No trap label is shown in this preview. These interpretations will remain hidden until calibration is approved.',
        ),
        const SizedBox(height: 12),
        const _InsightCard(
          color: _navy,
          title: 'Recommendation',
          description:
              'Before choosing, ask: Is this problem solvable now, or do I first need to regulate my state?',
        ),
        const SizedBox(height: 26),
        GamePrimaryButton(label: 'Finish mission', onPressed: onFinish),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Back',
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Zennyt Games',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
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

class _PurpleIconButton extends StatelessWidget {
  const _PurpleIconButton({
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
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon),
          color: Colors.white,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            side: const BorderSide(color: Color(0xFF9892F5)),
            backgroundColor: const Color(0xFF6158EA),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AccentInfoCard extends StatelessWidget {
  const _AccentInfoCard({
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D071333),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({
    required this.title,
    required this.description,
    this.outlined = false,
  });

  final String title;
  final String description;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      backgroundColor: outlined ? _surface : _violet,
      borderColor: outlined ? _magenta : _violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: outlined ? _magenta : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: TextStyle(
              color: outlined ? _ink : const Color(0xFFE7E5FF),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _PendingMetricTile extends StatelessWidget {
  const _PendingMetricTile({
    required this.color,
    required this.letter,
    required this.label,
  });

  final Color color;
  final String letter;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Pending',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingMetricBar extends StatelessWidget {
  const _PendingMetricBar({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              'Not scored',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: _border,
            borderRadius: BorderRadius.circular(99),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 18,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.color,
    required this.title,
    required this.description,
  });

  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.number, this.label);

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _magenta,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

extension _StrategicChoiceStrategyVisual on StrategicChoiceStrategy {
  IconData get icon => switch (this) {
    StrategicChoiceStrategy.avoidFlee => Icons.arrow_forward_rounded,
    StrategicChoiceStrategy.ruminate => Icons.sync_rounded,
    StrategicChoiceStrategy.breathePause => Icons.air_rounded,
    StrategicChoiceStrategy.cognitiveReappraisal =>
      Icons.psychology_alt_outlined,
    StrategicChoiceStrategy.assertiveCommunication =>
      Icons.chat_bubble_outline_rounded,
    StrategicChoiceStrategy.humor => Icons.sentiment_satisfied_alt_rounded,
    StrategicChoiceStrategy.seekSupport => Icons.people_outline_rounded,
    StrategicChoiceStrategy.directAction => Icons.open_in_full_rounded,
  };
}
