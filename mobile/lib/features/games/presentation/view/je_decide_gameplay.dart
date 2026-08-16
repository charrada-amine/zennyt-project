import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/decision_progress_store.dart';
import '../widgets/game_system_components.dart';

const _decisionInk = Color(0xFF28234F);
const _decisionMuted = Color(0xFF7E8DB2);
const _decisionBorder = Color(0xFFD8E2F6);
const _decisionMagenta = Color(0xFFD52E83);
const _decisionViolet = Color(0xFF4E46E8);
const _decisionSoftPink = Color(0xFFFFF1F7);
const _decisionTimer = Color(0xFF2BD06F);
const _decisionWarning = Color(0xFFFFA033);

/// Étapes de gameplay et de transition livrées dans les Phases 2–3.
///
/// Cette séquence démontre les cinq formats de scénario et leurs états
/// d'interaction. Le catalogue complet, le scoring et la persistance restent
/// volontairement hors de ce widget jusqu'à validation du barème serveur.
enum DecisionGameplayStep {
  analytical,
  riskBalance,
  quickChoice,
  xpFeedback,
  checkpoint,
  encouragement,
  pause,
  savedProgress,
  resumeJourney,
  badge,
  dimensionComplete,
  stabilityFirst,
  stabilitySecond,
  selfControl,
}

/// Étapes de transition/overlay qui ne doivent jamais servir de point de
/// reprise : les réutiliser comme cible ferait boucler la reprise entre les
/// écrans « Welcome back » et « Progress saved ».
const _nonResumableDecisionSteps = {
  DecisionGameplayStep.pause,
  DecisionGameplayStep.savedProgress,
  DecisionGameplayStep.resumeJourney,
};

/// Ramène une étape sauvegardée vers un scénario réellement reprenable.
DecisionGameplayStep sanitizeDecisionResumeStep(DecisionGameplayStep step) =>
    _nonResumableDecisionSteps.contains(step)
    ? DecisionGameplayStep.encouragement
    : step;

/// Boucle de gameplay mobile des Phases 2–3.
///
/// Les valeurs XP reproduisent uniquement les états visuels des maquettes :
/// elles ne constituent pas un barème et ne sont jamais soumises au backend.
class DecisionGameplayView extends StatefulWidget {
  const DecisionGameplayView({
    super.key,
    required this.onClose,
    required this.onComplete,
    this.initialStep = DecisionGameplayStep.analytical,
    this.resumeStepAfterWelcome = DecisionGameplayStep.encouragement,
  });

  final VoidCallback onClose;
  final VoidCallback onComplete;
  final DecisionGameplayStep initialStep;
  final DecisionGameplayStep resumeStepAfterWelcome;

  @override
  State<DecisionGameplayView> createState() => _DecisionGameplayViewState();
}

class _DecisionGameplayViewState extends State<DecisionGameplayView> {
  static const _quickChoiceDuration = 7;
  static const _criticalThreshold = 2;

  final Map<DecisionGameplayStep, int> _selections = {};
  Timer? _countdown;
  Timer? _timeoutAdvance;
  late DecisionGameplayStep _step;
  late DecisionGameplayStep _resumeTarget;
  int _secondsRemaining = _quickChoiceDuration;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _resumeTarget = widget.resumeStepAfterWelcome;
    if (_step == DecisionGameplayStep.quickChoice) {
      _scheduleQuickChoiceTimer();
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _timeoutAdvance?.cancel();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  int get _scenarioNumber => switch (_step) {
    DecisionGameplayStep.analytical => 4,
    DecisionGameplayStep.riskBalance => 7,
    DecisionGameplayStep.quickChoice => 13,
    DecisionGameplayStep.xpFeedback ||
    DecisionGameplayStep.checkpoint ||
    DecisionGameplayStep.pause ||
    DecisionGameplayStep.savedProgress => 15,
    DecisionGameplayStep.encouragement ||
    DecisionGameplayStep.resumeJourney ||
    DecisionGameplayStep.badge ||
    DecisionGameplayStep.dimensionComplete => 16,
    DecisionGameplayStep.stabilityFirst => 19,
    DecisionGameplayStep.stabilitySecond => 20,
    DecisionGameplayStep.selfControl => 30,
  };

  int get _visualXp => switch (_step) {
    DecisionGameplayStep.analytical => 36,
    DecisionGameplayStep.riskBalance => 48,
    DecisionGameplayStep.quickChoice || DecisionGameplayStep.xpFeedback => 48,
    DecisionGameplayStep.checkpoint ||
    DecisionGameplayStep.pause ||
    DecisionGameplayStep.savedProgress => 60,
    DecisionGameplayStep.encouragement ||
    DecisionGameplayStep.resumeJourney => 60,
    DecisionGameplayStep.badge => 72,
    DecisionGameplayStep.dimensionComplete => 84,
    DecisionGameplayStep.stabilityFirst => 96,
    DecisionGameplayStep.stabilitySecond => 108,
    DecisionGameplayStep.selfControl => 144,
  };

  bool get _isChoiceStep => switch (_step) {
    DecisionGameplayStep.analytical ||
    DecisionGameplayStep.riskBalance ||
    DecisionGameplayStep.quickChoice ||
    DecisionGameplayStep.stabilityFirst ||
    DecisionGameplayStep.stabilitySecond ||
    DecisionGameplayStep.selfControl => true,
    DecisionGameplayStep.xpFeedback ||
    DecisionGameplayStep.checkpoint ||
    DecisionGameplayStep.encouragement ||
    DecisionGameplayStep.pause ||
    DecisionGameplayStep.savedProgress ||
    DecisionGameplayStep.resumeJourney ||
    DecisionGameplayStep.badge ||
    DecisionGameplayStep.dimensionComplete => false,
  };

  bool get _usesLightShell => !_isChoiceStep;

  int? get _selection => _selections[_step];

  void _scheduleQuickChoiceTimer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _step != DecisionGameplayStep.quickChoice) return;
      _startQuickChoiceTimer();
    });
  }

  void _startQuickChoiceTimer({bool reset = true}) {
    _countdown?.cancel();
    if (reset) {
      _secondsRemaining = _quickChoiceDuration;
      _timedOut = false;
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _selection != null) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
        return;
      }
      timer.cancel();
      setState(() {
        _secondsRemaining = 0;
        _timedOut = true;
      });
      _timeoutAdvance = Timer(
        _reduceMotion
            ? const Duration(milliseconds: 450)
            : const Duration(milliseconds: 1500),
        () {
          if (mounted && _step == DecisionGameplayStep.quickChoice) {
            _goTo(DecisionGameplayStep.xpFeedback);
          }
        },
      );
    });
  }

  void _select(int index) {
    if (_timedOut) return;
    // Son générique au choix d'une option (les cartes ne sont pas des
    // GamePrimaryButton, donc pas de clic automatique).
    SoundService.instance.playSfx(GameSfx.buttonClick);
    if (_step == DecisionGameplayStep.quickChoice) {
      _countdown?.cancel();
    }
    setState(() => _selections[_step] = index);
  }

  void _goTo(DecisionGameplayStep next) {
    _countdown?.cancel();
    _timeoutAdvance?.cancel();
    setState(() {
      _step = next;
      _secondsRemaining = _quickChoiceDuration;
      _timedOut = false;
    });
    if (next == DecisionGameplayStep.quickChoice) {
      _scheduleQuickChoiceTimer();
    }
  }

  void _continue() {
    switch (_step) {
      case DecisionGameplayStep.analytical:
        _goTo(DecisionGameplayStep.riskBalance);
      case DecisionGameplayStep.riskBalance:
        _goTo(DecisionGameplayStep.quickChoice);
      case DecisionGameplayStep.quickChoice:
        _goTo(DecisionGameplayStep.xpFeedback);
      case DecisionGameplayStep.xpFeedback:
        _goTo(DecisionGameplayStep.checkpoint);
      case DecisionGameplayStep.checkpoint:
        _goTo(DecisionGameplayStep.encouragement);
      case DecisionGameplayStep.encouragement:
        _goTo(DecisionGameplayStep.badge);
      case DecisionGameplayStep.pause:
        _goTo(DecisionGameplayStep.encouragement);
      case DecisionGameplayStep.savedProgress:
        _goTo(DecisionGameplayStep.resumeJourney);
      case DecisionGameplayStep.resumeJourney:
        _goTo(_resumeTarget);
      case DecisionGameplayStep.badge:
        _goTo(DecisionGameplayStep.dimensionComplete);
      case DecisionGameplayStep.dimensionComplete:
        _goTo(DecisionGameplayStep.stabilityFirst);
      case DecisionGameplayStep.stabilityFirst:
        _goTo(DecisionGameplayStep.stabilitySecond);
      case DecisionGameplayStep.stabilitySecond:
        _goTo(DecisionGameplayStep.selfControl);
      case DecisionGameplayStep.selfControl:
        widget.onComplete();
    }
  }

  Future<void> _openPauseMenu() async {
    SoundService.instance.playSfx(GameSfx.pauseClick);
    final timerWasRunning =
        _step == DecisionGameplayStep.quickChoice &&
        _selection == null &&
        !_timedOut;
    _countdown?.cancel();
    final action = await showDialog<DecisionPauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DecisionPauseDialog(),
    );
    if (!mounted) return;
    switch (action) {
      case DecisionPauseAction.rules:
        await showDialog<void>(
          context: context,
          builder: (_) => const DecisionRulesDialog(),
        );
        if (mounted) await _openPauseMenu();
        return;
      case DecisionPauseAction.exit:
        final resumeStep = sanitizeDecisionResumeStep(_step);
        _resumeTarget = resumeStep;
        await DecisionProgressStore().saveCheckpoint(stepName: resumeStep.name);
        // « Save and exit » ramène directement à l'accueil ; la reprise se fera
        // via l'écran « Welcome back » à la prochaine ouverture.
        if (mounted) widget.onClose();
        return;
      case DecisionPauseAction.resume || null:
        if (timerWasRunning && mounted) {
          _startQuickChoiceTimer(reset: false);
        }
    }
  }

  Future<void> _saveFromCheckpoint() async {
    _resumeTarget = DecisionGameplayStep.encouragement;
    await DecisionProgressStore().saveCheckpoint(
      stepName: DecisionGameplayStep.encouragement.name,
    );
    if (mounted) _goTo(DecisionGameplayStep.savedProgress);
  }

  @override
  Widget build(BuildContext context) {
    final animationDuration = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final shellColor = _usesLightShell
        ? const Color(0xFFF7F8FE)
        : _decisionViolet;
    return ColoredBox(
      color: shellColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              _DecisionProgressHeader(
                scenarioNumber: _scenarioNumber,
                xp: _visualXp,
                onPause: _openPauseMenu,
                light: _usesLightShell,
              ),
              const SizedBox(height: 12),
              _JourneyProgress(
                value: _scenarioNumber / 30,
                light: _usesLightShell,
              ),
              if (_step == DecisionGameplayStep.quickChoice) ...[
                const SizedBox(height: 10),
                _DecisionTimer(
                  secondsRemaining: _secondsRemaining,
                  totalSeconds: _quickChoiceDuration,
                  critical: _secondsRemaining <= _criticalThreshold,
                ),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: AnimatedSwitcher(
                  duration: animationDuration,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.035, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
              if (_isChoiceStep && !_timedOut) ...[
                const SizedBox(height: 14),
                GamePrimaryButton(
                  key: const ValueKey('decision-continue'),
                  label: 'Continue',
                  onPressed: _selection == null ? null : _continue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == DecisionGameplayStep.quickChoice && _timedOut) {
      return const _TimeoutView();
    }
    return switch (_step) {
      DecisionGameplayStep.analytical => _ScenarioView(
        scenario: const _ScenarioData(
          label: 'Scenario',
          title: 'Delivery Bike',
          description:
              'You need an electric bike for daily delivery rounds. Your budget is limited. You need at least 40 km of range per day.',
          options: [
            _OptionData(title: 'Model A', subtitle: 'High price • 70 km range'),
            _OptionData(
              title: 'Model B',
              subtitle: 'Within budget • 45 km range',
            ),
            _OptionData(
              title: 'Model C',
              subtitle: 'Lowest price • 25 km range',
            ),
          ],
        ),
        selected: _selection,
        onSelected: _select,
      ),
      DecisionGameplayStep.riskBalance => _ScenarioView(
        scenario: const _ScenarioData(
          label: 'Scenario',
          title: 'A financial choice',
          description:
              'You have two possible outcomes. Choose the option you would personally take.',
          options: [
            _OptionData(
              eyebrow: 'Option X',
              title: '€60',
              subtitle: 'Guaranteed',
              tag: 'Certain',
            ),
            _OptionData(
              eyebrow: 'Option Y',
              title: '50% chance of\n€150',
              tag: 'Variable',
            ),
          ],
        ),
        selected: _selection,
        onSelected: _select,
      ),
      DecisionGameplayStep.quickChoice => _ScenarioView(
        scenario: const _ScenarioData(
          label: 'Quick choice',
          title: 'Choose quickly',
          description:
              'You need an electric bike for daily delivery rounds. Your budget is limited. You need at least 40 km of range per day.',
          options: [
            _OptionData(title: 'Model A', subtitle: 'High price • 70 km range'),
            _OptionData(
              title: 'Model B',
              subtitle: 'Within budget • 45 km range',
            ),
            _OptionData(
              title: 'Model C',
              subtitle: 'Lowest price • 25 km range',
            ),
          ],
          footer: 'Choose what feels best.',
        ),
        selected: _selection,
        onSelected: _select,
      ),
      DecisionGameplayStep.stabilityFirst => _ScenarioView(
        scenario: const _ScenarioData(
          label: 'Two-part scenario',
          part: 'Part 1 of 2',
          title: 'Company Reorganization',
          description:
              'A company of 120 employees must reorganize. Plan A saves 40 jobs for certain. Plan B has a 1 in 3 chance of saving all jobs and a 2 in 3 chance of saving none.',
          options: [
            _OptionData(title: 'Plan A', subtitle: '40 jobs saved for certain'),
            _OptionData(
              title: 'Plan B',
              subtitle:
                  '1 in 3 chance all jobs are saved • 2 in 3 chance none are saved',
            ),
          ],
        ),
        selected: _selection,
        onSelected: _select,
      ),
      DecisionGameplayStep.stabilitySecond => _ScenarioView(
        scenario: const _ScenarioData(
          label: 'Two-part scenario',
          part: 'Part 2 of 2',
          title: 'Company Reorganization',
          description:
              'Plan A means 80 jobs will be lost for certain. Plan B has a 1 in 3 chance that no jobs are lost and a 2 in 3 chance that all jobs are lost.',
          options: [
            _OptionData(title: 'Plan A', subtitle: '80 jobs lost for certain'),
            _OptionData(
              title: 'Plan B',
              subtitle:
                  '1 in 3 chance no jobs are lost • 2 in 3 chance all jobs are lost',
            ),
          ],
        ),
        selected: _selection,
        onSelected: _select,
      ),
      DecisionGameplayStep.selfControl => _ScenarioView(
        scenario: const _ScenarioData(
          label: 'Scenario',
          title: 'Reward timing',
          description: 'Choose the option you would personally prefer.',
          options: [
            _OptionData(
              eyebrow: 'Immediate',
              title: '€7',
              subtitle: 'Available today',
              tag: 'Now',
            ),
            _OptionData(
              eyebrow: 'Later',
              title: '€18',
              subtitle: 'Available after waiting',
              tag: 'In 6 days',
            ),
          ],
          footer: 'Both options are valid personal preferences.',
        ),
        selected: _selection,
        onSelected: _select,
      ),
      DecisionGameplayStep.xpFeedback => _XpFeedbackView(onContinue: _continue),
      DecisionGameplayStep.checkpoint => _CheckpointView(
        onContinue: _continue,
        onPause: () => _goTo(DecisionGameplayStep.pause),
      ),
      DecisionGameplayStep.encouragement => _EncouragementView(
        onContinue: _continue,
      ),
      DecisionGameplayStep.pause => _JourneyPausedView(
        onResume: _continue,
        onExit: _saveFromCheckpoint,
      ),
      DecisionGameplayStep.savedProgress => _SavedProgressView(
        onResume: _continue,
        onBack: widget.onClose,
      ),
      DecisionGameplayStep.resumeJourney => _ResumeJourneyView(
        onContinue: _continue,
      ),
      DecisionGameplayStep.badge => _BadgeView(onContinue: _continue),
      DecisionGameplayStep.dimensionComplete => _DimensionCompleteView(
        onContinue: _continue,
      ),
    };
  }
}

class _DecisionProgressHeader extends StatelessWidget {
  const _DecisionProgressHeader({
    required this.scenarioNumber,
    required this.xp,
    required this.onPause,
    required this.light,
  });

  final int scenarioNumber;
  final int xp;
  final VoidCallback onPause;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Pause decision journey',
            child: IconButton(
              key: const ValueKey('decision-pause-button'),
              tooltip: 'Pause',
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
              style: IconButton.styleFrom(
                fixedSize: const Size(48, 48),
                backgroundColor: Colors.white,
                foregroundColor: _decisionInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Scenario ${scenarioNumber.toString().padLeft(2, '0')} / 30',
                style: AppTypography.titleMedium.copyWith(
                  color: light ? _decisionInk : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Container(
            height: 34,
            constraints: const BoxConstraints(minWidth: 72),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'XP $xp',
              style: AppTypography.bodySmall.copyWith(
                color: _decisionMagenta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.value, required this.light});

  final double value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Journey progress ${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: 6,
          value: value.clamp(0, 1),
          backgroundColor: light
              ? _decisionBorder
              : Colors.white.withValues(alpha: 0.88),
          valueColor: const AlwaysStoppedAnimation(_decisionMagenta),
        ),
      ),
    );
  }
}

class _DecisionTimer extends StatelessWidget {
  const _DecisionTimer({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.critical,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? _decisionWarning : _decisionTimer;
    return Semantics(
      liveRegion: true,
      label: '$secondsRemaining seconds remaining',
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (secondsRemaining / totalSeconds).clamp(0, 1),
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                'Quick choice',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              Text(
                '$secondsRemaining sec',
                key: const ValueKey('decision-timer-label'),
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScenarioData {
  const _ScenarioData({
    required this.label,
    required this.title,
    required this.description,
    required this.options,
    this.part,
    this.footer,
  });

  final String label;
  final String? part;
  final String title;
  final String description;
  final List<_OptionData> options;
  final String? footer;
}

class _OptionData {
  const _OptionData({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.tag,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final String? tag;
}

class _ScenarioView extends StatelessWidget {
  const _ScenarioView({
    required this.scenario,
    required this.selected,
    required this.onSelected,
  });

  final _ScenarioData scenario;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ScenarioCard(data: scenario),
          const SizedBox(height: 22),
          for (var i = 0; i < scenario.options.length; i++) ...[
            _DecisionChoiceCard(
              key: ValueKey('decision-option-$i'),
              data: scenario.options[i],
              selected: selected == i,
              onTap: () => onSelected(i),
            ),
            if (i != scenario.options.length - 1) const SizedBox(height: 12),
          ],
          if (scenario.footer != null) ...[
            const SizedBox(height: 18),
            Text(
              scenario.footer!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.56),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.data});

  final _ScenarioData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A211A63),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: _OutlinedChip(
                  label: data.label,
                  accent: _decisionMagenta,
                ),
              ),
              if (data.part != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _OutlinedChip(
                      label: data.part!,
                      accent: _decisionMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: AppTypography.headlineSmall.copyWith(
              color: _decisionInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: AppTypography.bodyMedium.copyWith(
              color: _decisionInk,
              fontSize: 15.5,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionChoiceCard extends StatelessWidget {
  const _DecisionChoiceCard({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _OptionData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final semanticText = [
      data.eyebrow,
      data.title,
      data.subtitle,
      data.tag,
    ].whereType<String>().join('. ');
    return Semantics(
      button: true,
      selected: selected,
      label: semanticText,
      child: Material(
        color: selected ? _decisionSoftPink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _decisionMagenta : _decisionBorder,
                width: selected ? 2.2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12211A63),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.eyebrow != null)
                        Text(
                          data.eyebrow!,
                          style: AppTypography.titleSmall.copyWith(
                            color: _decisionInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (data.eyebrow != null) const SizedBox(height: 2),
                      Text(
                        data.title,
                        style: AppTypography.titleLarge.copyWith(
                          color: _decisionInk,
                          fontSize: data.eyebrow == null ? 17 : 25,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                      if (data.subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          data.subtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: _decisionMuted,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.tag != null) ...[
                  const SizedBox(width: 10),
                  _OutlinedChip(label: data.tag!, accent: _decisionMuted),
                ],
                if (selected) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: _decisionMagenta,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedChip extends StatelessWidget {
  const _OutlinedChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 31, minWidth: 82),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: accent == _decisionMagenta ? _decisionSoftPink : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _decisionBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _ScenarioCard(
            data: _ScenarioData(
              label: 'Quick choice',
              title: 'Choose quickly',
              description: 'The timed choice has ended.',
              options: [],
            ),
          ),
          const SizedBox(height: 78),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _decisionSoftPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _decisionMagenta, width: 2),
                  ),
                  child: const Icon(
                    Icons.front_hand_rounded,
                    color: Color(0xFFFF5B32),
                    size: 58,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Time’s up - moving on.',
                  key: const ValueKey('decision-timeout-title'),
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    color: _decisionInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No worries. The journey continues.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _decisionMuted,
                  ),
                ),
                const SizedBox(height: 22),
                GamePrimaryButton(label: 'Continuing...', onPressed: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpFeedbackView extends StatelessWidget {
  const _XpFeedbackView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _ScenarioCard(
            data: _ScenarioData(
              label: 'Scenario',
              title: 'Reward timing',
              description: 'Your selected choice is saved for the journey.',
              options: [],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _decisionSoftPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _decisionMagenta, width: 2),
                  ),
                  child: Text(
                    '+12 XP',
                    style: AppTypography.titleLarge.copyWith(
                      color: _decisionMagenta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Reflection complete',
                  key: const ValueKey('decision-xp-title'),
                  style: AppTypography.headlineSmall.copyWith(
                    color: _decisionInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your choice has been saved.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _decisionMuted,
                  ),
                ),
                const SizedBox(height: 20),
                GamePrimaryButton(
                  key: const ValueKey('decision-next-scenario'),
                  label: 'Next scenario',
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeView extends StatelessWidget {
  const _BadgeView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Container(
                width: 126,
                height: 126,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EEFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC5DE49),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _decisionWarning,
                      size: 58,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Badge unlocked',
                key: const ValueKey('decision-badge-title'),
                style: AppTypography.headlineMedium.copyWith(
                  color: _decisionInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Steady Explorer',
                style: AppTypography.titleLarge.copyWith(
                  color: _decisionMagenta,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You’re building a thoughtful\ndecision journey.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: _decisionMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              GamePrimaryButton(
                key: const ValueKey('decision-badge-continue'),
                label: 'Continue',
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckpointView extends StatelessWidget {
  const _CheckpointView({required this.onContinue, required this.onPause});

  final VoidCallback onContinue;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 18),
        const _BadgeMark(label: 'MB', color: _decisionViolet),
        const SizedBox(height: 20),
        Text(
          'Halfway there',
          key: const ValueKey('decision-checkpoint-title'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You’ve completed 15 of 30 scenarios.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _lightCardDecoration(),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Journey progress',
                      style: TextStyle(
                        color: _decisionInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '50%',
                    style: TextStyle(
                      color: _decisionMagenta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _JourneyProgress(value: 0.5, light: true),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _MilestoneChip(label: 'Thoughtful'),
                  _MilestoneChip(label: 'Focused'),
                  _MilestoneChip(label: 'Adaptive'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GamePrimaryButton(
          key: const ValueKey('decision-checkpoint-continue'),
          label: 'Continue journey',
          onPressed: onContinue,
        ),
        const SizedBox(height: 10),
        GameOutlineButton(
          key: const ValueKey('decision-checkpoint-pause'),
          label: 'Take a short pause',
          onPressed: onPause,
        ),
      ],
    );
  }
}

class _EncouragementView extends StatelessWidget {
  const _EncouragementView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 48),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
          decoration: _lightCardDecoration(),
          child: Column(
            children: [
              const _BadgeMark(label: '16', color: _decisionMagenta),
              const SizedBox(height: 28),
              Text(
                'Nice reflection. Let’s continue.',
                key: const ValueKey('decision-encouragement-title'),
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  color: _decisionInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Another scenario is ready.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-encouragement-continue'),
          label: 'Continue',
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _JourneyPausedView extends StatelessWidget {
  const _JourneyPausedView({required this.onResume, required this.onExit});

  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 48),
        const _BadgeMark(label: 'Ⅱ', color: _decisionViolet),
        const SizedBox(height: 24),
        Text(
          'Pause your journey',
          key: const ValueKey('decision-journey-paused'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your progress is saved. Come back whenever you’re ready.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: _decisionMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _lightCardDecoration(),
          child: const _CompletionLine(
            label: 'Journey complete',
            value: '15 / 30',
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-pause-resume'),
          label: 'Resume journey',
          onPressed: onResume,
        ),
        const SizedBox(height: 10),
        GameOutlineButton(
          key: const ValueKey('decision-pause-exit'),
          label: 'Exit for now',
          onPressed: onExit,
        ),
      ],
    );
  }
}

class _SavedProgressView extends StatelessWidget {
  const _SavedProgressView({required this.onResume, required this.onBack});

  final VoidCallback onResume;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 28),
        const _BadgeMark(label: '✓', color: Color(0xFF2BC66D)),
        const SizedBox(height: 22),
        Text(
          'Progress saved',
          key: const ValueKey('decision-progress-saved'),
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _lightCardDecoration(),
          child: const Column(
            children: [
              _CompletionLine(label: 'Scenarios complete', value: '15'),
              Divider(height: 28, color: _decisionBorder),
              _CompletionLine(label: 'Scenarios remaining', value: '15'),
              Divider(height: 28, color: _decisionBorder),
              _CompletionLine(label: 'Estimated time left', value: '7–10 min'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-saved-resume'),
          label: 'Resume',
          onPressed: onResume,
        ),
        const SizedBox(height: 10),
        GameOutlineButton(label: 'Back to home', onPressed: onBack),
      ],
    );
  }
}

class _ResumeJourneyView extends StatelessWidget {
  const _ResumeJourneyView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 30),
        const _BadgeMark(label: 'SE', color: _decisionMagenta),
        const SizedBox(height: 22),
        Text(
          'Welcome back',
          key: const ValueKey('decision-welcome-back'),
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You’re halfway through your decision journey.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _lightCardDecoration(),
          child: const Column(
            children: [
              _CompletionLine(label: 'Completed', value: '15 / 30'),
              SizedBox(height: 16),
              _JourneyProgress(value: 0.5, light: true),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-resume-continue'),
          label: 'Continue from scenario 16',
          onPressed: onContinue,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: _decisionMagenta),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Your previous choices are saved.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: _decisionMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DimensionCompleteView extends StatelessWidget {
  const _DimensionCompleteView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 20),
        const _BadgeMark(label: 'RN', color: _decisionMagenta),
        const SizedBox(height: 20),
        Text(
          'New milestone',
          style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
        ),
        const SizedBox(height: 5),
        Text(
          'Risk Navigator',
          key: const ValueKey('decision-dimension-complete'),
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _lightCardDecoration(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniBadge(label: 'AE', active: true),
              _MiniBadge(label: 'RN', active: true),
              _MiniBadge(label: 'QC', active: false),
              _MiniBadge(label: 'SE', active: false),
              _MiniBadge(label: 'SP', active: false),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-dimension-continue'),
          label: 'Continue',
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _LightStepScroll extends StatelessWidget {
  const _LightStepScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(children: children));
  }
}

class _BadgeMark extends StatelessWidget {
  const _BadgeMark({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          label,
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _decisionMagenta : const Color(0xFFF0F2F8),
        shape: BoxShape.circle,
        border: Border.all(color: active ? _decisionMagenta : _decisionBorder),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: active ? Colors.white : _decisionMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _decisionSoftPink,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: _decisionMagenta,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompletionLine extends StatelessWidget {
  const _CompletionLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _decisionInk)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _decisionInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _lightCardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: _decisionBorder),
  boxShadow: const [
    BoxShadow(color: Color(0x12211A63), blurRadius: 18, offset: Offset(0, 8)),
  ],
);

enum DecisionPauseAction { resume, rules, exit }

class DecisionPauseDialog extends StatelessWidget {
  const DecisionPauseDialog({super.key, this.gameplayActive = true});

  final bool gameplayActive;

  @override
  Widget build(BuildContext context) {
    return GamePauseScaffold(
      titleKey: const ValueKey('decision-pause-dialog'),
      description: gameplayActive
          ? 'Your current choice and timer are safely paused.'
          : 'Take a break, review the rules or leave the journey.',
      buttons: [
        GamePrimaryButton(
          key: const ValueKey('decision-pause-dialog-resume'),
          label: gameplayActive ? 'Resume' : 'Continue',
          onPressed: () =>
              Navigator.of(context).pop(DecisionPauseAction.resume),
        ),
        GameOutlineButton(
          key: const ValueKey('decision-view-rules'),
          label: 'View rules / Help',
          onPressed: () =>
              Navigator.of(context).pop(DecisionPauseAction.rules),
        ),
        GamePauseExitButton(
          label: gameplayActive ? 'Save and exit' : 'Exit journey',
          onPressed: () => Navigator.of(context).pop(DecisionPauseAction.exit),
        ),
      ],
    );
  }
}

class DecisionRulesDialog extends StatelessWidget {
  const DecisionRulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How to play'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleLine(
              icon: Icons.article_outlined,
              text: 'Read each everyday scenario.',
            ),
            _RuleLine(
              icon: Icons.touch_app_rounded,
              text: 'Choose what feels natural — there is no right or wrong.',
            ),
            _RuleLine(
              icon: Icons.timer_outlined,
              text: 'Quick choices allow 7 seconds and move on calmly.',
            ),
            _RuleLine(
              icon: Icons.link_rounded,
              text: 'Two-part scenarios always stay together.',
            ),
            _RuleLine(
              icon: Icons.lock_outline_rounded,
              text: 'Your individual choices stay private.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('decision-rules-back'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _decisionMagenta),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _decisionInk, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
