import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';
import '../../../navigation/presentation/widgets/app_bottom_nav.dart';
import '../../data/strategic_choices_bank_loader.dart';
import '../../domain/config/strategic_choices_content.dart';
import '../../domain/entities/game_score.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/score_breakdown.dart';
import '../../domain/entities/strategic_choices_bank.dart';
import '../../domain/entities/strategic_choices_metrics.dart';
import '../emotional_regulation_session_provider.dart';
import '../games_providers.dart';
import '../widgets/emotional_game_pause_dialog.dart';
import '../widgets/game_system_components.dart';
import '../widgets/strategic_choices_tutorial.dart';

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

/// Situations jouées dans une partie, tirées de la banque de quatre-vingts.
///
/// Les enchaîner toutes ferait une séance interminable. Dix par partie
/// conservent la durée annoncée au joueur, et le tirage change d'une passation
/// à l'autre.
const int kStrategicChoicesPerJourney = 10;

/// Parcours « Strategic Choices » relié au moteur Games.
///
/// Les vidéos ne sont pas encore livrées : les situations restent lisibles via
/// leur texte complet. Le client envoie uniquement les choix bruts ; le serveur
/// applique la cotation provisoire de la banque et renvoie le score et le
/// rapport. L'écran signale explicitement ce caractère provisoire.
class StrategicChoicesScreen extends ConsumerStatefulWidget {
  const StrategicChoicesScreen({
    super.key,
    this.reflectionDuration = StrategicChoicesContent.reflectionDuration,
    this.savedTransitionDuration =
        StrategicChoicesContent.savedTransitionDuration,
    this.scenariosForTesting,
  }) : assert(
         scenariosForTesting == null ||
             scenariosForTesting.length == kStrategicChoicesPerJourney,
       );

  final Duration reflectionDuration;
  final Duration savedTransitionDuration;

  /// Tirage déterministe réservé aux tests widget.
  @visibleForTesting
  final List<StrategicChoiceScenario>? scenariosForTesting;

  @override
  ConsumerState<StrategicChoicesScreen> createState() =>
      _StrategicChoicesScreenState();
}

class _StrategicChoicesScreenState extends ConsumerState<StrategicChoicesScreen>
    with WidgetsBindingObserver {
  _StrategicStage _stage = _StrategicStage.cover;
  _ScenarioPhase _scenarioPhase = _ScenarioPhase.reading;

  /// Les dix situations de la partie en cours.
  List<StrategicChoiceScenario> _scenarios = const [];

  /// Session serveur de la partie, ouverte au démarrage.
  GameSession? _session;

  /// Mesures brutes envoyées au serveur — jamais une cotation.
  final List<StrategicChoiceAnswerMetric> _answerMetrics = [];

  /// Instant d'affichage de la situation courante, pour le délai de réponse.
  DateTime? _situationShownAt;

  /// Score renvoyé par le serveur, une fois la partie remontée.
  GameScore? _serverScore;
  List<ScoreBreakdownLine> _serverBreakdown = const [];
  bool _submitting = false;
  String? _submitError;

  int _situationIndex = 0;
  Duration _reflectionRemaining = Duration.zero;
  StrategicChoiceStrategy? _selectedStrategy;
  final List<StrategicChoiceStrategy> _answers = [];

  Timer? _reflectionTimer;
  Timer? _savedTimer;
  bool _pauseOpen = false;
  bool _resumePauseAfterLifecycle = false;
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
        if (mounted) _openPause(afterLifecycle: true);
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

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  /// Remonte la partie et récupère le score calculé par le serveur.
  ///
  /// Le client n'envoie que la situation vue et la stratégie retenue : la
  /// cotation appartient au catalogue serveur. Un échec ne fait pas perdre la
  /// partie — l'écran le dit et propose de renvoyer, plutôt que d'afficher un
  /// tiret muet.
  Future<void> _submitJourney() async {
    final session = _session;
    if (session == null || _submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.strategicChoicesCore,
            metrics: StrategicChoicesMetrics(answers: List.of(_answerMetrics)),
          );
      ref.read(emotionalRegulationSessionProvider.notifier).keep(updated);
      if (!mounted) return;
      setState(() {
        _session = updated;
        _serverScore = updated.lastAttempt?.score;
        _serverBreakdown = updated.scoreBreakdown;
        _submitting = false;
      });
      SoundService.instance.playScoreboard();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = '$error';
        _submitting = false;
      });
    }
  }

  /// Tire les situations de la partie, sans répétition.
  ///
  /// Un tirage aléatoire plutôt qu'un ordre fixe : jouer toujours les dix
  /// mêmes fiches ferait qu'un joueur repassant l'épreuve
  /// retrouverait exactement les situations qu'il connaît déjà.
  List<StrategicChoiceScenario> _drawScenarios(StrategicChoicesBank bank) {
    final override = widget.scenariosForTesting;
    if (override != null) return List<StrategicChoiceScenario>.of(override);
    final pool = List<StrategicChoiceScenario>.of(bank.scenarios)
      ..shuffle(math.Random());
    return pool.take(kStrategicChoicesPerJourney).toList();
  }

  Future<void> _startJourney() async {
    _reflectionTimer?.cancel();
    _savedTimer?.cancel();
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    final bank = await StrategicChoicesBankLoader.load();
    if (!mounted) return;
    // La session est ouverte au démarrage, comme pour les autres jeux : sans
    // elle, la partie se jouerait puis n'aurait nulle part où être remontée.
    final sessionStore = ref.read(emotionalRegulationSessionProvider.notifier);
    final session =
        sessionStore.reusableFor(MiniGame.strategicChoicesCore) ??
        await ref
            .read(gamesRepositoryProvider)
            .startSession(GameType.emotionalRegulation);
    sessionStore.keep(session);
    if (!mounted) return;
    setState(() {
      _session = session;
      _scenarios = _drawScenarios(bank);
      _answerMetrics.clear();
      _serverScore = null;
      _serverBreakdown = const [];
      _submitError = null;
      _situationShownAt = DateTime.now();
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
    // Premier tic : le compteur de la carte affiche déjà « 3 s ».
    SoundService.instance.playSfx(GameSfx.timerDecrease);
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
      _playReflectionSfx(_reflectionRemaining, next);
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

  /// Tic à chaque seconde du compteur de réflexion, puis le son de fin quand
  /// la validation se débloque — synchronisé avec le chiffre affiché.
  void _playReflectionSfx(Duration previous, Duration next) {
    int seconds(Duration d) => (math.max(0, d.inMilliseconds) / 1000).ceil();
    final before = seconds(previous);
    final after = seconds(next);
    if (after == before) return;
    SoundService.instance.playSfx(
      after == 0 ? GameSfx.timerEnd : GameSfx.timerDecrease,
    );
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

    final shownAt = _situationShownAt;
    final situation = _scenarios[_situationIndex];
    final mesure = StrategicChoiceAnswerMetric(
      situationId: situation.id,
      selectedStrategy: selected,
      responseTimeMs: shownAt == null
          ? 0
          : DateTime.now().difference(shownAt).inMilliseconds,
      medium: situation.medium,
    );
    if (_answerMetrics.length == _situationIndex) {
      _answerMetrics.add(mesure);
    } else {
      _answerMetrics[_situationIndex] = mesure;
    }
    setState(() => _stage = _StrategicStage.saved);

    final delay = _reducedMotion
        ? Duration.zero
        : widget.savedTransitionDuration;
    _savedTimer = Timer(delay, () {
      if (!mounted) return;
      if (_situationIndex + 1 >= _scenarios.length) {
        setState(() => _stage = _StrategicStage.results);
        unawaited(_submitJourney());
        return;
      }
      setState(() {
        _situationIndex += 1;
        _selectedStrategy = null;
        _reflectionRemaining = widget.reflectionDuration;
        _scenarioPhase = _ScenarioPhase.reading;
        _stage = _StrategicStage.gameplay;
        _situationShownAt = DateTime.now();
      });
    });
  }

  /// Flèche « retour » : le menu tant que la fenêtre est ouverte, sinon la
  /// seule issue restante — quitter, donc renoncer au score.
  Future<void> _backOrExit() async {
    if (_pauseAllowance.canOpen) return _openPause();
    SoundService.instance.playSfx(GameSfx.buttonClick);
    if (!await GameExitConfirmDialog.show(context, missionLabel: 'journey')) {
      return;
    }
    if (mounted) context.go(AppRoutes.games);
  }

  /// [afterLifecycle] : retour d'arrière-plan, donc interruption SUBIE — elle ne
  /// consomme pas la fenêtre unique et n'affiche aucun compte à rebours.
  /// [reopen] : réaffichage interne (retour des règles, sortie annulée) sur le
  /// temps restant d'une fenêtre déjà ouverte.
  Future<void> _openPause({
    bool afterLifecycle = false,
    bool reopen = false,
  }) async {
    if (_stage != _StrategicStage.gameplay || _pauseOpen) return;
    if (!afterLifecycle && !reopen) {
      if (!_pauseAllowance.canOpen) return;
      _pauseAllowance.open();
      SoundService.instance.playSfx(GameSfx.pauseClick);
    }
    _pauseReflectionTimer();
    _pauseOpen = true;
    final action = await showGamePauseMenu<EmotionalGamePauseAction>(
      context,
      builder: (dialogCtx) => EmotionalGamePauseDialog(
        buttonsInput: _buttonsInput,
        onInputMode: (value) => _buttonsInput = value,
        countdown: afterLifecycle ? null : _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(dialogCtx).pop(EmotionalGamePauseAction.resume),
      ),
    );
    _pauseOpen = false;
    if (!mounted) return;
    switch (action) {
      case EmotionalGamePauseAction.rules:
        await _showRules();
        if (!mounted) return;
        if (_pauseAllowance.canReopen) return _openPauseAgain();
      case EmotionalGamePauseAction.exit:
        // Quitter annule la tentative : confirmation explicite d'abord.
        if (await GameExitConfirmDialog.show(
          context,
          missionLabel: 'journey',
        )) {
          if (mounted) context.go(AppRoutes.games);
          return;
        }
        if (!mounted) return;
        if (_pauseAllowance.canReopen) return _openPauseAgain();
      case EmotionalGamePauseAction.resume:
      case null:
        break;
    }
    if (!mounted) return;
    // La partie repart : le temps passé en pause rejoint le budget consommé, et
    // le bouton reste « Pause » tant qu'il en reste.
    _pauseAllowance.close();
    setState(_resumeReflectionTimer);
  }

  /// Réouverture interne (retour des règles / sortie annulée) : la fenêtre est
  /// déjà consommée, on repart sur son temps restant.
  Future<void> _openPauseAgain() => _openPause(reopen: true);

  Future<void> _showRules() => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: GameContentFrame(
          child: StrategicChoicesTutorial(
            totalSituations: kStrategicChoicesPerJourney,
            reviewing: true,
            leading: _SquareIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).pop(),
            ),
            onComplete: () => Navigator.of(context).pop(),
          ),
        ),
      ),
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
        _backOrExit();
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
          child: GameContentFrame(
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
                _StrategicStage.gameplay => GameplayMusic(
                  child: _GameplayView(
                    key: ValueKey('strategic-gameplay-$_situationIndex'),
                    situation: _scenarios[_situationIndex],
                    totalSituations: _scenarios.length,
                    situationNumber: _situationIndex + 1,
                    phase: _scenarioPhase,
                    reflectionRemaining: _reflectionRemaining,
                    reflectionTotal: widget.reflectionDuration,
                    selected: _selectedStrategy,
                    onStartReflection: _startReflection,
                    onSelect: _selectStrategy,
                    onValidate: _validateChoice,
                    onPause: _backOrExit,
                    affordance: _pauseAllowance.affordance,
                  ),
                ),
                _StrategicStage.saved => _SavedView(
                  key: ValueKey('strategic-saved-$_situationIndex'),
                  situationNumber: _situationIndex + 1,
                ),
                _StrategicStage.results => _ResultsView(
                  key: const ValueKey('strategic-results'),
                  score: _serverScore,
                  breakdown: _serverBreakdown,
                  submitting: _submitting,
                  errorMessage: _submitError,
                  onRetry: _submitJourney,
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Le chiffre suit la constante de partie : l'écrire en dur l'avait
            // déjà laissé faux une fois.
            const _FeatureChip(
              label: '$kStrategicChoicesPerJourney situations',
              color: _blue,
            ),
            const _FeatureChip(label: 'Supports mixtes', color: _magenta),
            const _FeatureChip(label: 'Final insights', color: _green),
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
          'Vous affronterez $kStrategicChoicesPerJourney situations de '
          'tension. Choisissez la stratégie qui vous paraît la plus adaptée.',
      buttonLabel: 'Continue',
      onButton: onContinue,
      children: const [
        _AccentInfoCard(
          color: _magenta,
          title: '$kStrategicChoicesPerJourney situations',
          // L'ancienne liste — « conflit, échec, retard, critique, surcharge » —
          // reprenait les catégories des dix situations inventées. La banque du
          // client n'en a aucune : annoncer une taxonomie qui n'existe plus
          // ferait chercher au joueur une structure absente.
          description:
              // Sans chiffre : « 60 » avait déjà cessé d'être vrai quand la
              // banque est passée à 80. Un nombre écrit ici ne suit jamais la
              // donnée, et il ment à la première extension.
              'Tirées au hasard dans la banque de situations de travail.',
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
          title: 'Written messages and video scenes',
          description:
              'Six situations display the received message verbatim. Video scenes remain readable while their media is being produced.',
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
  Widget build(BuildContext context) => StrategicChoicesTutorial(
    totalSituations: kStrategicChoicesPerJourney,
    leading: _SquareIconButton(
      icon: Icons.chevron_left_rounded,
      tooltip: 'Back',
      onTap: () {
        SoundService.instance.playSfx(GameSfx.buttonClick);
        onBack();
      },
    ),
    onComplete: onStart,
  );
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
    // Aucun défilement : la barre du haut et le bouton gardent leur taille, le
    // contenu entre les deux se réduit d'un bloc sur un écran court.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onBack: onBack),
          const SizedBox(height: 14),
          Expanded(
            child: GameFitToScreen(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 29,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 15.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GamePrimaryButton(label: buttonLabel, onPressed: onButton),
        ],
      ),
    );
  }
}

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    super.key,
    required this.situation,
    required this.totalSituations,
    required this.situationNumber,
    required this.phase,
    required this.reflectionRemaining,
    required this.reflectionTotal,
    required this.selected,
    required this.onStartReflection,
    required this.onSelect,
    required this.onValidate,
    required this.onPause,
    required this.affordance,
  });

  final StrategicChoiceScenario situation;

  /// Nombre de situations de la partie, pour l'entête et la progression.
  final int totalSituations;
  final int situationNumber;
  final _ScenarioPhase phase;
  final Duration reflectionRemaining;

  /// Durée complète de la réflexion, pour l'anneau du compteur.
  final Duration reflectionTotal;
  final StrategicChoiceStrategy? selected;
  final VoidCallback onStartReflection;
  final ValueChanged<StrategicChoiceStrategy> onSelect;
  final VoidCallback onValidate;
  final VoidCallback onPause;

  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;

  String get _statusLabel => switch (phase) {
    _ScenarioPhase.reading => 'Read first · choices locked',
    _ScenarioPhase.reflecting =>
      'Reflection time · choices available · validate waits',
    _ScenarioPhase.ready when selected == null =>
      'Reflection complete · choose one strategy',
    _ScenarioPhase.ready => 'Ready to validate · one strategy selected',
  };

  @override
  Widget build(BuildContext context) {
    final strategies = StrategicChoicesContent.strategies;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Situation $situationNumber / $totalSituations',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // L'état de la situation remplace l'ancienne bande du bas
                    // et le sous-titre : une seule ligne, en haut, à la place
                    // de deux.
                    Text(
                      _statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD8D6FF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _PurpleIconButton(
                icon: affordance.icon,
                tooltip: affordance.tooltip,
                onTap: onPause,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progression sur les SITUATIONS, animée d'une situation à la
          // suivante. La banque de Choix stratégique ne fixe aucun temps
          // conseillé : la barre ne peut donc pas suivre un temps, contrairement
          // au Temps réflexif. Le compteur « Situation n / N » reste à part.
          _SituationProgress(
            situationNumber: situationNumber,
            totalSituations: totalSituations,
          ),
          const SizedBox(height: 12),
          // Plateau sur un seul écran, équilibré :
          // - les stratégies ont la hauteur de leurs huit boutons, rien de plus
          //   (plus de grand vide blanc sous la grille) ;
          // - la situation prend tout le reste, et son texte grandit pour
          //   l'occuper, dans la limite d'une taille confortable. Un texte
          //   court laisse l'espace entre les deux blocs, pas dans un bloc.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                const gap = 8.0;
                const rows = 4;
                const panelChrome = 2 * 12 + 26 + 10 + (rows - 1) * gap;
                const blockGap = 16.0;
                final baseChoiceHeight = (box.maxHeight * 0.085)
                    .clamp(50.0, 64.0)
                    .toDouble();
                final cardMax = math.max(
                  0.0,
                  box.maxHeight -
                      panelChrome -
                      rows * baseChoiceHeight -
                      blockGap,
                );
                final showVideoFrame = cardMax > 440;
                // Place réellement prise par la situation, texte à sa taille
                // la plus grande. Ce qui reste n'est pas laissé en vide : les
                // boutons de stratégie grandissent pour l'occuper, jusqu'à une
                // hauteur confortable.
                final cardNeeded = _SituationCard.estimateHeight(
                  context,
                  situation: situation,
                  width: box.maxWidth,
                  showVideoFrame: showVideoFrame,
                );
                final spare = math.max(0.0, cardMax - cardNeeded);
                final choiceHeight = math.min(
                  78.0,
                  baseChoiceHeight + spare / rows,
                );
                final choicesPanel = panelChrome + rows * choiceHeight;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: _SituationCard(
                        situation: situation,
                        phase: phase,
                        reflectionRemaining: reflectionRemaining,
                        reflectionTotal: reflectionTotal,
                        // L'illustration vidéo n'apparaît que si le texte de
                        // la scène garde une place confortable à côté.
                        showVideoFrame: showVideoFrame,
                      ),
                    ),
                    const SizedBox(height: blockGap),
                    SizedBox(
                      height: choicesPanel,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 26,
                              child: Row(
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
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, area) {
                                  final cellWidth = (area.maxWidth - gap) / 2;
                                  // Une seule taille de police pour les huit
                                  // stratégies : celle à laquelle la plus
                                  // longue tient dans sa case.
                                  final fontSize = AutoFitText.fontSizeFor(
                                    context,
                                    texts: [
                                      for (final strategy in strategies)
                                        strategy.label,
                                    ],
                                    style: StrategicChoiceCard.textStyle,
                                    textAlign: TextAlign.start,
                                    minFontSize: 11,
                                    constraints: BoxConstraints(
                                      maxWidth: math.max(
                                        0,
                                        cellWidth -
                                            StrategicChoiceCard.horizontalInset,
                                      ),
                                      maxHeight: math.max(
                                        0,
                                        choiceHeight -
                                            StrategicChoiceCard.verticalInset,
                                      ),
                                    ),
                                  );
                                  return Column(
                                    children: [
                                      for (var r = 0; r < rows; r++) ...[
                                        if (r > 0) const SizedBox(height: gap),
                                        SizedBox(
                                          height: choiceHeight,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              for (var c = 0; c < 2; c++) ...[
                                                if (c > 0)
                                                  const SizedBox(width: gap),
                                                Expanded(
                                                  child: StrategicChoiceCard(
                                                    strategy:
                                                        strategies[r * 2 + c],
                                                    fontSize: fontSize,
                                                    enabled:
                                                        phase !=
                                                        _ScenarioPhase.reading,
                                                    selected:
                                                        selected ==
                                                        strategies[r * 2 + c],
                                                    onTap: () => onSelect(
                                                      strategies[r * 2 + c],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
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
    );
  }
}

/// Barre de progression des situations, animée de l'une à la suivante.
class _SituationProgress extends StatelessWidget {
  const _SituationProgress({
    required this.situationNumber,
    required this.totalSituations,
  });

  final int situationNumber;
  final int totalSituations;

  @override
  Widget build(BuildContext context) {
    final target = totalSituations == 0
        ? 0.0
        : situationNumber / totalSituations;
    final from = totalSituations == 0
        ? 0.0
        : (situationNumber - 1) / totalSituations;
    return Semantics(
      label: 'Progress',
      value: 'Situation $situationNumber of $totalSituations',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: from, end: target),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            key: const ValueKey('strategic-progress'),
            minHeight: 7,
            value: value,
            color: _magenta,
            backgroundColor: Colors.white24,
          ),
        ),
      ),
    );
  }
}

/// Carte de la situation : titre, compteur de réflexion, puis la scène.
///
/// Elle épouse la hauteur de son texte — aucun espace vide — et ne se réduit
/// que si ce texte dépasse la place laissée aux stratégies.
class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.situation,
    required this.phase,
    required this.reflectionRemaining,
    required this.reflectionTotal,
    required this.showVideoFrame,
  });

  final StrategicChoiceScenario situation;
  final _ScenarioPhase phase;
  final Duration reflectionRemaining;
  final Duration reflectionTotal;
  final bool showVideoFrame;

  bool get _written => situation.medium == StrategicChoiceMedium.written;

  /// Hauteur de la carte quand le texte de la scène est à sa taille maximale.
  ///
  /// Mesurée avec les mêmes styles que le rendu, pour que le plateau sache
  /// d'avance combien de place la situation laisse aux stratégies.
  static double estimateHeight(
    BuildContext context, {
    required StrategicChoiceScenario situation,
    required double width,
    required bool showVideoFrame,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: math.max(1, maxWidth));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    const cardPadding = 14 + 16.0;
    const chipRow = 30 + 14.0;
    final inner = width - 32;
    var height = cardPadding + chipRow;
    final message = situation.message;
    if (situation.medium == StrategicChoiceMedium.written && message != null) {
      // Encadré : marges, étiquette, espace, marges et bordure de la bulle.
      height +=
          2 * 10 +
          20 +
          8 +
          2 * 10 +
          2 +
          measure(message, _messageStyle, inner - 2 * 10 - 2 * 12 - 2) +
          14;
    }
    if (situation.medium == StrategicChoiceMedium.video && showVideoFrame) {
      height += 90 + 14;
    }
    return height +
        _SceneText.heightFor(
          context,
          situation.scene,
          _SceneText._maxSize,
          inner,
        );
  }

  static const TextStyle _messageStyle = TextStyle(
    color: _ink,
    fontSize: 16.5,
    height: 1.45,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau d'en-tête sur UNE ligne : support et titre de la fiche
          // dans la pastille, compteur de réflexion à droite.
          Row(
            children: [
              // Le titre de la fiche remplace l'ancienne étiquette de
              // catégorie : la banque du client n'en a pas, et en inventer
              // une reviendrait à classer les situations à la place du
              // psychologue.
              Flexible(
                child: _SituationTitleChip(
                  title: situation.title,
                  icon: _written
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.videocam_outlined,
                ),
              ),
              const SizedBox(width: 8),
              // Hauteur fixe : l'apparition du compteur ne décale rien.
              SizedBox(
                height: 30,
                child: phase == _ScenarioPhase.reflecting
                    ? _ReflectionCountdown(
                        remaining: reflectionRemaining,
                        total: reflectionTotal,
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Support écrit : le message s'affiche tel quel, dans sa bulle,
          // sur fond clair. Le fond noir est réservé à l'illustration
          // provisoire des vidéos.
          if (_written && situation.message != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: _magenta,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'MESSAGE REÇU',
                        style: TextStyle(
                          color: _magenta,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: const ValueKey('strategic-written-message'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(color: _border),
                    ),
                    child: Text(situation.message!, style: _messageStyle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Illustration provisoire de la vidéo, tant que la banque n'est pas
          // livrée : SEUL élément sur fond noir. Il cède la place aux
          // stratégies sur un écran court ; la description de scène tient
          // lieu de situation.
          if (situation.medium == StrategicChoiceMedium.video &&
              showVideoFrame) ...[
            Semantics(
              key: const ValueKey('strategic-video-placeholder'),
              label: 'Emplacement de la vidéo, non disponible',
              child: Container(
                width: double.infinity,
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.movie_outlined,
                      color: Color(0xFFB8F3D6),
                      size: 26,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Vidéo à venir',
                      style: TextStyle(
                        color: Color(0xFFC9D3EA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Flexible(child: _SceneText(text: situation.scene)),
        ],
      ),
    );
  }
}

/// Texte de la scène, mis en forme pour se lire d'un coup d'œil.
///
/// La banque livre chaque scène en un seul bloc de deux à quatre phrases.
/// Affiché tel quel, c'était un pavé dense et uniforme. On le découpe donc en
/// phrases, une par paragraphe :
///
/// - les phrases de **contexte**, en graisse normale et teinte douce ;
/// - la phrase de **décision** — la dernière, « Le personnage doit décider… »
///   — détachée et en gras : c'est elle qui pose la question.
///
/// La taille reste mesurée (17 pt au plus) et ne descend que si la scène ne
/// tient pas ; au-delà, le bloc se réduit d'un tenant plutôt que d'être coupé.
class _SceneText extends StatelessWidget {
  const _SceneText({required this.text});

  final String text;

  static const double _maxSize = 17;
  static const double _minSize = 14;
  static const double _paragraphGap = 10;

  static const Color _contextColor = Color(0xFF4A5372);

  /// Coupe après une ponctuation finale suivie d'une majuscule : les
  /// abréviations et les parenthèses internes de la banque ne sont pas coupées.
  static final RegExp _sentenceBreak = RegExp(r'(?<=[.!?…])\s+(?=[A-ZÀ-ÝÉÈ«])');

  static List<String> sentencesOf(String text) => [
    for (final part in text.trim().split(_sentenceBreak))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  static TextStyle contextStyle(double size) => TextStyle(
    color: _contextColor,
    fontSize: size,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static TextStyle decisionStyle(double size) => TextStyle(
    color: _ink,
    fontSize: size,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );

  /// Hauteur du texte mis en forme à la taille [size], sur [width].
  static double heightFor(
    BuildContext context,
    String text,
    double size,
    double width,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    final sentences = sentencesOf(text);
    var height = 0.0;
    for (var i = 0; i < sentences.length; i++) {
      final last = i == sentences.length - 1 && sentences.length > 1;
      final painter = TextPainter(
        text: TextSpan(
          text: sentences[i],
          style: last ? decisionStyle(size) : contextStyle(size),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: math.max(1, width));
      height += painter.height + (i > 0 ? _paragraphGap : 0);
      painter.dispose();
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        var size = _maxSize;
        if (box.hasBoundedWidth && box.hasBoundedHeight) {
          while (size > _minSize &&
              heightFor(context, text, size, box.maxWidth) > box.maxHeight) {
            size -= 0.5;
          }
        }
        final sentences = sentencesOf(text);
        final paragraphs = Column(
          key: const ValueKey('strategic-situation-prompt'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sentences.length; i++) ...[
              if (i > 0) const SizedBox(height: _paragraphGap),
              Text(
                sentences[i],
                style: i == sentences.length - 1 && sentences.length > 1
                    ? decisionStyle(size)
                    : contextStyle(size),
              ),
            ],
          ],
        );
        if (!box.hasBoundedWidth) return paragraphs;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(width: box.maxWidth, child: paragraphs),
        );
      },
    );
  }
}

/// Pastille arrondie du titre de la situation, sur une seule ligne.
///
/// Le titre ne passe plus à la ligne : un titre long rétrécit juste assez pour
/// tenir, sans être tronqué.
class _SituationTitleChip extends StatelessWidget {
  const _SituationTitleChip({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _blue),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit compteur des secondes de réflexion, dans la carte de la situation.
class _ReflectionCountdown extends StatelessWidget {
  const _ReflectionCountdown({required this.remaining, required this.total});

  final Duration remaining;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final seconds = (remaining.inMilliseconds / 1000).ceil().clamp(0, 99);
    final ratio = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final label = '00:${seconds.toString().padLeft(2, '0')}';
    return Semantics(
      liveRegion: true,
      label: 'Reflection time $label remaining',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: ratio.toDouble(),
                strokeWidth: 3,
                backgroundColor: const Color(0x332563EB),
                color: _blue,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$seconds s',
              key: const ValueKey('strategic-reflection-timer'),
              style: const TextStyle(
                color: _blue,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icône de stratégie conservée, état de sélection/verrouillage en badge séparé.
/// PROVISOIRE — à valider visuellement sur appareil (GAMES_MODULE, décision 72).
class StrategicChoiceCard extends StatelessWidget {
  const StrategicChoiceCard({
    super.key,
    required this.strategy,
    required this.enabled,
    required this.selected,
    required this.onTap,
    this.fontSize,
  });

  final StrategicChoiceStrategy strategy;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  /// Taille commune imposée par le plateau.
  final double? fontSize;

  static const TextStyle textStyle = TextStyle(
    fontSize: 15.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  /// Largeur non disponible pour le libellé : marges, bordure, pastille et
  /// espace. Le cadenas vit DANS la pastille : à droite, il volait au libellé
  /// la largeur qui lui manquait sur un petit écran.
  static const double horizontalInset = 2 * (8 + 2) + 28 + 8;

  /// Hauteur non disponible pour le libellé : marges et bordure.
  static const double verticalInset = 2 * (4 + 2);

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
          onTap: enabled
              ? () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _magenta : _border,
                width: 2,
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        strategy.icon,
                        key: ValueKey('strategic-icon-${strategy.name}'),
                        size: 18,
                        color: selected
                            ? Colors.white
                            : enabled
                            ? _magenta
                            : _muted,
                      ),
                      if (selected || !enabled)
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: ExcludeSemantics(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: selected ? _magenta : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white),
                              ),
                              child: Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.lock_outline,
                                size: 10,
                                color: selected ? Colors.white : _muted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Hauteur fixée par le plateau : le libellé s'y ajuste au
                // lieu de déborder ou d'être coupé.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AutoFitText(
                      strategy.label,
                      minFontSize: 10,
                      textAlign: TextAlign.start,
                      style: textStyle.copyWith(
                        color: enabled ? _ink : _muted,
                        fontSize: fontSize ?? textStyle.fontSize,
                      ),
                    ),
                  ),
                ),
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
                situationNumber < kStrategicChoicesPerJourney
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

/// « Final summary » de Strategic Choices, d'après la maquette client.
///
/// Rien n'est recalculé ici : le score global est celui du serveur ramené sur
/// 100, et les trois mesures du profil sont lues dans les lignes du barème
/// serveur (`scoreBreakdown`). La maquette annonçait « Adaptive choice /
/// Emotional flexibility / Inhibition capacity » : aucun barème ne les calcule,
/// l'écran montre donc les mesures qui existent réellement, sous leur vrai nom.
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.answerCount,
    required this.score,
    required this.breakdown,
    required this.submitting,
    required this.errorMessage,
    required this.onRetry,
    required this.onBack,
    required this.onInsights,
  });

  final int answerCount;

  /// Score calculé par le SERVEUR. `null` tant que la remontée n'a pas abouti.
  final GameScore? score;

  final List<ScoreBreakdownLine> breakdown;
  final bool submitting;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;
  final VoidCallback onInsights;

  /// Part « x/n » d'une ligne du barème serveur, en %. `null` si absente.
  double? _share(String label) {
    for (final line in breakdown) {
      if (line.label != label) continue;
      final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(line.detail ?? '');
      if (match == null) return null;
      final total = int.parse(match.group(2)!);
      if (total == 0) return null;
      return int.parse(match.group(1)!) * 100 / total;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final serverScore = score;
    final failed = errorMessage != null;
    final global = serverScore == null || serverScore.maxPoints == 0
        ? null
        : (serverScore.rawPoints * 100 / serverScore.maxPoints).round();
    final dysfunctional = _share('Dysfonctionnel');
    final profile = [
      (
        letter: 'O',
        tile: 'Optimal\nchoices',
        bar: 'Optimal strategy choices',
        value: _share('Stratégie optimale retenue'),
        color: _green,
      ),
      (
        letter: 'P',
        tile: 'Problem-\nfocused',
        bar: 'Problem-focused coping',
        value: _share('Centré problème'),
        color: _magenta,
      ),
      (
        letter: 'N',
        tile: 'Non-\ndysfunctional',
        bar: 'Non-dysfunctional coping',
        value: dysfunctional == null ? null : 100 - dysfunctional,
        color: _violet,
      ),
    ];
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            // Un seul écran : sur un téléphone court, le bloc se réduit au lieu
            // de défiler.
            child: GameFitToScreen(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(onBack: onBack),
                  const SizedBox(height: 16),
                  const Text(
                    'Final summary',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A coaching report based on your choices across '
                    '$answerCount situations.',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GlobalScoreCard(
                    percent: global,
                    level: serverScore?.level,
                    submitting: submitting,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Learning profile',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < profile.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _ProfileTile(
                            letter: profile[i].letter,
                            label: profile[i].tile,
                            percent: profile[i].value,
                            color: profile[i].color,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (final measure in profile)
                    _ProfileBar(
                      label: measure.bar,
                      percent: measure.value,
                      color: measure.color,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    failed
                        // Un échec de remontée ne doit pas se lire comme un
                        // score nul : on le nomme, et on propose de renvoyer.
                        ? 'Score non calculé — $errorMessage'
                        : 'Barème PROVISOIRE : reconstruit par inférence à '
                              'partir des titres, sans visionnage des vidéos. '
                              'À valider par le psychologue.',
                    key: failed
                        ? const ValueKey('strategic-submit-error')
                        : null,
                    style: TextStyle(
                      color: failed ? ZennytGamePalette.error : _muted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (failed) ...[
                GameOutlineButton(
                  label: 'Renvoyer le résultat',
                  onPressed: submitting ? null : () => onRetry(),
                ),
                const SizedBox(height: 10),
              ],
              GamePrimaryButton(
                label: 'See detailed insights',
                onPressed: onInsights,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlobalScoreCard extends StatelessWidget {
  const _GlobalScoreCard({
    required this.percent,
    required this.level,
    required this.submitting,
  });

  final int? percent;

  /// Niveau serveur, calculé sur l'indice corrigé du hasard.
  final String? level;
  final bool submitting;

  /// Libellés courts du niveau serveur, pour la pastille et sa légende.
  static ({String badge, String pattern})? _labels(String? level) =>
      switch (level) {
        'Highly adaptive strategies' => (
          badge: 'Advanced',
          pattern: 'Strong adaptive coping pattern',
        ),
        'Adaptive strategies' => (
          badge: 'Intermediate',
          pattern: 'Adaptive coping pattern',
        ),
        'Reactive strategies' => (
          badge: 'Developing',
          pattern: 'Reactive coping pattern',
        ),
        null => null,
        final other => (badge: other, pattern: ''),
      };

  @override
  Widget build(BuildContext context) {
    const scoreStyle = TextStyle(
      color: _ink,
      fontSize: 50,
      height: 1.05,
      fontWeight: FontWeight.w800,
    );
    final labels = _labels(level);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      // Fond blanc, texte sombre : le score se lit sans l'effet « trou
      // noir » de l'ancienne carte.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14071333),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global score',
            style: TextStyle(
              color: _muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (percent == null)
            Text(
              submitting ? 'Calcul…' : '—',
              key: const ValueKey('strategic-answer-count'),
              style: scoreStyle,
            )
          else
            AnimatedCountText(
              value: percent!,
              suffix: ' / 100',
              textKey: const ValueKey('strategic-answer-count'),
              onCompleted: SoundService.instance.stopScoreboard,
              style: scoreStyle,
            ),
          if (labels != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _magenta,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    labels.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    labels.pattern,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.letter,
    required this.label,
    required this.percent,
    required this.color,
  });

  final String letter;
  final String label;
  final double? percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  percent == null ? '—' : '${percent!.round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 13.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBar extends StatelessWidget {
  const _ProfileBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double? percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final target = ((percent ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                percent == null ? '—' : '${percent!.round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, fill, _) => LinearProgressIndicator(
                value: fill,
                minHeight: 9,
                backgroundColor: _border,
                color: color,
              ),
            ),
          ),
        ],
      ),
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
          'Observations descriptives. Elles complètent le score, elles ne le '
          'remplacent pas, et ne posent aucun diagnostic.',
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
              'Vos réponses sont envoyées au serveur, qui calcule le score. '
              'Le barème reste provisoire : il a été reconstruit sans '
              'visionnage des vidéos et attend une validation clinique.',
        ),
        const SizedBox(height: 12),
        const _InsightCard(
          color: _magenta,
          title: 'Trap tendencies',
          description:
              'No trap label is shown. These interpretations remain hidden until calibration is approved.',
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
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onBack();
          },
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
  const _NoticePanel({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      backgroundColor: _violet,
      borderColor: _violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: TextStyle(
              color: const Color(0xFFE7E5FF),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
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

extension _StrategicChoiceStrategyVisual on StrategicChoiceStrategy {
  IconData get icon => switch (this) {
    StrategicChoiceStrategy.avoidFlee => Icons.directions_run_rounded,
    StrategicChoiceStrategy.ruminate => Icons.sync_rounded,
    StrategicChoiceStrategy.breathePause => Icons.air_rounded,
    StrategicChoiceStrategy.cognitiveReappraisal =>
      Icons.psychology_alt_outlined,
    StrategicChoiceStrategy.assertiveCommunication =>
      Icons.chat_bubble_outline_rounded,
    StrategicChoiceStrategy.humor => Icons.sentiment_satisfied_alt_rounded,
    StrategicChoiceStrategy.seekSupport => Icons.people_outline_rounded,
    StrategicChoiceStrategy.directAction => Icons.touch_app_rounded,
  };
}
