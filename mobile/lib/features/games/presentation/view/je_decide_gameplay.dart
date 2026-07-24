import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../widgets/game_system_components.dart';

const _decisionInk = Color(0xFF28234F);
const _decisionMuted = Color(0xFF7E8DB2);
const _decisionBorder = Color(0xFFD8E2F6);
const _decisionMagenta = Color(0xFFD52E83);
const _decisionViolet = Color(0xFF4E46E8);
const _decisionSoftPink = Color(0xFFFFF1F7);
const _decisionTimer = Color(0xFF2BD06F);
const _decisionWarning = Color(0xFFFFA033);

/// Écrans de référence livrés dans la Phase 2 de « Je Décide ».
///
/// Cette séquence démontre les cinq formats de scénario et leurs états
/// d'interaction. Le catalogue complet, le scoring et la persistance restent
/// volontairement hors de ce widget jusqu'aux phases 3–4.
enum DecisionGameplayStep {
  analytical,
  riskBalance,
  quickChoice,
  stabilityFirst,
  stabilitySecond,
  selfControl,
  xpFeedback,
  badge,
}

/// Boucle de gameplay mobile de la Phase 2.
///
/// Les valeurs XP reproduisent uniquement les états visuels des maquettes :
/// elles ne constituent pas un barème et ne sont jamais soumises au backend.
class DecisionGameplayView extends StatefulWidget {
  const DecisionGameplayView({
    super.key,
    required this.onClose,
    required this.onComplete,
    this.initialStep = DecisionGameplayStep.analytical,
  });

  final VoidCallback onClose;
  final VoidCallback onComplete;
  final DecisionGameplayStep initialStep;

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
  int _secondsRemaining = _quickChoiceDuration;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
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
    DecisionGameplayStep.stabilityFirst => 19,
    DecisionGameplayStep.stabilitySecond => 20,
    DecisionGameplayStep.selfControl ||
    DecisionGameplayStep.xpFeedback ||
    DecisionGameplayStep.badge => 25,
  };

  int get _visualXp => switch (_step) {
    DecisionGameplayStep.analytical => 36,
    DecisionGameplayStep.riskBalance => 48,
    DecisionGameplayStep.quickChoice => 72,
    DecisionGameplayStep.stabilityFirst => 96,
    DecisionGameplayStep.stabilitySecond => 108,
    DecisionGameplayStep.selfControl || DecisionGameplayStep.xpFeedback => 132,
    DecisionGameplayStep.badge => 144,
  };

  bool get _isChoiceStep => switch (_step) {
    DecisionGameplayStep.analytical ||
    DecisionGameplayStep.riskBalance ||
    DecisionGameplayStep.quickChoice ||
    DecisionGameplayStep.stabilityFirst ||
    DecisionGameplayStep.stabilitySecond ||
    DecisionGameplayStep.selfControl => true,
    DecisionGameplayStep.xpFeedback || DecisionGameplayStep.badge => false,
  };

  int? get _selection => _selections[_step];

  void _scheduleQuickChoiceTimer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _step != DecisionGameplayStep.quickChoice) return;
      _startQuickChoiceTimer();
    });
  }

  void _startQuickChoiceTimer() {
    _countdown?.cancel();
    _secondsRemaining = _quickChoiceDuration;
    _timedOut = false;
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
            _goTo(DecisionGameplayStep.stabilityFirst);
          }
        },
      );
    });
  }

  void _select(int index) {
    if (_timedOut) return;
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
        _goTo(DecisionGameplayStep.stabilityFirst);
      case DecisionGameplayStep.stabilityFirst:
        _goTo(DecisionGameplayStep.stabilitySecond);
      case DecisionGameplayStep.stabilitySecond:
        _goTo(DecisionGameplayStep.selfControl);
      case DecisionGameplayStep.selfControl:
        _goTo(DecisionGameplayStep.xpFeedback);
      case DecisionGameplayStep.xpFeedback:
        _goTo(DecisionGameplayStep.badge);
      case DecisionGameplayStep.badge:
        widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationDuration = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return ColoredBox(
      color: _decisionViolet,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              _DecisionProgressHeader(
                scenarioNumber: _scenarioNumber,
                xp: _visualXp,
                onClose: widget.onClose,
              ),
              const SizedBox(height: 12),
              _JourneyProgress(value: _scenarioNumber / 30),
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
      DecisionGameplayStep.badge => _BadgeView(onContinue: _continue),
    };
  }
}

class _DecisionProgressHeader extends StatelessWidget {
  const _DecisionProgressHeader({
    required this.scenarioNumber,
    required this.xp,
    required this.onClose,
  });

  final int scenarioNumber;
  final int xp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Close decision journey',
            child: IconButton(
              key: const ValueKey('decision-close'),
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
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
                  color: Colors.white,
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
  const _JourneyProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Journey progress ${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: 6,
          value: value.clamp(0, 1),
          backgroundColor: Colors.white.withValues(alpha: 0.88),
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
