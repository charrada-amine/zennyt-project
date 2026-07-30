import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/config/emotional_radar_config.dart';
import '../../domain/entities/emotional_radar.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../emotional_regulation_session_provider.dart';
import '../games_providers.dart';
import '../widgets/emotional_game_pause_dialog.dart';
import '../widgets/emotional_radar_components.dart';
import 'emotional_radar_gameplay.dart';

/// Étapes du parcours, calquées sur « Prototype logic » (Developer handoff) :
/// Cover → Tutorial → Gameplay → Feedback → Transition → … → Results.
enum _Stage {
  cover,
  tutorial,
  loading,
  gameplay,
  feedback,
  transition,
  results,
  error,
}

/// Écran complet d'« Emotional Radar » (régulation émotionnelle, « Je gère »).
///
/// Le contenu des scènes (texte, image, vidéo) vient du **backend** : c'est le
/// premier jeu du module dont le matériel n'est pas embarqué dans l'app.
///
/// ⚠️ Le score n'est jamais calculé ici. L'écran envoie chaque réponse au serveur,
/// qui la note et renvoie la correction ; à la fin, il ne soumet que des mesures
/// comportementales (temps, aide, plein écran).
class EmotionalRadarScreen extends ConsumerStatefulWidget {
  const EmotionalRadarScreen({super.key});

  @override
  ConsumerState<EmotionalRadarScreen> createState() =>
      _EmotionalRadarScreenState();
}

class _EmotionalRadarScreenState extends ConsumerState<EmotionalRadarScreen> {
  _Stage _stage = _Stage.cover;

  GameSession? _session;
  EmotionalRadarSceneSet? _sceneSet;
  int _sceneIndex = 0;
  int _score = 0;
  String? _errorMessage;

  // Sélection de la scène courante.
  BasicEmotion? _emotion;
  EmotionalNuance? _nuance;
  int? _intensity;
  bool _validating = false;
  EmotionalRadarFeedback? _feedback;

  // Mesures comportementales (les seules données envoyées à la fin).
  final List<EmotionalRadarSceneMetric> _metrics = [];
  DateTime? _sceneStartedAt;
  bool _helpOpenedThisScene = false;
  bool _fullscreenOpenedThisScene = false;

  // Options de la carte Pause.
  bool _soundEffects = true;
  bool _music = false;
  bool _buttonsInput = true;

  EmotionalRadarScene? get _scene {
    final set = _sceneSet;
    if (set == null || _sceneIndex >= set.scenes.length) return null;
    return set.scenes[_sceneIndex];
  }

  int get _totalScenes =>
      _sceneSet?.totalScenes ?? EmotionalRadarConfig.pointsPerScene;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  // ── Cycle de jeu ──────────────────────────────────────────────────────────

  Future<void> _startGame() async {
    setState(() {
      _stage = _Stage.loading;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(gamesRepositoryProvider);
      final sharedSession = ref
          .read(emotionalRegulationSessionProvider.notifier)
          .reusableFor(MiniGame.emotionalRadarCore);
      final session =
          sharedSession ??
          await repo.startSession(GameType.emotionalRegulation);
      ref.read(emotionalRegulationSessionProvider.notifier).keep(session);
      final sceneSet = await repo.emotionalRadarScenes(session.id);

      if (!mounted) return;
      setState(() {
        _session = session;
        _sceneSet = sceneSet;
        _sceneIndex = 0;
        _score = 0;
        _metrics.clear();
        _stage = _Stage.gameplay;
      });
      _beginScene();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = '$error';
      });
    }
  }

  void _beginScene() {
    setState(() {
      _emotion = null;
      _nuance = null;
      _intensity = null;
      _feedback = null;
      _helpOpenedThisScene = false;
      _fullscreenOpenedThisScene = false;
      _sceneStartedAt = DateTime.now();
    });
  }

  Future<void> _validate() async {
    final session = _session;
    final scene = _scene;
    final emotion = _emotion;
    final nuance = _nuance;
    final intensity = _intensity;
    if (session == null ||
        scene == null ||
        emotion == null ||
        nuance == null ||
        intensity == null) {
      return;
    }

    setState(() => _validating = true);

    try {
      // La correction est faite SERVEUR : l'écran ne connaît la réponse
      // attendue qu'à cet instant, dans la réponse HTTP.
      final feedback = await ref
          .read(gamesRepositoryProvider)
          .answerEmotionalRadarScene(
            sessionId: session.id,
            sceneId: scene.id,
            emotion: emotion,
            nuanceKey: nuance.key,
            intensity: intensity,
          );

      _metrics.add(
        EmotionalRadarSceneMetric(
          sceneId: scene.id,
          responseTimeMs: _sceneStartedAt == null
              ? 0
              : DateTime.now().difference(_sceneStartedAt!).inMilliseconds,
          helpOpened: _helpOpenedThisScene,
          fullscreenOpened: _fullscreenOpenedThisScene,
          reducedMotion: _reducedMotion,
        ),
      );

      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        // Le score est mis à jour DÈS la validation : la maquette claire le
        // laissait à 0 sur la carte de feedback alors que la planche sombre
        // l'incrémentait (9 → 18). C'est cette dernière qui est cohérente.
        _score = feedback.totalPoints;
        _validating = false;
        _stage = _Stage.feedback;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _validating = false;
        _errorMessage = '$error';
        _stage = _Stage.error;
      });
    }
  }

  Future<void> _nextScene() async {
    final set = _sceneSet;
    if (set == null) return;

    final isLast = _sceneIndex >= set.scenes.length - 1;
    if (isLast) {
      await _finish();
      return;
    }

    setState(() {
      _sceneIndex += 1;
      _stage = _Stage.transition;
    });

    // Transition courte (200–300 ms de la maquette ; ici un temps de lecture),
    // supprimée en mouvement réduit.
    if (!_reducedMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.gameplay);
    _beginScene();
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;

    setState(() => _stage = _Stage.loading);
    try {
      // Ne remonte QUE des mesures comportementales : le score est reconstruit
      // serveur depuis les réponses déjà notées (AGENTS.md §7.4).
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.emotionalRadarCore,
            metrics: EmotionalRadarMetrics(scenes: List.of(_metrics)),
          );
      if (!mounted) return;
      ref.read(emotionalRegulationSessionProvider.notifier).keep(updated);
      setState(() {
        _session = updated;
        _stage = _Stage.results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _stage = _Stage.error;
      });
    }
  }

  // ── Overlays ──────────────────────────────────────────────────────────────

  Future<void> _openPause() async {
    final action = await showDialog<EmotionalGamePauseAction>(
      context: context,
      barrierColor: const Color(0xCC1B1B4B),
      builder: (context) => EmotionalGamePauseDialog(
        soundEffects: _soundEffects,
        music: _music,
        buttonsInput: _buttonsInput,
        onSoundEffects: (v) => setState(() => _soundEffects = v),
        onMusic: (v) => setState(() => _music = v),
        onInputMode: (buttons) => setState(() => _buttonsInput = buttons),
      ),
    );
    if (action == EmotionalGamePauseAction.rules) {
      await _openHelp();
    } else if (action == EmotionalGamePauseAction.exit && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _openHelp() async {
    setState(() => _helpOpenedThisScene = true);
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC1B1B4B),
      builder: (context) => const _HelpDialog(),
    );
  }

  Future<void> _openFullscreen() async {
    final scene = _scene;
    if (scene == null) return;
    setState(() => _fullscreenOpenedThisScene = true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenSceneView(
          scene: scene,
          sceneNumber: _sceneIndex + 1,
          totalScenes: _totalScenes,
        ),
      ),
    );
  }

  // ── Rendu ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.cover => _CoverView(
        onStart: () => setState(() => _stage = _Stage.tutorial),
        onViewRules: () => setState(() => _stage = _Stage.tutorial),
      ),
      _Stage.tutorial => _TutorialView(
        onStart: _startGame,
        onBack: () => setState(() => _stage = _Stage.cover),
      ),
      _Stage.loading => const _GameScaffold(child: _CenteredSpinner()),
      _Stage.transition => _buildShell(child: const _PreparingCard()),
      _Stage.gameplay => _buildGameplay(),
      _Stage.feedback => _buildFeedback(),
      _Stage.results => _ResultsView(
        session: _session,
        scenesPlayed: _metrics.length,
        onReplay: _startGame,
      ),
      _Stage.error => _ErrorView(message: _errorMessage, onRetry: _startGame),
    };
  }

  /// Coquille commune du gameplay : en-tête « Scene n / N », score, aide, barre.
  Widget _buildShell({required Widget child}) {
    final sceneNumber = (_sceneIndex + 1).clamp(1, _totalScenes);
    return _GameScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scene $sceneNumber / $_totalScenes',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Score $_score',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              _HelpPill(onTap: _openHelp),
              const SizedBox(width: 6),
              // La pause est une action explicite et étiquetée : la planche
              // d'accessibilité interdit un contrôle uniquement iconique.
              IconButton(
                onPressed: _openPause,
                icon: const Icon(
                  Icons.pause_circle_outline,
                  color: Colors.white,
                ),
                tooltip: 'Pause',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ProgressBar(value: sceneNumber / _totalScenes),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameplay() {
    final scene = _scene;
    final set = _sceneSet;
    if (scene == null || set == null) {
      return const _GameScaffold(child: _CenteredSpinner());
    }
    return _buildShell(
      child: Column(
        children: [
          SceneCard(scene: scene, onOpenFullscreen: _openFullscreen),
          const SizedBox(height: 14),
          AnswerPanel(
            sceneSet: set,
            selectedEmotion: _emotion,
            selectedNuance: _nuance,
            selectedIntensity: _intensity,
            validating: _validating,
            onSelectEmotion: (e) => setState(() {
              _emotion = e;
              // Changer de famille invalide la nuance et l'intensité :
              // une nuance n'a de sens que dans sa famille.
              _nuance = null;
              _intensity = null;
            }),
            onSelectNuance: (n) => setState(() {
              _nuance = n;
              _intensity = null;
            }),
            onSelectIntensity: (i) => setState(() => _intensity = i),
            onValidate: _validate,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final scene = _scene;
    final feedback = _feedback;
    if (scene == null || feedback == null) {
      return const _GameScaffold(child: _CenteredSpinner());
    }
    final isLast = _sceneIndex >= (_sceneSet?.scenes.length ?? 1) - 1;
    return _buildShell(
      child: Column(
        children: [
          SceneCard(scene: scene, onOpenFullscreen: _openFullscreen),
          const SizedBox(height: 14),
          FeedbackCard(
            feedback: feedback,
            selectedEmotion: _emotion!,
            selectedNuance: _nuance!,
            selectedIntensity: _intensity!,
          ),
          const SizedBox(height: 18),
          _MagentaButton(
            // « Next scene » partout : la planche sombre disait « Continue ».
            label: isLast ? 'See my results' : 'Next scene',
            onPressed: _nextScene,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Coquilles et petits composants d'écran
// ══════════════════════════════════════════════════════════════════════════

class _GameScaffold extends StatelessWidget {
  const _GameScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmotionalRadarPalette.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Colors.white));
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress',
      value: '${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation(
            EmotionalRadarPalette.magenta,
          ),
        ),
      ),
    );
  }
}

class _HelpPill extends StatelessWidget {
  const _HelpPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Help',
      child: Material(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Text(
              '? Help',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MagentaButton extends StatelessWidget {
  const _MagentaButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: EmotionalRadarPalette.magenta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _WhiteOutlineButton extends StatelessWidget {
  const _WhiteOutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: EmotionalRadarPalette.ink,
          side: const BorderSide(color: EmotionalRadarPalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Écran de transition « Preparing next scene… ».
class _PreparingCard extends StatelessWidget {
  const _PreparingCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: EmotionalRadarPalette.selectTint,
                shape: BoxShape.circle,
                border: Border.all(color: EmotionalRadarPalette.selectBlue),
              ),
              alignment: Alignment.center,
              child: const Text(
                '…',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: EmotionalRadarPalette.selectBlue,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Preparing next scene...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: EmotionalRadarPalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep the same method: observe, label, refine, then rate intensity.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: EmotionalRadarPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Cover & tutoriel (fond blanc, hors gameplay)
// ══════════════════════════════════════════════════════════════════════════

/// Écran de couverture : carte hero violette, pitch, « View rules » / « Start ».
class _CoverView extends StatelessWidget {
  const _CoverView({required this.onStart, required this.onViewRules});

  final VoidCallback onStart;
  final VoidCallback onViewRules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackSquareButton(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 20),
              const _CoverHero(),
              const SizedBox(height: 22),
              const Text(
                'Emotional Radar',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: EmotionalRadarPalette.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Recognize emotions in real situations.',
                style: TextStyle(
                  fontSize: 19,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: EmotionalRadarPalette.magenta,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Observe each scene, identify the basic emotion, choose the '
                'nuance, then rate its intensity.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: EmotionalRadarPalette.muted,
                ),
              ),
              const SizedBox(height: 28),
              _WhiteOutlineButton(label: 'View rules', onPressed: onViewRules),
              const SizedBox(height: 14),
              _MagentaButton(label: 'Start tutorial', onPressed: onStart),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte hero de la couverture (bandeau violet + illustration radar).
class _CoverHero extends StatelessWidget {
  const _CoverHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 16, 26),
      decoration: BoxDecoration(
        color: EmotionalRadarPalette.canvas,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Emotional management',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 26),
                Text(
                  'Emotional\nRadar',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Logo officiel ; tant que l'asset n'est pas exporté, on retombe sur
          // l'illustration de la catégorie plutôt que d'afficher une zone vide.
          Image.asset(
            'assets/games icons/Emotional Radar.png',
            width: 108,
            height: 108,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Image.asset(
              'assets/games icons/Emotional Regulation .png',
              width: 108,
              height: 108,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.favorite, size: 72, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran « Rules and tutorial » : les cinq étapes numérotées.
class _TutorialView extends StatelessWidget {
  const _TutorialView({required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackSquareButton(onTap: onBack),
              const SizedBox(height: 22),
              const Text(
                'Rules and tutorial',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: EmotionalRadarPalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A calm five-step flow. You can review it at any time.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: EmotionalRadarPalette.muted,
                ),
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < emotionalRadarSteps.length; i++) ...[
                _StepCard(index: i + 1, label: emotionalRadarSteps[i]),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 14),
              _MagentaButton(label: 'Start game', onPressed: onStart),
              const SizedBox(height: 14),
              _WhiteOutlineButton(label: 'Back to game', onPressed: onBack),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    // La première pastille est magenta sur la maquette, les suivantes violettes.
    final color = index == 1
        ? EmotionalRadarPalette.magenta
        : EmotionalRadarPalette.canvas;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EmotionalRadarPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EmotionalRadarPalette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackSquareButton extends StatelessWidget {
  const _BackSquareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EmotionalRadarPalette.border),
            ),
            child: const Icon(
              Icons.chevron_left,
              color: EmotionalRadarPalette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Overlays : pause, aide, plein écran
// ══════════════════════════════════════════════════════════════════════════

/// Aide en pause : rappel des cinq étapes, sans pénalité.
class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need a reminder?',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: EmotionalRadarPalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There is no penalty for reading the instructions again.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: EmotionalRadarPalette.muted,
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < emotionalRadarSteps.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? EmotionalRadarPalette.magenta
                          : EmotionalRadarPalette.selectTint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == 0
                            ? Colors.white
                            : EmotionalRadarPalette.selectBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      emotionalRadarSteps[i],
                      style: const TextStyle(
                        fontSize: 15,
                        color: EmotionalRadarPalette.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            _MagentaButton(
              label: 'Resume game',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vue plein écran d'une scène image (écran « 13C »).
class _FullscreenSceneView extends StatelessWidget {
  const _FullscreenSceneView({
    required this.scene,
    required this.sceneNumber,
    required this.totalScenes,
  });

  final EmotionalRadarScene scene;
  final int sceneNumber;
  final int totalScenes;

  @override
  Widget build(BuildContext context) {
    final url = scene.mediaUrl;
    return Scaffold(
      backgroundColor: EmotionalRadarPalette.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scene $sceneNumber / $totalScenes',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'Full screen',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    button: true,
                    label: 'Close full screen',
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141338),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Image full screen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: url == null
                              ? Container(
                                  color: const Color(0xFF23224F),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: Colors.white54,
                                  ),
                                )
                              : InteractiveViewer(
                                  maxScale: 4,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF23224F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          scene.altText ?? scene.instructionText,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Close full screen anytime.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Résultats & erreur
// ══════════════════════════════════════════════════════════════════════════

/// Résultats : score serveur + détail du score (panneau « d'où viennent mes points »).
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.session,
    required this.scenesPlayed,
    required this.onReplay,
  });

  final GameSession? session;
  final int scenesPlayed;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final attempt = session?.attempts
        .where((a) => a.miniGame == MiniGame.emotionalRadarCore)
        .lastOrNull;
    final score = attempt?.score;

    return Scaffold(
      backgroundColor: EmotionalRadarPalette.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Results',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$scenesPlayed scenes completed',
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Emotional recognition score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: EmotionalRadarPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      score == null
                          ? '—'
                          : '${score.rawPoints} / ${score.maxPoints}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: EmotionalRadarPalette.ink,
                      ),
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        score.level,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: EmotionalRadarPalette.magenta,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Le détail vient du serveur : le client n'en recalcule aucune ligne.
              if (session?.scoreBreakdown.isNotEmpty ?? false)
                _BreakdownPanel(lines: session!.scoreBreakdown),
              const SizedBox(height: 22),
              _MagentaButton(label: 'Play again', onPressed: onReplay),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text(
                    'Back to games',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({required this.lines});

  final List<dynamic> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B4B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score detail',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${line.label}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (line.detail != null)
                          Text(
                            '${line.detail}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (line.points != null)
                    Text(
                      '${line.points}/${line.maxPoints}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmotionalRadarPalette.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: Colors.white70),
              const SizedBox(height: 18),
              const Text(
                'The scenes could not be loaded',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message ?? 'Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 26),
              _MagentaButton(label: 'Try again', onPressed: onRetry),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Back to games',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
