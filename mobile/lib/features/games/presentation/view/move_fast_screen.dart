import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/config/move_fast_config.dart';
import '../../domain/entities/device_calibration.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/move_fast_metrics.dart';
import '../device_calibration_probe.dart';
import '../games_providers.dart';
import '../widgets/game_system_components.dart';

enum _MoveFastStage {
  intro,
  tutorialOrientation,
  tutorialMovement,
  gameplay,
  results,
  comparison,
}

enum _MoveFastRule { orientation, movement }

enum _MoveFastFeedback { none, correct, error }

enum _MoveFastInputMode { buttons, tactile }

class MoveFastScreen extends ConsumerStatefulWidget {
  const MoveFastScreen({super.key, @visibleForTesting this.seed});

  /// Graine RNG déterministe pour les tests — même rôle que sur
  /// `InvestigateScreen`. Sans elle, les avions tirés au hasard changent à
  /// chaque exécution et aucune capture de référence ne peut être comparée.
  final int? seed;

  @override
  ConsumerState<MoveFastScreen> createState() => _MoveFastScreenState();
}

class _MoveFastScreenState extends ConsumerState<MoveFastScreen> {
  // Condition de fin de session — LUE depuis MoveFastConfig (miroir backend),
  // jamais codée en dur ici. Le mode par défaut (FIXED_BUDGET) diverge de la
  // fiche (reach_max_multiplier) ; basculer = changer MoveFastConfig.sessionEndMode
  // (+ backend). Voir GAMES_MODULE.md.
  static const int _sessionSeconds = MoveFastConfig.sessionSeconds;
  // Les seuils de fin (target / maxResponses / multiplicateur) sont lus dans
  // MoveFastConfig via _reachedEndCondition — pas d'alias en dur ici.
  // Essais d'échauffement (warm-up) — miroir de MoveFastConfig.practiceTrialCount.
  // Les premiers essais sont marqués practiceTrial=true et exclus par le backend
  // du scoring et des statistiques (fiche révisée, Tableau 2).
  static const int _practiceTrialCount = MoveFastConfig.practiceTrialCount;
  /// Dernières secondes : barre rouge + tic sonore à chaque seconde.
  static const int _urgentSeconds = 10;
  /// Temps d'affichage de 00:00 avant la bascule vers le tableau de score.
  static const Duration _timeUpHold = Duration(milliseconds: 1400);

  late final math.Random _random = math.Random(widget.seed);
  final Stopwatch _reactionWatch = Stopwatch();
  Timer? _timer;

  _MoveFastStage _stage = _MoveFastStage.intro;
  _MoveFastRule _rule = _MoveFastRule.orientation;
  _MoveFastInputMode _inputMode = _MoveFastInputMode.buttons;
  _MoveFastFeedback _feedback = _MoveFastFeedback.none;
  _MoveFastStimulus _stimulus = _MoveFastStimulus.demoOrientation;

  bool _paused = false;
  /// Consigne du mode tactile encore à l'écran (maquette « Gameplay Waiting »).
  ///
  /// Passe à false à la PREMIÈRE réponse donnée au tactile, et le plateau se
  /// retrouve nu comme dans « 04C Gameplay – Tactile Mode ». Repasse à true si
  /// le joueur revient au tactile depuis le mode boutons : la consigne se
  /// re-présente à chaque entrée dans le mode, pas une seule fois par partie.
  bool _tactilePromptVisible = true;
  // Niveau unique à règle aléatoire : la règle est imprévisible dès le départ.
  bool _randomRule = false;
  int _secondsLeft = _sessionSeconds;
  int _score = 0;
  int _multiplier = 1;
  int _totalResponses = 0;
  int _correctResponses = 0;
  int _wrongResponses = 0;
  int _streakCounter = 0;
  int _completedSeriesStreak = 0;
  int _bestSeriesStreak = 0;
  // Plus longue suite de bonnes réponses consécutives — ce que « Best streak »
  // annonce au joueur. `_bestSeriesStreak`, lui, compte des SÉRIES DE 4 achevées :
  // il affichait 0 après 3 bonnes réponses d'affilée et restait à 1 après 7, parce
  // qu'il n'est mis à jour qu'au franchissement d'un palier. D'où le chiffre faux.
  int _correctStreak = 0;
  int _bestCorrectStreak = 0;
  int _reactionTotalMs = 0;
  /// Chrono à 00:00 : les entrées sont gelées le temps que le joueur voie zéro.
  bool _timeExpired = false;
  bool _resultSubmitted = false;
  bool _submittingResult = false;
  Future<GameSession>? _sessionStart;
  GameSession? _serverSession;
  GameDirection? _chosenDirection;
  GameDirection? _correctDirection;
  // Essais mesurés dans l'ordre de jeu (échauffement inclus, marqué practiceTrial).
  // Le score et les indicateurs de flexibilité sont calculés côté serveur.
  final List<MoveFastResponse> _responses = [];
  // Règle de l'essai précédent, pour détecter les bascules (isSwitchTrial) et
  // les erreurs persévératives (appliedOldRule).
  _MoveFastRule? _previousTrialRule;
  // Socle de calibrage appareil (Tâche 4) : mesure la latence machine hors
  // échauffement ; le calibrage n'affecte QUE les indicateurs corrigés serveur.
  final DeviceCalibrationProbe _calibrationProbe = DeviceCalibrationProbe();

  @override
  void initState() {
    super.initState();
    _stimulus = _buildStimulus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTutorials() {
    setState(() {
      _stage = _MoveFastStage.tutorialOrientation;
      _rule = _MoveFastRule.orientation;
      _feedback = _MoveFastFeedback.none;
      _stimulus = const _MoveFastStimulus(
        noseDirection: GameDirection.right,
        movementDirection: GameDirection.left,
      );
    });
  }

  void _startGameplay() {
    _timer?.cancel();
    setState(() {
      _stage = _MoveFastStage.gameplay;
      // Niveau unique : la règle (et sa couleur vert/jaune) change de façon
      // imprévisible dès le premier avion — plus de progression par paliers.
      _randomRule = true;
      _rule = _nextRandomRule();
      _feedback = _MoveFastFeedback.none;
      _secondsLeft = _sessionSeconds;
      _score = 0;
      _multiplier = 1;
      _totalResponses = 0;
      _correctResponses = 0;
      _wrongResponses = 0;
      _streakCounter = 0;
      _completedSeriesStreak = 0;
      _bestSeriesStreak = 0;
      _bestCorrectStreak = 0;
      _correctStreak = 0;
      _timeExpired = false;
      _reactionTotalMs = 0;
      _resultSubmitted = false;
      _submittingResult = false;
      _serverSession = null;
      _responses.clear();
      _previousTrialRule = null;
      _calibrationProbe.reset();
      _chosenDirection = null;
      _correctDirection = null;
      _stimulus = _buildStimulus();
    });
    _sessionStart = ref
        .read(gamesRepositoryProvider)
        .startSession(GameType.moveFast);
    _startTimer();
    _startReactionTimer();
    // Le tout premier avion annonce sa règle, comme tous les suivants.
    _playActiveRuleSfx();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused || _stage != _MoveFastStage.gameplay) return;
      // La limite de temps ne s'applique qu'en mode budget fixe. En mode
      // REACH_MAX_MULTIPLIER (fiche), aucune limite de durée.
      if (MoveFastConfig.sessionEndMode != MoveFastSessionEndMode.fixedBudget) {
        return;
      }
      if (_secondsLeft <= 0) return; // 00:00 atteint : _expireSession pilote

      setState(() => _secondsLeft--);

      if (_secondsLeft == 0) {
        _expireSession();
        return;
      }
      // Tic sonore de chaque dernière seconde, synchronisé avec la barre rouge.
      if (_secondsLeft <= _urgentSeconds) {
        SoundService.instance.playSfx(GameSfx.timerDecrease);
      }
    });
  }

  /// Temps écoulé — 00:00 doit être VU avant la bascule.
  ///
  /// L'ancienne boucle terminait la session dès `_secondsLeft <= 1`, donc le
  /// chrono passait de 00:01 au tableau de score sans jamais afficher zéro. On
  /// laisse désormais le compteur atteindre 00:00, on joue le son de fin, on gèle
  /// les entrées, puis on bascule après [_timeUpHold].
  void _expireSession() {
    _timer?.cancel();
    _reactionWatch.stop();
    SoundService.instance.playSfx(GameSfx.timerEnd);
    setState(() {
      _timeExpired = true;
      _feedback = _MoveFastFeedback.none;
      _chosenDirection = null;
      _correctDirection = null;
    });
    Timer(_timeUpHold, () {
      if (mounted && _stage == _MoveFastStage.gameplay) _finishSession();
    });
  }

  /// Condition de fin atteinte selon le mode configuré (aucune valeur en dur).
  bool get _reachedEndCondition {
    switch (MoveFastConfig.sessionEndMode) {
      case MoveFastSessionEndMode.fixedBudget:
        return _correctResponses >= MoveFastConfig.targetCorrectAnswers ||
            _totalResponses >= MoveFastConfig.maxResponses;
      case MoveFastSessionEndMode.reachMaxMultiplier:
        return _multiplier >= MoveFastConfig.maxMultiplier;
    }
  }

  /// Progression de la barre HUD selon le mode (temps restant / montée du multiplicateur).
  double get _sessionProgress {
    switch (MoveFastConfig.sessionEndMode) {
      case MoveFastSessionEndMode.fixedBudget:
        return _secondsLeft / MoveFastConfig.sessionSeconds;
      case MoveFastSessionEndMode.reachMaxMultiplier:
        return (_multiplier / MoveFastConfig.maxMultiplier).clamp(0.0, 1.0);
    }
  }

  void _startReactionTimer() {
    _reactionWatch
      ..reset()
      ..start();
  }

  void _finishSession() {
    if (_stage == _MoveFastStage.results ||
        _stage == _MoveFastStage.comparison) {
      return;
    }
    _timer?.cancel();
    _reactionWatch.stop();
    if (!mounted) return;
    setState(() {
      _stage = _MoveFastStage.results;
      _feedback = _MoveFastFeedback.none;
      _chosenDirection = null;
      _correctDirection = null;
    });
    SoundService.instance.playScoreboard();
    unawaited(_submitMoveFastResult());
  }

  Future<void> _submitMoveFastResult() async {
    // On n'envoie que s'il existe au moins un essai NOTÉ (hors échauffement).
    final scoredCount = _responses.where((r) => !r.practiceTrial).length;
    if (_resultSubmitted || scoredCount == 0) return;
    _resultSubmitted = true;
    setState(() => _submittingResult = true);

    final practiceExcluded = _responses.where((r) => r.practiceTrial).length;

    try {
      final session = await (_sessionStart ??= ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.moveFast));
      final calibration = _calibrationProbe.build(
        inputMode: _inputMode == _MoveFastInputMode.tactile
            ? InputMode.swipe
            : InputMode.touch,
      );
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.moveFastCore,
            metrics: MoveFastMetrics(
              practiceTrialExcludedCount: practiceExcluded,
              responses: List<MoveFastResponse>.unmodifiable(_responses),
            ),
            deviceCalibration: calibration,
          );
      if (!mounted) return;
      setState(() => _serverSession = updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Résultat non synchronisé : $error')),
      );
    } finally {
      if (mounted) setState(() => _submittingResult = false);
    }
  }

  _MoveFastStimulus _buildStimulus() {
    final directions = GameDirection.values;
    final nose = directions[_random.nextInt(directions.length)];
    var movement = directions[_random.nextInt(directions.length)];
    if (_random.nextBool()) {
      while (movement == nose) {
        movement = directions[_random.nextInt(directions.length)];
      }
    }
    return _MoveFastStimulus(noseDirection: nose, movementDirection: movement);
  }

  void _handleDirection(GameDirection direction) {
    if (_feedback != _MoveFastFeedback.none) return;
    // Chrono à 00:00 : la partie est finie, on n'enregistre plus rien.
    if (_timeExpired) return;

    // Première réponse au doigt : la consigne a fait son office, le plateau se
    // découvre. Placé avant tout `return` de tutoriel pour que la consigne
    // s'efface aussi quand on apprend à jouer au tactile.
    if (_inputMode == _MoveFastInputMode.tactile && _tactilePromptVisible) {
      setState(() => _tactilePromptVisible = false);
    }

    // Les deux écrans de règles attendent une réponse comme le jeu : ils
    // doivent sonner comme lui. Ils sortaient en silence, si bien que le tout
    // premier geste du joueur — celui qui lui apprend la mécanique — était le
    // seul sans retour sonore.
    if (_stage == _MoveFastStage.tutorialOrientation ||
        _stage == _MoveFastStage.tutorialMovement) {
      SoundService.instance.playSfx(
        direction == GameDirection.right
            ? GameSfx.correctChoice
            : GameSfx.wrongChoice,
      );
    }

    if (_stage == _MoveFastStage.tutorialOrientation) {
      if (direction == GameDirection.right) {
        setState(() {
          _stage = _MoveFastStage.tutorialMovement;
          _rule = _MoveFastRule.movement;
          _feedback = _MoveFastFeedback.none;
          _stimulus = const _MoveFastStimulus(
            noseDirection: GameDirection.up,
            movementDirection: GameDirection.right,
          );
        });
      } else {
        _showShortMessage('Suis le nez de l’avion: droite.');
      }
      return;
    }

    if (_stage == _MoveFastStage.tutorialMovement) {
      if (direction == GameDirection.right) {
        _startGameplay();
      } else {
        _showShortMessage('Ici la règle est Mouvement: droite.');
      }
      return;
    }

    if (_stage != _MoveFastStage.gameplay) return;

    _reactionWatch.stop();
    final correct = _expectedDirection;
    final isCorrect = direction == correct;
    final reactionMs = _reactionWatch.elapsedMilliseconds;
    SoundService.instance.playSfx(
      isCorrect ? GameSfx.correctChoice : GameSfx.wrongChoice,
    );

    // Métriques de flexibilité cognitive (calcul serveur — on ne fait que mesurer).
    final currentRule = _rule;
    final isPractice = _responses.length < _practiceTrialCount;
    final isSwitchTrial =
        _previousTrialRule != null && _previousTrialRule != currentRule;
    // Erreur persévérative : sur une erreur, la direction choisie correspond à
    // celle qu'imposait l'ancienne règle (application de la règle précédente).
    final oldRuleDirection = _previousTrialRule == null
        ? null
        : (_previousTrialRule == _MoveFastRule.orientation
              ? _stimulus.noseDirection
              : _stimulus.movementDirection);
    final appliedOldRule =
        !isCorrect && oldRuleDirection != null && direction == oldRuleDirection;

    setState(() {
      _chosenDirection = direction;
      _correctDirection = correct;
      _feedback = isCorrect
          ? _MoveFastFeedback.correct
          : _MoveFastFeedback.error;
      _totalResponses++;
      _reactionTotalMs += reactionMs;
      _responses.add(
        MoveFastResponse(
          practiceTrial: isPractice,
          correct: isCorrect,
          reactionTimeMs: reactionMs,
          ruleActive: currentRule == _MoveFastRule.orientation
              ? MoveFastRule.orientation
              : MoveFastRule.movement,
          isSwitchTrial: isSwitchTrial,
          appliedOldRule: appliedOldRule,
        ),
      );
      _previousTrialRule = currentRule;

      if (isCorrect) {
        _correctResponses++;
        _correctStreak++;
        _bestCorrectStreak = math.max(_bestCorrectStreak, _correctStreak);
        _streakCounter = math.min(
          MoveFastConfig.correctStreakForUpgrade,
          _streakCounter + 1,
        );
        _score += 50 * _multiplier;
        if (_streakCounter == MoveFastConfig.correctStreakForUpgrade) {
          _completedSeriesStreak++;
          _bestSeriesStreak = math.max(
            _bestSeriesStreak,
            _completedSeriesStreak,
          );
          _streakCounter = 0;
          _multiplier = math.min(
            MoveFastConfig.maxMultiplier,
            _multiplier + 1,
          );
          // Le multiplicateur grimpe : son dédié « increase-multiplier ».
          SoundService.instance.playSfx(GameSfx.increaseMultiplier);
        }
      } else {
        _wrongResponses++;
        _correctStreak = 0;
        if (_streakCounter > 0) {
          // Une série en cours est brisée : son « reset-counter ».
          _streakCounter = 0;
          SoundService.instance.playSfx(GameSfx.resetCounter);
        } else {
          _multiplier = math.max(1, _multiplier - 1);
        }
        _completedSeriesStreak = 0;
      }
    });

    // Latence machine mesurée UNIQUEMENT hors échauffement (calibrage technique).
    if (!isPractice) {
      _calibrationProbe.sampleInputLatency();
    }

    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || _stage != _MoveFastStage.gameplay) return;
      if (_reachedEndCondition) {
        _finishSession();
        return;
      }
      setState(() {
        _feedback = _MoveFastFeedback.none;
        _chosenDirection = null;
        _correctDirection = null;
        // Niveau unique : la règle change de façon imprévisible à chaque avion.
        if (_randomRule) _rule = _nextRandomRule();
        _stimulus = _buildStimulus();
        _playActiveRuleSfx();
      });
      _startReactionTimer();
    });
  }

  /// Retour sonore du nouvel avion — **jamais silencieux**.
  ///
  /// L'ancienne version ne jouait un son que si le nez ou la trajectoire avait
  /// changé. Or le tirage peut reproduire le même couple nez/trajectoire alors
  /// que la RÈGLE a basculé : le joueur voyait la couleur changer sans aucun son,
  /// ce qui rendait le retour audio erratique. Chaque nouvel essai a désormais
  /// son son, dans cet ordre de priorité.
  /// Retour sonore du nouvel avion — **toujours celui de la règle active**.
  ///
  /// L'implémentation précédente choisissait le son d'après ce qui avait changé
  /// À L'IMAGE (nez tourné → son d'orientation, trajectoire modifiée → son de
  /// mouvement), et retombait sur un son neutre quand le tirage reproduisait le
  /// même avion. Deux conséquences : le son pouvait annoncer « orientation »
  /// alors que la règle active était « mouvement », et le premier avion d'une
  /// manche était muet (aucun stimulus précédent à comparer).
  ///
  /// Les deux SFX portent le nom des deux RÈGLES : ils doivent donc dire au
  /// joueur quelle règle appliquer, pas ce qui a bougé à l'écran.
  void _playActiveRuleSfx() {
    SoundService.instance.playSfx(
      _rule == _MoveFastRule.orientation
          ? GameSfx.planeOrientationChange
          : GameSfx.planeMovementChange,
    );
  }

  /// Choisit la prochaine règle en mode aléatoire : bascule le plus souvent
  /// (2 fois sur 3) mais garde parfois la même pour rester imprévisible.
  _MoveFastRule _nextRandomRule() {
    if (_random.nextInt(3) == 0) return _rule;
    return _rule == _MoveFastRule.orientation
        ? _MoveFastRule.movement
        : _MoveFastRule.orientation;
  }

  Future<void> _openPause() async {
    if (_stage != _MoveFastStage.gameplay) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    _timer?.cancel();
    _reactionWatch.stop();
    setState(() => _paused = true);

    final action = await showDialog<GamePauseAction>(
      context: context,
      barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
      builder: (context) {
        var mode = _inputMode;
        return StatefulBuilder(
          builder: (context, setLocal) => GamePauseScaffold(
            inputMode: GamePauseInputModeToggle(
              buttonsSelected: mode == _MoveFastInputMode.buttons,
              onChanged: (buttons) {
                setLocal(() => mode = buttons
                    ? _MoveFastInputMode.buttons
                    : _MoveFastInputMode.tactile);
                _inputMode = mode;
                // Entrer (ou revenir) dans le tactile re-présente la consigne :
                // le joueur qui change de mode en cours de partie doit revoir
                // comment on joue au doigt.
                if (mode == _MoveFastInputMode.tactile) {
                  _tactilePromptVisible = true;
                }
              },
            ),
            buttons: [
              GamePrimaryButton(
                label: 'Resume',
                onPressed: () =>
                    Navigator.of(context).pop(GamePauseAction.resume),
              ),
              GameOutlineButton(
                label: 'View rules / Help',
                onPressed: () =>
                    Navigator.of(context).pop(GamePauseAction.help),
              ),
              GamePauseExitButton(
                label: 'Exit mission',
                onPressed: () =>
                    Navigator.of(context).pop(GamePauseAction.exit),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == GamePauseAction.exit) {
      context.pop();
      return;
    }
    if (action == GamePauseAction.help) {
      await _showRulesHelp();
    }

    if (!mounted) return;
    setState(() => _paused = false);
    if (_stage == _MoveFastStage.gameplay) {
      _startTimer();
      _startReactionTimer();
    }
  }

  Future<void> _showRulesHelp() {
    return showDialog<void>(
      context: context,
      barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
      builder: (context) => const _RulesDialog(),
    );
  }

  void _showShortMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  GameDirection get _expectedDirection {
    return _rule == _MoveFastRule.orientation
        ? _stimulus.noseDirection
        : _stimulus.movementDirection;
  }

  Color get _ruleColor {
    return _rule == _MoveFastRule.orientation
        ? ZennytGamePalette.success
        : ZennytGamePalette.ruleOrange;
  }

  Color get _planeColor => _ruleColor;

  String get _ruleLabel {
    return _rule == _MoveFastRule.orientation ? 'Orientation' : 'Movement';
  }

  double get _accuracy {
    if (_totalResponses == 0) return 0;
    return _correctResponses / _totalResponses;
  }

  int get _cognitiveScore {
    final serverScore = _serverSession?.lastAttempt?.score.normalized.round();
    if (serverScore != null) return serverScore;
    final accuracyScore = (_accuracy * 72).round();
    final streakScore = math.min(18, _bestSeriesStreak * 9);
    final speedScore = _averageReactionMs <= 850 ? 10 : 6;
    return math.min(100, accuracyScore + streakScore + speedScore);
  }

  int get _averageReactionMs {
    if (_totalResponses == 0) return 0;
    return (_reactionTotalMs / _totalResponses).round();
  }

  String get _timeLabel {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _stage == _MoveFastStage.intro ||
          _stage == _MoveFastStage.results ||
          _stage == _MoveFastStage.comparison,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage != _MoveFastStage.intro) {
          setState(() => _stage = _MoveFastStage.intro);
        }
      },
      child: Scaffold(
        backgroundColor: _stage == _MoveFastStage.gameplay
            ? ZennytGamePalette.gameBlue
            : Colors.white,
        body: SafeArea(child: _buildStage()),
      ),
    );
  }

  Widget _buildStage() {
    return switch (_stage) {
      _MoveFastStage.intro => _IntroView(onStart: _startTutorials),
      _MoveFastStage.tutorialOrientation => _TutorialView(
        title: 'Rule 1',
        chip: 'Orientation',
        chipColor: ZennytGamePalette.success,
        heading: 'Watch the nose',
        body: 'Watch the nose cue, then choose the matching arrow.',
        stimulus: const _MoveFastStimulus(
          noseDirection: GameDirection.right,
          movementDirection: GameDirection.left,
        ),
        planeColor: ZennytGamePalette.magenta,
        cueLabel: 'Cue',
        correctDirection: GameDirection.right,
        onDirection: _handleDirection,
        onBack: () => setState(() => _stage = _MoveFastStage.intro),
      ),
      _MoveFastStage.tutorialMovement => _TutorialView(
        title: 'Rule 2',
        chip: 'Movement',
        chipColor: ZennytGamePalette.ruleOrange,
        heading: 'Follow the movement',
        body: 'The nose points up, but the motion cue goes right.',
        stimulus: const _MoveFastStimulus(
          noseDirection: GameDirection.up,
          movementDirection: GameDirection.right,
        ),
        planeColor: ZennytGamePalette.ruleOrange,
        cueLabel: 'Motion cue',
        correctDirection: GameDirection.right,
        showMovement: true,
        onDirection: _handleDirection,
        onBack: () =>
            setState(() => _stage = _MoveFastStage.tutorialOrientation),
      ),
      _MoveFastStage.gameplay => GameplayMusic(child: _GameplayView(
        score: _score,
        timeLabel: _timeLabel,
        progress: _sessionProgress,
        ruleLabel: _ruleLabel,
        ruleColor: _ruleColor,
        stimulus: _stimulus,
        planeColor: _planeColor,
        feedback: _feedback,
        chosenDirection: _chosenDirection,
        correctDirection: _correctDirection,
        streakCounter: _streakCounter,
        multiplier: _multiplier,
        inputMode: _inputMode,
        tactilePromptVisible: _tactilePromptVisible,
        paused: _paused,
        timeCritical:
            MoveFastConfig.sessionEndMode ==
                MoveFastSessionEndMode.fixedBudget &&
            _secondsLeft <= _urgentSeconds,
        onPause: _openPause,
        onDirection: _handleDirection,
      )),
      _MoveFastStage.results => _ResultsView(
        cognitiveScore: _cognitiveScore,
        rawScore: _serverSession?.lastAttempt?.score.rawPoints,
        resultPending: _submittingResult,
        accuracy: _accuracy,
        averageReactionMs: _averageReactionMs,
        bestCorrectStreak: _bestCorrectStreak,
        onReplay: _startGameplay,
        onCompare: () => setState(() => _stage = _MoveFastStage.comparison),
        onBack: () => context.go(AppRoutes.games),
      ),
      _MoveFastStage.comparison => _ComparisonView(
        bestCorrectStreak: _bestCorrectStreak,
        scoreDelta: math.max(
          4,
          ((_serverSession?.lastAttempt?.score.rawPoints ?? _score) ~/ 25) -
              _wrongResponses,
        ),
        onReplay: _startGameplay,
        onBack: () => setState(() => _stage = _MoveFastStage.results),
      ),
    };
  }
}

class _MoveFastStimulus {
  const _MoveFastStimulus({
    required this.noseDirection,
    required this.movementDirection,
  });

  static const demoOrientation = _MoveFastStimulus(
    noseDirection: GameDirection.right,
    movementDirection: GameDirection.down,
  );

  final GameDirection noseDirection;
  final GameDirection movementDirection;
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBackButton(onPressed: () => context.go(AppRoutes.games)),
          const SizedBox(height: AppSpacing.base),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            // Les largeurs de cette bannière étaient figées (chip 170, sous-titre
            // 210, avion 162) alors que l'avion est posé en absolu par-dessus :
            // sur un écran de 320 px la carte n'offre plus que ~240 px, l'avion
            // en mangeait 154 et le titre passait DESSOUS. On dimensionne donc
            // l'avion et la colonne de texte à partir de la largeur réelle.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final planeSize = (width * 0.52).clamp(96.0, 162.0);
                // L'avion a des marges transparentes : le texte peut empiéter
                // un peu sur son cadre sans jamais toucher le dessin.
                final textWidth = math.max(120.0, width - planeSize * 0.72);
                final haloSize = planeSize * 1.09;

                return Stack(
                  children: [
                    Positioned(
                      right: -22,
                      top: 22,
                      child: Container(
                        width: haloSize,
                        height: haloSize,
                        decoration: BoxDecoration(
                          color: ZennytGamePalette.cyan.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          // 170 px suffisent à « Cognitive Flexibility » quand
                          // la police a sa taille pleine ; sur un écran étroit
                          // le texte y était tronqué, alors que la carte offre
                          // la place — on lui donne toute la largeur.
                          width: width < 340 ? width : 170,
                          child: const GameRuleChip(
                            label: 'Cognitive Flexibility',
                            color: Colors.white,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: textWidth,
                          child: Text(
                            'Move\nFast',
                            style: AppTypography.displayLarge.copyWith(
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        SizedBox(
                          width: textWidth,
                          child: Text(
                            'Rules change. Respond fast. Keep the right cue.',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                    Positioned(
                      right: -8,
                      top: 48,
                      child: MoveFastPlane(
                        noseDirection: GameDirection.down,
                        color: ZennytGamePalette.magenta,
                        size: planeSize,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(
                child: ResultStatTile(label: 'Goal', value: 'Flexibility'),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Duration',
                  value: '8-10 min',
                  valueColor: ZennytGamePalette.magenta,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(label: 'Format', value: 'Mobile'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePanel(
            borderColor: ZennytGamePalette.gameBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simple rule',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'The plane color tells you which rule is active: Orientation or Movement.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          GamePrimaryButton(label: 'Start', onPressed: onStart),
        ],
      ),
    );
  }
}

class _TutorialView extends StatelessWidget {
  const _TutorialView({
    required this.title,
    required this.chip,
    required this.chipColor,
    required this.heading,
    required this.body,
    required this.stimulus,
    required this.planeColor,
    required this.cueLabel,
    required this.correctDirection,
    required this.onDirection,
    required this.onBack,
    this.showMovement = false,
  });

  final String title;
  final String chip;
  final Color chipColor;
  final String heading;
  final String body;
  final _MoveFastStimulus stimulus;
  final Color planeColor;
  final String cueLabel;
  final GameDirection correctDirection;
  final ValueChanged<GameDirection> onDirection;
  final VoidCallback onBack;
  final bool showMovement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      child: Column(
        children: [
          Row(
            children: [
              _TopBackButton(onPressed: onBack),
              const Spacer(),
            ],
          ),
          Text(
            title,
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GameRuleChip(label: chip, color: chipColor),
          const SizedBox(height: AppSpacing.base),
          Expanded(
            child: GamePanel(
              backgroundColor: ZennytGamePalette.mist,
              child: Column(
                children: [
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineLarge.copyWith(
                      color: ZennytGamePalette.blue,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  if (showMovement)
                    _MovementCue(
                      stimulus: stimulus,
                      planeColor: planeColor,
                      label: cueLabel,
                    )
                  else
                    _OrientationCue(
                      stimulus: stimulus,
                      planeColor: planeColor,
                      label: cueLabel,
                    ),
                  const Spacer(),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: ZennytGamePalette.muted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GameDirectionControls(
            onDirection: onDirection,
            correctDirection: correctDirection,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _OrientationCue extends StatelessWidget {
  const _OrientationCue({
    required this.stimulus,
    required this.planeColor,
    required this.label,
  });

  final _MoveFastStimulus stimulus;
  final Color planeColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MoveFastPlane(
          noseDirection: stimulus.noseDirection,
          color: planeColor,
          size: 110,
          opacity: 0.9,
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: ZennytGamePalette.border),
          ),
          child: Text(
            label,
            style: AppTypography.titleSmall.copyWith(
              color: ZennytGamePalette.magenta,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementCue extends StatelessWidget {
  const _MovementCue({
    required this.stimulus,
    required this.planeColor,
    required this.label,
  });

  final _MoveFastStimulus stimulus;
  final Color planeColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MoveFastPlane(
              noseDirection: stimulus.noseDirection,
              color: planeColor,
              size: 92,
            ),
            const SizedBox(width: AppSpacing.base),
            Icon(
              stimulus.movementDirection.icon,
              size: 50,
              color: ZennytGamePalette.magenta,
            ),
            const SizedBox(width: AppSpacing.base),
            MoveFastPlane(
              noseDirection: stimulus.noseDirection,
              color: planeColor,
              size: 92,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nose: ${stimulus.noseDirection.label}',
              style: AppTypography.labelMedium.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: ZennytGamePalette.magenta,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    required this.score,
    required this.timeLabel,
    required this.progress,
    required this.ruleLabel,
    required this.ruleColor,
    required this.stimulus,
    required this.planeColor,
    required this.feedback,
    required this.chosenDirection,
    required this.correctDirection,
    required this.streakCounter,
    required this.multiplier,
    required this.inputMode,
    required this.tactilePromptVisible,
    required this.paused,
    required this.timeCritical,
    required this.onPause,
    required this.onDirection,
  });

  final int score;
  final String timeLabel;
  final double progress;
  final String ruleLabel;
  final Color ruleColor;
  final _MoveFastStimulus stimulus;
  final Color planeColor;
  final _MoveFastFeedback feedback;
  final GameDirection? chosenDirection;
  final GameDirection? correctDirection;
  final int streakCounter;
  final int multiplier;
  final _MoveFastInputMode inputMode;

  /// Consigne tactile encore visible (voir `_tactilePromptVisible`).
  final bool tactilePromptVisible;

  /// Menu pause ouvert : gèle le défilement des avions.
  final bool paused;

  /// Dix dernières secondes : barre rouge, en écho au tic sonore.
  final bool timeCritical;
  final VoidCallback onPause;
  final ValueChanged<GameDirection> onDirection;

  @override
  Widget build(BuildContext context) {
    final isFeedback = feedback != _MoveFastFeedback.none;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        children: [
          GameHud(
            score: score,
            timeLabel: timeLabel,
            progress: progress,
            // Le rouge des dernières secondes prime sur le rouge d'erreur :
            // c'est l'information la plus urgente à ce moment-là.
            progressColor:
                timeCritical || feedback == _MoveFastFeedback.error
                ? ZennytGamePalette.error
                : ZennytGamePalette.success,
            onPause: onPause,
          ),
          const SizedBox(height: AppSpacing.base),
          GameRuleChip(label: ruleLabel, color: ruleColor),
          const SizedBox(height: AppSpacing.md),
          // Le plateau des avions occupe presque tout l'écran ; les flèches sont
          // superposées PAR-DESSUS à ~35% d'opacité (elles restent tactiles :
          // Opacity ne bloque pas les événements de pointeur).
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _GameplayBoard(
                    stimulus: stimulus,
                    planeColor: planeColor,
                    feedback: feedback,
                    ruleColor: ruleColor,
                    streakCounter: streakCounter,
                    multiplier: multiplier,
                    inputMode: inputMode,
                    tactilePromptVisible: tactilePromptVisible,
                    paused: paused,
                    onDirection: isFeedback ? null : onDirection,
                  ),
                ),
                if (inputMode == _MoveFastInputMode.buttons)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.sm,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: 0.35,
                          child: GameDirectionControls(
                            onDirection: onDirection,
                            enabled: !isFeedback,
                            correctDirection:
                                feedback == _MoveFastFeedback.correct
                                ? correctDirection
                                : null,
                            wrongDirection: feedback == _MoveFastFeedback.error
                                ? chosenDirection
                                : null,
                            compact: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // La consigne vit SOUS la croix directionnelle. Elle était
                        // auparavant dessinée par le plateau à la même hauteur que
                        // les flèches, donc superposée à elles. Pleine opacité
                        // (contrairement aux flèches) et corps réduit.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            'Observe the plane. Apply the active rule.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
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

class _GameplayBoard extends StatelessWidget {
  const _GameplayBoard({
    required this.stimulus,
    required this.planeColor,
    required this.feedback,
    required this.ruleColor,
    required this.streakCounter,
    required this.multiplier,
    required this.inputMode,
    required this.tactilePromptVisible,
    required this.paused,
    required this.onDirection,
  });

  final _MoveFastStimulus stimulus;
  final Color planeColor;
  final _MoveFastFeedback feedback;
  final Color ruleColor;
  final int streakCounter;
  final int multiplier;
  final _MoveFastInputMode inputMode;
  final bool tactilePromptVisible;
  final bool paused;
  final ValueChanged<GameDirection>? onDirection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: onDirection == null
              ? null
              : (details) {
                  final v = details.velocity.pixelsPerSecond;
                  if (v.distance < 180) return;
                  onDirection!(_directionFromDelta(v.dx, v.dy));
                },
          onTapDown:
              inputMode == _MoveFastInputMode.tactile && onDirection != null
              ? (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final center = box.size.center(Offset.zero);
                  final local = box.globalToLocal(details.globalPosition);
                  final delta = local - center;
                  if (delta.distance < 32) return;
                  onDirection!(_directionFromDelta(delta.dx, delta.dy));
                }
              : null,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ZennytGamePalette.gamePanel,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  // Marges resserrées et symétriques : chaque pixel gagné va aux
                  // pastilles, qui sont l'élément que la maquette agrandit.
                  left: 16,
                  right: 16,
                  child: SeriesRibbon(
                    current: streakCounter,
                    multiplier: multiplier,
                    color: ruleColor,
                    // Maquette : le compteur au-dessus, sa légende en dessous.
                    // « upgrade » nomme ce que la série déclenche — la montée du
                    // multiplicateur.
                    statusValue: feedback == _MoveFastFeedback.error
                        ? '0/4'
                        : '$streakCounter/4',
                    statusCaption: feedback == _MoveFastFeedback.error
                        ? 'reset'
                        : 'upgrade',
                  ),
                ),
                Positioned.fill(
                  // Sous le bandeau : 10 (marge haute) + 64 (hauteur du bandeau,
                  // portée de 48 à la taille de la maquette) + 12 de respiration.
                  top: 86,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _PlaneCluster(
                      paused: paused,
                      key: ValueKey(
                        '${stimulus.noseDirection}-${stimulus.movementDirection}-$planeColor',
                      ),
                      stimulus: stimulus,
                      planeColor: planeColor,
                    ),
                  ),
                ),
                // En mode boutons, la consigne est rendue par _GameplayView SOUS
                // la croix directionnelle — la dessiner ici la superposerait aux
                // flèches.
                // Consigne tactile : présente tant que le joueur n'a pas
                // répondu au doigt, puis le plateau se découvre.
                if (inputMode == _MoveFastInputMode.tactile &&
                    tactilePromptVisible)
                  const Positioned.fill(child: _TactileOverlay()),
                if (feedback != _MoveFastFeedback.none)
                  Positioned(
                    top: 78,
                    right: 24,
                    child: _FeedbackBurst(feedback: feedback),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  GameDirection _directionFromDelta(double dx, double dy) {
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? GameDirection.right : GameDirection.left;
    }
    return dy > 0 ? GameDirection.down : GameDirection.up;
  }
}

class _PlaneCluster extends StatelessWidget {
  const _PlaneCluster({
    super.key,
    required this.stimulus,
    required this.planeColor,
    required this.paused,
  });

  final _MoveFastStimulus stimulus;
  final Color planeColor;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    // Chaque avion occupe une « voie » (position sur l'axe transverse) avec un
    // décalage de phase pour un défilement échelonné et continu.
    const lanes = <({double cross, double size, double phase})>[
      (cross: -0.64, size: 120, phase: 0.0),
      (cross: 0.56, size: 110, phase: 0.34),
      (cross: -0.05, size: 122, phase: 0.67),
    ];
    // Animation d'apparition : bascule 3D sur les axes X et Z (500 ms) rejouée
    // à chaque nouveau stimulus (le cluster est recréé par l'AnimatedSwitcher),
    // en plus du changement de couleur de la règle.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // perspective
            ..rotateX((1 - t) * (math.pi / 2))
            ..rotateZ((1 - t) * 0.35),
          child: child,
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (final lane in lanes)
                _ScrollingPlane(
                  paused: paused,
                  stimulus: stimulus,
                  color: planeColor,
                  size: lane.size,
                  cross: lane.cross,
                  phase: lane.phase,
                  board: constraints.biggest,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Avion qui défile en continu dans la direction du mouvement, en boucle : il
/// sort par un bord du plateau et réapparaît par le bord opposé (le plateau
/// clippe le débordement). Remplace l'ancienne animation d'entrée unique.
class _ScrollingPlane extends StatefulWidget {
  const _ScrollingPlane({
    required this.stimulus,
    required this.color,
    required this.size,
    required this.cross,
    required this.phase,
    required this.board,
    required this.paused,
  });

  final _MoveFastStimulus stimulus;
  final Color color;
  final double size;
  final double cross; // position sur l'axe transverse, fraction [-1, 1]
  final double phase; // décalage de départ dans la boucle [0, 1)
  final Size board;

  /// Menu pause ouvert : le défilement doit s'arrêter net (time scale = 0).
  final bool paused;

  @override
  State<_ScrollingPlane> createState() => _ScrollingPlaneState();
}

class _ScrollingPlaneState extends State<_ScrollingPlane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    if (!widget.paused) _controller.repeat();
  }

  @override
  void didUpdateWidget(_ScrollingPlane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Le menu pause doit VRAIMENT figer le jeu : le compte à rebours était
    // déjà gelé, mais les avions continuaient de défiler derrière la carte.
    // On stoppe la boucle sur place (`stop`, pas `reset`) pour qu'elle
    // reprenne exactement où elle en était.
    if (widget.paused == oldWidget.paused) return;
    if (widget.paused) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isVertical =>
      widget.stimulus.movementDirection == GameDirection.up ||
      widget.stimulus.movementDirection == GameDirection.down;

  bool get _isForward =>
      widget.stimulus.movementDirection == GameDirection.down ||
      widget.stimulus.movementDirection == GameDirection.right;

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    if (board.isEmpty) return const SizedBox.shrink();

    final s = widget.size;
    final axisLen = _isVertical ? board.height : board.width;
    final crossLen = _isVertical ? board.width : board.height;
    final travel = axisLen + s; // départ hors-champ → arrivée hors-champ
    final crossPx = (widget.cross + 1) / 2 * (crossLen - s);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value + widget.phase) % 1.0;
        final u = _isForward ? t : (1 - t);
        final alongPx = -s + u * travel;
        // Fondu léger aux extrémités pour lisser l'apparition/disparition.
        final edge = (u < 0.08) ? u / 0.08 : (u > 0.92 ? (1 - u) / 0.08 : 1.0);
        return Positioned(
          left: _isVertical ? crossPx : alongPx,
          top: _isVertical ? alongPx : crossPx,
          child: Opacity(opacity: edge.clamp(0, 1), child: child),
        );
      },
      child: MoveFastPlane(
        noseDirection: widget.stimulus.noseDirection,
        color: widget.color,
        size: s,
      ),
    );
  }
}

/// Amorce du mode tactile — maquette « 04B Gameplay Waiting – Tactile ».
///
/// Les quatre flèches et le libellé « Tactile mode » ne sont qu'une CONSIGNE :
/// ils se montrent tant que le joueur n'a pas encore répondu au tactile, puis
/// s'effacent pour laisser le plateau nu de la planche « 04C Gameplay – Tactile
/// Mode ». Auparavant l'overlay restait affiché toute la partie et les flèches
/// se superposaient en permanence aux avions.
class _TactileOverlay extends StatelessWidget {
  const _TactileOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 84, 20, 20),
        // Colonne — et non un Stack unique : la flèche « bas » et le bloc de
        // texte visaient tous deux `bottomCenter`/`bottomLeft` et se
        // chevauchaient. Le texte réserve d'abord sa place, les flèches se
        // répartissent dans ce qui reste.
        child: Column(
          children: [
            const Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: _TactileHint(direction: GameDirection.up),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _TactileHint(direction: GameDirection.left),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _TactileHint(direction: GameDirection.right),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _TactileHint(direction: GameDirection.down),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tactile mode',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Swipe in the direction you deduce from the active rule.',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      letterSpacing: 0,
                      height: 1.35,
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

/// Repère directionnel du mode tactile : une flèche dans un disque translucide,
/// placée du côté qu'elle désigne.
class _TactileHint extends StatelessWidget {
  const _TactileHint({required this.direction});

  final GameDirection direction;

  @override
  Widget build(BuildContext context) {
    // Flèche nue, sans pastille ni cercle : la maquette « 04B Gameplay Waiting »
    // ne montre que les quatre flèches sur le plateau. Le disque translucide
    // ajoutait un bouton là où il n'y a rien à toucher — l'entrée tactile se
    // fait n'importe où, par rapport au centre.
    return SizedBox(
      width: 52,
      height: 52,
      child: Icon(
        direction.icon,
        color: Colors.white.withValues(alpha: 0.92),
        size: 30,
      ),
    );
  }
}

class _FeedbackBurst extends StatelessWidget {
  const _FeedbackBurst({required this.feedback});

  final _MoveFastFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final correct = feedback == _MoveFastFeedback.correct;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      tween: Tween(begin: 0.85, end: 1),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color:
                  (correct
                          ? ZennytGamePalette.success
                          : ZennytGamePalette.error)
                      .withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    (correct
                            ? ZennytGamePalette.success
                            : ZennytGamePalette.error)
                        .withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            correct ? 'Correct' : 'Incorrect\nWrong direction',
            textAlign: TextAlign.right,
            style: AppTypography.titleMedium.copyWith(
              color: correct
                  ? ZennytGamePalette.success
                  : ZennytGamePalette.error,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.cognitiveScore,
    required this.rawScore,
    required this.resultPending,
    required this.accuracy,
    required this.averageReactionMs,
    required this.bestCorrectStreak,
    required this.onReplay,
    required this.onCompare,
    required this.onBack,
  });

  final int cognitiveScore;
  final int? rawScore;
  final bool resultPending;
  final double accuracy;
  final int averageReactionMs;
  final int bestCorrectStreak;
  final VoidCallback onReplay;
  final VoidCallback onCompare;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final reaction = (averageReactionMs / 1000).toStringAsFixed(2);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _TopBackButton(onPressed: onBack),
          ),
          Text(
            'Results',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          Text(
            resultPending ? 'Synchronizing score...' : 'Move Fast completed',
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
                  value: cognitiveScore,
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
                      ? (cognitiveScore >= 80
                            ? 'Fast adaptation to rule changes.'
                            : 'Good progress. Keep practicing rule switches.')
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
                  label: 'Accuracy',
                  value: '${(accuracy * 100).round()}%',
                  valueColor: ZennytGamePalette.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(label: 'Reaction', value: '${reaction}s'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Best Streak',
                  value: '$bestCorrectStreak correct',
                  valueColor: ZennytGamePalette.magenta,
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
                  'The player keeps the active rule in mind and quickly adjusts attention when the instruction changes.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: GamePrimaryButton(label: 'Replay', onPressed: onReplay),
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

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({
    required this.bestCorrectStreak,
    required this.scoreDelta,
    required this.onReplay,
    required this.onBack,
  });

  final int bestCorrectStreak;
  final int scoreDelta;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBackButton(onPressed: onBack),
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
                  'Ranking data required from platform',
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
                  '#12',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 48,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'in your professional network',
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
              const ResultStatTile(
                label: 'My network',
                value: '#12 / 148',
                valueColor: ZennytGamePalette.blue,
              ),
              const ResultStatTile(
                label: 'Global',
                value: '#1,284',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Previous attempt',
                value: '+$scoreDelta pts',
                valueColor: ZennytGamePalette.blue,
              ),
              ResultStatTile(
                label: 'Best streak',
                value: '$bestCorrectStreak correct',
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
                  'Last attempts show faster adaptation and longer completed-series streaks.',
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

class _TopBackButton extends StatelessWidget {
  const _TopBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: 'Retour',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: ZennytGamePalette.blue,
          side: const BorderSide(color: ZennytGamePalette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: const Icon(Icons.chevron_left),
      ),
    );
  }
}

/// Dialogue « Règles » — deux règles codées par couleur (Orientation / Mouvement)
/// avec icône, badge et description, plus un bouton primaire « Compris ».
class _RulesDialog extends StatelessWidget {
  const _RulesDialog();

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
                    Icons.menu_book_rounded,
                    color: ZennytGamePalette.gameBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Règles du jeu',
                    style: AppTypography.titleLarge.copyWith(
                      color: ZennytGamePalette.ink,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _RuleCard(
              color: ZennytGamePalette.success,
              icon: Icons.navigation_rounded,
              badge: 'Orientation',
              title: 'Barre verte',
              description: 'Réponds à la direction du nez de l\'avion.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _RuleCard(
              color: ZennytGamePalette.ruleOrange,
              icon: Icons.open_with_rounded,
              badge: 'Mouvement',
              title: 'Barre orange',
              description: 'Réponds à la direction du déplacement.',
            ),
            const SizedBox(height: AppSpacing.xl),
            GamePrimaryButton(
              label: 'Compris',
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

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.color,
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String badge;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: ZennytGamePalette.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
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
