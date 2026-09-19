import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/config/ist_config.dart';
import '../../domain/config/ist_provisional_rules.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/ist_metrics.dart';
import '../../domain/entities/mini_game.dart';
import '../games_providers.dart';
import '../widgets/decision_behavioral_components.dart';
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_spinner.dart';

/// IST — Information Sampling Task (Clark et al., 2006).
///
/// Maquette de référence : planche « IST · Concept » (couverture, grille en gain
/// décroissant, recueil de confiance). Le client mesure : cases ouvertes dans
/// l'ordre avec horodatages, couleur choisie, confiance facultative. Les grilles
/// sont dérivées de l'UUID de session ; le serveur les régénère, rejoue les
/// ouvertures et calcule P(correct) sous la loi de génération réelle.
class IstScreen extends ConsumerStatefulWidget {
  const IstScreen({super.key});

  @override
  ConsumerState<IstScreen> createState() => _IstScreenState();
}

enum _IstStage { cover, starting, trial, confidence, submitting, results }

class _IstScreenState extends ConsumerState<IstScreen>
    with WidgetsBindingObserver {
  static const _rules =
      'Ouvrez des cases pour découvrir leur couleur, puis choisissez la couleur '
      'majoritaire sur les 25. En gain fixe, ouvrir est gratuit ; en gain décroissant, '
      'chaque case ouverte coûte 10 points. Une réponse fausse coûte 100 points.';

  static const _confidenceLabels = [
    'Au hasard',
    'Plutôt sûr',
    'Sûr',
    'Certain',
  ];

  _IstStage _stage = _IstStage.cover;
  GameSession? _session;
  List<IstLayout> _layouts = const [];
  final List<IstTrialMetric> _trials = [];
  final Stopwatch _trialClock = Stopwatch();

  int _index = 0;
  final List<IstBoxOpening> _openings = [];
  IstColor? _chosen;
  int _decisionStamp = 0;
  int? _confidence;

  int _backgroundEventCount = 0;
  int _focusLossCount = 0;

  IstIndicators? _indicators;
  String? _error;

  IstLayout get _layout => _layouts[_index];
  bool get _isPractice => _layout.slot.phase == IstPhase.practice;
  bool get _measuring =>
      _layouts.isNotEmpty &&
      !_isPractice &&
      (_stage == _IstStage.trial || _stage == _IstStage.confidence);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_measuring && state == AppLifecycleState.paused) {
      _backgroundEventCount++;
      _focusLossCount++;
    }
  }

  Future<void> _start() async {
    setState(() {
      _stage = _IstStage.starting;
      _error = null;
    });
    try {
      final session = await ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.decisionBehavioral);
      if (!mounted) return;
      _session = session;
      _layouts = IstConfig.generateLayouts(session.id);
      _trials.clear();
      _backgroundEventCount = 0;
      _focusLossCount = 0;
      _indicators = null;
      _beginTrial(0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _IstStage.cover;
        _error = 'Impossible de démarrer la partie. $error';
      });
    }
  }

  void _beginTrial(int index) {
    setState(() {
      _index = index;
      _openings.clear();
      _chosen = null;
      _confidence = null;
      _stage = _IstStage.trial;
    });
    _trialClock
      ..reset()
      ..start();
  }

  bool _isOpen(int box) => _openings.any((o) => o.boxIndex == box);

  void _open(int box) {
    if (_stage != _IstStage.trial || _isOpen(box)) return;
    SoundService.instance.playSfx(GameSfx.buttonClick);
    setState(() {
      _openings.add(
        IstBoxOpening(
          boxIndex: box,
          timestampMs: _trialClock.elapsedMilliseconds,
        ),
      );
    });
  }

  void _choose(IstColor color) {
    if (_stage != _IstStage.trial) return;
    _decisionStamp = _trialClock.elapsedMilliseconds;
    _trialClock.stop();
    setState(() {
      _chosen = color;
      _stage = _IstStage.confidence;
    });
  }

  void _confirm({required bool skip}) {
    _trials.add(
      IstTrialMetric(
        trialIndex: _index,
        openings: List.of(_openings),
        chosenColor: _chosen!,
        decisionTimestampMs: _decisionStamp,
        confidence: skip ? null : _confidence,
      ),
    );
    final next = _index + 1;
    if (next >= IstConfig.totalTrialCount) {
      _submit();
    } else {
      _beginTrial(next);
    }
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null) return;
    setState(() => _stage = _IstStage.submitting);
    try {
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.informationSamplingCore,
            metrics: IstMetrics(
              trials: _trials,
              interrupted: false,
              backgroundEventCount: _backgroundEventCount,
              focusLossCount: _focusLossCount,
            ),
          );
      if (!mounted) return;
      SoundService.instance.playScoreboard();
      setState(() {
        _session = updated;
        _indicators = updated.istIndicators;
        _stage = _IstStage.results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Envoi impossible. $error';
        _stage = _IstStage.results;
      });
    }
  }

  Future<void> _openPause() async {
    final wasRunning = _trialClock.isRunning;
    _trialClock.stop();
    final action = await showDecisionPause(context, rules: _rules);
    if (!mounted) return;
    if (action == DecisionPauseAction.exit) {
      _exit();
      return;
    }
    if (wasRunning) _trialClock.start();
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.games);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_stage) {
        _IstStage.cover || _IstStage.starting => DecisionGameCover(
          title: 'IST',
          subtitle: 'Observer puis décider',
          illustrationAsset: DecisionBehavioralAssets.istLogo,
          tiles: const [
            DecisionCoverTile(
              icon: HugeIcons.strokeRoundedLayers01,
              value: '20',
              label: 'essais',
            ),
            DecisionCoverTile(
              icon: HugeIcons.strokeRoundedMortarboard01,
              value: '2',
              label: 'essais pratiques',
            ),
          ],
          instruction:
              'Ouvrez des cases, puis choisissez la couleur majoritaire.',
          busy: _stage == _IstStage.starting,
          error: _error,
          onStart: _start,
          onBack: _exit,
        ),
        _IstStage.trial || _IstStage.confidence => _buildTrial(),
        _IstStage.submitting => const DecisionGameplayFrame(
          children: [
            SizedBox(height: 200),
            Center(child: AppSpinner(color: Colors.white)),
          ],
        ),
        _IstStage.results => _buildResults(),
      },
    );
  }

  String get _title {
    if (_isPractice) return 'Entraînement ${_index + 1} / 2';
    final n = _index - 1;
    return 'Essai $n / ${2 * IstConfig.testTrialsPerCondition}';
  }

  double get _progress => _isPractice
      ? (_index + 1) / 2
      : (_index - 1) / (2 * IstConfig.testTrialsPerCondition);

  Widget _buildTrial() {
    final header = DecisionTrialHeader(
      title: _title,
      progress: _progress,
      progressColor: ZennytGamePalette.magenta,
      onPause: _openPause,
    );
    if (_stage == _IstStage.confidence) {
      return DecisionGameplayFrame(
        children: [
          header,
          const SizedBox(height: AppSpacing.lg),
          _buildConfidenceCard(),
        ],
      );
    }
    final condition = _layout.slot.condition;
    final decreasing = condition == IstCondition.decreasingWin;
    return DecisionGameplayFrame(
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        DecisionPill(label: decreasing ? 'Gain décroissant' : 'Gain fixe'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DecisionValueTile(
                label: 'Gain possible',
                value:
                    '${IstConfig.possibleWin(condition, _openings.length)} pts',
                valueColor: ZennytGamePalette.magenta,
                valueKey: const ValueKey('ist-possible-win'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DecisionValueTile(
                label: 'Cases ouvertes',
                value: '${_openings.length} / ${IstConfig.boxCount}',
                valueKey: const ValueKey('ist-opened-count'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: IstConfig.gridSide,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            children: [
              for (var box = 0; box < IstConfig.boxCount; box++) _buildBox(box),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          decreasing
              ? 'Chaque case ouverte coûte ${IstConfig.decreasingWinCostPerBox} points.'
              : 'Ouvrir des cases ne coûte rien.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Quelle couleur est majoritaire ?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ColorChoice(color: IstColor.blue, onTap: _choose),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ColorChoice(color: IstColor.orange, onTap: _choose),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Réponse incorrecte : −${IstConfig.incorrectPenaltyPoints} points',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildBox(int box) {
    final open = _isOpen(box);
    final color = !open
        ? DecisionBehavioralColors.closedBox
        : _layout.boxes[box] == IstColor.blue
        ? DecisionBehavioralColors.revealedBlue
        : DecisionBehavioralColors.revealedOrange;
    return Semantics(
      button: !open,
      label: open
          ? 'Case ${box + 1}, ${_layout.boxes[box] == IstColor.blue ? 'bleue' : 'orange'}'
          : 'Case ${box + 1}, fermée',
      child: GestureDetector(
        key: ValueKey('ist-box-$box'),
        onTap: () => _open(box),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final chosen = _chosen!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Swatch(color: chosen, size: 72),
              const SizedBox(width: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre choix :',
                    style: TextStyle(
                      color: ZennytGamePalette.muted,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _colorName(chosen),
                    style: const TextStyle(
                      color: ZennytGamePalette.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: AppSpacing.xxl),
          const Text(
            'À quel point êtes-vous sûr ?',
            style: TextStyle(
              color: ZennytGamePalette.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (
            var level = IstProvisionalRules.confidenceMin;
            level <= IstProvisionalRules.confidenceMax;
            level++
          )
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ConfidenceOption(
                key: ValueKey('ist-confidence-$level'),
                label: _confidenceLabels[level - 1],
                selected: _confidence == level,
                onTap: () => setState(() => _confidence = level),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          GamePrimaryButton(
            key: const ValueKey('ist-confirm'),
            label: 'Confirmer',
            onPressed: _confidence == null ? null : () => _confirm(skip: false),
          ),
          TextButton(
            key: const ValueKey('ist-skip'),
            onPressed: () => _confirm(skip: true),
            child: const Text(
              'Passer',
              style: TextStyle(
                color: ZennytGamePalette.gameBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final report = _indicators;
    final attempt = _session?.lastAttempt?.score;
    if (report == null) {
      return GameResultsTemplate(
        onBack: _exit,
        gameName: 'IST',
        scoreLabel: 'Score provisoire',
        scorePercent: null,
        stats: const [
          GameResultStat(label: 'Justes', value: '—'),
          GameResultStat(label: 'Cases GF / GD', value: '—'),
          GameResultStat(label: 'P(correct)', value: '—'),
        ],
        insight: null,
        notice: Text(_error ?? 'Résultat indisponible.'),
        primaryLabel: 'Rejouer',
        onPrimary: _start,
        secondaryLabel: 'Retour aux jeux',
        onSecondary: () => context.go(AppRoutes.games),
      );
    }
    final bias = report.calibrationBias;
    final calibration = bias == null
        ? 'Aucune confiance renseignée.'
        : bias > 0.05
        ? 'Votre confiance dépasse légèrement votre exactitude.'
        : bias < -0.05
        ? 'Vous avez été plus juste que vous ne le pensiez.'
        : 'Votre confiance correspond à votre exactitude.';
    return GameResultsTemplate(
      onBack: _exit,
      gameName: 'IST',
      scoreLabel: 'Score provisoire',
      scorePercent: report.sessionValid ? report.provisionalScore : null,
      points: attempt?.rawPoints ?? report.provisionalScore,
      maxPoints: attempt?.maxPoints ?? 100,
      scoreKey: const ValueKey('ist-result-score'),
      stats: [
        GameResultStat(
          label: 'Justes',
          value: '${report.correctCount}/${report.testTrialCount}',
          color: ZennytGamePalette.success,
        ),
        GameResultStat(
          label: 'Cases GF / GD',
          value:
              '${report.meanBoxesFixedWin.toStringAsFixed(1)} / ${report.meanBoxesDecreasingWin.toStringAsFixed(1)}',
        ),
        GameResultStat(
          label: 'P(correct)',
          value: '${(report.meanPCorrectAtDecision * 100).round()} %',
          color: ZennytGamePalette.magenta,
        ),
      ],
      insight:
          'Vous avez décidé avec en moyenne ${(report.meanPCorrectAtDecision * 100).round()} % '
          'de chances d\'avoir raison. $calibration Résultat provisoire, non validé.',
      notice: report.sessionValid
          ? null
          : Text(
              'Passation non retenue (${report.validityIssues.join(', ')}). '
              'Rejouez pour enregistrer un résultat.',
            ),
      primaryLabel: 'Rejouer',
      onPrimary: _start,
      secondaryLabel: 'Retour aux jeux',
      onSecondary: () => context.go(AppRoutes.games),
    );
  }
}

String _colorName(IstColor color) => color == IstColor.blue ? 'Bleu' : 'Orange';

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.size = 40});

  final IstColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color == IstColor.blue
            ? DecisionBehavioralColors.revealedBlue
            : DecisionBehavioralColors.revealedOrange,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.color, required this.onTap});

  final IstColor color;
  final ValueChanged<IstColor> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        key: ValueKey('ist-choose-${color.wire}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onTap(color);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Swatch(color: color),
              const SizedBox(width: AppSpacing.md),
              Text(
                _colorName(color),
                style: const TextStyle(
                  color: ZennytGamePalette.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceOption extends StatelessWidget {
  const _ConfidenceOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? ZennytGamePalette.gameBlue
                  : ZennytGamePalette.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AppIcon(
                selected
                    ? HugeIcons.strokeRoundedRadioButton
                    : HugeIcons.strokeRoundedCircle,
                color: selected
                    ? ZennytGamePalette.gameBlue
                    : ZennytGamePalette.muted,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: const TextStyle(
                  color: ZennytGamePalette.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
