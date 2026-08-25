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
import '../flame/grid_config.dart';
import '../flame/planifik_game.dart';
import '../games_controller.dart';
import '../widgets/game_system_components.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _beginGame() async {
    setState(() {
      _levelConfigs = GridConfig.randomLevels();
      _level = 0;
      _score = 0;
      _levelCellFaults = 0;
      _game = PlanifikGame(
        config: _levelConfigs[_level],
        onWrongCell: _onWrongCell,
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

  /// Clic sur une case interdite (rouge) : vibration d'erreur + pénalité
  /// incrémentale (le jeu dessine puis efface le faux segment de son côté).
  void _onWrongCell() {
    // La vibration est déclenchée par SoundService avec le son d'erreur : un
    // appel direct à HapticFeedback ici échapperait au réglage « Vibration »
    // du menu pause.
    SoundService.instance.playSfx(GameSfx.wrongChoice);
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
      _PlanifikStage.howToPlay => _HowToPlayView(
        onBack: () => setState(() => _stage = _PlanifikStage.intro),
        onDone: _beginGame,
      ),
      _PlanifikStage.gameplay => GameplayMusic(child: _GameplayView(
        key: ValueKey(_level),
        game: _game,
        busy: _busy,
        score: _score,
        level: _level + 1,
        totalLevels: _levelConfigs.length,
        levelFailed: _levelFailed,
        onCorrect: _onCorrectRoute,
        onWrong: _onWrongRoute,
        onExit: () => context.go(AppRoutes.games),
      )),
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

// ─────────────────────────── Intro (Path Mind hero) ───────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  // Ombre douce commune aux cartes (spec : ombre très douce, diffusion large).
  static const List<BoxShadow> _softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
          ),
          const SizedBox(height: 20), // header → hero
          // Hero card « Path Mind » (violet plein #4F46E5).
          LayoutBuilder(
            builder: (context, constraints) {
              final heroHeight = math.max(340.0, constraints.maxWidth * 0.9);
              return Container(
                height: heroHeight,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: const Color(0xFF4F46E5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x334F46E5),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -78,
                      top: 0,
                      bottom: 0,
                      width: constraints.maxWidth * 0.86,
                      child: CustomPaint(painter: _PathMindHeroBackground()),
                    ),
                    Positioned(
                      right: 10,
                      top: 38,
                      bottom: 34,
                      width: constraints.maxWidth * 0.48,
                      child: CustomPaint(painter: _PathMindArt()),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Spatial Planning',
                            style: AppTypography.labelMedium.copyWith(
                              color: ZennytGamePalette.blue,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Text(
                          'Path\nMind',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Connect the optimal\npath. Be strategic.',
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.28,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18), // hero → stats
          // Ligne meta : 3 cartes blanches sur fond gris.
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3FB),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: _softShadow,
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _MetaCell(label: 'Goal', value: 'Planning'),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaCell(
                    label: 'Duration',
                    value: '15 min',
                    valueColor: ZennytGamePalette.magenta,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaCell(label: 'Format', value: 'Mobile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // stats → description
          // Carte « Simple rule » (bordure bleu périwinkle discrète + ombre douce).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: const Color(0xFF9FB4EF)),
              boxShadow: _softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simple rule',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Leila needs to reach the meeting room from her lab. '
                  'Draw the shortest path, avoid construction zones, '
                  'and collect documents along the way.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: ZennytGamePalette.muted,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22), // description → bouton
          _StartButton(onPressed: onStart),
        ],
      ),
    );
  }
}

/// CTA « Start » — capsule magenta (coins totalement arrondis), texte gras centré.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ZennytGamePalette.magenta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: AppTypography.buttonLarge.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: const Text('Start'),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.label,
    required this.value,
    this.valueColor = ZennytGamePalette.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFE4E9F5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cercles décoratifs de fond de la carte hero.
class _PathMindHeroBackground extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final purple = Paint()
      ..color = const Color(0xFF6B5CF6).withValues(alpha: 0.28);
    final pink = Paint()
      ..color = const Color(0xFFE85B9A).withValues(alpha: 0.10);
    final cyan = Paint()
      ..color = const Color(0xFF4FC3E8).withValues(alpha: 0.06);

    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.50),
      size.width * 0.43,
      purple,
    );
    canvas.drawCircle(
      Offset(size.width * 1.18, size.height * 0.36),
      size.width * 0.24,
      pink,
    );
    canvas.drawCircle(
      Offset(size.width * 1.00, size.height * 0.82),
      size.width * 0.25,
      cyan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Illustration de la carte hero : grille 3×3 avec chemin magenta,
/// case départ (blanche) et arrivée (verte).
class _PathMindArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Positions de la grille 3×3 (plus grande, remplit la zone).
    Offset node(int col, int row) => Offset(
      size.width * (0.16 + col * 0.34),
      size.height * (0.18 + row * 0.32),
    );

    final path = <Offset>[
      node(0, 0),
      node(1, 0),
      node(1, 1),
      node(2, 1),
      node(2, 2),
    ];

    // Ligne du chemin (magenta).
    final line = Paint()
      ..color = const Color(0xFFD12E7D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final p = Path()..moveTo(path.first.dx, path.first.dy);
    for (final o in path.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(p, line);

    // Tous les nœuds (gris clair).
    final dot = Paint()..color = const Color(0xFFDDDDF0);
    for (var c = 0; c < 3; c++) {
      for (var r = 0; r < 3; r++) {
        canvas.drawCircle(node(c, r), size.width * 0.085, dot);
      }
    }
    // Départ : cercle blanc + anneau rose (comme le logo Figma).
    canvas.drawCircle(
      node(0, 0),
      size.width * 0.105,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      node(0, 0),
      size.width * 0.105,
      Paint()
        ..color = const Color(0xFFD12E7D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03,
    );
    // Arrivée (vert).
    canvas.drawCircle(
      node(2, 2),
      size.width * 0.10,
      Paint()..color = const Color(0xFF22C55E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
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
          child: Icon(icon, color: ZennytGamePalette.ink, size: 24),
        ),
      ),
    );
  }
}

// ─────────────────────────── How To Play (tutorial) ───────────────────────────

class _HowToPlayView extends StatefulWidget {
  const _HowToPlayView({required this.onBack, required this.onDone});

  final VoidCallback onBack;
  final VoidCallback onDone;

  @override
  State<_HowToPlayView> createState() => _HowToPlayViewState();
}

class _HowToPlayViewState extends State<_HowToPlayView> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _pages = 2;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back() {
    if (_index > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      widget.onBack();
    }
  }

  void _next() {
    if (_index < _pages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              _SquareIconButton(icon: Icons.chevron_left, onTap: _back),
              const SizedBox(width: AppSpacing.md),
              Text(
                'How To Play',
                style: AppTypography.displaySmall.copyWith(
                  color: ZennytGamePalette.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: const [_HowToPlayPage1(), _HowToPlayPage2()],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TrailingArrowButton(label: 'Next', onPressed: _next),
        ],
      ),
    );
  }
}

/// Bouton primaire magenta avec la flèche **après** le texte (« Next → »),
/// conforme à la maquette Figma.
class _TrailingArrowButton extends StatelessWidget {
  const _TrailingArrowButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ZennytGamePalette.magenta,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: AppTypography.buttonLarge.copyWith(letterSpacing: 0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.arrow_forward_rounded, size: AppSpacing.iconMd),
        ],
      ),
    );
  }
}

class _HowToPlayPage1 extends StatelessWidget {
  const _HowToPlayPage1();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FD),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              children: [
                Text(
                  'Connect the Stations',
                  style: AppTypography.titleLarge.copyWith(
                    color: ZennytGamePalette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: CustomPaint(painter: _StationsArt()),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Touch the stations to trace the lines',
                  style: AppTypography.bodySmall.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  children: const [
                    _MiniLegend(
                      color: Color(0xFF9AA4C7),
                      label: 'Start',
                      outlined: true,
                    ),
                    _MiniLegend(color: Color(0xFF22C55E), label: 'End'),
                    _MiniLegend(color: Color(0xFFEF5B5B), label: 'Blocked'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Find the optimal route',
            style: AppTypography.titleLarge.copyWith(
              color: ZennytGamePalette.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Leila starts at the Lab (green) and needs to reach the Meeting '
            'Room (pink). Tap stations to trace your path — each segment costs '
            '1 move. Avoid red zones (under construction) to save moves. '
            'You can only move right and left, up and down.',
            style: AppTypography.bodyMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToPlayPage2 extends StatelessWidget {
  const _HowToPlayPage2();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FD),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              children: [
                Text(
                  'Scoring Breakdown',
                  style: AppTypography.titleLarge.copyWith(
                    color: ZennytGamePalette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Barème réel : chaque niveau est noté /10 (miroir backend),
                // puis moyenné sur les 4 niveaux → /100.
                const _ScoringRow(
                  icon: Icons.gps_fixed_rounded,
                  iconColor: Color(0xFF22C55E),
                  label: 'Optimal route (within 10%)',
                  points: '+4 pts',
                  pointsColor: Color(0xFF22C55E),
                ),
                const _ScoringRow(
                  icon: Icons.replay_rounded,
                  iconColor: Color(0xFF00A9D6),
                  label: 'Attempts (1st / 2nd / 3rd)',
                  points: '+3 / +2 / +1',
                  pointsColor: Color(0xFF00A9D6),
                ),
                const _ScoringRow(
                  icon: Icons.do_not_disturb_rounded,
                  iconColor: Color(0xFFEF5B5B),
                  label: 'Costly zones avoided',
                  points: '+2 pts',
                  pointsColor: ZennytGamePalette.magenta,
                ),
                const _ScoringRow(
                  icon: Icons.star_rounded,
                  iconColor: Color(0xFFF5B800),
                  label: 'Documents collected',
                  points: '+1 pt',
                  pointsColor: Color(0xFFF5B800),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Collect files, earn bonus points',
            style: AppTypography.titleLarge.copyWith(
              color: ZennytGamePalette.ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yellow star stations hold Leila\'s documents — collecting them '
            'earns bonus points. Plan your route to grab them without going '
            'too far out of your way. Fewer moves = higher score!',
            style: AppTypography.bodyMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoringRow extends StatelessWidget {
  const _ScoringRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.points,
    required this.pointsColor,
  });

  final IconData icon;
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
          Icon(icon, color: iconColor, size: 24),
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

/// Illustration des stations (page 1) : LAB → A → étoile → MTG, avec un nœud
/// bloqué (éclair). Lignes en pointillés, style « calm » de la charte.
class _StationsArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);

    final lab = at(0.14, 0.60);
    final a = at(0.44, 0.30);
    final star = at(0.66, 0.55);
    final mtg = at(0.87, 0.42);
    final blocked = at(0.44, 0.80);

    _dashedLine(canvas, lab, a);
    _dashedLine(canvas, a, star);
    _dashedLine(canvas, star, mtg);

    final radius = size.height * 0.155;

    _node(
      canvas,
      lab,
      radius,
      fill: Colors.white,
      border: const Color(0xFF6C8CF5),
      label: 'LAB',
    );
    _node(
      canvas,
      a,
      radius,
      fill: const Color(0xFF6C8CF5),
      border: const Color(0xFF6C8CF5),
      label: 'A',
      labelColor: Colors.white,
    );
    // Station étoile (documents).
    _node(
      canvas,
      star,
      radius,
      fill: const Color(0xFFF9D9E7),
      border: ZennytGamePalette.magenta,
    );
    _star(canvas, star, radius * 0.62, const Color(0xFFF5B800));
    // Arrivée MTG.
    _node(
      canvas,
      mtg,
      radius,
      fill: const Color(0xFF22C55E),
      border: const Color(0xFF22C55E),
      label: 'MTG',
      labelColor: Colors.white,
      labelSize: 8,
    );
    // Nœud bloqué (éclair).
    _node(
      canvas,
      blocked,
      radius,
      fill: const Color(0xFFFBE0E0),
      border: const Color(0xFFEF5B5B),
    );
    _bolt(canvas, blocked, radius * 0.7, const Color(0xFFEF5B5B));
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b) {
    final paint = Paint()
      ..color = const Color(0xFF8FB0E6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dash = 6.0, gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final p1 = a + dir * d;
      final p2 = a + dir * (d + dash).clamp(0, total).toDouble();
      canvas.drawLine(p1, p2, paint);
      d += dash + gap;
    }
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
          style: TextStyle(
            color: labelColor,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
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
    required this.onCorrect,
    required this.onWrong,
    required this.onExit,
  });

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
    if (_feedback != _Feedback.none) return;
    setState(() {
      _feedback = _Feedback.wrong;
      _feedbackText = "Time's up";
      _tries++;
    });
    widget.onWrong();
  }

  /// Menu pause (comme Move Fast) : pause le timer, propose Reprendre / Règles /
  /// Quitter, et des options audio.
  Future<void> _openPause() async {
    SoundService.instance.playSfx(GameSfx.pauseClick);
    setState(() => _paused = true);
    final action = await showDialog<GamePauseAction>(
      context: context,
      barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
      builder: (context) => GamePauseScaffold(
        buttons: [
          GamePrimaryButton(
            label: 'Resume',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.resume),
          ),
          GameOutlineButton(
            label: 'View rules / Help',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.help),
          ),
          GamePauseExitButton(
            label: 'Exit mission',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.exit),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == GamePauseAction.exit) {
      widget.onExit();
      return;
    }
    if (action == GamePauseAction.help) {
      await showDialog<void>(
        context: context,
        barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
        builder: (context) => const _OptimalRulesDialog(),
      );
    }
    if (!mounted) return;
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
  double get _timeProgress =>
      (_secondsLeft / _levelSeconds).clamp(0.0, 1.0);

  bool get _timeIsUrgent => _secondsLeft <= _urgentSeconds;

  void _validate() {
    // Niveau scellé (échec 3 essais) : plus aucune validation acceptée.
    if (widget.busy || widget.levelFailed || _feedback != _Feedback.none) return;
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
      widget.onWrong(); // peut sceller le niveau (3ᵉ échec) → widget.levelFailed
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
              progressColor:
                  (_feedback == _Feedback.wrong || _timeIsUrgent)
                  ? ZennytGamePalette.error
                  : ZennytGamePalette.success,
              onPause: _openPause,
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
                    'Level ${widget.level}/${widget.totalLevels} — tap stations '
                    'to trace Leila\'s route.',
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
                    enabled: game.canUndo && !widget.busy && !widget.levelFailed,
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
  });

  final int score;
  final String timeLabel;
  final int tries;
  final double progress;
  final Color progressColor;
  final VoidCallback onPause;

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
              child: _HudStatPill(label: 'Timer', value: timeLabel),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              // Plafonné : n'affiche jamais X/3 avec X > 3 (limite dure = 3).
              child: _HudStatPill(label: 'Tries', value: '${tries > 3 ? 3 : tries}/3'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _HudIconButton(icon: Icons.pause_rounded, onTap: onPause),
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
  const _HudIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 24),
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
          correct ? 'Correct!' : 'Wrong route!',
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
        _BoardLegendItem(color: Colors.white, label: 'Start'),
        _BoardLegendItem(color: Color(0xFF22C55E), label: 'Goal'),
        _BoardLegendItem(color: Color(0xFFE8574C), label: 'Block'),
        _BoardLegendItem(color: Color(0xFFF5B800), label: 'Star', star: true),
        _BoardLegendItem(color: Color(0xFFD12E7D), label: 'Path'),
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
            ? Icon(Icons.star_rounded, color: color, size: 14)
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
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Clear',
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Validate route',
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
                  child: const Icon(
                    Icons.route_rounded,
                    color: ZennytGamePalette.gameBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'How to play',
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
              icon: Icons.touch_app_rounded,
              text: 'Tap adjacent stations from LAB to trace your route.',
            ),
            _RuleLine(
              icon: Icons.flag_rounded,
              text: 'Reach MTG with the shortest route. Avoid the blocks.',
            ),
            _RuleLine(
              icon: Icons.star_rounded,
              text: 'Grab star stations for bonus points.',
            ),
            _RuleLine(
              icon: Icons.check_circle_rounded,
              text: 'Validate when ready. Clear to restart the route.',
            ),
            const SizedBox(height: AppSpacing.md),
            GamePrimaryButton(
              label: 'Got it',
              icon: Icons.check_rounded,
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

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ZennytGamePalette.gameBlue, size: 22),
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
    final scorePercent = attempt?.score.normalized.round() ?? 0;
    final rawScore = attempt?.score.rawPoints;
    final routeEfficiency = metrics == null
        ? 0
        : ((metrics!.optimalLength /
                      math.max(metrics!.pathLength, metrics!.optimalLength)) *
                  100)
              .round();
    final delta = metrics == null
        ? 0
        : metrics!.pathLength - metrics!.optimalLength;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
          ),
          Text(
            'Results',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          Text(
            attempt == null ? 'Synchronizing score...' : 'Path Mind completed',
            style: AppTypography.bodyMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
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
            child: Column(
              children: [
                Text(
                  'Cognitive score',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                AnimatedCountText(
                  value: scorePercent,
                  suffix: '%',
                  onCompleted: SoundService.instance.stopScoreboard,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 56,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  rawScore == null
                      ? 'Planning score is being calculated.'
                      : '$rawScore points calculated by the server.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: ResultStatTile(
                  label: 'Efficiency',
                  value: '$routeEfficiency%',
                  valueColor: ZennytGamePalette.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Route',
                  value: metrics == null ? '—' : '${metrics!.pathLength}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Delta',
                  value: metrics == null
                      ? '—'
                      : delta <= 0
                      ? 'Optimal'
                      : '+$delta',
                  valueColor: delta <= 0
                      ? ZennytGamePalette.success
                      : ZennytGamePalette.magenta,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary insight',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'The player plans a route under constraints, balances optional objectives, and compares the chosen path with the optimal graph route.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          // Le détail de la formule de calcul du score (points par critère,
          // « ±10 % », « /4 »…) a été retiré du tableau de score sur retour
          // client : le joueur voit son résultat et l'analyse, pas le barème.
          // Le calcul reste entier côté serveur (ScoreBreakdownService).
          const SizedBox(height: AppSpacing.xxl),
          // Jeu individuel : bouton terminal qui referme Optimal Path.
          GamePrimaryButton(label: 'Finish', onPressed: onNext),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GameOutlineButton(label: 'Replay', onPressed: onReplay),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: GameOutlineButton(
                  label: 'Compare',
                  onPressed: onCompare,
                ),
              ),
            ],
          ),
        ],
      ),
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
          _SquareIconButton(icon: Icons.chevron_left, onTap: onBack),
          Center(
            child: Column(
              children: [
                Text(
                  'Comparative Results',
                  style: AppTypography.headlineLarge.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  'Optimal route benchmark',
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
                    'against the optimal planning route',
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
                label: 'Your route',
                value: '$steps',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Optimal',
                value: '$optimalLength',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Difference',
                value: delta <= 0 ? 'Optimal' : '+$delta steps',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Level',
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
                  'Performance evolution',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  (m?.costlyZonesAvoided ?? true)
                      ? 'The route avoided costly zones and stayed close to the optimal graph solution.'
                      : 'The route reached the goal, but crossed a costly zone. Replay to improve the benchmark.',
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
            label: 'Replay to improve ranking',
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
