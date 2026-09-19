import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/planifik_metrics.dart';
import '../flame/cell_component.dart';
import '../flame/grid_config.dart';
import '../flame/planifik_game.dart';
import '../games_controller.dart';
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';
import '../widgets/game_tutorial_deck.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_spinner.dart';

/// Jeu « Optimal Path » (Planifik — « Je planifie »).
///
/// Flow complet aligné sur la maquette Figma :
/// `Start → Briefing → Map scan / Plan route → Validate → Score → Replay`.
/// Il assemble :
/// - [PlanifikGame] (Flame) pour le plateau et la collecte des métriques ;
/// - [gamesControllerProvider] (Riverpod) pour le cycle session/score ;
/// - les composants partagés du design system jeux ([GamePanel], boutons…).
///
/// Flame ne connaît pas Riverpod : l'écran fait le pont au clic sur « Validate ».
class PlanifikScreen extends ConsumerStatefulWidget {
  const PlanifikScreen({super.key});

  @override
  ConsumerState<PlanifikScreen> createState() => _PlanifikScreenState();
}

enum _PlanifikStage { intro, howToPlay, gameplay, score, comparison }

class _PlanifikScreenState extends ConsumerState<PlanifikScreen> {
  // Recréé à chaque partie : évite tout état résiduel / re-onLoad de Flame.
  PlanifikGame _game = PlanifikGame();
  List<GridConfig> _levelConfigs = GridConfig.randomLevels();

  // Limite dure d'essais — miroir de OptimalPathConfig.MAX_ATTEMPTS (backend).
  static const int _maxAttempts = 3;

  _PlanifikStage _stage = _PlanifikStage.intro;
  // Essais de validation sur le NIVEAU courant (incrémenté à chaque mauvaise route).
  int _levelAttempts = 0;
  // true dès que le niveau est scellé en échec (3 validations ratées) : plus
  // aucune validation acceptée, passage auto au niveau suivant.
  bool _levelFailed = false;
  bool _busy = false;
  int _level = 0;
  int _score = 0;
  // Fautes de case interdite (rouge) AU NIVEAU courant : chaque tentative de
  // franchissement est comptée comme un « essai » supplémentaire dans les
  // métriques → sanctionne le score /10 du niveau, en plus de la pénalité
  // visuelle immédiate sur le score affiché.
  int _levelCellFaults = 0;
  PlanifikMetrics? _lastMetrics;
  // Cumul explicite des métriques PAR NIVEAU — soumis en un seul PlanifikMetrics
  // au dernier niveau (le backend note chaque niveau /10 puis fait la moyenne).
  final List<PlanifikLevelMetrics> _levelMetrics = [];

  /// Droit de pause de la PARTIE — une ouverture, 30 s (CdC pause §2-3).
  ///
  /// Porté par l'écran et non par `_GameplayView` : celui-ci est reconstruit à
  /// chaque niveau (`key: ValueKey(_level)`), ce qui aurait rendu un droit de
  /// pause par niveau au lieu d'un par session.
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _beginGame() async {
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    setState(() {
      _levelConfigs = GridConfig.randomLevels();
      _level = 0;
      _score = 0;
      _levelCellFaults = 0;
      _game = PlanifikGame(
        config: _levelConfigs[_level],
        onWrongCell: _onWrongCell,
        onBlockedTap: _onBlockedTap,
        onPointAdded: _onPointAdded,
      );
      _stage = _PlanifikStage.gameplay;
      _levelAttempts = 0;
      _levelFailed = false;
      _levelMetrics.clear();
      _lastMetrics = null;
    });
    await ref.read(gamesControllerProvider.notifier).start(GameType.planifik);
  }

  /// Route correcte validée : +250, on fige les métriques du niveau, puis niveau
  /// suivant (plus dur) ou, au dernier niveau, soumission au backend.
  void _onCorrectRoute() {
    SoundService.instance.playSfx(GameSfx.correctChoice);
    _score += 250;
    _captureLevelMetrics();
    _goToNextLevelOrSubmit();
  }

  /// Un point vient d'être ajouté au tracé : son « start-point » pour chaque
  /// point (départ + intermédiaires), son « goal-point » quand on atteint la
  /// case d'arrivée.
  void _onPointAdded(bool isGoal) {
    SoundService.instance.playSfx(
      isGoal ? GameSfx.goalPoint : GameSfx.startPoint,
    );
  }

  /// Appui sur une case interdite (rouge), **où qu'elle soit** : retour d'erreur
  /// sonore et haptique.
  ///
  /// La vibration est déclenchée par SoundService avec le son d'erreur : un
  /// appel direct à HapticFeedback ici échapperait au réglage « Vibration » du
  /// menu pause.
  void _onBlockedTap() {
    SoundService.instance.playSfx(GameSfx.wrongChoice);
  }

  /// Case interdite touchée **en prolongement du tracé** : erreur de
  /// planification, donc pénalité de score (le jeu dessine puis efface le faux
  /// segment de son côté).
  ///
  /// Ne joue pas le son : [_onBlockedTap] vient de le faire pour ce même appui.
  void _onWrongCell() {
    setState(() {
      _levelCellFaults++; // sanctionne le score /10 du niveau (compté en essais)
      // Sanction visuelle claire : chaque case interdite retire 3 points.
      _score = math.max(0, _score - 3);
    });
  }

  void _onWrongRoute() {
    if (_levelFailed) return; // niveau déjà scellé
    _levelAttempts++;
    setState(() => _score = math.max(0, _score - 2));
    // Limite dure : 3 validations ratées → niveau échoué (cas « réussi au 3ᵉ
    // essai » exclu : la réussite passe par _onCorrectRoute, jamais ici).
    if (_levelAttempts >= _maxAttempts) {
      _failLevel();
    }
  }

  /// Scelle le niveau en échec : capture des métriques d'échec (1/10) puis
  /// passage automatique au niveau suivant après un court délai.
  void _failLevel() {
    _levelMetrics.add(
      _game.buildFailedLevelMetrics(
        levelIndex: _level,
        // Fautes de case interdite comptées comme des essais → aggravent la
        // sanction (>= 3 → 1 pt sur « essais »).
        attempts: _levelAttempts + _levelCellFaults,
      ),
    );
    setState(() => _levelFailed = true);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _goToNextLevelOrSubmit();
    });
  }

  /// Passe au niveau suivant (nouveau plateau) ou soumet au dernier niveau.
  void _goToNextLevelOrSubmit() {
    if (_level < _levelConfigs.length - 1) {
      setState(() {
        _level++;
        _levelAttempts = 0;
        _levelCellFaults = 0;
        _levelFailed = false;
        _game = PlanifikGame(
          config: _levelConfigs[_level],
          onWrongCell: _onWrongCell,
          onBlockedTap: _onBlockedTap,
          onPointAdded: _onPointAdded,
        );
      });
    } else {
      _submitFinal();
    }
  }

  /// Fige les métriques du niveau courant. Les « essais » = mauvaises routes + 1
  /// + fautes de case interdite : franchir (tenter) une case rouge est ainsi
  /// sanctionné dans le score /10 du niveau (barème « essais » : 1→3, 2→2, ≥3→1).
  void _captureLevelMetrics() {
    final metrics = _game.buildLevelMetrics(
      levelIndex: _level,
      attempts: _levelAttempts + 1 + _levelCellFaults,
    );
    if (metrics != null) _levelMetrics.add(metrics);
  }

  Future<void> _submitFinal() async {
    if (_levelMetrics.isEmpty) return;
    final metrics = PlanifikMetrics(
      levels: List<PlanifikLevelMetrics>.unmodifiable(_levelMetrics),
    );
    _lastMetrics = metrics;
    setState(() => _busy = true);
    await ref
        .read(gamesControllerProvider.notifier)
        .submit(miniGame: MiniGame.optimalPath, metrics: metrics);
    if (!mounted) return;
    final scored = ref.read(gamesControllerProvider).value?.lastAttempt != null;
    setState(() {
      _busy = false;
      if (scored) _stage = _PlanifikStage.score;
    });
    if (scored) SoundService.instance.playScoreboard();
  }

  void _replay() {
    _beginGame();
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

    return PopScope(
      canPop: _stage == _PlanifikStage.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _stage = _PlanifikStage.intro);
      },
      child: Scaffold(
        backgroundColor: _stage == _PlanifikStage.gameplay
            ? ZennytGamePalette.gameBlue
            : Colors.white,
        body: SafeArea(child: _buildStage()),
      ),
    );
  }

  Widget _buildStage() {
    final session = ref.watch(gamesControllerProvider).value;
    return switch (_stage) {
      _PlanifikStage.intro => _IntroView(
        onStart: () => setState(() => _stage = _PlanifikStage.howToPlay),
        onBack: () => context.go(AppRoutes.games),
      ),
      _PlanifikStage.howToPlay => OptimalPathTutorial(
        leading: _SquareIconButton(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          onTap: () => setState(() => _stage = _PlanifikStage.intro),
        ),
        onComplete: _beginGame,
      ),
      _PlanifikStage.gameplay => GameplayMusic(
        child: _GameplayView(
          key: ValueKey(_level),
          game: _game,
          busy: _busy,
          score: _score,
          level: _level + 1,
          totalLevels: _levelConfigs.length,
          levelFailed: _levelFailed,
          pauseAllowance: _pauseAllowance,
          onCorrect: _onCorrectRoute,
          onWrong: _onWrongRoute,
          onExit: () => context.go(AppRoutes.games),
        ),
      ),
      _PlanifikStage.score => _ScoreView(
        session: session,
        metrics: _lastMetrics,
        onReplay: _replay,
        onCompare: () => setState(() => _stage = _PlanifikStage.comparison),
        // Chaque jeu est individuel : Optimal Path se termine sur son propre
        // écran de score et revient au hub, sans enchaîner sur l'ordonnancement.
        onNext: () => context.go(AppRoutes.games),
        onBack: () => context.go(AppRoutes.games),
      ),
      _PlanifikStage.comparison => _ComparisonView(
        session: session,
        metrics: _lastMetrics,
        optimalLength: _game.optimalLength,
        onReplay: _replay,
        onBack: () => setState(() => _stage = _PlanifikStage.score),
      ),
    };
  }
}

// ─────────────────────────── Accueil ──────────────────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart, required this.onBack});
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => GameWelcomePage(
    title: 'Optimal Path',
    logoAsset: 'assets/games icons/Optimal Path transparent.png',
    logoScale: 1.15,
    mission: 'Trace le meilleur chemin en respectant les contraintes.',
    contextText:
        'Rejoins l’arrivée en évitant les obstacles et en récupérant les documents du parcours.',
    contextDetail: 'Anticipe le trajet avant de le tracer.',
    journey: const ['Observe', 'Trace', 'Valide'],
    leading: _SquareIconButton(icon: HugeIcons.strokeRoundedArrowLeft01, onTap: onBack),
    startLabel: 'Commencer',
    onStart: onStart,
  );
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final AppIconData icon;
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
          child: AppIcon(icon, color: ZennytGamePalette.ink, size: 24),
        ),
      ),
    );
  }
}

// ─────────────────────────── How To Play (tutorial) ───────────────────────────

/// Amélioration des deux pages existantes, avec leur style de stations rondes.
/// PROVISOIRE — à valider visuellement sur appareil (GAMES_MODULE, décision 71).
class OptimalPathTutorial extends StatelessWidget {
  const OptimalPathTutorial({
    super.key,
    required this.leading,
    required this.onComplete,
  });

  final Widget leading;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => GameTutorialDeck(
    leading: leading,
    onComplete: onComplete,
    completionLabel: 'Commencer le parcours',
    steps: const [
      GameTutorialStep(
        title: 'Relie LAB à MTG',
        description:
            'Glisse ou touche les stations voisines, sans diagonale. '
            'Évite les blocs rouges. Glisse en arrière pour effacer un pas.',
        illustration: _StationsTutorialArt(),
        illustrationLabel:
            'Départ LAB : cercle blanc bordé de bleu. Le chemin magenta '
            'passe par les stations voisines et une étoile, contourne le bloc '
            'rouge et atteint MTG, le cercle vert. Aucun segment diagonal.',
      ),
      GameTutorialStep(
        title: 'Choisis un trajet efficace',
        description:
            'Privilégie une route courte et peu d’essais. Récupère les étoiles '
            'sans grand détour. Quand ton trajet est prêt, appuie sur « Valider le trajet ».',
        illustration: _OptimalScoreArt(),
        illustrationLabel:
            'Chaque niveau vaut jusqu’à dix points : route optimale quatre, '
            'essais trois, zones coûteuses évitées deux, objectifs atteints un. '
            'Le score du jeu est la moyenne des niveaux.',
      ),
    ],
  );
}

class _OptimalTutorialDiagram extends StatelessWidget {
  const _OptimalTutorialDiagram({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.withNoTextScaling(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(width: 300, height: 270, child: child),
    ),
  );
}

class _StationsTutorialArt extends StatelessWidget {
  const _StationsTutorialArt();

  @override
  Widget build(BuildContext context) => _OptimalTutorialDiagram(
    child: Column(
      children: [
        Text(
          'De station en station',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: CustomPaint(painter: _StationsArt(), size: Size.infinite),
        ),
        const SizedBox(height: 12),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            _MiniLegend(
              color: BoardPalette.startRing,
              label: 'Départ',
              outlined: true,
            ),
            _MiniLegend(color: BoardPalette.finish, label: 'Arrivée'),
            _MiniLegend(color: BoardPalette.blockIcon, label: 'Bloc'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Haut · bas · gauche · droite',
          style: AppTypography.bodyMedium.copyWith(
            color: ZennytGamePalette.ink,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class _OptimalScoreArt extends StatelessWidget {
  const _OptimalScoreArt();

  @override
  Widget build(BuildContext context) => _OptimalTutorialDiagram(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Jusqu’à 10 points par niveau',
          style: AppTypography.titleMedium.copyWith(
            color: ZennytGamePalette.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 22),
        const _ScoringRow(
          icon: HugeIcons.strokeRoundedGps01,
          iconColor: BoardPalette.finish,
          label: 'Route optimale (±10 %)',
          points: '4 pts',
          pointsColor: ZennytGamePalette.ink,
        ),
        const _ScoringRow(
          icon: HugeIcons.strokeRoundedReload,
          iconColor: ZennytGamePalette.cyan,
          label: 'Peu d’essais',
          points: '3 pts',
          pointsColor: ZennytGamePalette.ink,
        ),
        const _ScoringRow(
          icon: HugeIcons.strokeRoundedMinusSignCircle,
          iconColor: BoardPalette.blockIcon,
          label: 'Zones coûteuses évitées',
          points: '2 pts',
          pointsColor: ZennytGamePalette.ink,
        ),
        const _ScoringRow(
          icon: AppIcons.starFilled,
          iconColor: BoardPalette.star,
          label: 'Objectifs atteints',
          points: '1 pt',
          pointsColor: ZennytGamePalette.ink,
        ),
        Text(
          'Score du jeu = moyenne des niveaux',
          style: AppTypography.labelSmall.copyWith(
            color: ZennytGamePalette.ink,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class _ScoringRow extends StatelessWidget {
  const _ScoringRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.points,
    required this.pointsColor,
  });

  final AppIconData icon;
  final Color iconColor;
  final String label;
  final String points;
  final Color pointsColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          AppIcon(icon, color: iconColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: ZennytGamePalette.ink,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            points,
            style: AppTypography.titleMedium.copyWith(
              color: pointsColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLegend extends StatelessWidget {
  const _MiniLegend({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: outlined ? Colors.white : color,
            shape: BoxShape.circle,
            border: outlined ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: ZennytGamePalette.muted,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Même style de stations rondes ; chemin orthogonal conforme au plateau.
class _StationsArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Offset at(int col, int row) => Offset(
      size.width * (0.14 + col * 0.24),
      size.height * (0.18 + row * 0.32),
    );
    final lab = at(0, 2);
    final bend = at(0, 0);
    final star = at(2, 0);
    final mtg = at(3, 0);
    final blocked = at(1, 1);
    final radius = math.min(size.width * 0.065, size.height * 0.13);

    final route = Path()
      ..moveTo(lab.dx, lab.dy)
      ..lineTo(bend.dx, bend.dy)
      ..lineTo(mtg.dx, mtg.dy);
    canvas.drawPath(
      route,
      Paint()
        ..color = BoardPalette.route
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in [at(0, 1), bend, at(1, 0)]) {
      _node(
        canvas,
        point,
        radius,
        fill: BoardPalette.nodeInPath,
        border: BoardPalette.route,
      );
    }
    _node(
      canvas,
      lab,
      radius,
      fill: BoardPalette.start,
      border: BoardPalette.startRing,
      label: 'LAB',
      labelColor: BoardPalette.startRing,
      labelSize: radius * 0.62,
    );
    _node(
      canvas,
      star,
      radius,
      fill: BoardPalette.nodeInPath,
      border: BoardPalette.route,
    );
    _star(canvas, star, radius * 0.65, BoardPalette.star);
    _node(
      canvas,
      mtg,
      radius,
      fill: BoardPalette.finish,
      border: BoardPalette.finish,
      label: 'MTG',
      labelColor: Colors.white,
      labelSize: radius * 0.62,
    );
    _node(
      canvas,
      blocked,
      radius,
      fill: BoardPalette.block,
      border: BoardPalette.blockIcon,
    );
    _bolt(canvas, blocked, radius * 0.65, BoardPalette.blockIcon);
  }

  void _node(
    Canvas canvas,
    Offset c,
    double r, {
    required Color fill,
    required Color border,
    String? label,
    Color labelColor = const Color(0xFF3B4568),
    double labelSize = 9,
  }) {
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: AppTypography.labelMedium.copyWith(
            color: labelColor,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _star(Canvas canvas, Offset c, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final o = Offset(
        c.dx + rad * math.cos(angle),
        c.dy + rad * math.sin(angle),
      );
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _bolt(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx + s * 0.15, c.dy - s)
      ..lineTo(c.dx - s * 0.5, c.dy + s * 0.15)
      ..lineTo(c.dx, c.dy + s * 0.15)
      ..lineTo(c.dx - s * 0.15, c.dy + s)
      ..lineTo(c.dx + s * 0.5, c.dy - s * 0.15)
      ..lineTo(c.dx, c.dy - s * 0.15)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────── Gameplay ───────────────────────────

enum _Feedback { none, correct, wrong }

class _GameplayView extends StatefulWidget {
  const _GameplayView({
    super.key,
    required this.game,
    required this.busy,
    required this.score,
    required this.level,
    required this.totalLevels,
    required this.levelFailed,
    required this.pauseAllowance,
    required this.onCorrect,
    required this.onWrong,
    required this.onExit,
  });

  /// Droit de pause de la session, détenu par l'écran (voir sa déclaration).
  final GamePauseAllowance pauseAllowance;

  final PlanifikGame game;
  final bool busy;
  final int score;
  final int level; // 1-based
  final int totalLevels;
  final bool levelFailed; // niveau scellé en échec (3 essais ratés)
  final VoidCallback onCorrect; // route complète : +250, niveau suivant / fin
  final VoidCallback onWrong; // route incomplète : -2
  final VoidCallback onExit; // quitter la partie (menu pause → Exit)

  @override
  State<_GameplayView> createState() => _GameplayViewState();
}

class _GameplayViewState extends State<_GameplayView> {
  /// Budget de temps d'un niveau, dérivé de sa longueur optimale.
  ///
  /// Le chrono ne comptait que le temps ÉCOULÉ, sans plafond : la barre de
  /// progression du HUD n'avait donc aucun dénominateur temporel et affichait
  /// en réalité l'avancement du tracé (`stepCount / optimalLength`). D'où
  /// « la barre de progression du timer n'est pas fonctionnelle ».
  ///
  /// 12 s par case du chemin optimal laisse largement le temps de réfléchir
  /// puis de tracer (niveaux 9–12 cases → 108–144 s). Le temps n'entre dans
  /// AUCUNE métrique envoyée au serveur ([PlanifikLevelMetrics] n'a pas de
  /// champ de durée) : ce budget ne touche donc pas au barème.
  static const int _secondsPerOptimalStep = 12;
  static const int _minLevelSeconds = 60;

  /// Dernières secondes : barre rouge + tic sonore, comme « Je bouge ».
  static const int _urgentSeconds = 10;

  Timer? _timer;
  late int _secondsLeft = _levelSeconds;
  int _tries = 0;
  bool _paused = false;
  _Feedback _feedback = _Feedback.none;
  String _feedbackText = '';

  int get _levelSeconds => math.max(
    _minLevelSeconds,
    widget.game.optimalLength * _secondsPerOptimalStep,
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      if (_secondsLeft <= 0) return; // 00:00 : _expireLevel a déjà pris la main

      setState(() => _secondsLeft--);

      if (_secondsLeft == 0) {
        _expireLevel();
        return;
      }
      if (_secondsLeft <= _urgentSeconds) {
        SoundService.instance.playSfx(GameSfx.timerDecrease);
      }
    });
  }

  /// Temps écoulé : le niveau est scellé en échec par le MÊME chemin qu'un
  /// 3ᵉ essai raté (`onWrong` → `levelFailed` → métriques d'échec + passage
  /// automatique). Aucune sémantique d'échec nouvelle n'est introduite.
  void _expireLevel() {
    _timer?.cancel();
    SoundService.instance.playSfx(GameSfx.timerEnd);
    // Le temps écoulé EST un échec de niveau — même chemin qu'un 3ᵉ essai raté —
    // et doit donc vibrer comme lui. La vibration est demandée explicitement
    // ici, et non en ajoutant `timerEnd` aux sons d'erreur de SoundService :
    // Move Fast joue le MÊME son à la fin normale de sa session, où une
    // vibration d'échec serait un contresens.
    //
    // Passe par SoundService et non par HapticFeedback : le réglage
    // « Vibration » du menu pause doit continuer de tout couper.
    SoundService.instance.vibrateError();
    if (_feedback != _Feedback.none) return;
    setState(() {
      _feedback = _Feedback.wrong;
      _feedbackText = "Time's up";
      _tries++;
    });
    widget.onWrong();
  }

  /// Bouton unique du HUD : menu de pause tant que la fenêtre est ouverte,
  /// confirmation de sortie ensuite. Voir [GameMenuAffordance].
  Future<void> _openMenu() async {
    if (widget.pauseAllowance.canOpen) return _openPause();
    // Fenêtre consommée : on ne met PAS le jeu en pause. Geler le chronomètre
    // ici rendrait la pause renouvelable à volonté par simple ouverture de la
    // boîte, ce que la fenêtre unique existe pour empêcher.
    if (await GameExitConfirmDialog.show(context)) widget.onExit();
  }

  /// Menu pause (comme Move Fast) : pause le timer, propose Reprendre / Règles /
  /// Quitter, et des options audio.
  Future<void> _openPause() async {
    // Une seule fenêtre de pause par partie (CdC pause §2-3).
    if (!widget.pauseAllowance.canOpen) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    widget.pauseAllowance.open();
    setState(() => _paused = true);
    await _showPauseMenu();
  }

  /// Réaffiché après les règles sur le **temps restant** de la fenêtre.
  Future<void> _showPauseMenu() async {
    final action = await showGamePauseMenu<GamePauseAction>(
      context,
      builder: (context) => GamePauseScaffold(
        countdown: widget.pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(context).pop(GamePauseAction.resume),
        actions: [
          GamePauseMenuAction.resume(
            onPressed: () => Navigator.of(context).pop(GamePauseAction.resume),
          ),
          GamePauseMenuAction.rules(
            onPressed: () => Navigator.of(context).pop(GamePauseAction.help),
          ),
          GamePauseMenuAction.exit(
            onPressed: () => Navigator.of(context).pop(GamePauseAction.exit),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == GamePauseAction.exit) {
      // Quitter annule la tentative : confirmation explicite d'abord.
      if (await GameExitConfirmDialog.show(context)) {
        widget.onExit();
        return;
      }
      if (!mounted) return;
      if (widget.pauseAllowance.canReopen) return _showPauseMenu();
    } else if (action == GamePauseAction.help) {
      await showDialog<void>(
        context: context,
        barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
        builder: (context) => const _OptimalRulesDialog(),
      );
      if (!mounted) return;
      if (widget.pauseAllowance.canReopen) return _showPauseMenu();
    }
    if (!mounted) return;
    // La partie repart : le temps passé en pause rejoint le budget consommé.
    widget.pauseAllowance.close();
    setState(() => _paused = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Part de temps RESTANTE — ce que la barre du HUD doit refléter.
  double get _timeProgress => (_secondsLeft / _levelSeconds).clamp(0.0, 1.0);

  bool get _timeIsUrgent => _secondsLeft <= _urgentSeconds;

  void _validate() {
    // Niveau scellé (échec 3 essais) : plus aucune validation acceptée.
    if (widget.busy || widget.levelFailed || _feedback != _Feedback.none) {
      return;
    }
    final game = widget.game;
    if (game.stepCount < 1) return;

    if (game.isComplete) {
      setState(() {
        _feedback = _Feedback.correct;
        _feedbackText = '+250pts';
        _tries++;
      });
      _timer?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onCorrect();
      });
    } else {
      // Valider un chemin qui n'atteint pas l'arrivée est LA faute principale
      // du jeu, et elle ne produisait ni son ni vibration : seul le clic sur
      // une case interdite en déclenchait. Le son d'erreur porte la vibration
      // (via SoundService), donc le réglage « Vibration » du menu pause reste
      // respecté — un HapticFeedback direct y échapperait.
      SoundService.instance.playSfx(GameSfx.wrongChoice);
      setState(() {
        _feedback = _Feedback.wrong;
        _feedbackText = '-2pts';
        _tries++;
      });
      widget
          .onWrong(); // peut sceller le niveau (3ᵉ échec) → widget.levelFailed
      _timer?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 1300), () {
        // Chemin raté : on efface le feedback ET on réinitialise le trait de
        // trajet au départ pour que le joueur retrace. (Sauf si le niveau vient
        // d'être scellé en échec : il passe alors au niveau suivant.)
        if (mounted && !widget.levelFailed) {
          setState(() => _feedback = _Feedback.none);
          widget.game.clear();
          // Le chrono avait été coupé pour figer le feedback ; il ne repartait
          // jamais, laissant le Timer gelé pour le reste du niveau.
          _startTimer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: game.revision,
            builder: (context, _, _) => _OptimalHud(
              score: widget.score,
              timeLabel: _timeLabel,
              tries: _tries,
              // La barre suit le TEMPS RESTANT (elle se vide), et non plus
              // l'avancement du tracé — c'est bien un « timer bar ».
              progress: _timeProgress,
              progressColor: (_feedback == _Feedback.wrong || _timeIsUrgent)
                  ? ZennytGamePalette.error
                  : ZennytGamePalette.success,
              onPause: _openMenu,
              affordance: widget.pauseAllowance.affordance,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 24,
                    child: widget.levelFailed
                        ? const _FeedbackBanner(
                            correct: false,
                            text: 'Niveau échoué — 3 essais',
                          )
                        : _feedback == _Feedback.none
                        ? null
                        : _FeedbackBanner(
                            correct: _feedback == _Feedback.correct,
                            text: _feedbackText,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(child: GameWidget(game: game)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Niveau ${widget.level}/${widget.totalLevels} — glisse ou touche '
                    'les stations pour tracer le trajet de Leila.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _BoardLegend(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<int>(
            valueListenable: game.revision,
            builder: (context, _, _) => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ClearButton(
                    enabled:
                        game.canUndo && !widget.busy && !widget.levelFailed,
                    onTap: game.clear,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: _ValidateButton(
                    // NE PAS gater sur canValidate/l'arrivée : cela rendrait le
                    // critère "essais" toujours = 1 et casserait le barème.
                    // Valider un chemin incomplet DOIT rester possible (→ essai raté).
                    // (Gate sur levelFailed = niveau scellé après 3 échecs.)
                    enabled:
                        game.stepCount >= 1 &&
                        !widget.busy &&
                        !widget.levelFailed &&
                        _feedback == _Feedback.none,
                    busy: widget.busy,
                    onTap: _validate,
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

/// HUD Optimal Path : pills Score / Timer / Tries + Pause, puis barre de progression.
class _OptimalHud extends StatelessWidget {
  const _OptimalHud({
    required this.score,
    required this.timeLabel,
    required this.tries,
    required this.progress,
    required this.progressColor,
    required this.onPause,
    required this.affordance,
  });

  final int score;
  final String timeLabel;
  final int tries;
  final double progress;
  final Color progressColor;
  final VoidCallback onPause;

  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HudStatPill(label: 'Score', value: '$score'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _HudStatPill(label: 'Temps', value: timeLabel),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              // Plafonné : n'affiche jamais X/3 avec X > 3 (limite dure = 3).
              child: _HudStatPill(
                label: 'Essais',
                value: '${tries > 3 ? 3 : tries}/3',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _HudIconButton(
              icon: affordance.icon,
              tooltip: affordance.tooltip,
              semanticsLabel: affordance.semanticsLabel,
              onTap: onPause,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}

class _HudStatPill extends StatelessWidget {
  const _HudStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.semanticsLabel,
  });

  final AppIconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: AppIcon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          correct ? 'Correct !' : 'Mauvais trajet !',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: TextStyle(
            color: correct
                ? ZennytGamePalette.success
                : ZennytGamePalette.error,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BoardLegend extends StatelessWidget {
  const _BoardLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: 6,
      children: [
        _BoardLegendItem(color: Colors.white, label: 'Départ'),
        _BoardLegendItem(color: Color(0xFF22C55E), label: 'Arrivée'),
        _BoardLegendItem(color: Color(0xFFE8574C), label: 'Bloc'),
        _BoardLegendItem(color: Color(0xFFF5B800), label: 'Étoile', star: true),
        _BoardLegendItem(color: Color(0xFFD12E7D), label: 'Chemin'),
      ],
    );
  }
}

class _BoardLegendItem extends StatelessWidget {
  const _BoardLegendItem({
    required this.color,
    required this.label,
    this.star = false,
  });

  final Color color;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        star
            ? AppIcon(AppIcons.starFilled, color: color, size: 14)
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                HugeIcons.strokeRoundedDelete02,
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Effacer',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                  fontSize: 16,
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

class _ValidateButton extends StatelessWidget {
  const _ValidateButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? ZennytGamePalette.success
          : ZennytGamePalette.success.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: AppSpinner(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(HugeIcons.strokeRoundedTick02, color: Colors.white, size: 22),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Valider le trajet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

// ─────────────────────────── Menu pause (comme Move Fast) ───────────────────────────

/// Dialogue « Règles » d'Optimal Path (ouvert depuis le menu pause).
class _OptimalRulesDialog extends StatelessWidget {
  const _OptimalRulesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ZennytGamePalette.gameBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const AppIcon(
                    HugeIcons.strokeRoundedRoute01,
                    color: ZennytGamePalette.gameBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Comment jouer',
                    style: AppTypography.titleLarge.copyWith(
                      color: ZennytGamePalette.ink,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _RuleLine(
              icon: HugeIcons.strokeRoundedSwipeLeft01,
              text:
                  'Fais glisser ton doigt depuis LAB sur les stations voisines '
                  'pour tracer ton trajet, ou touche-les une par une. Glisse en '
                  'arrière pour effacer le dernier pas.',
            ),
            _RuleLine(
              icon: HugeIcons.strokeRoundedFlag02,
              text: 'Rejoins MTG par le trajet le plus court. Évite les blocs.',
            ),
            _RuleLine(
              icon: AppIcons.starFilled,
              text: 'Passe par les étoiles pour gagner des points bonus.',
            ),
            _RuleLine(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              text: 'Valide quand tu es prêt. Efface pour recommencer le trajet.',
            ),
            const SizedBox(height: AppSpacing.md),
            GamePrimaryButton(
              label: 'Compris',
              icon: HugeIcons.strokeRoundedTick02,
              color: ZennytGamePalette.gameBlue,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});

  final AppIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: ZennytGamePalette.gameBlue, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Score ───────────────────────────

class _ScoreView extends StatelessWidget {
  const _ScoreView({
    required this.session,
    required this.metrics,
    required this.onReplay,
    required this.onCompare,
    required this.onNext,
    required this.onBack,
  });

  final GameSession? session;
  final PlanifikMetrics? metrics;
  final VoidCallback onReplay;
  final VoidCallback onCompare;
  final VoidCallback onNext; // termine le jeu → retour au hub des jeux
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final attempt = session?.lastAttempt;
    final routeEfficiency = metrics == null
        ? 0
        : ((metrics!.optimalLength /
                      math.max(metrics!.pathLength, metrics!.optimalLength)) *
                  100)
              .round();
    final delta = metrics == null
        ? 0
        : metrics!.pathLength - metrics!.optimalLength;

    return GameResultsTemplate(
      onBack: onBack,
      gameName: 'Path Mind',
      pending: attempt == null,
      scoreLabel: 'Score cognitif',
      scorePercent: attempt?.score.normalized.round(),
      points: attempt?.score.rawPoints,
      maxPoints: attempt?.score.maxPoints,
      stats: [
        GameResultStat(
          label: 'Efficacité',
          value: '$routeEfficiency%',
          color: ZennytGamePalette.success,
        ),
        GameResultStat(
          label: 'Trajet',
          value: metrics == null ? '—' : '${metrics!.pathLength}',
        ),
        GameResultStat(
          label: 'Écart',
          value: metrics == null
              ? '—'
              : delta <= 0
              ? 'Optimal'
              : '+$delta',
          color: delta <= 0
              ? ZennytGamePalette.success
              : ZennytGamePalette.magenta,
        ),
      ],
      // Le détail de la formule de calcul du score (points par critère,
      // « ±10 % », « /4 »…) a été retiré du tableau de score sur retour
      // client : le joueur voit son résultat et l'analyse, pas le barème.
      insight: metrics == null
          ? null
          : 'Trajet de ${metrics!.pathLength} pas pour un optimum de '
                '${metrics!.optimalLength}. Le joueur planifie un trajet sous '
                'contraintes, arbitre les objectifs facultatifs et compare le '
                'chemin choisi au trajet optimal.',
      // « Finish » faisait doublon avec le retour, qui ramène déjà au hub.
      primaryLabel: 'Rejouer',
      onPrimary: onReplay,
      secondaryLabel: 'Comparer',
      onSecondary: onCompare,
    );
  }
}

// ─────────────────────────── Comparison ───────────────────────────

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({
    required this.session,
    required this.metrics,
    required this.optimalLength,
    required this.onReplay,
    required this.onBack,
  });

  final GameSession? session;
  final PlanifikMetrics? metrics;
  final int optimalLength;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final steps = m?.pathLength ?? 0;
    final delta = steps - optimalLength;
    final rank = delta <= 0 ? '#1' : '#${math.min(99, 12 + delta)}';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareIconButton(icon: HugeIcons.strokeRoundedArrowLeft01, onTap: onBack),
          Center(
            child: Column(
              children: [
                Text(
                  'Résultats comparatifs',
                  style: AppTypography.headlineLarge.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Référence : trajet optimal',
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
                    'par rapport au trajet optimal',
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
              ResultStatTile(
                label: 'Ton trajet',
                value: '$steps',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Optimal',
                value: '$optimalLength',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Différence',
                value: delta <= 0 ? 'Optimal' : '+$delta pas',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Niveau',
                value: session?.lastAttempt?.score.level ?? '—',
                valueColor: ZennytGamePalette.blue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Évolution des performances',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  (m?.costlyZonesAvoided ?? true)
                      ? 'Le trajet a évité les zones coûteuses et est resté proche de la solution optimale.'
                      : 'Le trajet a atteint l’arrivée mais a traversé une zone coûteuse. Rejoue pour améliorer ta référence.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                const _EvolutionTrack(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePrimaryButton(
            label: 'Rejouer pour améliorer ton classement',
            onPressed: onReplay,
          ),
        ],
      ),
    );
  }
}

class _EvolutionTrack extends StatelessWidget {
  const _EvolutionTrack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: CustomPaint(
        painter: _EvolutionTrackPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EvolutionTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = ZennytGamePalette.border
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = ZennytGamePalette.magenta
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), base);
    canvas.drawLine(Offset(0, y), Offset(size.width * 0.78, y), active);
    for (final x in [size.width * 0.16, size.width * 0.44]) {
      canvas.drawCircle(Offset(x, y), 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(x, y),
        9,
        Paint()
          ..color = ZennytGamePalette.magenta
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.78, y),
      14,
      Paint()..color = ZennytGamePalette.magenta,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
