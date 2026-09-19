import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/config/bart_config.dart';
import '../../domain/entities/bart_metrics.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../games_providers.dart';
import '../widgets/decision_behavioral_components.dart';
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_spinner.dart';

/// BART — Balloon Analogue Risk Task (Lejuez et al., 2002).
///
/// Maquette de référence : planche « BART · Concept » (couverture, gonflage,
/// ballon éclaté). Le client MESURE seulement : nombre de pompes, horodatages,
/// issue de chaque ballon. Le point d'éclatement est dérivé de l'UUID de session
/// (même générateur que le serveur) pour que le ballon éclate au bon moment ; le
/// serveur rejoue tout et recalcule le score, qui n'est jamais envoyé.
///
/// Fidélité au protocole : le seul indice visuel est la TAILLE du ballon, qui ne
/// dépend que du nombre de pompes du joueur — jamais du point d'éclatement.
class BartScreen extends ConsumerStatefulWidget {
  const BartScreen({super.key});

  @override
  ConsumerState<BartScreen> createState() => _BartScreenState();
}

enum _BartStage { cover, starting, playing, outcome, submitting, results }

class _BartScreenState extends ConsumerState<BartScreen>
    with WidgetsBindingObserver {
  static const _rules =
      'Gonflez pour accumuler des points dans la réserve du ballon. Collectez pour '
      'les mettre en banque. Si le ballon éclate, sa réserve est perdue. Les deux '
      'premiers ballons sont un entraînement.';

  _BartStage _stage = _BartStage.cover;
  GameSession? _session;
  List<int> _explosionPoints = const [];
  final List<BartBalloonMetric> _balloons = [];
  final Stopwatch _balloonClock = Stopwatch();

  int _index = 0;
  int _pumps = 0;
  final List<int> _pumpStamps = [];
  bool _pumpPressed = false;
  int _bank = 0;
  BartBalloonOutcome? _lastOutcome;
  int _lastReserve = 0;

  bool _interrupted = false;
  int _backgroundEventCount = 0;
  int _focusLossCount = 0;

  BartIndicators? _indicators;
  String? _error;

  bool get _isPractice => BartConfig.phaseOf(_index) == BartPhase.practice;
  bool get _measuring =>
      !_isPractice &&
      (_stage == _BartStage.playing || _stage == _BartStage.outcome);

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
    // Sortie de l'application pendant les ballons notés : comptée, et la passation
    // sera marquée invalide côté serveur (BACKGROUND / FOCUS_LOSS).
    if (_measuring && state == AppLifecycleState.paused) {
      _backgroundEventCount++;
      _focusLossCount++;
    }
  }

  Future<void> _start() async {
    setState(() {
      _stage = _BartStage.starting;
      _error = null;
    });
    try {
      final session = await ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.decisionBehavioral);
      if (!mounted) return;
      _session = session;
      _explosionPoints = BartConfig.explosionPoints(session.id);
      _balloons.clear();
      _bank = 0;
      _interrupted = false;
      _backgroundEventCount = 0;
      _focusLossCount = 0;
      _indicators = null;
      _beginBalloon(0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _BartStage.cover;
        _error = 'Impossible de démarrer la partie. $error';
      });
    }
  }

  void _beginBalloon(int index) {
    setState(() {
      _index = index;
      _pumps = 0;
      _pumpStamps.clear();
      _lastOutcome = null;
      _stage = _BartStage.playing;
    });
    _balloonClock
      ..reset()
      ..start();
  }

  void _pump() {
    if (_stage != _BartStage.playing) return;
    final stamp = _balloonClock.elapsedMilliseconds;
    final pumps = _pumps + 1;
    if (pumps >= _explosionPoints[_index]) {
      _balloonClock.stop();
      _pumpStamps.add(stamp);
      _balloons.add(
        BartBalloonMetric(
          balloonIndex: _index,
          pumpCount: pumps,
          outcome: BartBalloonOutcome.exploded,
          pumpTimestampsMs: _pumpStamps,
        ),
      );
      SoundService.instance.playSfx(GameSfx.wrongChoice);
      setState(() {
        _pumps = pumps;
        _lastReserve = pumps * BartConfig.pointsPerPump;
        _lastOutcome = BartBalloonOutcome.exploded;
        _stage = _BartStage.outcome;
      });
      return;
    }
    _pumpStamps.add(stamp);
    setState(() {
      _pumps = pumps;
      _pumpPressed = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _pumpPressed = false);
    });
  }

  void _collect() {
    if (_stage != _BartStage.playing) return;
    _balloonClock.stop();
    final reserve = _pumps * BartConfig.pointsPerPump;
    _balloons.add(
      BartBalloonMetric(
        balloonIndex: _index,
        pumpCount: _pumps,
        outcome: BartBalloonOutcome.collected,
        pumpTimestampsMs: _pumpStamps,
        collectTimestampMs: _balloonClock.elapsedMilliseconds,
      ),
    );
    SoundService.instance.playSfx(GameSfx.correctChoice);
    setState(() {
      _bank += reserve;
      _lastReserve = reserve;
      _lastOutcome = BartBalloonOutcome.collected;
      _stage = _BartStage.outcome;
    });
  }

  void _next() {
    final next = _index + 1;
    if (next >= BartConfig.totalBalloonCount) {
      _submit();
      return;
    }
    // Fin de l'entraînement : la banque repart de zéro pour les ballons notés.
    if (next == BartConfig.practiceBalloonCount) _bank = 0;
    _beginBalloon(next);
  }

  Future<void> _submit() async {
    final session = _session;
    if (session == null) return;
    setState(() => _stage = _BartStage.submitting);
    try {
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.bartCore,
            metrics: BartMetrics(
              balloons: _balloons,
              interrupted: _interrupted,
              backgroundEventCount: _backgroundEventCount,
              focusLossCount: _focusLossCount,
            ),
          );
      if (!mounted) return;
      SoundService.instance.playScoreboard();
      setState(() {
        _session = updated;
        _indicators = updated.bartIndicators;
        _stage = _BartStage.results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Envoi impossible. $error';
        _stage = _BartStage.results;
      });
    }
  }

  Future<void> _openPause() async {
    final wasRunning = _balloonClock.isRunning;
    _balloonClock.stop();
    final action = await showDecisionPause(context, rules: _rules);
    if (!mounted) return;
    if (action == DecisionPauseAction.exit) {
      _exit();
      return;
    }
    if (wasRunning) _balloonClock.start();
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
        _BartStage.cover || _BartStage.starting => DecisionGameCover(
          title: 'BART',
          subtitle: 'Gonfler ou collecter',
          illustrationAsset: DecisionBehavioralAssets.bartLogo,
          tiles: const [
            DecisionCoverTile(
              icon: HugeIcons.strokeRoundedChartBubble01,
              value: '30',
              label: 'ballons',
            ),
            DecisionCoverTile(
              icon: HugeIcons.strokeRoundedMortarboard01,
              value: '2',
              label: 'essais pratiques',
            ),
          ],
          instruction:
              'Gonflez pour accumuler des points. Collectez avant que le ballon éclate.',
          busy: _stage == _BartStage.starting,
          error: _error,
          onStart: _start,
          onBack: _exit,
        ),
        _BartStage.playing => _buildPlaying(),
        _BartStage.outcome => _buildOutcome(),
        _BartStage.submitting => const DecisionGameplayFrame(
          children: [
            SizedBox(height: 200),
            Center(child: AppSpinner(color: Colors.white)),
          ],
        ),
        _BartStage.results => _buildResults(),
      },
    );
  }

  String get _title {
    if (_isPractice) {
      return 'Entraînement ${_index + 1} / ${BartConfig.practiceBalloonCount}';
    }
    final n = _index - BartConfig.practiceBalloonCount + 1;
    return 'Ballon ${n.toString().padLeft(2, '0')} / ${BartConfig.testBalloonCount}';
  }

  double get _progress => _isPractice
      ? (_index + 1) / BartConfig.practiceBalloonCount
      : (_index - BartConfig.practiceBalloonCount + 1) /
            BartConfig.testBalloonCount;

  Widget _buildPlaying() {
    final reserve = _pumps * BartConfig.pointsPerPump;
    return DecisionGameplayFrame(
      children: [
        DecisionTrialHeader(
          title: _title,
          progress: _progress,
          progressColor: ZennytGamePalette.cyan,
          onPause: _openPause,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: DecisionValueTile(
                label: 'Banque',
                value: _pts(_bank),
                valueKey: const ValueKey('bart-bank'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DecisionValueTile(
                label: 'Réserve',
                value: _pts(reserve),
                valueColor: ZennytGamePalette.magenta,
                valueKey: const ValueKey('bart-reserve'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        GestureDetector(
          onTap: _pump,
          child: Container(
            height: 330,
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gamePanel,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: Stack(
              children: [
                // Tuyau pompe → bout de la ficelle, sous le ballon et la pompe.
                const Positioned.fill(
                  child: CustomPaint(painter: _HosePainter()),
                ),
                Positioned(
                  left: 0,
                  right: _pumpLaneWidth,
                  bottom: 0,
                  top: 0,
                  child: _Balloon(pumps: _pumps),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: _pumpWidth,
                  height: _pumpHeight,
                  child: SvgPicture.asset(
                    _pumpPressed
                        ? DecisionBehavioralAssets.pumpPressed
                        : DecisionBehavioralAssets.pumpIdle,
                    semanticsLabel: 'Pompe',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          '$_pumps ${_pumps > 1 ? 'pompes' : 'pompe'}',
          key: const ValueKey('bart-pump-count'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: GamePrimaryButton(
                key: const ValueKey('bart-pump'),
                label: 'Gonfler',
                onPressed: _pump,
                playClickSound: false,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GamePrimaryButton(
                key: const ValueKey('bart-collect'),
                label: 'Collecter',
                color: Colors.white,
                foregroundColor: ZennytGamePalette.ink,
                onPressed: _collect,
                playClickSound: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutcome() {
    final exploded = _lastOutcome == BartBalloonOutcome.exploded;
    final lastPractice = _index == BartConfig.practiceBalloonCount - 1;
    final last = _index == BartConfig.totalBalloonCount - 1;
    return DecisionGameplayFrame(
      children: [
        DecisionTrialHeader(
          title: _title,
          progress: _progress,
          progressColor: ZennytGamePalette.cyan,
          onPause: _openPause,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: SvgPicture.asset(
                  exploded
                      ? DecisionBehavioralAssets.balloonExploded
                      : DecisionBehavioralAssets.balloonCollected,
                  semanticsLabel: exploded
                      ? 'Ballon éclaté'
                      : 'Réserve collectée',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                exploded ? 'Ballon éclaté' : 'Réserve collectée',
                key: const ValueKey('bart-outcome-title'),
                style: const TextStyle(
                  color: ZennytGamePalette.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                exploded
                    ? 'La réserve de ce ballon est perdue.'
                    : 'Les points de la réserve sont en banque.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ZennytGamePalette.muted,
                  fontSize: 17,
                ),
              ),
              if (_isPractice) ...[
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Entraînement : ces points ne comptent pas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ZennytGamePalette.muted,
                    fontSize: 14,
                  ),
                ),
              ],
              const Divider(height: AppSpacing.xxl),
              _OutcomeRow(
                label: exploded ? 'Réserve' : 'Réserve collectée',
                value: exploded ? _pts(0) : '+${_pts(_lastReserve)}',
                color: exploded
                    ? ZennytGamePalette.magenta
                    : ZennytGamePalette.success,
              ),
              const Divider(height: AppSpacing.xl),
              _OutcomeRow(
                label: exploded ? 'Banque conservée' : 'Banque',
                value: _pts(_bank),
                color: ZennytGamePalette.ink,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GamePrimaryButton(
          key: const ValueKey('bart-next'),
          label: last
              ? 'Voir le résultat'
              : lastPractice
              ? 'Commencer les 30 ballons'
              : 'Ballon suivant',
          onPressed: _next,
        ),
      ],
    );
  }

  Widget _buildResults() {
    final report = _indicators;
    final attempt = _session?.lastAttempt?.score;
    if (report == null) {
      return GameResultsTemplate(
        onBack: _exit,
        gameName: 'BART',
        scoreLabel: 'Efficience provisoire',
        scorePercent: null,
        stats: const [
          GameResultStat(label: 'Collectés', value: '—'),
          GameResultStat(label: 'Éclatés', value: '—'),
          GameResultStat(label: 'Pompes moy.', value: '—'),
        ],
        insight: null,
        notice: Text(_error ?? 'Résultat indisponible.'),
        primaryLabel: 'Rejouer',
        onPrimary: _start,
        secondaryLabel: 'Retour aux jeux',
        onSecondary: () => context.go(AppRoutes.games),
      );
    }
    return GameResultsTemplate(
      onBack: _exit,
      gameName: 'BART',
      scoreLabel: 'Efficience provisoire',
      scorePercent: report.sessionValid ? report.efficiencyPercent : null,
      points: attempt?.rawPoints ?? report.efficiencyPercent,
      maxPoints: attempt?.maxPoints ?? 100,
      scoreKey: const ValueKey('bart-result-score'),
      stats: [
        GameResultStat(
          label: 'Collectés',
          value: '${report.collectedCount}/${report.testBalloonCount}',
          color: ZennytGamePalette.success,
        ),
        GameResultStat(label: 'Éclatés', value: '${report.explosionCount}'),
        GameResultStat(
          label: 'Pompes moy.',
          value: report.adjustedAveragePumps?.toStringAsFixed(1) ?? '—',
          color: ZennytGamePalette.magenta,
        ),
      ],
      insight:
          'Vous avez gagné ${report.totalEarnings} pts, contre ${report.evOptimalEarnings} pts '
          'pour la stratégie de référence (${report.optimalFixedPumps} pompes par ballon) '
          'sur les mêmes ballons. Les pompes moyennes décrivent votre appétence au '
          'risque : ni haute ni basse n\'est meilleure. Résultat provisoire, non validé.',
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

/// Points au singulier jusqu'à 1 inclus, comme en français (« 0 pt », « 1 pt »).
String _pts(int value) => value <= 1 ? '$value pt' : '$value pts';

// Géométrie du plateau : la pompe occupe un couloir à droite, le ballon le reste.
const double _pumpLaneWidth = 110;
const double _pumpWidth = 120;
const double _pumpHeight = 150;

/// Relie la sortie du tuyau de la pompe au bout de la ficelle du ballon.
///
/// Le ballon est ancré en bas-centre et mis à l'échelle depuis ce point : le bout
/// de sa ficelle (y = 236 sur 240 dans le SVG) reste donc au bas de sa zone quelle
/// que soit sa taille, et le tuyau n'a jamais à suivre le gonflage. La sortie du
/// tuyau vient de bart_pump_*.svg (point (4, 120) sur 160 × 200, rendu à 0,75).
class _HosePainter extends CustomPainter {
  const _HosePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const pumpScale = _pumpWidth / 160;
    final outlet = Offset(
      size.width - _pumpWidth + 4 * pumpScale,
      size.height - _pumpHeight + 120 * pumpScale,
    );
    final stringEnd = Offset(
      (size.width - _pumpLaneWidth) / 2,
      size.height - 4,
    );
    final hose = Path()
      ..moveTo(outlet.dx, outlet.dy)
      ..cubicTo(
        outlet.dx - 34,
        outlet.dy - 26,
        stringEnd.dx + 56,
        size.height - 2,
        stringEnd.dx,
        stringEnd.dy,
      );
    canvas
      ..drawPath(
        hose,
        Paint()
          ..color = const Color(0xFF1F1B4D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9 * pumpScale
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        hose,
        Paint()
          ..color = const Color(0xFF9AA3C7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * pumpScale
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(covariant _HosePainter oldDelegate) => false;
}

/// Ballon dont la taille ne dépend QUE du nombre de pompes (ancre : le nœud).
class _Balloon extends StatelessWidget {
  const _Balloon({required this.pumps});

  final int pumps;

  @override
  Widget build(BuildContext context) {
    if (pumps == 0) {
      return SvgPicture.asset(
        DecisionBehavioralAssets.balloonIdle,
        alignment: Alignment.bottomCenter,
        semanticsLabel: 'Nouveau ballon',
      );
    }
    final fraction = math.min(pumps, BartConfig.maxPumps) / BartConfig.maxPumps;
    final scale = 0.5 + 0.5 * math.sqrt(fraction);
    return AnimatedScale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 110),
      child: SvgPicture.asset(
        DecisionBehavioralAssets.balloonInflated,
        alignment: Alignment.bottomCenter,
        semanticsLabel: 'Ballon gonflé de $pumps pompes',
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
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
              color: ZennytGamePalette.muted,
              fontSize: 18,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
