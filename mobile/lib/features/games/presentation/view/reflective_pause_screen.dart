import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/config/reflective_pause_config.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_runtime_snapshot.dart';
import '../../domain/config/game_presentation_timing.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../data/reflective_pause_bank_loader.dart';
import '../../domain/entities/reflective_pause_bank.dart';
import '../../domain/entities/reflective_pause_metrics.dart';
import '../emotional_regulation_session_provider.dart';
import '../games_providers.dart';
import '../widgets/emotional_game_pause_dialog.dart';
import '../widgets/game_system_components.dart';
import '../widgets/game_results_template.dart';
import '../widgets/reflective_pause_tutorial.dart';
import '../widgets/zennyt_loader.dart';

const _ink = Color(0xFF28234F);
const _muted = Color(0xFF607095);
const _border = Color(0xFFDCE5F5);
const _canvas = Color(0xFFF7F9FE);
const _magenta = Color(0xFFD72C83);
const _violet = Color(0xFF5146E8);
const _green = Color(0xFF20B978);
const _navy = Color(0xFF071B3A);
const _logoAsset = 'assets/games icons/Reflective Pause.png';

/// Fond mauve du plateau, commun aux autres jeux.
const _board = ZennytGamePalette.gameBlue;

/// Secondes finales du délai de réflexion rythmées par un tic sonore.
const int _countdownSfxSeconds = 5;

enum _ReflectiveStage {
  cover,
  intro,
  tutorial,
  loading,
  gameplay,
  saved,
  results,
  insights,
  error,
}

/// Parcours complet « Reflective Pause ».
///
/// Le client mesure le temps de réponse et le choix brut. Le score et les trois
/// indicateurs affichés aux résultats sont exclusivement renvoyés par le
/// backend (ou par son miroir exact en mode mock).
class ReflectivePauseScreen extends ConsumerStatefulWidget {
  const ReflectivePauseScreen({super.key, this.now, this.situationIds});

  /// Horloge injectable pour rendre le timer déterministe en test.
  final DateTime Function()? now;

  /// Situations imposées, au lieu du tirage.
  ///
  /// Le tirage est aléatoire par construction : sans ce crochet, le score d'un
  /// parcours de test dépendrait des dix situations sorties, et l'assertion ne
  /// mesurerait plus le barème mais la chance.
  final List<String>? situationIds;

  @override
  ConsumerState<ReflectivePauseScreen> createState() =>
      _ReflectivePauseScreenState();
}

class _ReflectivePauseScreenState extends ConsumerState<ReflectivePauseScreen> {
  _ReflectiveStage _stage = _ReflectiveStage.cover;
  GameSession? _session;

  /// Les dix situations de la partie, tirées dans la banque des soixante.
  List<ReflectivePauseSituation> _situations = const [];

  /// Graine du mélange des réponses, fixée à l'ouverture de la partie.
  ///
  /// Dans la banque livrée, la position encode la catégorie : « A » est la
  /// réponse impulsive dans les soixante situations. Affiché tel quel, l'ordre
  /// s'apprend en deux situations. La graine dépend de la partie, l'ordre
  /// diffère donc aussi d'une passation à l'autre.
  int _shuffleSeed = 0;

  int _momentIndex = 0;
  ReflectivePauseResponseType? _selectedResponse;
  final List<ReflectivePauseMomentMetric> _metrics = [];
  Timer? _clock;
  int _elapsedMs = 0;
  int _elapsedBeforeStartMs = 0;
  DateTime? _clockStartedAt;
  bool _submitting = false;
  String? _errorMessage;

  bool _buttonsInput = true;

  GamePresentationTiming get _timing =>
      GamePresentationTiming(_session?.runtime ?? const GameRuntimeSnapshot());
  bool get _minimumReached => _elapsedMs >= _timing.reflectiveThinkingTimeMs;

  bool get _reducedMotion =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (_session?.runtime.modifierBool(
            'reducedMotionDefault',
            fallback: false,
          ) ??
          false);

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _setStage(_ReflectiveStage stage) {
    setState(() => _stage = stage);
  }

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  Future<void> _startGame() async {
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    setState(() {
      _stage = _ReflectiveStage.loading;
      _errorMessage = null;
    });
    try {
      final sessionStore = ref.read(
        emotionalRegulationSessionProvider.notifier,
      );
      final session =
          sessionStore.reusableFor(MiniGame.reflectivePauseCore) ??
          await ref
              .read(gamesRepositoryProvider)
              .startSession(GameType.emotionalRegulation);
      sessionStore.keep(session);
      final bank = await ReflectivePauseBankLoader.load();
      if (!mounted) return;
      setState(() {
        _session = session;
        _situations = _drawSituations(bank);
        // `_now()`, pas `DateTime.now()` : l'écran a déjà une horloge
        // injectable, et s'en écarter ici rendait l'ordre des réponses
        // imprévisible en test — donc les parcours de test intermittents.
        _shuffleSeed = _now().microsecondsSinceEpoch & 0xFFFFF;
        _momentIndex = 0;
        _metrics.clear();
        _stage = _ReflectiveStage.gameplay;
      });
      _beginMoment();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _stage = _ReflectiveStage.error;
      });
    }
  }

  /// Tire les dix situations de la partie, une par catégorie.
  ///
  /// La banque compte dix catégories de six situations. Une par catégorie
  /// couvre donc tout le référentiel en une partie, là où un tirage libre
  /// pourrait donner trois fois « critique injuste » et jamais « pression
  /// hiérarchique » — et ne mesurerait plus la même chose d'un joueur à
  /// l'autre.
  List<ReflectivePauseSituation> _drawSituations(ReflectivePauseBank bank) {
    final imposees = widget.situationIds;
    if (imposees != null) return [for (final id in imposees) bank.byId(id)];

    final random = math.Random();
    final parCategorie = <int, List<ReflectivePauseSituation>>{};
    for (final situation in bank.situations) {
      parCategorie
          .putIfAbsent(situation.categoryNumber, () => [])
          .add(situation);
    }
    final numeros = parCategorie.keys.toList()..sort();
    final tirees = [
      for (final numero in numeros)
        parCategorie[numero]![random.nextInt(parCategorie[numero]!.length)],
    ];
    // L'ordre des catégories ne doit pas être toujours le même non plus : la
    // difficulté monterait alors de façon prévisible d'une passation à l'autre.
    tirees.shuffle(random);
    return tirees;
  }

  ReflectivePauseSituation get _situation => _situations[_momentIndex];

  void _beginMoment() {
    _clock?.cancel();
    _elapsedBeforeStartMs = 0;
    _clockStartedAt = null;
    setState(() {
      _selectedResponse = null;
      _elapsedMs = 0;
    });
    // Premier tic de la réflexion : le compteur affiche déjà « 3 s ».
    if (_timing.reflectiveThinkingTimeMs > 0) {
      SoundService.instance.playSfx(GameSfx.timerDecrease);
    }
    _startClock();
  }

  void _startClock() {
    _clockStartedAt = _now();
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _stage != _ReflectiveStage.gameplay) return;
      _refreshElapsed();
    });
  }

  void _refreshElapsed() {
    final startedAt = _clockStartedAt;
    if (startedAt == null) return;
    final measured =
        _elapsedBeforeStartMs + _now().difference(startedAt).inMilliseconds;
    if (measured == _elapsedMs) return;
    _playCountdownSfx(_elapsedMs, measured);
    setState(() => _elapsedMs = measured);
  }

  /// Sons des deux comptes à rebours d'un moment, chacun synchronisé avec ce
  /// qu'il rythme :
  ///
  /// - **réflexion** (3 s) : un tic à chaque seconde du compteur de la carte,
  ///   puis le son de fin quand les réponses se déverrouillent ;
  /// - **temps conseillé** : un tic sur ses [_countdownSfxSeconds] dernières
  ///   secondes, au rythme de la barre, puis le son de fin à l'échéance.
  ///
  /// Chaque son tombe au passage d'une seconde entière du temps RESTANT.
  void _playCountdownSfx(int previousElapsedMs, int elapsedMs) {
    if (_situations.isEmpty) return;
    final thinking = _timing.reflectiveThinkingTimeMs;
    int secondsLeft(int end, int elapsed) =>
        (math.max(0, end - elapsed) / 1000).ceil();

    if (previousElapsedMs < thinking) {
      final before = secondsLeft(thinking, previousElapsedMs);
      final after = secondsLeft(thinking, elapsedMs);
      if (after != before) {
        SoundService.instance.playSfx(
          after == 0 ? GameSfx.timerEnd : GameSfx.timerDecrease,
        );
      }
      return;
    }

    final end = thinking + _situation.responseDeadlineSec * 1000;
    final before = secondsLeft(end, previousElapsedMs);
    final after = secondsLeft(end, elapsedMs);
    if (after == before) return;
    if (after == 0) {
      SoundService.instance.playSfx(GameSfx.timerEnd);
    } else if (after <= _countdownSfxSeconds) {
      SoundService.instance.playSfx(GameSfx.timerDecrease);
    }
  }

  void _freezeClock() {
    _refreshElapsed();
    _clock?.cancel();
    _elapsedBeforeStartMs = _elapsedMs;
    _clockStartedAt = null;
  }

  void _resumeClockIfNeeded() {
    if (_stage != _ReflectiveStage.gameplay) return;
    _startClock();
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

  /// [reopen] : réaffichage interne (retour des règles, sortie annulée) sur le
  /// temps restant d'une fenêtre déjà ouverte.
  Future<void> _openPause({bool reopen = false}) async {
    if (!reopen) {
      // Une seule fenêtre de pause par partie (CdC pause §2-3).
      if (!_pauseAllowance.canOpen) return;
      _pauseAllowance.open();
      SoundService.instance.playSfx(GameSfx.pauseClick);
    }
    _freezeClock();
    final action = await showGamePauseMenu<EmotionalGamePauseAction>(
      context,
      builder: (dialogCtx) => EmotionalGamePauseDialog(
        buttonsInput: _buttonsInput,
        onInputMode: (value) => setState(() => _buttonsInput = value),
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(dialogCtx).pop(EmotionalGamePauseAction.resume),
      ),
    );
    if (!mounted) return;
    if (action == EmotionalGamePauseAction.rules) {
      await showDialog<void>(
        context: context,
        barrierColor: const Color(0xCC1B1B4B),
        builder: (_) => const _ReflectiveRulesDialog(),
      );
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _openPause(reopen: true);
    } else if (action == EmotionalGamePauseAction.exit) {
      // Quitter annule la tentative : confirmation explicite d'abord.
      if (await GameExitConfirmDialog.show(context, missionLabel: 'journey')) {
        if (mounted) context.go(AppRoutes.games);
        return;
      }
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _openPause(reopen: true);
    }
    if (!mounted) return;
    // La partie repart : le temps passé en pause rejoint le budget consommé, et
    // le bouton reste « Pause » tant qu'il en reste.
    _pauseAllowance.close();
    setState(_resumeClockIfNeeded);
  }

  Future<void> _validateResponse() async {
    final response = _selectedResponse;
    if (!_minimumReached || response == null || _submitting) return;
    _freezeClock();
    final moment = _situation;
    _metrics.add(
      ReflectivePauseMomentMetric(
        momentId: moment.id,
        selectedResponse: response,
        responseTimeMs: _elapsedMs,
        // Le client demande d'enregistrer le SUPPORT au même titre que le choix
        // et le délai : lire un message et regarder une scène ne sollicitent
        // pas la même charge, et le comparer suppose de savoir lequel des deux
        // le joueur a eu.
        medium: moment.medium,
        // The server's protected scoring threshold stays at 3 s even when
        // the presentation policy asks the player to think longer.
        minimumTimerReached: _elapsedMs >= ReflectivePauseConfig.minimumPauseMs,
      ),
    );
    setState(() => _stage = _ReflectiveStage.saved);

    if (!_reducedMotion) {
      await Future<void>.delayed(
        Duration(milliseconds: _timing.reflectiveTransitionMs),
      );
    }
    if (!mounted) return;
    if (_momentIndex == _situations.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _momentIndex += 1;
      _stage = _ReflectiveStage.gameplay;
    });
    _beginMoment();
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    setState(() {
      _submitting = true;
      _stage = _ReflectiveStage.loading;
    });
    try {
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.reflectivePauseCore,
            metrics: ReflectivePauseMetrics(moments: List.of(_metrics)),
          );
      ref.read(emotionalRegulationSessionProvider.notifier).keep(updated);
      if (!mounted) return;
      // Même entrée que « Je Bouge » : le tableau de score sonne pendant que
      // le score compte jusqu'à sa valeur.
      SoundService.instance.playScoreboard();
      setState(() {
        _session = updated;
        _submitting = false;
        _stage = _ReflectiveStage.results;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = '$error';
        _stage = _ReflectiveStage.error;
      });
    }
  }

  void _back() {
    switch (_stage) {
      case _ReflectiveStage.cover:
        context.go(AppRoutes.games);
      case _ReflectiveStage.intro:
        _setStage(_ReflectiveStage.cover);
      case _ReflectiveStage.tutorial:
        _setStage(_ReflectiveStage.intro);
      case _ReflectiveStage.results:
        context.go(AppRoutes.games);
      case _ReflectiveStage.insights:
        _setStage(_ReflectiveStage.results);
      case _ReflectiveStage.error:
        _setStage(_ReflectiveStage.cover);
      case _ReflectiveStage.loading ||
          _ReflectiveStage.gameplay ||
          _ReflectiveStage.saved:
        _backOrExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onBoard = switch (_stage) {
      _ReflectiveStage.loading ||
      _ReflectiveStage.gameplay ||
      _ReflectiveStage.saved => true,
      _ => false,
    };
    return Scaffold(
      backgroundColor: onBoard ? _board : Colors.white,
      body: SafeArea(
        child: GameContentFrame(
          child: AnimatedSwitcher(
            duration: _reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: switch (_stage) {
              _ReflectiveStage.cover => _CoverView(
                key: const ValueKey('reflective-cover'),
                onBack: _back,
                onStart: () => _setStage(_ReflectiveStage.intro),
              ),
              _ReflectiveStage.intro => _IntroView(
                key: const ValueKey('reflective-intro'),
                onBack: _back,
                onContinue: () => _setStage(_ReflectiveStage.tutorial),
              ),
              _ReflectiveStage.tutorial => _TutorialView(
                key: const ValueKey('reflective-tutorial'),
                onBack: _back,
                onStart: _startGame,
              ),
              _ReflectiveStage.loading => const _LoadingView(
                key: ValueKey('reflective-loading'),
              ),
              _ReflectiveStage.gameplay => GameplayMusic(
                child: _GameplayView(
                  key: ValueKey('reflective-gameplay-$_momentIndex'),
                  situation: _situation,
                  totalMoments: _situations.length,
                  shuffleSeed: _shuffleSeed,
                  momentNumber: _momentIndex + 1,
                  elapsedMs: _elapsedMs,
                  thinkingTimeMs: _timing.reflectiveThinkingTimeMs,
                  minimumReached: _minimumReached,
                  selectedResponse: _selectedResponse,
                  onSelect: (response) =>
                      setState(() => _selectedResponse = response),
                  onValidate: _validateResponse,
                  onPause: _backOrExit,
                  onBack: _backOrExit,
                  affordance: _pauseAllowance.affordance,
                ),
              ),
              _ReflectiveStage.saved => _SavedView(
                totalMoments: _situations.length,
                key: ValueKey('reflective-saved-$_momentIndex'),
                momentNumber: _momentIndex + 1,
              ),
              _ReflectiveStage.results => _ResultsView(
                key: const ValueKey('reflective-results'),
                session: _session,
                onBack: _back,
                onInsights: () => _setStage(_ReflectiveStage.insights),
              ),
              _ReflectiveStage.insights => ReflectivePauseInsightsView(
                key: const ValueKey('reflective-insights'),
                indicators: _session?.reflectivePauseIndicators,
                onBack: _back,
                onFinish: () => context.go(AppRoutes.games),
              ),
              _ReflectiveStage.error => _ErrorView(
                key: const ValueKey('reflective-error'),
                message: _errorMessage ?? 'An unexpected error occurred.',
                onBack: _back,
                onRetry: _startGame,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    this.title,
    this.onPause,
    this.affordance = GameMenuAffordance.pause,
    this.onDark = false,
  });

  final VoidCallback onBack;
  final String? title;
  final VoidCallback? onPause;

  /// Titre blanc, pour le plateau mauve.
  final bool onDark;

  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Back',
          // En jeu, le retour ouvre la pause, qui joue son propre son.
          onTap: onPause != null
              ? onBack
              : () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  onBack();
                },
        ),
        if (title != null) ...[
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onDark ? Colors.white : _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ] else
          const Spacer(),
        if (onPause != null)
          _SquareIconButton(
            icon: affordance.icon,
            tooltip: affordance.tooltip,
            onTap: onPause!,
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

class _CoverView extends StatelessWidget {
  const _CoverView({super.key, required this.onBack, required this.onStart});
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => GameWelcomePage(
    title: 'Reflective Pause',
    logoAsset: _logoAsset,
    mission: 'Prends un temps de recul avant de choisir ta réponse.',
    contextText:
        'Une situation te met sous pression. Accorde-toi une pause avant de choisir ta réaction.',
    journey: const ['Découvre', 'Attends', 'Réponds'],
    leading: _SquareIconButton(
      icon: Icons.chevron_left_rounded,
      tooltip: 'Back',
      onTap: onBack,
    ),
    startKey: const ValueKey('reflective-start-mission'),
    startLabel: 'Start mission',
    onStart: onStart,
  );
}

class _IntroView extends StatelessWidget {
  const _IntroView({super.key, required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _InfoPage(
      onBack: onBack,
      title: 'Train calm responses\nunder pressure',
      subtitle:
          'You will move through short moments that can trigger an immediate reaction.',
      icon: Icons.timer_outlined,
      items: const [
        ('Pause first', 'Give yourself one calm moment before acting.'),
        ('Choose naturally', 'Select the response that feels most like you.'),
        (
          'Notice patterns',
          'Your final indicators reveal your response habits.',
        ),
      ],
      buttonLabel: 'Continue',
      onButton: onContinue,
    );
  }
}

class _TutorialView extends StatelessWidget {
  const _TutorialView({super.key, required this.onBack, required this.onStart});

  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => ReflectivePauseTutorial(
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

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.buttonLabel,
    required this.onButton,
  });

  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<(String, String)> items;
  final String buttonLabel;
  final VoidCallback onButton;

  @override
  Widget build(BuildContext context) {
    // Aucun défilement : le contenu se réduit d'un bloc sur un écran court,
    // la barre du haut et le bouton restent à leur taille.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: _TopBar(onBack: onBack, title: 'Reflective Pause'),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: GameFitToScreen(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F2FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: _violet),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 27,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _InstructionCard(
                      number: index + 1,
                      title: items[index].$1,
                      description: items[index].$2,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: GamePrimaryButton(label: buttonLabel, onPressed: onButton),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _magenta,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.3,
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

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    super.key,
    required this.situation,
    required this.totalMoments,
    required this.shuffleSeed,
    required this.momentNumber,
    required this.elapsedMs,
    required this.thinkingTimeMs,
    required this.minimumReached,
    required this.selectedResponse,
    required this.onSelect,
    required this.onValidate,
    required this.onPause,
    required this.onBack,
    required this.affordance,
  });

  final ReflectivePauseSituation situation;
  final int totalMoments;
  final int shuffleSeed;
  final int momentNumber;
  final int elapsedMs;
  final int thinkingTimeMs;
  final bool minimumReached;
  final ReflectivePauseResponseType? selectedResponse;
  final ValueChanged<ReflectivePauseResponseType> onSelect;
  final VoidCallback onValidate;
  final VoidCallback onPause;
  final VoidCallback onBack;

  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;

  /// Secondes restantes du temps conseillé, qui ne court qu'après la
  /// réflexion — la même mesure que la barre.
  int get _recommendedSecondsLeft {
    final used = math.max(0, elapsedMs - thinkingTimeMs);
    final left = math.max(0, situation.responseDeadlineSec * 1000 - used);
    return (left / 1000).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final remainingMs = math.max(0, thinkingTimeMs - elapsedMs);
    final remainingSeconds = (remainingMs / 1000).ceil();
    final choices = situation.choicesInDisplayOrder(shuffleSeed);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(
            onBack: onBack,
            title: 'Moment $momentNumber / $totalMoments',
            onPause: onPause,
            affordance: affordance,
            onDark: true,
          ),
          const SizedBox(height: 12),
          // La barre suit le TEMPS CONSEILLÉ de la situation (13 à 20 s selon
          // la fiche). Elle reste pleine pendant la réflexion imposée, puis se
          // vide à partir du déverrouillage des réponses jusqu'à l'échéance. Le compteur « Moment n / N » reste affiché à part. Le
          // temps conseillé ne coupe rien — le document le donne comme
          // « recommandé », à valider par prétest.
          _RecommendedTimeBar(
            elapsedMs: math.max(0, elapsedMs - thinkingTimeMs),
            totalMs: situation.responseDeadlineSec * 1000,
          ),
          SizedBox(
            height: 22,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                // Décompte avec la barre : plein pendant la réflexion, puis
                // les secondes restantes du temps conseillé.
                'Temps conseillé : $_recommendedSecondsLeft s',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Plateau sur un seul écran. La carte de la situation prend la
          // hauteur de SON texte, sans espace vide ; les réponses récupèrent
          // tout le reste. La carte ne rétrécit que si son texte dépasse la
          // place laissée aux réponses à leur hauteur minimale.
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                const gap = 6.0;
                const minChoiceHeight = 44.0;
                const maxChoiceHeight = 76.0;
                final count = choices.length;
                final minChoicesHeight =
                    minChoiceHeight * count + gap * (count - 1);
                final situationBudget = math.max(
                  0.0,
                  box.maxHeight - minChoicesHeight - 12,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: situationBudget),
                      child: _SituationCard(
                        situation: situation,
                        // Le cadre vidéo n'apparaît que si les réponses
                        // gardent une hauteur confortable à côté.
                        height:
                            box.maxHeight -
                            (60.0 * count + gap * (count - 1)) -
                            12,
                        thinkingRemainingMs: minimumReached ? 0 : remainingMs,
                        thinkingTotalMs: thinkingTimeMs,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, area) {
                          final choiceHeight =
                              ((area.maxHeight - gap * (count - 1)) / count)
                                  .clamp(minChoiceHeight, maxChoiceHeight)
                                  .toDouble();
                          // Une seule taille de police pour les cinq
                          // réponses : celle à laquelle la plus longue tient
                          // dans son bouton.
                          final choiceFontSize = AutoFitText.fontSizeFor(
                            context,
                            texts: [for (final choice in choices) choice.text],
                            style: _ResponseCard.textStyle,
                            maxLines: 3,
                            minFontSize: 10,
                            textAlign: TextAlign.start,
                            constraints: BoxConstraints(
                              maxWidth: math.max(
                                0,
                                area.maxWidth - _ResponseCard.horizontalInset,
                              ),
                              maxHeight: math.max(
                                0,
                                choiceHeight - _ResponseCard.verticalInset,
                              ),
                            ),
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Ordre mélangé : dans la banque livrée, « A »
                              // est la réponse impulsive des soixante
                              // situations et « B » toujours « respirer ».
                              // Affichée telle quelle, la grille s'apprend en
                              // deux situations et se répond sans lire la
                              // scène.
                              for (var i = 0; i < count; i++) ...[
                                if (i > 0) const SizedBox(height: gap),
                                SizedBox(
                                  height: choiceHeight,
                                  child: _ResponseCard(
                                    // Clé sur la RÉACTION, pas sur la
                                    // position : l'ordre est mélangé à dessein.
                                    key: ValueKey(
                                      'reflective-choice-'
                                      '${choices[i].responseType.wire}',
                                    ),
                                    choice: choices[i],
                                    fontSize: choiceFontSize,
                                    enabled: minimumReached,
                                    selected:
                                        selectedResponse ==
                                        choices[i].responseType,
                                    onTap: () =>
                                        onSelect(choices[i].responseType),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Le compte à rebours de réflexion est affiché dans la carte de la
          // question ; le bouton reste inactif tant qu'il court.
          Semantics(
            liveRegion: true,
            label: minimumReached
                ? 'Response choices are now available'
                : '$remainingSeconds seconds before choices become available',
            child: GamePrimaryButton(
              label: 'Validate response',
              onPressed: minimumReached && selectedResponse != null
                  ? onValidate
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre du temps conseillé : se vide sur la durée recommandée de la fiche et
/// passe au rouge sur ses [_countdownSfxSeconds] dernières secondes, au rythme
/// du tic sonore.
class _RecommendedTimeBar extends StatelessWidget {
  const _RecommendedTimeBar({required this.elapsedMs, required this.totalMs});

  final int elapsedMs;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final remainingMs = math.max(0, totalMs - elapsedMs);
    final ratio = totalMs <= 0 ? 0.0 : remainingMs / totalMs;
    final seconds = (remainingMs / 1000).ceil();
    final urgent = seconds <= _countdownSfxSeconds;
    return Semantics(
      label: 'Temps conseillé restant : $seconds secondes',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          key: const ValueKey('reflective-time-bar'),
          value: ratio.clamp(0.0, 1.0),
          minHeight: 7,
          backgroundColor: Colors.white24,
          color: urgent ? const Color(0xFFFF5A5F) : _magenta,
        ),
      ),
    );
  }
}

/// Présentation d'une situation, selon son support.
///
/// Le client attend « selon le scénario, une vidéo OU un message écrit, puis
/// les choix de réaction écrits ». Les deux supports partagent le même cadre et
/// la même question, et ne diffèrent que par la façon dont la scène arrive.
///
/// ⚠️ Aujourd'hui, AUCUNE situation n'emprunte le chemin écrit : les soixante
/// fiches de la banque déclarent un support vidéo, y compris celles dont la
/// scène est un SMS — TR-001 est une notification lue à l'écran, spécifiée
/// comme une vidéo dont le prompt interdit de rendre le texte lisible.
///
/// Le chemin écrit est conservé parce que le client l'attend au cahier des
/// charges (« SMS, chat ou e-mail »), et qu'il suffira de fiches marquées
/// `WRITTEN` pour l'emprunter. Il lui manquera alors une chose que la banque ne
/// fournit pas : le texte littéral du message. On n'en invente aucun — une
/// phrase forgée ici changerait la situation que le psychologue a cotée.
class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.situation,
    required this.height,
    required this.thinkingRemainingMs,
    required this.thinkingTotalMs,
  });

  final ReflectivePauseSituation situation;

  /// Temps de réflexion restant avant que les réponses se déverrouillent ;
  /// 0 une fois écoulé, le compteur disparaît alors.
  final int thinkingRemainingMs;
  final int thinkingTotalMs;

  /// Hauteur que le plateau peut accorder à la carte : décide de la taille de
  /// l'emplacement vidéo, qui cède la place aux réponses sur un écran court.
  /// La carte elle-même épouse son contenu.
  final double height;

  bool get _written => situation.medium == ReflectivePauseMedium.written;

  @override
  Widget build(BuildContext context) {
    // L'emplacement vidéo n'est qu'un cadre d'attente : c'est lui qui rétrécit
    // d'abord, puis disparaît, avant que le texte de la scène ne soit réduit.
    final mediaHeight = (height - 300).clamp(0.0, 120.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GameFitToScreen(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _written
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.videocam_outlined,
                  size: 18,
                  color: _magenta,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _written ? 'Message reçu' : 'Scène en face à face',
                    style: const TextStyle(
                      color: _magenta,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Hauteur fixe : l'apparition puis la disparition du compteur
                // ne décale pas le texte de la carte.
                SizedBox(
                  height: 30,
                  child: thinkingRemainingMs > 0
                      ? _ThinkingCountdown(
                          remainingMs: thinkingRemainingMs,
                          totalMs: thinkingTotalMs,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              situation.context,
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (_written)
              _MessageBubble(text: situation.trigger)
            else
              _VideoPlaceholder(
                trigger: situation.trigger,
                mediaHeight: mediaHeight,
              ),
            const SizedBox(height: 12),
            Text(
              situation.question,
              style: const TextStyle(
                color: _ink,
                fontSize: 19,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit compteur des secondes de réflexion, dans la carte de la question.
///
/// Anneau qui se vide et nombre de secondes restantes : les réponses restent
/// verrouillées tant qu'il tourne.
class _ThinkingCountdown extends StatelessWidget {
  const _ThinkingCountdown({required this.remainingMs, required this.totalMs});

  final int remainingMs;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final seconds = (remainingMs / 1000).ceil();
    final ratio = totalMs <= 0 ? 0.0 : (remainingMs / totalMs).clamp(0.0, 1.0);
    return Semantics(
      liveRegion: true,
      label: '$seconds seconds before choices become available',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('reflective-thinking-countdown'),
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F7),
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
                backgroundColor: const Color(0x33D72C83),
                color: _magenta,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$seconds s',
              style: const TextStyle(
                color: _magenta,
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

/// Bulle de message, pour les situations qui arrivent par SMS, chat ou e-mail.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: _ink, fontSize: 16, height: 1.4),
      ),
    );
  }
}

/// Emplacement du média, tant que la banque vidéo n'est pas livrée.
///
/// Même parti pris que le radar émotionnel : l'emplacement est réservé et dit
/// franchement qu'il attend la scène, plutôt que de laisser croire à un média
/// cassé. Le texte de l'événement déclencheur tient lieu de scène en
/// attendant — sans lui, la situation serait injouable.
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.trigger, required this.mediaHeight});

  final String trigger;

  /// Hauteur du cadre ; sous 56 px il n'apporte plus rien et disparaît.
  final double mediaHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mediaHeight >= 56) ...[
          Semantics(
            label: 'Emplacement de la vidéo, non disponible',
            child: Container(
              width: double.infinity,
              height: mediaHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.movie_outlined, color: _muted, size: 30),
                    SizedBox(height: 8),
                    Text(
                      'Vidéo à venir',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          trigger,
          style: const TextStyle(color: _ink, fontSize: 16, height: 1.4),
        ),
      ],
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    super.key,
    required this.choice,
    required this.enabled,
    required this.selected,
    required this.onTap,
    this.fontSize,
  });

  final ReflectivePauseChoice choice;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  /// Taille commune imposée par le plateau.
  final double? fontSize;

  static const TextStyle textStyle = TextStyle(
    fontSize: 14.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  /// Largeur non disponible pour le texte : marges, bordure, espace et icône.
  static const double horizontalInset = 2 * (14 + 2) + 10 + 24;

  /// Hauteur non disponible pour le texte : marges et bordure.
  static const double verticalInset = 2 * (5 + 2);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: choice.text,
      child: Material(
        // Verrouillée : carte blanche voilée sur le fond mauve, lisible mais
        // manifestement inactive.
        color: selected
            ? const Color(0xFFFFF1F7)
            : enabled
            ? Colors.white
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: enabled
              ? () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? _magenta : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // La hauteur du bouton est fixée par le plateau : le texte
                // s'y ajuste (taille puis retour à la ligne) au lieu d'être
                // coupé.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AutoFitText(
                      choice.text,
                      maxLines: 3,
                      minFontSize: 10,
                      textAlign: TextAlign.start,
                      style: textStyle.copyWith(
                        color: enabled ? _ink : _muted,
                        fontSize: fontSize ?? textStyle.fontSize,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (selected)
                  const Icon(Icons.check_circle, color: _magenta)
                else if (enabled)
                  const Icon(Icons.circle_outlined, color: _border)
                else
                  const Icon(Icons.lock_outline_rounded, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({
    super.key,
    required this.momentNumber,
    required this.totalMoments,
  });

  final int momentNumber;
  final int totalMoments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Answer saved',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _green, size: 52),
            ),
            const SizedBox(height: 22),
            const Text(
              'Answer saved',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              momentNumber < totalMoments
                  ? 'Moving calmly to the next moment.'
                  : 'Your response pattern is ready.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Results preview » de Reflective Pause, d'après la maquette client.
///
/// Toutes les valeurs sont celles du barème serveur (/10, 3 + 4 + 3) : le
/// client ne recalcule rien. Seule la phrase de synthèse est choisie ici, selon
/// la bande d'interprétation du score (0–4, 5–7, 8–10).
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.session,
    required this.onBack,
    required this.onInsights,
  });

  final GameSession? session;
  final VoidCallback onBack;
  final VoidCallback onInsights;

  /// Bandes d'interprétation du barème, dans l'ordre.
  static const _bands = [
    (min: 0, max: 4, label: 'Strong impulsivity'),
    (min: 5, max: 7, label: 'Good stress management'),
    (min: 8, max: 10, label: 'Very good self-control'),
  ];

  @override
  Widget build(BuildContext context) {
    final score = session?.lastAttempt?.score;
    final indicators = session?.reflectivePauseIndicators;
    final raw = score?.rawPoints;
    final max = score?.maxPoints ?? 10;
    final level = indicators?.level ?? score?.level;
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
                  const SizedBox(height: 18),
                  const Text(
                    'Results preview',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ScoreCard(raw: raw, max: max, level: level),
                  const SizedBox(height: 22),
                  const Text(
                    'Indicators',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _IndicatorBar(
                    icon: Icons.timer_outlined,
                    label: 'Controlled reaction time',
                    value: indicators?.controlledReactionTimeScore ?? 0,
                    max: 3,
                    color: _magenta,
                  ),
                  _IndicatorBar(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'Non-impulsive responses',
                    value: indicators?.nonImpulsiveResponsesScore ?? 0,
                    max: 4,
                    color: _violet,
                  ),
                  _IndicatorBar(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Ability to step back',
                    value: indicators?.abilityToStepBackScore ?? 0,
                    max: 3,
                    color: _green,
                  ),
                  const SizedBox(height: 4),
                  _ScoreInterpretation(raw: raw, max: max),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: GamePrimaryButton(
            label: 'View learning insights',
            onPressed: onInsights,
          ),
        ),
      ],
    );
  }

  /// Bande du barème contenant [raw].
  static String? bandOf(int? raw) {
    if (raw == null) return null;
    for (final band in _bands) {
      if (raw >= band.min && raw <= band.max) return band.label;
    }
    return null;
  }

  /// Phrase de synthèse, choisie selon la bande du score.
  static String summaryOf(int? raw) {
    if (raw == null) {
      return 'Your answers are saved. The summary appears once the server has '
          'calculated your score.';
    }
    if (raw >= 8) {
      return 'You stayed calm across most pressure moments and avoided '
          'repeated impulsive reactions.';
    }
    if (raw >= 5) {
      return 'You mostly paused before reacting, with a few quick answers '
          'under pressure.';
    }
    return 'Pressure often pushed you to answer quickly. A short pause before '
        'responding helps regain control.';
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.raw, required this.max, required this.level});

  final int? raw;
  final int max;
  final String? level;

  @override
  Widget build(BuildContext context) {
    const scoreStyle = TextStyle(
      color: _ink,
      fontSize: 52,
      height: 1.05,
      fontWeight: FontWeight.w800,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F071433),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score',
            style: TextStyle(
              color: _muted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (raw == null)
            const Text('—', style: scoreStyle)
          else
            // Même entrée que les autres jeux : le score compte jusqu'à sa
            // valeur, et le tableau de score se tait à l'arrivée.
            AnimatedCountText(
              key: const ValueKey('reflective-result-score'),
              value: raw!,
              suffix: ' / $max',
              onCompleted: SoundService.instance.stopScoreboard,
              style: scoreStyle,
            ),
          if (level != null && level!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3FAF1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Level: $level',
                style: const TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _ResultsView.summaryOf(raw),
            style: const TextStyle(color: _muted, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _IndicatorBar extends StatelessWidget {
  const _IndicatorBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final target = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_format(value)} / ${_format(max)}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            // Les barres se remplissent au rythme du comptage du score.
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, fill, _) => LinearProgressIndicator(
                value: fill,
                minHeight: 9,
                backgroundColor: const Color(0xFFE8EDF5),
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _format(double value) => value == value.roundToDouble()
      ? '${value.toInt()}'
      : value.toStringAsFixed(1);
}

class _ScoreInterpretation extends StatelessWidget {
  const _ScoreInterpretation({required this.raw, required this.max});

  final int? raw;
  final int max;

  @override
  Widget build(BuildContext context) {
    final band = _ResultsView.bandOf(raw);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D071433),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score interpretation',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (band != null) '$raw / $max maps to $band.',
              for (final b in _ResultsView._bands)
                '${b.min}–${b.max}: ${b.label}',
            ].join('\n'),
            style: const TextStyle(color: _muted, fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Indicateurs serveur présentés selon leurs maxima validés, sans recalcul de score.
/// PROVISOIRE — à valider visuellement sur appareil (GAMES_MODULE, décision 72).
class ReflectivePauseInsightsView extends StatelessWidget {
  const ReflectivePauseInsightsView({
    super.key,
    required this.indicators,
    required this.onBack,
    required this.onFinish,
  });

  final ReflectivePauseIndicators? indicators;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final controlled = indicators?.controlledReactionTimeScore ?? 0;
    final nonImpulsive = indicators?.nonImpulsiveResponsesScore ?? 0;
    final stepBack = indicators?.abilityToStepBackScore ?? 0;
    final strongest = _strongestInsight(controlled, nonImpulsive, stepBack);
    final risk = (indicators?.impulsiveChoiceCount ?? 0) == 0
        ? 'You avoided impulsive answers across all pressure moments.'
        : 'Watch for moments where speed pushes you toward defensive answers.';
    final pressure = controlled >= 1.5
        ? 'You often paused before reacting, which supports better emotional control.'
        : 'A slightly longer pause can help you regain control under pressure.';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            children: [
              _TopBar(onBack: onBack, title: 'Learning insights'),
              const SizedBox(height: 28),
              if (indicators == null || indicators!.momentsPlayed == 0)
                const GamePanel(
                  child: Text(
                    'No insights available yet. Complete a session to see your profile.',
                  ),
                )
              else ...[
                GamePanel(
                  backgroundColor: _canvas,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Your regulation profile',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Each bar shows progress within its own criterion.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final metric in [
                        (
                          label: 'Controlled reaction time',
                          score: controlled,
                          max: ReflectivePauseConfig.controlledReactionMax,
                          color: _violet,
                          icon: Icons.pause_circle_outline_rounded,
                        ),
                        (
                          label: 'Non-impulsive responses',
                          score: nonImpulsive,
                          max: ReflectivePauseConfig.nonImpulsiveMax,
                          color: _green,
                          icon: Icons.chat_bubble_outline_rounded,
                        ),
                        (
                          label: 'Ability to step back',
                          score: stepBack,
                          max: ReflectivePauseConfig.stepBackMax,
                          color: _magenta,
                          icon: Icons.psychology_alt_outlined,
                        ),
                      ]) ...[
                        GameResultInsightMeter(
                          key: ValueKey('reflective-insight-${metric.label}'),
                          compact: false,
                          icon: metric.icon,
                          valueLabel:
                              '${metric.score == metric.score.roundToDouble() ? metric.score.toStringAsFixed(0) : metric.score.toStringAsFixed(1)} / ${metric.max}',
                          bar: GameResultInsightBar(
                            label: metric.label,
                            fraction: metric.score / metric.max,
                            color: metric.color,
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _InsightCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: _violet,
                  title: 'Strongest area',
                  description: strongest,
                ),
                const SizedBox(height: 20),
                _InsightCard(
                  icon: Icons.bolt_rounded,
                  iconColor: _magenta,
                  title: 'Impulsivity risk',
                  description:
                      '${indicators!.impulsiveChoiceCount} / ${indicators!.momentsPlayed} impulsive choices. $risk',
                ),
                const SizedBox(height: 20),
                _InsightCard(
                  icon: Icons.pause_circle_outline_rounded,
                  iconColor: _green,
                  title: 'Pressure pattern',
                  description: pressure,
                ),
                const SizedBox(height: 20),
              ],
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: _violet),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recommendation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Before responding, ask: Do I need to reply now, or do I need one moment to regulate first?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: GamePrimaryButton(label: 'Back to games', onPressed: onFinish),
        ),
      ],
    );
  }

  static String _strongestInsight(
    double controlled,
    double nonImpulsive,
    double stepBack,
  ) {
    final controlledRate = controlled / 3;
    final nonImpulsiveRate = nonImpulsive / 4;
    final stepBackRate = stepBack / 3;
    if (stepBackRate >= controlledRate && stepBackRate >= nonImpulsiveRate) {
      return 'Your strongest pattern is creating distance before reacting.';
    }
    if (nonImpulsiveRate >= controlledRate) {
      return 'Your strongest pattern is choosing deliberate responses under pressure.';
    }
    return 'Your strongest pattern is pausing before reacting.';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10071433),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}

class _ReflectiveRulesDialog extends StatelessWidget {
  const _ReflectiveRulesDialog();

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.white,
    child: SafeArea(
      child: GameContentFrame(
        child: ReflectivePauseTutorial(
          leading: _SquareIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).pop(),
          ),
          onComplete: () => Navigator.of(context).pop(),
          reviewing: true,
        ),
      ),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZennytLoadingView(onDark: true);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    super.key,
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _TopBar(onBack: onBack),
          const Spacer(),
          const Icon(Icons.error_outline_rounded, color: _magenta, size: 56),
          const SizedBox(height: 18),
          const Text(
            'Unable to continue',
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const Spacer(),
          GamePrimaryButton(label: 'Try again', onPressed: onRetry),
        ],
      ),
    );
  }
}
