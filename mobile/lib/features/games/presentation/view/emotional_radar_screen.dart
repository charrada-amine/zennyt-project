import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/sound_service.dart';
import '../../domain/config/emotional_radar_v2_config.dart';
import '../../domain/entities/emotional_radar_v2.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/repositories/emotional_radar_v2_repository.dart';
import '../emotional_regulation_session_provider.dart';
import '../games_providers.dart';
import '../widgets/emotional_game_pause_dialog.dart';
import '../widgets/game_system_components.dart';
import '../widgets/emotional_radar_components.dart';
import 'emotional_radar_v2_gameplay.dart';

/// Étapes du parcours : Cover → Tutorial → Gameplay → Feedback → … → Results.
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

/// Écran d'« Emotional Radar » — parcours v2 (référentiel Cowen & Keltner).
///
/// Le serveur est l'unique autorité : il tire la scène, choisit les
/// distracteurs selon la distance sémantique visée, tient le budget de réponse,
/// corrige, fait monter ou descendre le niveau et produit le rapport final.
/// L'écran ne calcule aucun score et ne conserve aucune clé de correction :
/// il l'apprend dans la réponse HTTP, après coup.
///
/// ⚠️ En phase A, ce parcours **ne soumet aucun résultat**. Le serveur refuse
/// une session déjà marquée par le parcours v1 (`rejectLegacyAttempt`), et il
/// s'interdit lui-même d'enregistrer une tentative tant que les stimuli sont
/// des placeholders — sinon un score non normé remonterait dans Recruitment.
class EmotionalRadarScreen extends ConsumerStatefulWidget {
  const EmotionalRadarScreen({super.key});

  @override
  ConsumerState<EmotionalRadarScreen> createState() =>
      _EmotionalRadarScreenState();
}

class _EmotionalRadarScreenState extends ConsumerState<EmotionalRadarScreen> {
  _Stage _stage = _Stage.cover;

  GameSession? _session;
  EmotionalRadarV2State? _radar;
  String? _errorMessage;

  // Sélection de la scène courante.
  String? _emotionKey;
  EmotionalRadarV2Intensity? _intensity;
  bool _validating = false;
  EmotionalRadarV2Feedback? _feedback;

  /// Budget de réponse restant, en millisecondes.
  ///
  /// Simple reflet de l'horloge serveur — le serveur date la scène à sa
  /// création et recalcule l'écoulé à la réponse. Ce compteur n'arrête donc
  /// rien : il ne fait qu'afficher ce qui est déjà décidé ailleurs.
  int _remainingMs = 0;
  Timer? _budgetTicker;

  /// Route plein écran en cours, pour pouvoir la refermer d'autorité quand le
  /// budget de réponse expire : rester en plein écran après l'échéance
  /// laisserait le joueur regarder une vidéo qu'il ne peut plus utiliser.
  ModalRoute<void>? _fullscreenRoute;

  // Options de la carte Pause.
  bool _buttonsInput = true;

  EmotionalRadarV2Scene? get _scene => _radar?.currentScene;

  int get _totalScenes => _radar?.totalScenes ?? EmotionalRadarV2Config.totalScenes;

  /// Numéro affiché : la scène en cours est la suivante de celles répondues.
  int get _sceneNumber {
    final radar = _radar;
    if (radar == null) return 1;
    final order = radar.currentScene?.sceneOrder ?? radar.answeredScenes;
    return order.clamp(1, _totalScenes);
  }

  int get _currentLevel =>
      _radar?.currentLevel ?? EmotionalRadarV2Config.startingLevel;

  bool get _reducedMotion =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (_session?.runtime.modifierBool(
            'reducedMotionDefault',
            fallback:
                _session?.runtime.settingBool(
                  'reducedMotionDefault',
                  fallback: false,
                ) ??
                false,
          ) ??
          false);

  bool get _helpEnabled =>
      _session?.runtime.settingBool('helpEnabled', fallback: true) ?? true;

  bool get _feedbackEnabled =>
      _session?.runtime.modifierBool('answerFeedback', fallback: true) ?? true;

  int get _transitionDurationMs =>
      _session?.runtime.modifierInt(
        'transitionDurationMs',
        fallback: 900,
        minimum: 0,
        maximum: 5000,
      ) ??
      900;

  EmotionalRadarV2Repository get _radarRepo =>
      ref.read(gamesRepositoryProvider) as EmotionalRadarV2Repository;

  // ── Cycle de jeu ──────────────────────────────────────────────────────────

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  /// Orientations du jeu hors plein écran.
  ///
  /// Tout l'écran est dessiné en portrait — grille de 6 ou 9 propositions et
  /// échelle d'intensité. Le plein écran est la seule exception, et il doit
  /// rendre le portrait en sortant.
  static const List<DeviceOrientation> _portrait = [DeviceOrientation.portraitUp];

  @override
  void initState() {
    super.initState();
    // Le verrou est posé ici et levé dans [dispose] : il ne dépasse donc pas
    // l'écran du jeu. L'app n'imposait aucune orientation avant, et elle n'en
    // imposera aucune après.
    unawaited(SystemChrome.setPreferredOrientations(_portrait));
  }

  @override
  void dispose() {
    _budgetTicker?.cancel();
    // Liste vide = aucune préférence : on rend la main aux orientations
    // déclarées dans Info.plist, comme avant l'entrée dans le jeu.
    unawaited(SystemChrome.setPreferredOrientations(const []));
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    super.dispose();
  }

  Future<void> _startGame() async {
    _pauseAllowance.reset();
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

      // Une seule opération d'activation : c'est elle qui démarre le budget
      // serveur de la scène. On ne la déclenche donc jamais à l'avance.
      final state = await _radarRepo.activateNextEmotionalRadarV2Scene(
        session.id,
      );

      if (!mounted) return;
      setState(() {
        _session = session;
        _radar = state;
        _stage = _Stage.gameplay;
      });
      _beginScene();
    } catch (error) {
      _failWith(error);
    }
  }

  void _beginScene() {
    final scene = _scene;
    setState(() {
      _emotionKey = null;
      _intensity = null;
      _feedback = null;
      _remainingMs = scene?.remainingResponseTimeMs ?? 0;
    });
    _startBudgetTicker();
  }

  void _startBudgetTicker() {
    _budgetTicker?.cancel();
    if (_remainingMs <= 0) return;
    const tick = Duration(milliseconds: 100);
    _budgetTicker = Timer.periodic(tick, (timer) {
      if (!mounted) return timer.cancel();
      final next = _remainingMs - tick.inMilliseconds;
      setState(() => _remainingMs = next <= 0 ? 0 : next);
      if (next <= 0) {
        timer.cancel();
        _closeFullscreenIfOpen();
      }
    });
  }

  Future<void> _validate() async {
    final session = _session;
    final scene = _scene;
    final emotionKey = _emotionKey;
    final intensity = _intensity;
    if (session == null || scene == null || emotionKey == null ||
        intensity == null) {
      return;
    }

    setState(() => _validating = true);

    try {
      // La correction est faite SERVEUR : l'écran n'apprend l'émotion attendue
      // qu'ici, dans la réponse HTTP.
      final result = await _radarRepo.answerEmotionalRadarV2Scene(
        sessionId: session.id,
        sceneOrder: scene.sceneOrder,
        selectedEmotionKey: emotionKey,
        selectedIntensity: intensity,
        // Champ conservé au contrat, vide : la troisième question a été retirée
        // de l'écran à la demande du client. Le garder permet de rétablir la
        // mesure sans migration si elle revient.
        explanation: '',
      );

      if (!mounted) return;
      _budgetTicker?.cancel();
      final showFeedback = _feedbackEnabled;
      setState(() {
        _feedback = result.feedback;
        _radar = result.state;
        _validating = false;
        _stage = showFeedback ? _Stage.feedback : _Stage.gameplay;
      });
      if (!showFeedback) await _nextScene();
    } catch (error) {
      if (!mounted) return;
      setState(() => _validating = false);
      _failWith(error);
    }
  }

  Future<void> _nextScene() async {
    final session = _session;
    final radar = _radar;
    if (session == null || radar == null) return;

    if (radar.completed) {
      // Le rapport arrive avec le dernier état : rien à soumettre, rien à
      // recalculer côté client.
      setState(() => _stage = _Stage.results);
      return;
    }

    setState(() => _stage = _Stage.transition);
    if (!_reducedMotion) {
      await Future<void>.delayed(Duration(milliseconds: _transitionDurationMs));
    }
    if (!mounted) return;

    try {
      // Activation tardive, volontaire : le budget de la scène ne doit pas
      // s'écouler pendant la transition ni derrière la carte de feedback.
      final state = await _radarRepo.activateNextEmotionalRadarV2Scene(
        session.id,
      );
      if (!mounted) return;
      setState(() {
        _radar = state;
        _stage = _Stage.gameplay;
      });
      _beginScene();
    } catch (error) {
      _failWith(error);
    }
  }

  void _failWith(Object error) {
    if (!mounted) return;
    _budgetTicker?.cancel();
    setState(() {
      _errorMessage = '$error';
      _stage = _Stage.error;
    });
  }

  // ── Overlays ──────────────────────────────────────────────────────────────

  /// Bouton unique du bandeau : menu de pause tant que la fenêtre est ouverte,
  /// confirmation de sortie ensuite. Voir [GameMenuAffordance].
  int _videoOverlayDepth = 0;

  Future<void> _withVideoPaused(Future<void> Function() action) async {
    setState(() => _videoOverlayDepth++);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _videoOverlayDepth--);
    }
  }

  Future<void> _openMenu() => _withVideoPaused(_showMenu);

  Future<void> _showMenu() async {
    if (_pauseAllowance.canOpen) return _openPause();
    if (await GameExitConfirmDialog.show(context)) {
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  /// [reopen] : réaffichage interne (retour de l'aide, sortie annulée) sur le
  /// temps restant d'une fenêtre déjà ouverte.
  Future<void> _openPause({bool reopen = false}) =>
      _withVideoPaused(() => _showPause(reopen: reopen));

  Future<void> _showPause({bool reopen = false}) async {
    if (!reopen) {
      // Une seule fenêtre de pause par partie (CdC pause §2-3).
      if (!_pauseAllowance.canOpen) return;
      _pauseAllowance.open();
    }
    final action = await showDialog<EmotionalGamePauseAction>(
      context: context,
      barrierColor: const Color(0xCC1B1B4B),
      builder: (dialogCtx) => EmotionalGamePauseDialog(
        buttonsInput: _buttonsInput,
        onInputMode: (buttons) => setState(() => _buttonsInput = buttons),
        showRules: _helpEnabled,
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(dialogCtx).pop(EmotionalGamePauseAction.resume),
      ),
    );
    if (!mounted) return;
    if (action == EmotionalGamePauseAction.rules) {
      await _openHelp();
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _openPause(reopen: true);
    } else if (action == EmotionalGamePauseAction.exit) {
      // Quitter annule la tentative : confirmation explicite d'abord.
      if (await GameExitConfirmDialog.show(context)) {
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _openPause(reopen: true);
    }
    _pauseAllowance.close();
    if (mounted) setState(() {});
  }

  Future<void> _openHelp() => _withVideoPaused(_showHelp);

  Future<void> _showHelp() async {
    if (!_helpEnabled) return;
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC1B1B4B),
      builder: (context) => const _HelpDialog(),
    );
  }

  Future<void> _openFullscreen() => _withVideoPaused(_showFullscreen);

  Future<void> _showFullscreen() async {
    final scene = _scene;
    if (scene == null) return;

    // Le plein écran bascule en paysage : les stimuli sont filmés en 16:9, et
    // en portrait la vidéo n'occupe qu'une bande au milieu de l'écran.
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Barres système masquées : un lecteur plein écran ne laisse pas l'heure
    // et la batterie par-dessus l'image.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // La bascule d'orientation est asynchrone : l'écran a pu être quitté
    // pendant ce temps. On rend alors la main aux orientations d'origine
    // plutôt que de laisser l'app bloquée en paysage.
    if (!mounted) {
      await _leaveFullscreenChrome();
      return;
    }

    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RadarFullscreenSceneView(
        scene: scene,
        sceneNumber: _sceneNumber,
        totalScenes: _totalScenes,
      ),
    );
    _fullscreenRoute = route;
    try {
      await Navigator.of(context).push(route);
    } finally {
      _fullscreenRoute = null;
      await _leaveFullscreenChrome();
    }
  }

  /// Rend le portrait et les barres système en quittant le plein écran.
  ///
  /// Regroupé pour que les deux sorties — fermeture normale et abandon parce
  /// que l'écran a été quitté pendant la bascule — restaurent exactement la
  /// même chose. Une liste d'orientations vide ne suffisait pas : sans
  /// préférence, iOS n'a aucune raison de repivoter, et le jeu restait couché.
  Future<void> _leaveFullscreenChrome() async {
    await SystemChrome.setPreferredOrientations(_portrait);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Referme le plein écran quand le budget de réponse est épuisé.
  void _closeFullscreenIfOpen() {
    if (!mounted) return;
    final route = _fullscreenRoute;
    // `isCurrent` évite de fermer autre chose : si une boîte de dialogue s'est
    // ouverte par-dessus, ce n'est plus notre route qui est au sommet.
    if (route == null || !route.isCurrent) return;
    Navigator.of(context).pop();
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
      _Stage.gameplay => GameplayMusic(child: _buildGameplay()),
      _Stage.feedback => _buildFeedback(),
      _Stage.results => _ResultsView(
        report: _radar?.report,
        scoringProvisional: _radar?.scoringProvisional ?? true,
        mediaLibraryReady: _radar?.mediaLibraryReady ?? false,
        onReplay: _startGame,
      ),
      _Stage.error => _ErrorView(message: _errorMessage, onRetry: _startGame),
    };
  }

  /// Coquille commune du gameplay : « Scene n / N », niveau, aide, barre.
  Widget _buildShell({required Widget child}) {
    return _GameScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scene $_sceneNumber / $_totalScenes',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_helpEnabled) ...[
                _HelpPill(onTap: _openHelp),
                const SizedBox(width: 6),
              ],
              // La pause est une action explicite et étiquetée : la planche
              // d'accessibilité interdit un contrôle uniquement iconique.
              Semantics(
                button: true,
                label: _pauseAllowance.affordance.semanticsLabel,
                child: IconButton(
                  onPressed: _openMenu,
                  icon: Icon(
                    _pauseAllowance.affordance.icon,
                    color: Colors.white,
                  ),
                  tooltip: _pauseAllowance.affordance.tooltip,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ProgressBar(value: _sceneNumber / _totalScenes),
          const SizedBox(height: 12),
          // Aucun score courant affiché : le référentiel n'en définit aucun en
          // cours de partie, et le rapport /10 n'existe qu'à la fin. Le niveau,
          // lui, change en jeu — c'est la seule information de progression qui
          // ait un sens ici.
          RadarLevelBanner(
            level: _currentLevel,
            choicesCount:
                _scene?.choicesCount ??
                EmotionalRadarV2Config.choicesForLevel(_currentLevel),
          ),
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
    if (scene == null) {
      return const _GameScaffold(child: _CenteredSpinner());
    }
    return _buildShell(
      child: Column(
        children: [
          RadarSceneStage(
            scene: scene,
            remainingMs: _remainingMs,
            onOpenFullscreen: _openFullscreen,
            playbackEnabled: _videoOverlayDepth == 0,
          ),
          const SizedBox(height: 14),
          RadarAnswerPanel(
            scene: scene,
            selectedEmotionKey: _emotionKey,
            selectedIntensity: _intensity,
            validating: _validating,
            onSelectEmotion: (key) => setState(() => _emotionKey = key),
            onSelectIntensity: (value) => setState(() => _intensity = value),
            onValidate: _validate,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    final feedback = _feedback;
    final radar = _radar;
    if (feedback == null || radar == null) {
      return const _GameScaffold(child: _CenteredSpinner());
    }
    return _buildShell(
      child: Column(
        children: [
          RadarFeedbackCard(
            feedback: feedback,
            selectedEmotionKey: _emotionKey!,
            selectedIntensity: _intensity!,
          ),
          const SizedBox(height: 18),
          _MagentaButton(
            label: radar.completed ? 'See my results' : 'Next scene',
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
        child: GameContentFrame(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
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
          // Pastille « ? Help » : c'est un bouton de règles, il doit cliquer
          // comme les autres (elle passait à côté du son car elle n'utilise pas
          // les boutons partagés).
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
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
        // Porte « Start tutorial », « Start game », « Play again »… : même clic
        // que les boutons partagés, dont il ne reprend que le style magenta.
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
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
        // Porte « View rules » sur la cover : même clic que les boutons
        // partagés, dont ce bouton reprend seulement le style clair.
        onPressed: () {
          SoundService.instance.playSfx(GameSfx.buttonClick);
          onPressed();
        },
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
                'Watch each scene, name the dominant emotion among the '
                'options, then rate how strong it is.',
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
              Text(
                // Le nombre suit la liste : l'écrire en dur l'avait laissé à
                // « Five » après le retrait de la justification, en
                // contradiction avec les quatre étapes affichées juste en
                // dessous.
                '${emotionalRadarSteps.length} calm steps. '
                'You can review them at any time.',
                style: const TextStyle(
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
              onPressed: () {
                SoundService.instance.playSfx(GameSfx.buttonClick);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Rapport de fin de session, tel que le serveur le renvoie.
///
/// Les deux axes de difficulté du référentiel sont restitués séparément —
/// `accuracy_by_choice_count` et `accuracy_by_semantic_distance` — parce que
/// c'est précisément ce que la séparation des niveaux 3 et 4 sert à mesurer :
/// savoir si le joueur bute sur le nombre de propositions ou sur la finesse de
/// discrimination.
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.report,
    required this.scoringProvisional,
    required this.mediaLibraryReady,
    required this.onReplay,
  });

  final EmotionalRadarV2Report? report;
  final bool scoringProvisional;
  final bool mediaLibraryReady;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final data = report;
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
                data == null
                    ? 'Session interrompue'
                    : '${data.totalScenes} scènes · niveau '
                          '${data.startingLevel} → ${data.finalLevel}',
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              if (data == null)
                const _RadarResultCard(
                  child: Text(
                    'Aucun rapport disponible pour cette session.',
                    style: TextStyle(
                      fontSize: 15,
                      color: EmotionalRadarPalette.muted,
                    ),
                  ),
                )
              else ...[
                _RadarScoreCard(report: data),
                const SizedBox(height: 14),
                _RadarResultCard(
                  title: 'Reconnaissance',
                  child: Column(
                    children: [
                      _RadarStatRow(
                        label: 'Émotions correctes',
                        value:
                            '${data.correctEmotions} / ${data.totalScenes}'
                            '  (${data.emotionAccuracyPercent.round()} %)',
                      ),
                      _RadarStatRow(
                        label: 'Intensité juste',
                        value: '${data.intensityMatchPercent.round()} %',
                      ),
                      _RadarStatRow(
                        label: 'Temps de réponse moyen',
                        value:
                            '${(data.averageResponseTimeMs / 1000).toStringAsFixed(1)} s',
                      ),
                      _RadarStatRow(
                        label: 'Réponses impulsives',
                        value: '${data.impulsiveResponsesPercent.round()} %',
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Charge cognitive isolée : 6 propositions contre 9.
                if (data.accuracyByChoiceCount.isNotEmpty)
                  _RadarResultCard(
                    title: 'Selon le nombre de propositions',
                    child: Column(
                      children: [
                        for (final entry
                            in data.accuracyByChoiceCount.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key)))
                          _RadarStatRow(
                            label: '${entry.key} propositions',
                            value: '${entry.value.round()} %',
                            last:
                                entry.key ==
                                data.accuracyByChoiceCount.keys.reduce(
                                  (a, b) => a > b ? a : b,
                                ),
                          ),
                      ],
                    ),
                  ),
                if (data.semanticDistanceScoringAvailable &&
                    data.accuracyBySemanticDistance.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _RadarResultCard(
                    title: 'Selon la finesse de discrimination',
                    child: Column(
                      children: [
                        for (final entry
                            in data.accuracyBySemanticDistance.entries.toList())
                          _RadarStatRow(
                            label: _distanceLabel(entry.key),
                            value: '${entry.value.round()} %',
                            last:
                                entry.key ==
                                data.accuracyBySemanticDistance.keys.last,
                          ),
                      ],
                    ),
                  ),
                ],
                if (scoringProvisional || !mediaLibraryReady) ...[
                  const SizedBox(height: 14),
                  _RadarProvisionalNotice(
                    mediaLibraryReady: mediaLibraryReady,
                  ),
                ],
              ],
              const SizedBox(height: 22),
              _MagentaButton(label: 'Play again', onPressed: onReplay),
              const SizedBox(height: 12),
              _WhiteOutlineButton(
                label: 'Back to games',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Les clés viennent du serveur (`HIGH`/`MEDIUM`/`LOW`) : on les traduit du
  /// point de vue du joueur, où une distance élevée est le cas FACILE.
  static String _distanceLabel(String key) => switch (key.toUpperCase()) {
    'HIGH' => 'Émotions bien distinctes',
    'MEDIUM' => 'Émotions assez proches',
    'LOW' => 'Émotions très proches',
    _ => key,
  };
}

class _RadarScoreCard extends StatelessWidget {
  const _RadarScoreCard({required this.report});

  final EmotionalRadarV2Report report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'Score de reconnaissance émotionnelle',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: EmotionalRadarPalette.muted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${report.radarEmotionScore} / 10',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: EmotionalRadarPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: EmotionalRadarPalette.selectTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Niveau émotionnel : ${report.emotionalLevel}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EmotionalRadarPalette.selectBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarResultCard extends StatelessWidget {
  const _RadarResultCard({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            Text(
              heading,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: EmotionalRadarPalette.ink,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _RadarStatRow extends StatelessWidget {
  const _RadarStatRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: EmotionalRadarPalette.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: EmotionalRadarPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avertissement affiché tant que le jeu n'est pas normé.
///
/// Le référentiel conditionne l'usage des scores à un norming par panel
/// indépendant (Kappa ≥ 0,70). Tant que le serveur annonce
/// `scoringProvisional`, le rapport se lit comme un entraînement, pas comme une
/// mesure — et le taire serait laisser croire l'inverse.
class _RadarProvisionalNotice extends StatelessWidget {
  const _RadarProvisionalNotice({required this.mediaLibraryReady});

  final bool mediaLibraryReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mediaLibraryReady
                  ? 'Score provisoire : le barème n\'est pas encore normé.'
                  : 'Score provisoire : la bibliothèque vidéo n\'est pas '
                        'complète et le barème n\'est pas encore normé. '
                        'À lire comme un entraînement.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Colors.white70,
              ),
            ),
          ),
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
                onPressed: () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  Navigator.of(context).maybePop();
                },
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
