import 'dart:async';
import 'dart:math' as math;

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
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';
import '../widgets/emotional_radar_components.dart';
import '../widgets/emotional_radar_tutorial.dart';
import '../widgets/zennyt_loader.dart';
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

  /// Scène qui vient d'être corrigée. Le serveur ne la renvoie plus comme
  /// scène courante après la réponse, or la correction s'affiche SOUS sa
  /// vidéo, à la place des propositions.
  EmotionalRadarV2Scene? _answeredScene;

  /// Budget de réponse restant, en millisecondes.
  ///
  /// Simple reflet de l'horloge serveur — le serveur date la scène à sa
  /// création et recalcule l'écoulé à la réponse. Ce compteur n'arrête donc
  /// rien : il ne fait qu'afficher ce qui est déjà décidé ailleurs.
  ///
  /// Observable : la route plein écran n'est pas reconstruite par cet écran,
  /// elle écoute directement cette valeur pour garder sa barre synchronisée.
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0);
  int get _remainingMs => _remaining.value;
  Timer? _budgetTicker;

  /// Route plein écran en cours, pour pouvoir la refermer d'autorité quand le
  /// budget de réponse expire : rester en plein écran après l'échéance
  /// laisserait le joueur regarder une vidéo qu'il ne peut plus utiliser.
  ModalRoute<void>? _fullscreenRoute;

  // Options de la carte Pause.
  bool _buttonsInput = true;

  EmotionalRadarV2Scene? get _scene => _radar?.currentScene;

  int get _totalScenes =>
      _radar?.totalScenes ?? EmotionalRadarV2Config.totalScenes;

  /// Numéro affiché : la scène en cours est la suivante de celles répondues.
  int get _sceneNumber {
    final radar = _radar;
    if (radar == null) return 1;
    final order = radar.currentScene?.sceneOrder ?? radar.answeredScenes;
    return order.clamp(1, _totalScenes);
  }

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
  static const List<DeviceOrientation> _portrait = [
    DeviceOrientation.portraitUp,
  ];

  /// Orientations autorisées en plein écran : portrait ET paysage.
  static const List<DeviceOrientation> _fullscreenOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

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
    _remaining.dispose();
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
      _remaining.value = scene?.remainingResponseTimeMs ?? 0;
    });
    _startBudgetTicker();
  }

  void _startBudgetTicker() {
    _budgetTicker?.cancel();
    if (_remainingMs <= 0) return;
    const tick = Duration(milliseconds: 100);
    _budgetTicker = Timer.periodic(tick, (timer) {
      if (!mounted) return timer.cancel();
      final previous = _remainingMs;
      final next = previous - tick.inMilliseconds;
      setState(() => _remaining.value = next <= 0 ? 0 : next);
      _playCountdownSfx(previous, _remainingMs);
      if (next <= 0) {
        timer.cancel();
        _closeFullscreenIfOpen();
      }
    });
  }

  /// Décompte sonore des [kRadarCountdownSfxSeconds] dernières secondes.
  ///
  /// Joué au passage de chaque seconde entière — au moment exact où la barre
  /// du haut franchit 5, 4, 3, 2, 1 — puis le son de fin à 0. Muet pendant le
  /// menu pause, qui joue déjà son propre décompte.
  void _playCountdownSfx(int previousMs, int nextMs) {
    final before = (previousMs / 1000).ceil();
    final after = (nextMs / 1000).ceil();
    if (after == before || _pauseAllowance.isPaused) return;
    if (after == 0) {
      SoundService.instance.playSfx(GameSfx.timerEnd);
    } else if (after <= kRadarCountdownSfxSeconds) {
      SoundService.instance.playSfx(GameSfx.timerDecrease);
    }
  }

  Future<void> _validate() async {
    final session = _session;
    final scene = _scene;
    final emotionKey = _emotionKey;
    final intensity = _intensity;
    if (session == null ||
        scene == null ||
        emotionKey == null ||
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
      SoundService.instance.playSfx(
        result.feedback.correct ? GameSfx.correctChoice : GameSfx.wrongChoice,
      );
      final showFeedback = _feedbackEnabled;
      setState(() {
        _answeredScene = scene;
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
    // Double appui sur « Next scene » pendant la préparation : ignoré.
    if (_stage == _Stage.transition) return;
    final session = _session;
    final radar = _radar;
    if (session == null || radar == null) return;

    if (radar.completed) {
      // Le rapport arrive avec le dernier état : rien à soumettre, rien à
      // recalculer côté client.
      setState(() => _stage = _Stage.results);
      SoundService.instance.playScoreboard();
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

  Future<void> _openMenu() {
    // Même son que les autres jeux : « pause » à l'ouverture du menu, clic
    // générique quand le bouton ne propose plus que la sortie.
    SoundService.instance.playSfx(
      _pauseAllowance.canOpen ? GameSfx.pauseClick : GameSfx.buttonClick,
    );
    return _withVideoPaused(_showMenu);
  }

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
    final action = await showGamePauseMenu<EmotionalGamePauseAction>(
      context,
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
    final scene = _stage == _Stage.feedback ? _answeredScene : _scene;
    if (scene == null) return;

    // Le plein écran suit l'orientation du téléphone : il n'impose plus le
    // paysage. On se contente d'AUTORISER la rotation ; tant que le joueur
    // tient son téléphone droit, la vidéo reste en portrait, centrée.
    await SystemChrome.setPreferredOrientations(_fullscreenOrientations);
    // Barres système masquées : un lecteur plein écran ne laisse pas l'heure
    // et la batterie par-dessus l'image.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // La bascule d'orientation est asynchrone : l'écran a pu être quitté
    // pendant ce temps. On rend alors la main aux orientations d'origine
    // plutôt que de laisser l'app tournée.
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
        remainingMs: _remaining,
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
      ),
      _Stage.tutorial => _TutorialView(
        onStart: _startGame,
        onBack: () => setState(() => _stage = _Stage.cover),
      ),
      _Stage.loading => const _GameScaffold(child: _CenteredSpinner()),
      // Jeu et correction partagent un seul plateau : des arbres de widgets
      // distincts faisaient clignoter TOUTE la page (en-tête reconstruit,
      // vidéo rechargée). Seule la zone du bas change, en fondu.
      _Stage.gameplay || _Stage.feedback => GameplayMusic(child: _buildBoard()),
      // « Preparing next scene… » reste une page à part entière, comme dans la
      // version validée. [GameplayMusic] à la même place de l'arbre : la
      // musique continue sans repartir du début.
      _Stage.transition => GameplayMusic(
        child: _buildShell(
          child: const GameFitToScreen(child: _PreparingCard()),
        ),
      ),
      _Stage.results => EmotionalRadarResultsView(
        report: _radar?.report,
        scoringProvisional: _radar?.scoringProvisional ?? true,
        mediaLibraryReady: _radar?.mediaLibraryReady ?? false,
        onReplay: _startGame,
      ),
      _Stage.error => _ErrorView(message: _errorMessage, onRetry: _startGame),
    };
  }

  /// Coquille commune du gameplay : « Scene n / N », aide, pause, puis la
  /// barre du temps restant.
  ///
  /// Le bandeau « Niveau n · 6 propositions » a été retiré : il ne figure pas
  /// dans la maquette Figma validée. Le compteur de scènes reste, mais il est
  /// désormais indépendant de la barre, qui suit le temps de la scène.
  Widget _buildShell({required Widget child}) {
    return _GameScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 6),
          RadarTimeBar(
            remainingMs: _remainingMs,
            totalMs:
                _scene?.maxResponseTimeMs ??
                EmotionalRadarV2Config.maxResponseTimeMs,
          ),
          const SizedBox(height: 12),
          // Aucun défilement : le contenu reçoit exactement la hauteur
          // restante et s'y ajuste.
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Hauteur du bouton « Next scene » et des deux espacements qui l'entourent.
  static const double _feedbackButtonBlock = 56 + 10 + 10;

  /// Plateau persistant d'une scène : jeu puis correction.
  ///
  /// La structure ne change jamais entre ces étapes — même en-tête, même cadre
  /// vidéo à la même place — pour que Flutter conserve les widgets au lieu de
  /// les recréer. Seule la zone du bas passe, en fondu, des propositions à la
  /// correction.
  Widget _buildBoard() {
    final scene = _stage == _Stage.gameplay
        ? (_scene ?? _answeredScene)
        : _answeredScene;
    if (scene == null) {
      return const _GameScaffold(child: _CenteredSpinner());
    }
    final answering = _stage == _Stage.gameplay;
    final motion = _reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return _buildShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget bottom;
          if (answering) {
            bottom = RadarAnswerPanel(
              key: ValueKey('answer-${scene.sceneOrder}'),
              scene: scene,
              scale: RadarAnswerPanel.scaleFor(
                budget: constraints.maxHeight * 0.64,
                choices: scene.choices.length,
              ),
              selectedEmotionKey: _emotionKey,
              selectedIntensity: _intensity,
              validating: _validating,
              onSelectEmotion: (key) => setState(() => _emotionKey = key),
              onSelectIntensity: (value) => setState(() => _intensity = value),
              onValidate: _validate,
            );
          } else {
            bottom = _buildFeedbackBlock(
              scene: scene,
              maxHeight: constraints.maxHeight,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RadarSceneStage(
                        scene: scene,
                        remainingMs: _remainingMs,
                        showExpiredBadge: answering,
                        onOpenFullscreen: _openFullscreen,
                        playbackEnabled: _videoOverlayDepth == 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSize(
                duration: motion,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: motion,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: bottom,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Correction de la scène (maquette Figma « Feedback ») : elle remplace le
  /// panneau de réponse sous la vidéo, et rien ne défile.
  Widget _buildFeedbackBlock({
    required EmotionalRadarV2Scene scene,
    required double maxHeight,
  }) {
    final feedback = _feedback;
    final radar = _radar;
    final key = ValueKey('feedback-${scene.sceneOrder}');
    if (feedback == null || radar == null) {
      return SizedBox(key: key, height: _feedbackButtonBlock);
    }
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La carte garde sa taille naturelle ; la vidéo cède la place jusqu'à
        // un minimum lisible, et la carte ne rétrécit qu'au-delà.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.max(
              0,
              maxHeight -
                  _feedbackButtonBlock -
                  math.max(130, maxHeight * 0.26),
            ),
          ),
          child: GameFitToScreen(
            child: RadarFeedbackCard(
              feedback: feedback,
              selectedEmotionKey: _emotionKey!,
              selectedIntensity: _intensity!,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _MagentaButton(
          label: radar.completed ? 'See my results' : 'Next scene',
          onPressed: _nextScene,
        ),
      ],
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
  Widget build(BuildContext context) => const ZennytLoadingView(onDark: true);
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
            // Animation Zennyt à la place de l'ancien rond « … » immobile.
            const ZennytLoader(
              size: 92,
              semanticsLabel: 'Preparing next scene',
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
  const _CoverView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: GameWelcomePage(
        title: 'Emotional Radar',
        logoAsset: 'assets/games icons/Emotional Radar.png',
        mission: 'Reconnais l’émotion et son intensité dans chaque situation.',
        contextText:
            'Un geste, une expression, une situation : repère ce que ressent la personne et à quel degré.',
        contextDetail: 'Prends aussi en compte les indices de la scène.',
        journey: const ['Observe', 'Identifie', 'Évalue'],
        leading: _BackSquareButton(
          onTap: () => Navigator.of(context).maybePop(),
        ),
        startLabel: 'Commencer le tutoriel',
        onStart: onStart,
      ),
    ),
  );
}

class _TutorialView extends StatelessWidget {
  const _TutorialView({required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: GameContentFrame(
        child: EmotionalRadarTutorial(
          leading: _BackSquareButton(onTap: onBack),
          onComplete: onStart,
        ),
      ),
    ),
  );
}

class _BackSquareButton extends StatelessWidget {
  const _BackSquareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Retour',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
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

/// Même tutoriel depuis l'aide ; fermer reprend le parcours existant.
class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.white,
    child: SafeArea(
      child: GameContentFrame(
        child: EmotionalRadarTutorial(
          leading: _BackSquareButton(onTap: () => Navigator.of(context).pop()),
          onComplete: () => Navigator.of(context).pop(),
          reviewing: true,
        ),
      ),
    ),
  );
}

/// Rapport de fin de session, tel que le serveur le renvoie, présenté avec le
/// modèle commun des jeux ([GameResultsTemplate], référence « Je Bouge »).
///
/// Les deux axes de difficulté du référentiel sont restitués en graphiques
/// séparés — `accuracy_by_choice_count` et `accuracy_by_semantic_distance` —
/// parce que c'est précisément ce que la séparation des niveaux 3 et 4 sert à
/// mesurer : savoir si le joueur bute sur le nombre de propositions ou sur la
/// finesse de discrimination.
/// PROVISOIRE — à valider visuellement sur appareil (GAMES_MODULE, décision 72).
class EmotionalRadarResultsView extends StatelessWidget {
  const EmotionalRadarResultsView({
    super.key,
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
    void back() => Navigator.of(context).maybePop();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: data == null
            ? GameResultsTemplate(
                onBack: back,
                gameName: 'Emotional Radar',
                scoreLabel: 'Emotion recognition score',
                scorePercent: null,
                stats: const [
                  GameResultStat(label: 'Émotions', value: '—'),
                  GameResultStat(label: 'Intensité', value: '—'),
                  GameResultStat(label: 'Temps moyen', value: '—'),
                ],
                insight: 'Session interrompue : aucun rapport disponible.',
                primaryLabel: 'Rejouer',
                onPrimary: onReplay,
                secondaryLabel: 'Retour aux jeux',
                onSecondary: back,
              )
            : GameResultsTemplate(
                onBack: back,
                gameName: 'Emotional Radar',
                scoreLabel: 'Emotion recognition score',
                scorePercent: gameResultPercent(data.radarEmotionScore, 10),
                points: data.radarEmotionScore,
                maxPoints: 10,
                stats: [
                  GameResultStat(
                    label: 'Émotions',
                    value: '${data.emotionAccuracyPercent.round()}%',
                    color: ZennytGamePalette.success,
                  ),
                  GameResultStat(
                    label: 'Intensité',
                    value: '${data.intensityMatchPercent.round()}%',
                  ),
                  GameResultStat(
                    label: 'Temps moyen',
                    value:
                        '${(data.averageResponseTimeMs / 1000).toStringAsFixed(1)}s',
                    color: ZennytGamePalette.magenta,
                  ),
                ],
                insight: _insight(data),
                insightTitle: 'Évaluation de l’intensité',
                insightBars: _intensityBars(data),
                notice: scoringProvisional || !mediaLibraryReady
                    ? _RadarProvisionalNotice(
                        mediaLibraryReady: mediaLibraryReady,
                      )
                    : null,
                primaryLabel: 'Rejouer',
                onPrimary: onReplay,
                secondaryLabel: 'Retour aux jeux',
                onSecondary: back,
              ),
      ),
    );
  }

  /// Les comptes viennent du rapport ; aucune intensité n’est recalculée localement.
  static List<GameResultInsightBar> _intensityBars(
    EmotionalRadarV2Report data,
  ) {
    if (data.totalScenes <= 0 || data.intensityErrorDirection.isEmpty) {
      return const [];
    }
    const colors = [
      ZennytGamePalette.cyan,
      ZennytGamePalette.gameBlue,
      ZennytGamePalette.magenta,
    ];
    final entries = data.intensityErrorDirection.entries.toList();
    int order(String label) => label.toLowerCase().contains('sous')
        ? 0
        : label.toLowerCase().contains('correct')
        ? 1
        : 2;
    entries.sort((a, b) => order(a.key).compareTo(order(b.key)));
    return [
      for (final entry in entries)
        GameResultInsightBar(
          label: '${entry.key} : ${entry.value} / ${data.totalScenes}',
          fraction: entry.value / data.totalScenes,
          color: colors[order(entry.key)],
        ),
    ];
  }

  /// Synthèse chiffrée du rapport serveur. Les deux axes de difficulté restent
  /// lisibles dans le texte — nombre de propositions et finesse de discrimination.
  /// Les barres de synthèse sont réservées aux comptes d’évaluation de l’intensité.
  static String _insight(EmotionalRadarV2Report data) {
    final parts = <String>[
      'Niveau émotionnel : ${data.emotionalLevel}. '
          '${data.correctEmotions} émotions reconnues sur ${data.totalScenes} '
          '(niveau ${data.startingLevel} → ${data.finalLevel}).',
      'Réponses impulsives : ${data.impulsiveResponsesPercent.round()} %.',
    ];
    if (data.accuracyByChoiceCount.isNotEmpty) {
      final entries = data.accuracyByChoiceCount.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      parts.add(
        'Selon le nombre de propositions : '
        '${entries.map((e) => '${e.key} → ${e.value.round()} %').join(' · ')}.',
      );
    }
    if (data.semanticDistanceScoringAvailable &&
        data.accuracyBySemanticDistance.isNotEmpty) {
      parts.add(
        'Selon la finesse : '
        '${data.accuracyBySemanticDistance.entries.map((e) => '${_distanceLabel(e.key)} → ${e.value.round()} %').join(' · ')}.',
      );
    }
    return parts.join(' ');
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.science_outlined,
          size: 18,
          color: ZennytGamePalette.muted,
        ),
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
              color: ZennytGamePalette.muted,
            ),
          ),
        ),
      ],
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
              _MagentaButton(label: 'Réessayer', onPressed: onRetry),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  Navigator.of(context).maybePop();
                },
                child: const Text(
                  'Retour aux jeux',
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
