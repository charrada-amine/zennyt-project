import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import '../../domain/entities/game_runtime_snapshot.dart';
import '../../domain/config/game_presentation_timing.dart';
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

  /// Échéance de l'essai en cours (cf. [MoveFastConfig.trialTimeoutMs]).
  Timer? _trialTimer;

  /// Passage à l'avion suivant, 650 ms après le retour visuel de l'essai.
  Timer? _advanceTimer;

  /// Attente de la fin de l'acrobatie, avant d'ouvrir la fenêtre de réponse.
  Timer? _settleTimer;

  /// La fenêtre de réponse est-elle ouverte ?
  ///
  /// Fausse tant que la formation manœuvre : la direction n'est pas encore
  /// lisible, et une réponse donnée là serait une anticipation, pas une
  /// réaction. Le chronomètre ne tourne pas non plus.
  bool _responseOpen = false;

  /// Numéro du prochain essai — voir [_MoveFastStimulus.serial].
  int _trialSerial = 0;

  _MoveFastStage _stage = _MoveFastStage.intro;
  _MoveFastRule _rule = _MoveFastRule.orientation;
  _MoveFastInputMode _inputMode = _MoveFastInputMode.buttons;
  _MoveFastFeedback _feedback = _MoveFastFeedback.none;
  _MoveFastStimulus _stimulus = _MoveFastStimulus.demoOrientation;

  bool _paused = false;

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

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
    _trialTimer?.cancel();
    _advanceTimer?.cancel();
    _settleTimer?.cancel();
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

  bool _starting = false;
  Future<void> _startGameplay() async {
    if (_starting) return;
    _starting = true;
    try {
      _sessionStart = ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.moveFast);
      final session = await _sessionStart!;
      if (!mounted) return;
      _serverSession = session;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Partie indisponible : $error')));
      }
      return;
    } finally {
      _starting = false;
    }
    _timer?.cancel();
    _trialTimer?.cancel();
    _advanceTimer?.cancel();
    _settleTimer?.cancel();
    // Nouvelle partie = nouveau droit de pause. Rejouer n'est pas une reprise.
    _pauseAllowance.reset();
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
      _responses.clear();
      _previousTrialRule = null;
      _calibrationProbe.reset();
      _chosenDirection = null;
      _correctDirection = null;
      // Remis à zéro AVANT le tirage : le premier avion d'une partie ne pivote
      // pas — il n'a aucune direction précédente à quitter. Sans cela il
      // hériterait de celle tirée au montage de l'écran, jamais montrée.
      _trialSerial = 0;
      _stimulus = _buildStimulus();
    });
    // Start clocks only after availability and runtime snapshot are confirmed.
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
    _trialTimer?.cancel();
    _advanceTimer?.cancel();
    _settleTimer?.cancel();
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

  /// Ouvre la fenêtre de réponse — mais seulement une fois la formation posée.
  ///
  /// Retour client : « ajuste pour avoir toujours 2 000 ms pour répondre ; si
  /// l'animation prend de ce temps, ajuste ça ». L'acrobatie occupe
  /// [MoveFastPlane.formationSettle] : la faire courir sur l'échéance revenait
  /// à n'en laisser que 800 ms au joueur. Et pour la mesure, c'était pire — le
  /// temps de réaction de CHAQUE essai se trouvait gonflé de la durée de
  /// l'animation, donc incomparable au barème du serveur.
  ///
  /// Le chronomètre de réaction part donc au même instant que l'échéance : à la
  /// seconde où le dernier avion de la vague se pose. Avant cela, la direction
  /// n'est pas encore lisible et l'écran n'accepte rien — c'est la même règle
  /// que pendant les 650 ms de retour visuel.
  /// Attente avant l'ouverture, pour l'essai en cours.
  ///
  /// Le tout premier avion d'une partie ne manœuvre pas : il n'a aucune
  /// direction précédente à quitter, seul son élan d'entrée se joue. Lui
  /// imposer l'attente d'une acrobatie qui n'a pas lieu ferait patienter le
  /// joueur devant un plateau déjà immobile.
  Duration get _settleDelay => MoveFastPlane.formationSettle(
    _MoveFastStimulus.maxLanes,
    manoeuvring: _stimulus.previousNoseDirection != null,
  );

  void _startReactionTimer() {
    _settleTimer?.cancel();
    _trialTimer?.cancel();
    _reactionWatch
      ..reset()
      ..stop();
    setState(() => _responseOpen = false);
    _settleTimer = Timer(_settleDelay, () {
      if (!mounted || _paused || _timeExpired) return;
      if (_stage != _MoveFastStage.gameplay) return;
      setState(() => _responseOpen = true);
      _reactionWatch
        ..reset()
        ..start();
      _armTrialDeadline();
    });
  }

  /// Arme l'échéance de réponse de l'essai en cours.
  ///
  /// Retour client : « changement toutes les 2 000 ms — si le joueur ne choisit
  /// pas, la couleur change automatiquement, il sera pénalisé comme si le
  /// niveau était faux ».
  ///
  /// Appelée par [_startReactionTimer], donc exactement là où le chrono de
  /// réaction repart : à chaque nouvel avion ET à la reprise après pause. Le
  /// menu de pause ne consomme donc pas l'échéance — c'est la même garantie que
  /// pour le chrono de session.
  void _armTrialDeadline() {
    _trialTimer?.cancel();
    if (_stage != _MoveFastStage.gameplay || _timeExpired) return;
    _trialTimer = Timer(
      const Duration(milliseconds: MoveFastConfig.trialTimeoutMs),
      _handleTrialTimeout,
    );
  }

  /// Personne n'a répondu dans le temps imparti : l'essai est perdu.
  void _handleTrialTimeout() {
    if (!mounted || _paused || _timeExpired) return;
    if (_stage != _MoveFastStage.gameplay) return;
    // Une réponse vient d'arriver et son retour est encore à l'écran : ce n'est
    // pas un essai manqué.
    if (_feedback != _MoveFastFeedback.none) return;
    _registerTrial(direction: null, reactionMs: MoveFastConfig.trialTimeoutMs);
  }

  void _finishSession() {
    if (_stage == _MoveFastStage.results ||
        _stage == _MoveFastStage.comparison) {
      return;
    }
    _timer?.cancel();
    _trialTimer?.cancel();
    _advanceTimer?.cancel();
    _settleTimer?.cancel();
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
    return _MoveFastStimulus(
      noseDirection: nose,
      movementDirection: movement,
      lanes: _buildLanes(),
      serial: ++_trialSerial,
      // Au tout premier avion de la partie il n'y a pas de virage à jouer : le
      // `_trialSerial` vient d'être incrémenté, il vaut donc 1 ici.
      previousNoseDirection: _trialSerial == 1 ? null : _stimulus.noseDirection,
    );
  }

  /// Formation d'avions d'un essai.
  ///
  /// Retour client : « réduire la taille des avions et en afficher plusieurs à
  /// la fois : entre 4, 5 et 6 — le nombre varie aléatoirement pour avoir
  /// plusieurs scénarios, pas le même qui se répète ». Le plateau, lui, ne
  /// grandit pas : plus il y a d'avions, plus ils sont petits.
  ///
  /// Tout passe par [_random], la graine des tests : sans cela une capture de
  /// référence ne pourrait plus jamais être recomparée.
  List<_PlaneLane> _buildLanes() {
    final count = 4 + _random.nextInt(3); // 4, 5 ou 6
    final base = switch (count) {
      4 => 88.0,
      5 => 80.0,
      _ => 72.0,
    };
    final slot = 2 / count; // largeur d'une voie sur l'axe transverse [-1, 1]
    return [
      for (var i = 0; i < count; i++)
        _PlaneLane(
          // Les voies utilisées sont RÉPARTIES sur les six, pas prises dans
          // l'ordre : une formation de 4 occupe les voies 0, 2, 3 et 5 et
          // couvre donc toute la boucle de défilement. Prendre les quatre
          // premières laisserait un tiers du plateau désert.
          //
          // La phase découle de la voie et n'est jamais tirée au sort. Les
          // avions ne sont plus détruits d'un essai à l'autre, ils glissent de
          // leur ancienne trajectoire vers la nouvelle : une phase retirée au
          // sort ferait reculer un avion sur son axe de vol, ce qu'un avion ne
          // fait pas. Fixée par la voie, elle laisse le vol continu tant que la
          // règle de mouvement ne change pas — et c'est alors le CHANGEMENT de
          // règle qui se voit, au lieu d'un tremblement à chaque essai.
          slot: (i * _MoveFastStimulus.maxLanes / count).round(),
          // Une voie par avion sur l'axe transverse, plus un flottement qui
          // casse l'alignement parfait sans laisser deux avions se recouvrir.
          cross:
              (-1 +
                      slot * (i + 0.5) +
                      (_random.nextDouble() - 0.5) * slot * 0.5)
                  .clamp(-1.0, 1.0),
          // Taille NETTE, sans tirage aléatoire.
          //
          // Chaque avion recevait un facteur aléatoire de ±14 %, retiré à chaque
          // essai. La formation changeait donc de proportions en permanence, y
          // compris pour les avions qui ne quittaient pas leur voie : elle
          // « respirait » sans que rien ne le justifie. La taille ne varie plus
          // qu'avec le NOMBRE d'avions, ce qui est la seule variation qui ait un
          // sens — le plateau ne grandit pas quand la formation s'étoffe.
          size: base,
        ),
    ];
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

    // La formation manœuvre encore : la direction n'est pas lisible, et le
    // chronomètre n'a pas démarré. On ignore, comme pendant le retour visuel —
    // le joueur n'est pas pénalisé, il n'a simplement rien à lire encore.
    if (!_responseOpen) return;

    _reactionWatch.stop();
    _registerTrial(
      direction: direction,
      reactionMs: _reactionWatch.elapsedMilliseconds,
    );
  }

  /// Clôt l'essai en cours, l'enregistre, puis enchaîne sur le suivant.
  ///
  /// [direction] vaut `null` quand personne n'a répondu dans les
  /// [MoveFastConfig.trialTimeoutMs] impartis. L'essai est alors compté FAUX,
  /// exactement comme une mauvaise flèche : `direction == correct` est faux,
  /// et le retour visuel montre quand même la bonne réponse — sans cela le
  /// candidat serait sanctionné sans jamais savoir de quoi.
  void _registerTrial({
    required GameDirection? direction,
    required int reactionMs,
  }) {
    _trialTimer?.cancel();
    _reactionWatch.stop();
    final correct = _expectedDirection;
    final isCorrect = direction == correct;
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
          _multiplier = math.min(MoveFastConfig.maxMultiplier, _multiplier + 1);
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

    // Minuterie NOMMÉE, et non un `Future.delayed` anonyme : celui-ci survivait
    // au démontage de l'écran, faute de prise pour l'annuler.
    _advanceTimer?.cancel();
    final timing = GamePresentationTiming(
      _serverSession?.runtime ?? const GameRuntimeSnapshot(),
    );
    _advanceTimer = Timer(Duration(milliseconds: timing.responseFeedbackMs), () {
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

  /// Bouton unique du HUD : menu de pause tant que la fenêtre est ouverte,
  /// confirmation de sortie ensuite. Voir [GameMenuAffordance].
  Future<void> _openMenu() async {
    if (_stage != _MoveFastStage.gameplay) return;
    if (_pauseAllowance.canOpen) return _openPause();
    await _confirmExit();
  }

  /// Sortie volontaire après consommation de la fenêtre.
  ///
  /// Le jeu n'est PAS mis en pause : la fenêtre est consommée, geler le temps
  /// ici la rendrait renouvelable en boucle par simple ouverture de la boîte.
  /// Le candidat qui renonce retrouve donc sa partie là où elle en est.
  Future<void> _confirmExit() async {
    if (await GameExitConfirmDialog.show(context)) {
      if (mounted) context.pop();
    }
  }

  Future<void> _openPause() async {
    if (_stage != _MoveFastStage.gameplay) return;
    // Fenêtre déjà consommée : plus aucune pause volontaire jusqu'à la fin de
    // la partie. Le bouton propose alors « Exit mission » — cette garde couvre
    // les autres chemins (retour système, tests).
    if (!_pauseAllowance.canOpen) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    _timer?.cancel();
    _trialTimer?.cancel();
    _advanceTimer?.cancel();
    _settleTimer?.cancel();
    _reactionWatch.stop();
    _pauseAllowance.open();
    setState(() => _paused = true);
    await _showPauseMenu();
  }

  /// Affiche le menu (et le réaffiche au retour des règles) sur le **temps
  /// restant** de la fenêtre, jamais sur 30 s fraîches.
  Future<void> _showPauseMenu() async {
    final action = await showDialog<GamePauseAction>(
      context: context,
      barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
      builder: (context) {
        var mode = _inputMode;
        return StatefulBuilder(
          builder: (context, setLocal) => GamePauseScaffold(
            countdown: _pauseAllowance.remaining,
            onCountdownExpired: () =>
                Navigator.of(context).pop(GamePauseAction.resume),
            inputMode: GamePauseInputModeToggle(
              buttonsSelected: mode == _MoveFastInputMode.buttons,
              onChanged: (buttons) {
                setLocal(
                  () => mode = buttons
                      ? _MoveFastInputMode.buttons
                      : _MoveFastInputMode.tactile,
                );
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
      // Sortir annule la tentative : on le dit avant, pas après.
      if (await GameExitConfirmDialog.show(context)) {
        if (mounted) context.pop();
        return;
      }
      if (!mounted) return;
      // Refus de sortir : on revient au menu s'il reste du temps, sinon la
      // partie reprend directement.
      if (_pauseAllowance.canReopen) return _showPauseMenu();
    } else if (action == GamePauseAction.help) {
      await _showRulesHelp();
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _showPauseMenu();
    }

    if (!mounted) return;
    // La partie repart : le temps passé en pause rejoint le budget consommé.
    // Tant qu'il en reste, le bouton propose de nouveau la pause.
    _pauseAllowance.close();
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
      _MoveFastStage.gameplay => GameplayMusic(
        child: _GameplayView(
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
          onPause: _openMenu,
          affordance: _pauseAllowance.affordance,
          onDirection: _handleDirection,
        ),
      ),
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

/// Une voie de vol : un avion, sa position sur l'axe transverse du plateau, sa
/// taille et son décalage de phase dans la boucle de défilement.
class _PlaneLane {
  const _PlaneLane({
    required this.slot,
    required this.cross,
    required this.size,
  });

  /// Voie du plateau occupée, dans `[0, _MoveFastStimulus.maxLanes[`.
  ///
  /// C'est l'identité de l'avion d'un essai à l'autre : le plateau tient ses
  /// voies montées en permanence et retrouve la sienne par ce numéro.
  final int slot;

  final double cross; // position transverse, fraction [-1, 1]
  final double size; // côté de l'avion en px

  /// Décalage de départ dans la boucle de défilement, dans `[0, 1[`.
  ///
  /// Déduit de la voie, jamais tiré au sort : voir `_buildLanes`.
  double get phase => slot / _MoveFastStimulus.maxLanes;
}

class _MoveFastStimulus {
  const _MoveFastStimulus({
    required this.noseDirection,
    required this.movementDirection,
    this.lanes = demoLanes,
    this.serial = 0,
    this.previousNoseDirection,
  });

  /// Nombre de voies que le plateau tient prêtes.
  ///
  /// Le plateau monte TOUJOURS ce nombre d'avions, quitte à en garder certains
  /// transparents : un essai à 4 avions n'en détruit pas deux, il les efface.
  /// C'est ce qui permet de n'avoir plus aucune apparition ni disparition
  /// pendant la partie — tout changement est un fondu, pas un remplacement.
  static const int maxLanes = 6;

  /// Formation de repli — tutoriels et premier montage, avant tout tirage.
  static const demoLanes = <_PlaneLane>[
    _PlaneLane(slot: 0, cross: -0.75, size: 84),
    _PlaneLane(slot: 2, cross: -0.25, size: 76),
    _PlaneLane(slot: 3, cross: 0.25, size: 88),
    _PlaneLane(slot: 5, cross: 0.75, size: 78),
  ];

  static const demoOrientation = _MoveFastStimulus(
    noseDirection: GameDirection.right,
    movementDirection: GameDirection.down,
  );

  final GameDirection noseDirection;
  final GameDirection movementDirection;

  /// Formation d'avions de CET essai — tirée au sort à chaque nouvel avion.
  final List<_PlaneLane> lanes;

  /// Numéro d'essai. Deux tirages identiques (même nez, même trajectoire, même
  /// règle) restent deux essais distincts : sans ce numéro, l'`AnimatedSwitcher`
  /// reconnaîtrait l'ancienne clé et ne rejouerait aucune animation d'entrée.
  final int serial;

  /// Direction du nez à l'essai PRÉCÉDENT — l'avion pivote depuis celle-ci.
  ///
  /// Elle voyage avec le stimulus parce que les avions sont reconstruits à
  /// chaque essai : sans mémoire du virage à faire, le nouvel avion se poserait
  /// déjà tourné et il n'y aurait rien à animer. Nulle au tout premier essai.
  final GameDirection? previousNoseDirection;
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
                  // Annoncé au candidat = budget réel de la session
                  // (`MoveFastConfig.sessionSeconds`), pas une estimation.
                  value: '15 min',
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
    required this.affordance,
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

  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;
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
            progressColor: timeCritical || feedback == _MoveFastFeedback.error
                ? ZennytGamePalette.error
                : ZennytGamePalette.success,
            onPause: onPause,
            affordance: affordance,
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
                    // Le seuil vient de la config, il n'est plus recopié ici :
                    // deux littéraux « 4 » pouvaient diverger en silence.
                    statusValue: feedback == _MoveFastFeedback.error
                        ? '0/${MoveFastConfig.correctStreakForUpgrade}'
                        : '$streakCounter/'
                              '${MoveFastConfig.correctStreakForUpgrade}',
                    statusCaption: feedback == _MoveFastFeedback.error
                        ? 'reset'
                        : 'upgrade',
                  ),
                ),
                Positioned.fill(
                  // Sous le bandeau : 10 (marge haute) + 64 (hauteur du bandeau,
                  // portée de 48 à la taille de la maquette) + 12 de respiration.
                  top: 86,
                  // Plus d'`AnimatedSwitcher` ici.
                  //
                  // Retour client : « quand je change de couleur ou de règle de
                  // mouvement, il ne faut pas une apparition rapide comme une
                  // transition très rapide — ce sera une animation complète qui
                  // contient le changement de couleur ». Le fondu croisé de
                  // 220 ms remplaçait TOUTE la formation : deux escadrilles se
                  // superposaient un court instant, l'ancienne s'effaçait, la
                  // nouvelle surgissait. C'est précisément la « transition très
                  // rapide » décrite.
                  //
                  // Les avions vivent maintenant d'un essai à l'autre : ce sont
                  // les MÊMES qui virent, changent de couleur et rejoignent leur
                  // nouvelle trajectoire, en une seule figure continue.
                  child: _PlaneCluster(
                    paused: paused,
                    stimulus: stimulus,
                    planeColor: planeColor,
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
    // décalage de phase pour un défilement échelonné et continu. La formation
    // est tirée au sort par l'écran, essai par essai : 4 à 6 avions, plus petits
    // qu'avant — cf. `_MoveFastScreenState._buildLanes`.
    final lanes = {for (final lane in stimulus.lanes) lane.slot: lane};
    // Plus aucune animation d'APPARITION de la formation.
    //
    // Il y en avait deux, successivement rejetées par le client : une bascule
    // 3D de 90° sur l'axe X (qui écrasait l'escadrille jusqu'à l'épaisseur d'un
    // trait), puis un fondu croisé de 220 ms entre l'ancienne formation et la
    // nouvelle. Toutes deux REMPLAÇAIENT les avions au lieu de les faire
    // changer.
    //
    // Le plateau monte donc un nombre FIXE de voies et les garde en vie toute
    // la partie. Un essai qui n'utilise que 4 des 6 voies rend les deux autres
    // transparentes ; celles qui servent virent, changent de couleur et
    // glissent vers leur nouvelle trajectoire — cf. `_ScrollingPlaneState`.
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (var i = 0; i < _MoveFastStimulus.maxLanes; i++)
              _ScrollingPlane(
                // La clé est la VOIE, jamais l'essai : c'est elle qui fait que
                // Flutter réutilise l'avion au lieu d'en construire un neuf.
                key: ValueKey(i),
                paused: paused,
                stimulus: stimulus,
                color: planeColor,
                lane: lanes[i],
                board: constraints.biggest,
              ),
          ],
        );
      },
    );
  }
}

/// Avion qui défile en continu dans la direction du mouvement, en boucle : il
/// sort par un bord du plateau et réapparaît par le bord opposé (le plateau
/// clippe le débordement). Remplace l'ancienne animation d'entrée unique.
class _ScrollingPlane extends StatefulWidget {
  const _ScrollingPlane({
    super.key,
    required this.stimulus,
    required this.color,
    required this.lane,
    required this.board,
    required this.paused,
  });

  final _MoveFastStimulus stimulus;
  final Color color;

  /// Voie occupée à CET essai, ou `null` si l'essai n'a pas besoin de cette
  /// voie — l'avion s'efface alors sans être détruit.
  final _PlaneLane? lane;

  final Size board;

  /// Menu pause ouvert : le défilement doit s'arrêter net (time scale = 0).
  final bool paused;

  @override
  State<_ScrollingPlane> createState() => _ScrollingPlaneState();
}

/// Où se trouve un avion, et de quelle taille, pour une règle de mouvement et
/// une voie données.
class _PlaneSpot {
  const _PlaneSpot({required this.left, required this.top, required this.size});

  final double left;
  final double top;
  final double size;

  /// Interpole deux états. [t] conduit la TRAJECTOIRE, [sizeT] la TAILLE.
  ///
  /// Deux paramètres et non un : la trajectoire est calée sur le cap, parce que
  /// c'est le même geste qui porte la réponse ; la taille, elle, ne dit rien au
  /// joueur. La caler sur le cap la faisait changer dans la fenêtre étroite où
  /// celui-ci bouge — toute la formation se redimensionnait d'un coup à chaque
  /// essai. Elle suit donc la figure entière.
  static _PlaneSpot lerp(
    _PlaneSpot a,
    _PlaneSpot b,
    double t, {
    required double sizeT,
  }) => _PlaneSpot(
    left: ui.lerpDouble(a.left, b.left, t)!,
    top: ui.lerpDouble(a.top, b.top, t)!,
    size: ui.lerpDouble(a.size, b.size, sizeT)!,
  );
}

/// L'état d'un avion à l'essai qu'il vient de quitter — le point de départ de
/// la figure de transition.
class _PlaneFrom {
  const _PlaneFrom({
    required this.stimulus,
    required this.lane,
    required this.color,
    required this.visible,
  });

  final _MoveFastStimulus stimulus;
  final _PlaneLane lane;
  final Color color;
  final bool visible;
}

class _ScrollingPlaneState extends State<_ScrollingPlane>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  /// Élan d'entrée, joué une fois au montage de l'avion.
  ///
  /// Retour client : « ajouter une animation de mouvement de l'avion au moment
  /// du changement de couleur […] rendre la transition plus dynamique, en
  /// faisant apparaître une petite animation de déplacement de l'avion lors de
  /// chaque changement ». À chaque nouvel essai, l'`AnimatedSwitcher` reconstruit
  /// toute la formation : ces états sont donc neufs, et l'élan se rejoue seul.
  /// La bascule 3D du cluster fait apparaître la formation ; cet élan-ci la fait
  /// SURGIR dans son axe de vol, ce qui est le déplacement demandé.
  late final AnimationController _dash;
  late final Animation<double> _dashCurve;

  /// Recul de départ, en fraction de la longueur du plateau dans l'axe de vol.
  static const double _dashSpan = 0.22;

  /// Poussée de la figure, en fraction de la longueur du plateau.
  ///
  /// Discrète à dessein : au-delà, l'avion doublerait sa propre trajectoire de
  /// croisière et le défilement paraîtrait irrégulier.
  static const double _surgeSpan = 0.045;

  /// Figure de transition d'un essai au suivant.
  ///
  /// Retour client : « je ne veux pas une apparition rapide, une transition
  /// très rapide — ce sera une animation complète qui contient le changement de
  /// couleur ». C'est cette horloge-là qui porte TOUT ce qui change entre deux
  /// essais : la couleur, la trajectoire, la taille, la présence. Elle dure
  /// exactement le temps du tonneau que l'avion enroule au même instant, si
  /// bien que le joueur ne voit qu'un seul geste.
  late final AnimationController _morph;

  /// D'où part la figure. Nul avant le premier changement d'essai.
  _PlaneFrom? _from;

  /// Dernière voie réellement occupée — gardée même quand l'essai courant
  /// n'utilise pas cette voie, pour que l'avion s'efface SUR PLACE au lieu de
  /// sauter à une géométrie arbitraire.
  late _PlaneLane _lane;

  /// Attitude de DÉPART de la figure en cours : cap et roulis affichés à
  /// l'instant où elle a été armée.
  ///
  /// Ce ne sont pas les valeurs nominales de l'essai précédent, mais celles que
  /// l'avion montrait vraiment. Une réponse rapide écourte l'essai (650 ms plus
  /// tard) alors que la figure en demande près du double : sans cette reprise,
  /// l'avion sautait de la tranche à l'horizontale. C'est l'« apparition très
  /// rapide » que le client voyait sur certaines transitions seulement — celles
  /// où il avait répondu vite.
  late double _headingFrom;
  late double _headingTo;
  double _rollFrom = 0;
  double _rollWay = 1;

  @override
  void initState() {
    super.initState();
    _lane = widget.lane ?? _MoveFastStimulus.demoLanes.first;
    _headingFrom = _headingTo = MoveFastPlane.angleFor(
      widget.stimulus.noseDirection,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _dash = AnimationController(
      vsync: this,
      duration: MoveFastPlane.entryDuration,
    );
    _morph = AnimationController(
      vsync: this,
      duration: _turnDelay + MoveFastPlane.turnDuration,
      value: 1,
    );
    // Départ décalé selon la voie : la formation entre en vague plutôt qu'en
    // bloc, comme un vrai passage d'escadrille.
    final delay = (_lane.phase * 0.4).clamp(0.0, 0.4);
    _dashCurve = CurvedAnimation(
      parent: _dash,
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
    );
    if (!widget.paused) {
      _controller.repeat();
      _dash.forward();
    }
  }

  @override
  void didUpdateWidget(_ScrollingPlane oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.stimulus.serial != oldWidget.stimulus.serial) {
      // ATTITUDE RÉELLE, pas nominale : la figure précédente peut être en
      // cours. On la relève avant toute chose, c'est d'elle que part la
      // suivante.
      final f = MoveFastPlane.figureProgress(_morph.value, _turnDelay);
      _rollFrom = _rollAtFigure(f);
      _headingFrom = _headingAtFigure(f);
      _headingTo = MoveFastPlane.shortestTurnFrom(
        fromAngle: _headingFrom,
        to: widget.stimulus.noseDirection,
      );
      // Le tonneau s'enroule dans le sens du virage ; sur un essai qui ne
      // change pas de direction, il garde le sens du précédent plutôt que d'en
      // choisir un au hasard.
      final travel = _headingTo - _headingFrom;
      if (travel != 0) _rollWay = travel.isNegative ? -1 : 1;

      // On fige d'où l'on part AVANT d'adopter la nouvelle voie : c'est ce
      // couple (ancien état, nouvel état) que la figure interpole.
      _from = _PlaneFrom(
        stimulus: oldWidget.stimulus,
        lane: _lane,
        color: oldWidget.color,
        visible: oldWidget.lane != null,
      );
      if (widget.lane != null) _lane = widget.lane!;
      // La voie peut avoir changé : le retard dans la vague avec elle.
      _morph.duration = _turnDelay + MoveFastPlane.turnDuration;
      _morph.forward(from: 0);
    }

    // Le menu pause doit VRAIMENT figer le jeu : le compte à rebours était
    // déjà gelé, mais les avions continuaient de défiler derrière la carte.
    // On stoppe la boucle sur place (`stop`, pas `reset`) pour qu'elle
    // reprenne exactement où elle en était.
    if (widget.paused == oldWidget.paused) return;
    if (widget.paused) {
      _controller.stop();
      _dash.stop();
      _morph.stop();
    } else {
      _controller.repeat();
      _dash.forward();
      _morph.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dash.dispose();
    _morph.dispose();
    super.dispose();
  }

  /// Position et taille de l'avion pour une règle de mouvement et une voie
  /// données, à l'instant [loop] de la boucle de défilement.
  ///
  /// Écrite comme une fonction pure de l'état : c'est ce qui permet de la
  /// calculer DEUX fois — pour l'essai qu'on quitte et pour celui qu'on
  /// rejoint — et d'interpoler entre les deux. Un changement de règle de
  /// mouvement (« de droite-à-gauche à haut-en-bas ») devient alors une courbe
  /// que l'avion décrit, au lieu d'un saut d'un axe à l'autre.
  static bool _isVertical(_MoveFastStimulus stimulus) =>
      stimulus.movementDirection == GameDirection.up ||
      stimulus.movementDirection == GameDirection.down;

  /// +1 si le vol descend l'écran ou va vers la droite, −1 sinon.
  static double _forwardOf(_MoveFastStimulus stimulus) =>
      stimulus.movementDirection == GameDirection.down ||
          stimulus.movementDirection == GameDirection.right
      ? 1
      : -1;

  /// Retard de CET avion dans la vague, tiré de sa voie.
  Duration get _turnDelay => MoveFastPlane.staggerFor(_lane.slot);

  /// Cap affiché à l'instant [f] de la figure en cours.
  double _headingAtFigure(double f) =>
      _headingFrom +
      (_headingTo - _headingFrom) * MoveFastPlane.headingProgress(f);

  /// Roulis affiché à l'instant [f] de la figure en cours.
  double _rollAtFigure(double f) =>
      MoveFastPlane.rollFigure(from: _rollFrom, way: _rollWay, f: f);

  _PlaneSpot _spot(_MoveFastStimulus stimulus, _PlaneLane lane, double loop) {
    final vertical = _isVertical(stimulus);
    final forward = _forwardOf(stimulus) > 0;

    final board = widget.board;
    final s = lane.size;
    final axisLen = vertical ? board.height : board.width;
    final crossLen = vertical ? board.width : board.height;
    final travel = axisLen + s; // départ hors-champ → arrivée hors-champ
    final crossPx = (lane.cross + 1) / 2 * (crossLen - s);

    final t = (loop + lane.phase) % 1.0;
    final u = forward ? t : (1 - t);
    // Élan d'entrée : l'avion démarre EN ARRIÈRE de sa position de croisière et
    // la rattrape. `alongPx` croît toujours avec `u` — c'est `u` qui porte le
    // sens du vol — donc « en arrière » se lit dans le sens de `forward`.
    final dashPx =
        (1 - _dashCurve.value) * axisLen * _dashSpan * (forward ? -1 : 1);
    final alongPx = -s + u * travel + dashPx;

    // AUCUN fondu aux extrémités.
    //
    // Il y en avait un — l'avion s'estompait sur 8 % de sa boucle avant de
    // reparaître par le bord opposé. Mais à 8 % de la boucle il est encore
    // largement DANS le plateau : on le voyait donc s'effacer en plein vol,
    // puis se rallumer de l'autre côté. C'était l'une des « apparitions ultra
    // rapides » que le client voyait revenir.
    //
    // Rien ne le remplace, et rien n'a à le remplacer : la course va de `-s`
    // (entièrement hors champ avant le bord) à `axisLen` (entièrement hors
    // champ après), et le plateau découpe à ses bords. Le bouclage se produit
    // donc alors que l'avion est déjà invisible.
    return _PlaneSpot(
      left: vertical ? crossPx : alongPx,
      top: vertical ? alongPx : crossPx,
      size: s,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.board.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _dashCurve, _morph]),
      builder: (context, _) {
        // La voie attend son tour : c'est ce décalage qui fait remonter la
        // figure le long de la formation au lieu de la jouer en bloc.
        final f = MoveFastPlane.figureProgress(_morph.value, _turnDelay);
        // Le cap est la seule chose qui porte la réponse ; la couleur et la
        // trajectoire peuvent donc suivre la même courbe que lui, elles ne
        // trompent personne. Tout arrive d'un seul tenant.
        final k = MoveFastPlane.headingProgress(f);
        final from = _from;

        // Part du trajet d'arrivée/de départ. Sur sa PROPRE courbe, étalée sur
        // toute la figure : voir `MoveFastPlane.joinProgress`.
        final j = MoveFastPlane.joinProgress(f);

        final target = _spot(widget.stimulus, _lane, _controller.value);

        // La formation compte 4 à 6 avions : à chaque essai, une voie ou deux
        // s'ajoutent ou se retirent.
        //
        // Elles s'estompaient sur place — un avion se matérialisait en plein
        // milieu du plateau, un autre s'y dissolvait. C'est LA disparition que
        // le client voyait encore. Elles quittent donc la formation EN VOLANT :
        // celui qui s'en va accélère et sort par l'avant, celui qui arrive
        // rattrape la formation par l'arrière. Le plateau découpe à ses bords,
        // si bien que ni l'un ni l'autre ne se voit apparaître.
        final visible = widget.lane != null;
        final joining = from != null && !from.visible && visible;
        final presence = from == null
            ? (visible ? 1.0 : 0.0)
            : ui.lerpDouble(from.visible ? 1.0 : 0.0, visible ? 1.0 : 0.0, j)!;
        // Rien à dessiner uniquement quand l'avion est DÉJÀ dehors.
        if (presence <= 0.001) return const SizedBox.shrink();

        // Un avion qui ARRIVE remonte sa propre voie, il n'interpole pas depuis
        // celle qu'il occupait il y a plusieurs essais — voie qui peut être à
        // l'autre bout du plateau, ou, s'il n'a jamais volé, la voie de
        // démonstration. Cette interpolation-là lui faisait traverser le plateau
        // en biais pendant son entrée, en changeant de taille au passage.
        final spot = (from == null || joining)
            ? target
            : _PlaneSpot.lerp(
                _spot(from.stimulus, from.lane, _controller.value),
                target,
                k,
                sizeT: j,
              );

        // LE point du retour client : la couleur ne bascule pas d'un coup entre
        // deux formations, elle se déverse pendant que l'avion enroule son
        // tonneau. C'est la même figure qui porte les deux.
        final color = from == null
            ? widget.color
            : Color.lerp(from.color, widget.color, k)!;

        final vertical = _isVertical(widget.stimulus);
        final forward = _forwardOf(widget.stimulus);
        final axisLen = vertical ? widget.board.height : widget.board.width;

        // Élan de la figure : l'avion accélère dans son axe de vol au moment où
        // il enroule son tonneau, et grossit un peu au passage. Sans cette
        // poussée, la rotation a l'air posée sur un objet immobile.
        final surge = MoveFastPlane.surgeAt(f);
        // Écart à la formation : devant pour celui qui part, derrière pour
        // celui qui arrive — jamais sur place.
        //
        // La distance est celle qu'il FAUT pour sortir du cadre, pas une valeur
        // ronde. Elle valait 1,2 longueur de plateau quelle que soit la position
        // de l'avion sur sa boucle : celui qui se trouvait déjà près du bord
        // d'entrée devait donc traverser tout le plateau et revenir, à plus de
        // 8 000 px/s sur un grand écran. C'est ce trajet inutile que le joueur
        // lisait comme une apparition brusque.
        final alongPos = vertical ? spot.top : spot.left;
        final toStart = forward > 0 ? alongPos + spot.size : axisLen - alongPos;
        final toEnd = forward > 0 ? axisLen - alongPos : alongPos + spot.size;
        // Une demi-envergure de marge : l'avion doit être franchement dehors,
        // pas posé sur le bord où un pixel d'aile dépasserait.
        final room = (joining ? toStart : toEnd) + spot.size * 0.5;
        final away = (1 - presence) * room * (joining ? -1 : 1);
        final along = surge * _surgeSpan * axisLen * forward + away * forward;

        return Positioned(
          left: spot.left + (vertical ? 0 : along),
          top: spot.top + (vertical ? along : 0),
          child: Opacity(
            // Pleine opacité en jeu : plus rien ne s'estompe. Seul l'élan
            // d'entrée, au tout premier montage du plateau, monte de 0,4 à 1.
            opacity: (0.4 + 0.6 * _dashCurve.value).clamp(0.0, 1.0),
            // Léger grossissement à l'arrivée : l'avion « prend de la vitesse »
            // au lieu de simplement glisser.
            child: Transform.scale(
              // `approachScale` vaut 1 tant que l'avion reste dans la formation :
              // seuls celui qui arrive et celui qui part sont concernés.
              scale:
                  (0.88 + 0.12 * _dashCurve.value) *
                  (1 + 0.1 * surge) *
                  MoveFastPlane.approachScale(presence),
              // Aucune clé, donc aucun remontage : l'avion traverse les essais.
              // Son attitude lui est DONNÉE image par image, ce qui est la
              // seule façon d'enchaîner une figure sur une figure interrompue.
              child: MoveFastPlane(
                noseDirection: widget.stimulus.noseDirection,
                turnFrom: widget.stimulus.previousNoseDirection,
                heading: _headingAtFigure(f),
                roll: _rollAtFigure(f),
                color: color,
                size: spot.size,
              ),
            ),
          ),
        );
      },
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
