import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/memory_pace_store.dart';
import '../../domain/config/memory_quest_config.dart';
import '../../domain/entities/device_calibration.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_runtime_snapshot.dart';
import '../../domain/config/game_presentation_timing.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/memory_distraction.dart';
import '../../domain/entities/memory_object.dart';
import '../../domain/entities/memory_quest_metrics.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/service/memory_distraction_factory.dart';
import '../device_calibration_probe.dart';
import '../games_providers.dart';
import '../widgets/game_results_template.dart';
import '../widgets/game_system_components.dart';
import '../widgets/memory_prompt.dart';
import '../widgets/memory_quest_tutorial.dart';

// Conserve les imports existants du composant public de Memory Quest.
export '../widgets/memory_prompt.dart' show MemoryPrompt, kMemoryPromptColor;

/// « J'investigue » — jeu de MÉMOIRE DE TRAVAIL (GameType MEMORY_QUEST).
///
/// Phase 0 + Mission A (Digit Span) : observe une séquence de chiffres révélés
/// un par un (encodage séquentiel, saisie verrouillée), puis rappelle dans le
/// MÊME ordre, puis en ordre INVERSE (charge accrue). La séquence d'origine
/// n'est jamais affichée pendant le rappel.
///
/// Score (mock local, en attendant le backend) : chaque tâche est notée 0–5 ;
/// le composite = moyenne des tâches, normalisé /100 (indicatif, non diagnostique).
///
/// Missions B (manipulation d'objets) et Distraction : phases suivantes.
class InvestigateScreen extends ConsumerStatefulWidget {
  const InvestigateScreen({
    super.key,
    this.mode = InvestigateMode.full,
    @visibleForTesting this.seed,
    @visibleForTesting this.onMissionBReady,
    @visibleForTesting this.onDistractionReady,
  });

  /// Missions jouées par cette partie (voir [InvestigateMode]).
  final InvestigateMode mode;

  /// Graine RNG déterministe pour les tests (séquences reproductibles).
  final int? seed;

  /// Notifie l'ordre INITIAL des objets (Mission B) — hook de test uniquement.
  final void Function(List<MemoryObject> initialOrder)? onMissionBReady;

  /// Notifie la séquence à protéger + la bonne réponse de la question de
  /// distraction — hook de test uniquement.
  final void Function(List<int> sequence, int answer)? onDistractionReady;

  @override
  ConsumerState<InvestigateScreen> createState() => _InvestigateScreenState();
}

/// Découpage de « J'investigue » en deux jeux distincts.
///
/// Le jeu enchaînait deux missions dans une seule partie : mémorisation de
/// CHIFFRES (empan direct, inverse, résistance à l'interférence) puis
/// mémorisation d'IMAGES (ordre des objets). Le client demande de les séparer,
/// pour les valider — et les faire jouer — indépendamment.
///
/// Le mode ne touche QUE l'enchaînement des phases : le barème, la session et
/// les métriques envoyées au serveur restent ceux de `memoryQuestCore`. Les
/// tâches non jouées sont simplement absentes du composite, exactement comme
/// une partie écourtée.
enum InvestigateMode {
  /// Les deux missions à la suite — comportement historique.
  full,

  /// Chiffres uniquement : empan direct, inverse et distraction.
  digits,

  /// Images uniquement : observation, manipulation, restauration de l'ordre.
  images;

  bool get playsDigits => this != InvestigateMode.images;
  bool get playsImages => this != InvestigateMode.digits;
}

enum _Stage {
  intro,
  tutorial,
  observeSequence,
  recallSameOrder,
  recallReverseOrder,
  observeObjects,
  manipulateObjects,
  restoreOrder,

  /// Question d'interférence intercalée ENTRE la mémorisation et le rappel.
  ///
  /// Elle ne fait mémoriser aucune séquence supplémentaire : la séquence à
  /// protéger est celle du niveau, déjà observée.
  distraction,
  feedback,
  results,
}

class _InvestigateScreenState extends ConsumerState<InvestigateScreen> {
  // Session serveur (mock hors-ligne / backend) : le score fait autorité côté repo.
  Future<GameSession>? _sessionStart;
  GameSession? _serverSession;
  bool _submitting = false;

  // ── Timers (data-driven, cf. handoff §6/§8) ──────────────────────────────
  GamePresentationTiming get _timing => GamePresentationTiming(
    _serverSession?.runtime ?? const GameRuntimeSnapshot(),
  );
  int get _digitVisibleMs => _timing.memoryDigitVisibleMs;
  int get _isiMs => _timing.memoryDigitGapMs;
  bool _starting = false;
  static const int _feedbackMs = 250;

  // ── Système de niveaux (fiche Tableau 1, via MemoryQuestConfig) ───────────
  late final math.Random _random = widget.seed == null
      ? math.Random()
      : math.Random(widget.seed!);

  _Stage _stage = _Stage.intro;
  bool _paused = false;

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  // Niveau courant (1-based). Un seul tour par niveau, puis incrémentation.
  int _level = 1;
  // Échecs enchaînés sur le niveau COURANT : au [maxFailuresPerLevel]ᵉ, fin de
  // partie. Remis à zéro à chaque montée de niveau.
  int _levelFailures = 0;

  /// Allure du joueur — recalée à chaque niveau, restaurée du profil au
  /// lancement. Voir [MemoryQuestConfig.nextPlayerFactor].
  double _playerFactor = MemoryQuestConfig.playerPaceNeutral;

  /// Toutes les tâches du tour en cours ont-elles été parfaites ?
  ///
  /// C'est ce qui décide de la montée de niveau : un tour est réussi quand le
  /// rappel direct, le rappel inverse et — à partir du niveau
  /// [MemoryQuestConfig.distractionMinLevel] — le rappel après distraction sont
  /// tous exacts.
  bool _roundPerfect = true;
  // Tâches par instance (avec timing) — active l'ajustement timeout du calibrage.
  final List<MemoryTaskResult> _tasks = [];
  final Stopwatch _taskWatch =
      Stopwatch(); // temps de la tâche de rappel courante
  final Stopwatch _sessionWatch =
      Stopwatch(); // durée de session (max_session_duration_min)
  final DeviceCalibrationProbe _calibrationProbe = DeviceCalibrationProbe();

  // Round courant.
  int _length = MemoryQuestConfig.initialSequenceLength;
  List<int> _sequence = const [];
  int _revealIndex = 0;
  bool _showingDigit = false;
  int _seqToken = 0; // annule une observation en cours (pause/dispose)

  // Saisie de rappel.
  final List<int> _entry = [];
  bool _lastCorrect = false;

  // Résultats cumulés (Mission A).
  int _observedDigits = 0;
  int _correctSameDigits = 0;
  int _correctReverseDigits = 0;
  int _highestLength = 0;

  // ── Mission B — manipulation d'objets (nb d'objets selon le niveau) ──────
  static const int _bManipulations = 2; // 2 manipulations automatiques
  int get _manipStepMs => _timing.memoryManipulationStepMs;
  int get _preRecallMs => _timing.memoryRetentionMs;

  List<MemoryObject> _objects = const []; // ordre INITIAL à restaurer
  List<MemoryObject> _shownOrder =
      const []; // ordre affiché (observe/manipulation)
  int _highlightA = -1;
  int _highlightB = -1;

  /// Grille de restauration : tous les objets, dans un ordre mélangé qui ne
  /// bouge plus. Les cartes restent en place, c'est le RANG qu'on leur attribue.
  List<MemoryObject> _board = const [];

  /// Objets classés, dans l'ordre des appuis. Le rang d'un objet est sa position
  /// dans cette liste (+1) ; absent = pas encore classé.
  List<MemoryObject> _ranking = const [];
  int _restoreCorrect = 0;
  bool _missionBDone = false;
  int _objToken = 0; // annule une phase objet en cours (pause/dispose)

  // ── Phase de distraction (résistance à l'interférence) ────────────────────

  /// Battement du rebours de restitution. Assez fin pour que la barre glisse,
  /// assez large pour ne pas reconstruire le plateau à chaque image.
  static const Duration _restoreTickInterval = Duration(milliseconds: 100);

  String _distractQuestionText = '';
  int _distractQuestionAnswer = 0; // réponse correcte de la question
  List<int> _distractChoices = const [];
  bool _distractQuestionCorrect = false;
  int _distractSecondsLeft = 0;
  Timer? _distractTimer;

  /// Compte à rebours de la restitution — la phase avait un temps illimité.
  ///
  /// Suivi en MILLISECONDES et non en secondes : la barre de temps se vide en
  /// continu, un pas d'une seconde la ferait sauter par quarts sur une phase
  /// qui n'en dure que six.
  int _restoreLimitMs = 0;
  int _restoreMsLeft = 0;
  Timer? _restoreTimer;

  /// Fraction de temps restante pour la restitution, dans [0, 1].
  double get _restoreProgress =>
      _restoreLimitMs <= 0 ? 0 : _restoreMsLeft / _restoreLimitMs;
  int _afterDistractObserved = 0;
  int _afterDistractCorrect = 0;
  bool _distractionDone = false;

  /// Le tour en cours a-t-il été coupé par la question d'interférence ?
  /// C'est ce qui fait du rappel direct un rappel « après distraction ».
  bool _roundHadDistraction = false;

  /// Épreuve visuelle du jeu des images, fabriquée à la volée.
  final _distractionSequencer = MemoryDistractionSequencer();
  MemoryDistractionChallenge? _objectChallenge;
  bool _challengeAnswered = false;

  bool get _reduceMotion =>
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
      (_serverSession?.runtime.modifierBool(
            'reducedMotionDefault',
            fallback: false,
          ) ??
          false);

  bool get _inputLocked =>
      _paused ||
      _stage == _Stage.observeSequence ||
      _stage == _Stage.observeObjects ||
      _stage == _Stage.manipulateObjects ||
      _stage == _Stage.feedback;

  /// Longueur du rappel courant — toujours celle de la séquence du niveau.
  int get _recallLength => _length;

  @override
  void initState() {
    super.initState();
    // Lecture synchrone : les préférences sont déjà résolues dans main().
    _playerFactor = ref.read(memoryPaceStoreProvider).read();
  }

  @override
  void dispose() {
    _seqToken++; // stoppe toute observation planifiée
    _objToken++;
    _distractTimer?.cancel();
    _restoreTimer?.cancel();
    SoundService.instance.stopSpeaking();
    super.dispose();
  }

  // ── Cycle de jeu ─────────────────────────────────────────────────────────

  Future<void> _startMission() async {
    if (_starting) return;
    _starting = true;
    try {
      _sessionStart = ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.memoryQuest);
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
    setState(() {
      _level = 1;
      _levelFailures = 0;
      _length = MemoryQuestConfig.sequenceLengthForLevel(_level);
      _observedDigits = 0;
      _correctSameDigits = 0;
      _correctReverseDigits = 0;
      _highestLength = 0;
      _missionBDone = false;
      _restoreCorrect = 0;
      _objects = const [];
      _distractionDone = false;
      _roundHadDistraction = false;
      _afterDistractObserved = 0;
      _afterDistractCorrect = 0;
      _distractQuestionCorrect = false;
      _submitting = false;
      _tasks.clear();
    });
    _distractTimer?.cancel();
    _restoreTimer?.cancel();
    _calibrationProbe.reset();
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    _sessionWatch
      ..reset()
      ..start();
    // Snapshot received before any observation timer starts.
    _beginRound();
  }

  void _beginRound() {
    // Nouveau tour : il est parfait jusqu'à preuve du contraire, et l'éventuelle
    // interférence est à rejouer.
    _roundPerfect = true;
    _roundHadDistraction = false;
    // Mode « images seules » : aucune séquence de chiffres n'est jouée, la
    // manche commence directement par la mission d'objets.
    if (!widget.mode.playsDigits) {
      _beginMissionB();
      return;
    }
    _length = MemoryQuestConfig.sequenceLengthForLevel(_level);
    _sequence = List<int>.generate(_length, (_) => _random.nextInt(10));
    _entry.clear();
    setState(() {
      _stage = _Stage.observeSequence;
      _revealIndex = 0;
      _showingDigit = false;
    });
    _runObservation();
  }

  /// Enregistre une tâche de rappel notée (avec son timing) pour le score.
  void _recordTask(MemoryTaskKind kind, int correct, int total) {
    final ms = _taskWatch.isRunning ? _taskWatch.elapsedMilliseconds : 0;
    _taskWatch.stop();
    _calibrationProbe.sampleInputLatency();
    _tasks.add(
      MemoryTaskResult(
        kind: kind,
        correct: correct,
        total: total,
        responseTimeMs: ms,
      ),
    );
    // Une seule tâche imparfaite suffit à rater le tour — donc à rejouer le
    // niveau au lieu de monter.
    if (total > 0 && correct < total) _roundPerfect = false;
  }

  bool get _sessionTimeExhausted =>
      _sessionWatch.elapsed.inMinutes >=
      MemoryQuestConfig.maxSessionDurationMin;

  Future<void> _runObservation() async {
    final token = ++_seqToken;
    final lang =
        _lang; // langue capturée pour la voix (le context reste stable)
    // Court délai avant le 1er chiffre (état calme, pas de flash).
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (var i = 0; i < _sequence.length; i++) {
      if (!mounted || token != _seqToken) return;
      setState(() {
        _revealIndex = i;
        _showingDigit = true;
      });
      // Son de chiffre, alterné entre deux variantes pour éviter la monotonie.
      SoundService.instance.playSfx(
        i.isEven ? GameSfx.numberClick : GameSfx.numberClickV2,
      );
      // Voix native qui énonce le chiffre affiché, dans la langue du jeu.
      SoundService.instance.speakNumber(_sequence[i], languageCode: lang);
      await Future<void>.delayed(Duration(milliseconds: _digitVisibleMs));
      if (!mounted || token != _seqToken) return;
      setState(() => _showingDigit = false); // ISI (blanc, input verrouillé)
      SoundService.instance.playSfx(GameSfx.blankInterval);
      await Future<void>.delayed(Duration(milliseconds: _isiMs));
    }
    if (!mounted || token != _seqToken) return;
    setState(() => _observedDigits += _sequence.length);
    _afterObservation();
  }

  /// Ce qui suit immédiatement la mémorisation.
  ///
  /// À partir du niveau [MemoryQuestConfig.distractionMinLevel], une question
  /// d'interférence s'intercale ici, **entre la mémorisation et le rappel** :
  /// c'est tout l'objet de la phase (protéger la séquence malgré une tâche
  /// parasite). Sinon on passe directement au rappel.
  void _afterObservation() {
    if (widget.mode.playsDigits &&
        MemoryQuestConfig.distractionActiveAtLevel(_level)) {
      _beginDistraction();
      return;
    }
    _toRecallSameOrder();
  }

  void _toRecallSameOrder() {
    setState(() {
      _entry.clear();
      _stage = _Stage.recallSameOrder;
    });
    _taskWatch
      ..reset()
      ..start(); // chronomètre la tâche de rappel (timeout appliqué serveur)
  }

  void _onKey(int digit) {
    if (_inputLocked || _entry.length >= _recallLength) return;
    // SFX de SAISIE. Les sons `numberClick` existaient déjà, mais uniquement
    // dans la boucle de RÉVÉLATION (quand l'app montre les chiffres) : taper
    // sur le pavé ne produisait rien. On alterne les deux variantes selon la
    // position saisie, comme à la révélation, pour éviter la répétition.
    SoundService.instance.playSfx(
      _entry.length.isEven ? GameSfx.numberClick : GameSfx.numberClickV2,
    );
    setState(() => _entry.add(digit));
  }

  void _onBackspace() {
    if (_inputLocked || _entry.isEmpty) return;
    SoundService.instance.playSfx(GameSfx.buttonClick);
    setState(() => _entry.removeLast());
  }

  void _onValidate() {
    if (_inputLocked || _entry.length != _recallLength) return;

    if (_stage == _Stage.recallSameOrder) {
      final correct = _matchingDigits(_entry, _sequence);
      _correctSameDigits += correct;
      // Quand une question d'interférence s'est intercalée, ce rappel EST le
      // rappel « après distraction » — c'est la séquence du niveau qu'il a
      // fallu protéger. On ne journalise qu'UNE tâche, sinon le même rappel
      // pèserait deux fois dans le composite (moyenne des tâches).
      if (_roundHadDistraction) {
        _afterDistractObserved += _sequence.length;
        _afterDistractCorrect += correct;
        _distractionDone = true;
        _recordTask(MemoryTaskKind.afterDistraction, correct, _sequence.length);
      } else {
        _recordTask(MemoryTaskKind.sameOrder, correct, _sequence.length);
      }
      setState(() {
        _stage = _Stage.recallReverseOrder;
        _entry.clear();
      });
      _taskWatch
        ..reset()
        ..start();
      return;
    }

    // recallReverseOrder → fin de la Mission A du niveau.
    final reversed = _sequence.reversed.toList();
    final correctRev = _matchingDigits(_entry, reversed);
    _correctReverseDigits += correctRev;
    final reversePerfect = correctRev == reversed.length;
    if (reversePerfect) _highestLength = math.max(_highestLength, _length);
    _recordTask(MemoryTaskKind.reverseOrder, correctRev, reversed.length);
    // Le retour porte sur les DEUX rappels : se tromper à l'endroit puis réussir
    // à l'envers n'est pas un tour réussi, et c'est le tour qui décide de la
    // montée de niveau. `_recordTask` vient de mettre `_roundPerfect` à jour.
    _lastCorrect = _roundPerfect;
    SoundService.instance.playSfx(
      _roundPerfect ? GameSfx.correctChoice : GameSfx.wrongChoice,
    );

    setState(() => _stage = _Stage.feedback);
    Future<void>.delayed(const Duration(milliseconds: _feedbackMs + 550), () {
      if (!mounted) return;
      // Mode « chiffres seuls » : le tour s'arrête à la fin de la mission A,
      // sans enchaîner sur la manipulation d'objets.
      if (!widget.mode.playsImages) {
        // La distraction a déjà eu lieu avant le rappel : le tour est complet.
        _endLevel();
        return;
      }
      _beginMissionB(); // Mission A terminée → manipulation d'objets
    });
  }

  /// Fin des phases d'un tour. C'est ici que se joue la progression :
  ///
  /// * **tour réussi** → niveau suivant (un chiffre de plus), compteur d'échecs
  ///   remis à zéro ; au dernier niveau, la partie se termine par une réussite ;
  /// * **tour raté** → on REJOUE le même niveau avec une nouvelle séquence, et
  ///   au [MemoryQuestConfig.maxFailuresPerLevel]ᵉ échec sur ce niveau la partie
  ///   s'arrête (écran de score).
  ///
  /// La version précédente montait d'un niveau **à chaque tour**, réussi ou non,
  /// et comptait les erreurs dans un budget global de 3 tous niveaux confondus :
  /// la séquence s'allongeait donc même quand le joueur venait d'échouer.
  ///
  /// Le temps de session reste une borne haute indépendante.
  void _endLevel() {
    _recordPace(success: _roundPerfect);
    if (_sessionTimeExhausted) {
      _finishAndSubmit();
      return;
    }

    if (!_roundPerfect) {
      _levelFailures++;
      if (_levelFailures >= MemoryQuestConfig.maxFailuresPerLevel) {
        _finishAndSubmit();
        return;
      }
      // Même niveau, nouvelle séquence (resetSequenceOnError).
      _beginRound();
      return;
    }

    if (_level >= MemoryQuestConfig.totalLevels) {
      _finishAndSubmit(); // dernier niveau réussi : parcours terminé
      return;
    }
    setState(() {
      _level++;
      _levelFailures = 0; // le compteur d'échecs est propre à un niveau
    });
    _beginRound();
  }

  /// Recale l'allure du joueur sur l'issue du niveau, et la persiste.
  ///
  /// Volontairement appelé sur chaque niveau, réussi ou raté : c'est le rapport
  /// entre le petit pas de descente et le grand pas de remontée qui fait
  /// converger l'allure vers [MemoryQuestConfig.targetSuccessRate]. N'en garder
  /// qu'un des deux ferait dériver le temps dans une seule direction.
  void _recordPace({required bool success}) {
    final next = MemoryQuestConfig.nextPlayerFactor(
      _playerFactor,
      success: success,
    );
    if (next == _playerFactor) return;
    _playerFactor = next;
    // L'écriture est asynchrone mais n'influe sur rien à l'écran : le tour
    // suivant lit `_playerFactor`, pas les préférences.
    unawaited(ref.read(memoryPaceStoreProvider).write(next));
  }

  // ── Mission B — manipulation d'objets ────────────────────────────────────

  void _beginMissionB() {
    final count = MemoryQuestConfig.objectCountForLevel(_level);
    final pool = List<MemoryObject>.of(kMemoryObjectLibrary)..shuffle(_random);
    _objects = pool
        .take(count)
        .toList(); // ordre INITIAL à mémoriser (nb selon niveau)
    _shownOrder = List<MemoryObject>.of(_objects);
    _highlightA = -1;
    _highlightB = -1;
    widget.onMissionBReady?.call(_objects); // hook de test
    setState(() => _stage = _Stage.observeObjects);
    _runObserveThenManipulate();
  }

  Future<void> _runObserveThenManipulate() async {
    final token = ++_objToken;
    // Phase d'observation (ordre initial visible, saisie verrouillée). Le temps
    // de mémorisation croît avec le nombre d'objets, plus vite au-delà de la
    // capacité de la mémoire de travail — cf. MemoryQuestConfig.
    await Future<void>.delayed(
      Duration(
        milliseconds: MemoryQuestConfig.objectObservationMs(
          _objects.length,
          playerFactor: _playerFactor,
        ),
      ),
    );
    if (!mounted || token != _objToken) return;
    setState(() => _stage = _Stage.manipulateObjects);

    // Manipulations automatiques : on échange 2 positions à la fois.
    for (var i = 0; i < _bManipulations; i++) {
      if (!mounted || token != _objToken) return;
      final a = _random.nextInt(_shownOrder.length);
      var b = _random.nextInt(_shownOrder.length);
      while (b == a) {
        b = _random.nextInt(_shownOrder.length);
      }
      setState(() {
        _highlightA = a;
        _highlightB = b;
      });
      await Future<void>.delayed(Duration(milliseconds: _manipStepMs));
      if (!mounted || token != _objToken) return;
      setState(() {
        final tmp = _shownOrder[a];
        _shownOrder[a] = _shownOrder[b];
        _shownOrder[b] = tmp;
      });
      await Future<void>.delayed(Duration(milliseconds: _manipStepMs));
    }

    if (!mounted || token != _objToken) return;
    // Rétention : on efface les surbrillances et on laisse 3 s au joueur pour
    // consolider l'ordre initial AVANT de basculer sur le rappel.
    setState(() {
      _highlightA = -1;
      _highlightB = -1;
    });
    await Future<void>.delayed(Duration(milliseconds: _preRecallMs));
    if (!mounted || token != _objToken) return;
    // À partir du niveau [distractionMinLevel], une tâche parasite s'intercale
    // ici — entre la mémorisation et la restauration —, exactement comme la
    // question d'interférence du jeu de chiffres.
    // `!playsDigits` : dans le mode historique qui enchaîne les deux missions,
    // l'interférence a déjà eu lieu avant le rappel des chiffres — la rejouer
    // ici en ferait deux par tour.
    if (!widget.mode.playsDigits &&
        MemoryQuestConfig.imagesDistractionActiveAtLevel(_level)) {
      _beginObjectDistraction();
      return;
    }
    _toRestoreOrder();
  }

  /// Restauration : l'utilisateur reconstruit l'ORDRE INITIAL (pas l'état final).
  void _toRestoreOrder() {
    _restoreTimer?.cancel();
    final limitMs = MemoryQuestConfig.restoreTimeLimitMs(
      _objects.length,
      playerFactor: _playerFactor,
    );
    setState(() {
      _board = List<MemoryObject>.of(_objects)..shuffle(_random);
      _ranking = <MemoryObject>[];
      _restoreLimitMs = limitMs;
      _restoreMsLeft = limitMs;
      _stage = _Stage.restoreOrder;
    });
    _taskWatch
      ..reset()
      ..start(); // chronomètre la tâche de restauration
    _restoreTimer = Timer.periodic(_restoreTickInterval, (_) {
      if (!mounted) return;
      // La phase a pu changer entre deux battements (validation, pause quittée,
      // fin de session) : le rebours ne doit alors plus rien décider.
      if (_stage != _Stage.restoreOrder) {
        _restoreTimer?.cancel();
        return;
      }
      if (_restoreMsLeft <= _restoreTickInterval.inMilliseconds) {
        setState(() => _restoreMsLeft = 0);
        _settleRestore(); // temps écoulé → on valide en l'état
        return;
      }
      setState(() => _restoreMsLeft -= _restoreTickInterval.inMilliseconds);
    });
  }

  /// Interférence du jeu d'IMAGES : **une épreuve par niveau**, tirée au hasard
  /// entre « trouver l'intrus » et « pièce manquante ».
  ///
  /// L'épreuve est fabriquée à la volée par [MemoryDistractionFactory] : rien
  /// n'est stocké, deux parties au même niveau ne voient pas la même grille.
  ///
  /// Aucun chiffre n'y apparaît, à aucun moment — c'est la règle du jeu des
  /// images, tâche parasite comprise.
  void _beginObjectDistraction() {
    _roundHadDistraction = true;
    _objectChallenge = _distractionSequencer.next(_level, _random);
    _challengeAnswered = false;
    _startDistractionCountdown();
  }

  /// Réponse du joueur à l'épreuve visuelle.
  void _answerObjectChallenge(int optionIndex) {
    final challenge = _objectChallenge;
    if (challenge == null || _challengeAnswered) return;
    _challengeAnswered = true;
    final correct = optionIndex == challenge.solutionIndex;
    _distractQuestionCorrect = correct;
    SoundService.instance.playSfx(
      correct ? GameSfx.correctChoice : GameSfx.wrongChoice,
    );
    // Court instant pour que le retour visuel soit lu avant l'enchaînement.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || _stage != _Stage.distraction) return;
      _endDistraction();
    });
    setState(() {});
  }

  /// Appui sur une carte : elle prend le rang suivant, ou perd le sien.
  ///
  /// Retour client : « supprimer le drag and drop — le classement se fait au
  /// clic, avec un petit numéro (1, 2, 3…) affiché en haut de l'objet ». Le
  /// glisser-déposer imposait deux zones (réserve + emplacements) qui mangeaient
  /// tout l'écran et forçaient des cartes minuscules ; une seule grille laisse
  /// la place de les agrandir.
  ///
  /// Reclasser est SANS TROU : retirer le rang 2 fait remonter 3 → 2, 4 → 3…
  /// Un classement à trous (1, _, 3) serait invalide et il faudrait alors
  /// interdire la validation en plein milieu du geste, sans que le joueur
  /// comprenne pourquoi.
  ///
  /// Les deux sons restent ceux du glisser-déposer : dépôt quand on classe,
  /// prise en main quand on déclasse. Le geste change, pas ce qu'il fait.
  void _toggleRank(MemoryObject obj) {
    if (_inputLocked) return;
    final at = _ranking.indexWhere((o) => o.id == obj.id);
    SoundService.instance.playSfx(
      at >= 0 ? GameSfx.imageDrag : GameSfx.imageDrop,
    );
    setState(() {
      if (at >= 0) {
        _ranking.removeAt(at);
      } else {
        _ranking.add(obj);
      }
    });
  }

  void _validateRestore() {
    if (_inputLocked || _ranking.length != _objects.length) return;
    _settleRestore();
  }

  /// Clôt la restitution avec le classement tel qu'il est.
  ///
  /// Appelée par le bouton *Validate* — classement complet — et par l'expiration
  /// du rebours, où il peut être partiel ou vide. Les rangs posés comptent quand
  /// même ([MemoryQuestConfig.partialCreditEnabled]) : annuler tout au coup de
  /// sifflet effacerait ce que le joueur avait bel et bien retenu.
  void _settleRestore() {
    _restoreTimer?.cancel();
    var correct = 0;
    for (var i = 0; i < _objects.length && i < _ranking.length; i++) {
      if (_ranking[i].id == _objects[i].id) correct++;
    }
    _restoreCorrect += correct;
    _missionBDone = true;
    // Quand une tâche parasite s'est intercalée, cette restauration EST la
    // restitution « après distraction ». Une seule tâche est journalisée, sinon
    // le même essai pèserait deux fois dans la moyenne du composite.
    if (_roundHadDistraction) {
      _afterDistractObserved += _objects.length;
      _afterDistractCorrect += correct;
      _distractionDone = true;
      _recordTask(MemoryTaskKind.afterDistraction, correct, _objects.length);
    } else {
      _recordTask(MemoryTaskKind.restore, correct, _objects.length);
    }
    SoundService.instance.playSfx(
      correct == _objects.length ? GameSfx.correctChoice : GameSfx.wrongChoice,
    );
    _endLevel();
  }

  // ── Phase de distraction ─────────────────────────────────────────────────

  /// Intercale la question d'interférence **entre la mémorisation et le rappel**.
  ///
  /// La phase faisait auparavant mémoriser une SECONDE séquence, distincte de
  /// celle du niveau, avant de poser la question. Deux défauts en découlaient,
  /// tous deux remontés par le client : la partie semblait « refaire le niveau »
  /// (une seconde mémorisation sous le même intitulé « Level 3 »), et cette
  /// séquence était figée à 4 chiffres — donc plus courte que le niveau atteint.
  ///
  /// Le paradigme est celui de l'interférence : on mémorise, on subit une tâche
  /// parasite, puis on restitue **la même** séquence. Il n'y a donc qu'une seule
  /// mémorisation par tour, quel que soit le niveau.
  void _beginDistraction() {
    _roundHadDistraction = true;
    _entry.clear();
    // Question d'interférence rapide, variée : addition, soustraction ou
    // multiplication (fiche « J'investigue » — résistance à l'interférence).
    final (text, answer) = _buildArithmetic();
    _distractQuestionAnswer = answer;
    _distractQuestionText = text;
    _distractChoices = _buildChoices(_distractQuestionAnswer);
    _distractQuestionCorrect = false;
    widget.onDistractionReady?.call(_sequence, _distractQuestionAnswer);
    _startDistractionCountdown();
  }

  /// Génère une opération simple au résultat positif — tirée aléatoirement
  /// entre addition, soustraction (a ≥ b) et multiplication (petits facteurs).
  (String, int) _buildArithmetic() {
    switch (_random.nextInt(3)) {
      case 0:
        final a = 1 + _random.nextInt(9);
        final b = 1 + _random.nextInt(9);
        return ('$a + $b = ?', a + b);
      case 1:
        final x = 1 + _random.nextInt(9);
        final y = 1 + _random.nextInt(9);
        final a = math.max(x, y); // soustraction à résultat ≥ 0
        final b = math.min(x, y);
        return ('$a − $b = ?', a - b);
      default:
        final a = 2 + _random.nextInt(8); // 2..9
        final b = 2 + _random.nextInt(8);
        return ('$a × $b = ?', a * b);
    }
  }

  List<int> _buildChoices(int answer) {
    final set = <int>{answer};
    while (set.length < 3) {
      final delta = 1 + _random.nextInt(3);
      final candidate = _random.nextBool() ? answer + delta : answer - delta;
      if (candidate >= 0) set.add(candidate); // pas de proposition négative
    }
    final list = set.toList()..shuffle(_random);
    return list;
  }

  void _startDistractionCountdown() {
    _distractTimer?.cancel();
    setState(() {
      _stage = _Stage.distraction;
      _distractSecondsLeft = _distractSeconds;
    });
    _distractTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_distractSecondsLeft <= 1) {
        _endDistraction(); // temps écoulé → question comptée non répondue
        return;
      }
      setState(() => _distractSecondsLeft--);
    });
  }

  /// Réponse à la question d'interférence du jeu des CHIFFRES.
  ///
  /// Sonorisée comme l'épreuve visuelle du jeu des images : les deux tâches
  /// parasites jouent le même rôle, elles doivent donner le même retour. Seule
  /// celle des images en avait un.
  void _pickDistraction(int choice) {
    if (_stage != _Stage.distraction) return;
    final correct = choice == _distractQuestionAnswer;
    _distractQuestionCorrect = correct;
    SoundService.instance.playSfx(
      correct ? GameSfx.correctChoice : GameSfx.wrongChoice,
    );
    _endDistraction();
  }

  /// Fin de l'interférence → restitution de ce qu'il fallait protéger : la
  /// séquence de chiffres, ou l'ordre des objets selon le jeu.
  void _endDistraction() {
    _distractTimer?.cancel();
    // Le mode tranche : pendant la phase de distraction, `_stage` ne dit plus de
    // quelle mission on vient.
    if (!widget.mode.playsDigits) {
      _toRestoreOrder();
      return;
    }
    _toRecallSameOrder();
  }

  // ── Fin de mission : soumission au repository (score serveur/mock) ────────

  MemoryQuestMetrics _buildMetrics() {
    return MemoryQuestMetrics(
      observedDigits: _observedDigits,
      correctSameDigits: _correctSameDigits,
      correctReverseDigits: _correctReverseDigits,
      highestSequenceLength: _highestLength,
      objectCount: _missionBDone ? _objects.length : 0,
      restoreCorrect: _restoreCorrect,
      manipulationCount: _missionBDone ? _bManipulations : 0,
      distractionPlayed: _distractionDone,
      afterDistractionObserved: _afterDistractObserved,
      afterDistractionCorrect: _afterDistractCorrect,
      distractionQuestionCorrect: _distractQuestionCorrect,
      finalLevel: _level,
      sessionCompleted:
          true, // soumission = fin naturelle (abandon = pas de soumission)
      tasks: List<MemoryTaskResult>.unmodifiable(_tasks),
    );
  }

  Future<void> _finishAndSubmit() async {
    _sessionWatch.stop();
    setState(() {
      _stage = _Stage.results;
      _submitting = true;
    });
    SoundService.instance.playScoreboard();
    try {
      final session = await (_sessionStart ??= ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.memoryQuest));
      // Calibrage appareil : le SCORE dépend enfin du temps (timeout par tâche).
      final calibration = _calibrationProbe.build(inputMode: InputMode.touch);
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.memoryQuestCore,
            metrics: _buildMetrics(),
            deviceCalibration: calibration,
          );
      if (!mounted) return;
      setState(() => _serverSession = updated);
    } catch (error) {
      // Hors-ligne / erreur : on garde le composite calculé localement (fallback).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Score non synchronisé : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int _matchingDigits(List<int> a, List<int> b) {
    var n = 0;
    final len = math.min(a.length, b.length);
    for (var i = 0; i < len; i++) {
      if (a[i] == b[i]) n++;
    }
    return n;
  }

  // ── Scoring mock (0–5 par tâche → composite /100) ────────────────────────

  double get _sameAccuracy =>
      _observedDigits == 0 ? 0 : _correctSameDigits / _observedDigits;
  double get _reverseAccuracy =>
      _observedDigits == 0 ? 0 : _correctReverseDigits / _observedDigits;

  int get _sameTaskScore => (_sameAccuracy * 5).round(); // 0–5
  int get _reverseTaskScore => (_reverseAccuracy * 5).round(); // 0–5

  double get _restoreAccuracy =>
      _objects.isEmpty ? 0 : _restoreCorrect / _objects.length;
  int get _restoreTaskScore => (_restoreAccuracy * 5).round(); // 0–5

  // Distraction : ce qui est noté = la SURVIE de la mémoire (rappel après
  // interférence). La justesse de la question est un indicateur affiché à part.
  double get _afterDistractAccuracy => _afterDistractObserved == 0
      ? 0
      : _afterDistractCorrect / _afterDistractObserved;
  int get _distractionTaskScore => (_afterDistractAccuracy * 5).round(); // 0–5

  int get _compositeScore {
    // Composite = moyenne des tâches jouées, normalisé /100 (indicatif).
    final tasks = <int>[_sameTaskScore, _reverseTaskScore];
    if (_missionBDone) tasks.add(_restoreTaskScore);
    if (_distractionDone) tasks.add(_distractionTaskScore);
    final avg = tasks.reduce((a, b) => a + b) / tasks.length; // /5
    return (avg / 5 * 100).round(); // /100
  }

  // ── Pause ────────────────────────────────────────────────────────────────

  /// Bouton unique de l'en-tête : menu de pause tant que la fenêtre est
  /// ouverte, confirmation de sortie ensuite. Voir [GameMenuAffordance].
  Future<void> _openMenu() async {
    if (_pauseAllowance.canOpen) return _openPause();
    if (await GameExitConfirmDialog.show(context)) {
      if (mounted) context.go(AppRoutes.games);
    }
  }

  Future<void> _openPause() async {
    if (_stage == _Stage.intro ||
        _stage == _Stage.tutorial ||
        _stage == _Stage.results) {
      return;
    }
    // Une seule fenêtre de pause par partie (CdC pause §2-3).
    if (!_pauseAllowance.canOpen) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    SoundService.instance.stopSpeaking(); // coupe la voix des chiffres
    _seqToken++; // gèle les phases verrouillées en cours
    _objToken++;
    _distractTimer?.cancel();
    _pauseAllowance.open();
    setState(() => _paused = true);
    await _showPauseMenu();
  }

  /// Menu de pause, réaffiché après les règles sur le **temps restant** de la
  /// fenêtre — sinon l'aller-retour la relancerait indéfiniment.
  Future<void> _showPauseMenu() async {
    final action = await showGamePauseMenu<GamePauseAction>(
      context,
      builder: (context) => GamePauseScaffold(
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(context).pop(GamePauseAction.resume),
        description: 'The game timer and the sequence are frozen.',
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
        if (mounted) context.go(AppRoutes.games);
        return;
      }
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _showPauseMenu();
    } else if (action == GamePauseAction.help) {
      await _showRulesHelp();
      if (!mounted) return;
      if (_pauseAllowance.canReopen) return _showPauseMenu();
    }
    if (!mounted) return;
    // La partie repart : le temps passé en pause rejoint le budget consommé.
    _pauseAllowance.close();
    setState(() => _paused = false);
    // Reprise : on rejoue la phase (verrouillée) courante depuis son début.
    if (_stage == _Stage.observeSequence) {
      _beginRound();
    } else if (_stage == _Stage.observeObjects ||
        _stage == _Stage.manipulateObjects) {
      _beginMissionB();
    } else if (_stage == _Stage.distraction) {
      // La séquence est déjà mémorisée : on repose seulement une question et on
      // relance le compte à rebours.
      _beginDistraction();
    }
  }

  MemoryQuestMode get _tutorialMode => switch (widget.mode) {
    InvestigateMode.digits => MemoryQuestMode.digits,
    InvestigateMode.images => MemoryQuestMode.images,
    InvestigateMode.full => MemoryQuestMode.full,
  };

  /// L’aide explique uniquement les missions jouées. Le cycle de pause existant
  /// garde son budget et reprend après le retour au menu.
  Future<void> _showRulesHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: GameContentFrame(
            child: MemoryQuestTutorial(
              mode: _tutorialMode,
              reviewing: true,
              leading: BackButton(
                key: const ValueKey('memory-tutorial-help-back'),
                onPressed: () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  Navigator.of(context).pop();
                },
              ),
              onComplete: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  bool get _isDark =>
      _stage != _Stage.intro &&
      _stage != _Stage.tutorial &&
      _stage != _Stage.results;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == _Stage.intro || _stage == _Stage.results,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage != _Stage.intro) {
          _seqToken++;
          setState(() => _stage = _Stage.intro);
        }
      },
      child: Scaffold(
        backgroundColor: _isDark ? ZennytGamePalette.gameBlue : Colors.white,
        body: SafeArea(child: _buildStage()),
      ),
    );
  }

  Widget _buildStage() {
    return switch (_stage) {
      _Stage.intro => _IntroView(
        mode: widget.mode,
        onStart: () => setState(() => _stage = _Stage.tutorial),
        onBack: () => context.go(AppRoutes.games),
      ),
      _Stage.tutorial => GameContentFrame(
        child: MemoryQuestTutorial(
          mode: _tutorialMode,
          leading: _BackButton(
            onPressed: () => setState(() => _stage = _Stage.intro),
          ),
          onComplete: _startMission,
        ),
      ),
      _Stage.observeSequence ||
      _Stage.recallSameOrder ||
      _Stage.recallReverseOrder ||
      _Stage.observeObjects ||
      _Stage.manipulateObjects ||
      _Stage.restoreOrder ||
      _Stage.distraction ||
      _Stage.feedback => GameplayMusic(child: _buildGameplay()),
      _Stage.results => _ResultsView(
        // Le composite fait autorité côté repo (mock/backend) ; repli local.
        composite:
            _serverSession?.lastAttempt?.score.normalized.round() ??
            _compositeScore,
        points: _serverSession?.lastAttempt?.score.rawPoints,
        maxPoints: _serverSession?.lastAttempt?.score.maxPoints,
        submitting: _submitting,
        sameScore: _sameTaskScore,
        reverseScore: _reverseTaskScore,
        restoreScore: _missionBDone ? _restoreTaskScore : null,
        distractionScore: _distractionDone ? _distractionTaskScore : null,
        distractionQuestionCorrect: _distractQuestionCorrect,
        highestLength: _highestLength,
        onReplay: _startMission,
        onBack: () => context.go(AppRoutes.games),
      ),
    };
  }

  String get _lang =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'fr' ? 'fr' : 'en';

  bool get _isMissionB =>
      _stage == _Stage.observeObjects ||
      _stage == _Stage.manipulateObjects ||
      _stage == _Stage.restoreOrder;

  bool get _isDistraction => _stage == _Stage.distraction;

  Widget _buildGameplay() {
    final phaseLabel = switch (_stage) {
      _Stage.observeSequence => 'Memorize',
      _Stage.recallSameOrder => 'Recall',
      _Stage.recallReverseOrder => 'Recall ↺',
      _Stage.observeObjects => 'Observation',
      _Stage.manipulateObjects => 'Manipulation',
      _Stage.restoreOrder => 'Restore',
      _Stage.distraction => 'Distraction',
      _ => 'Check',
    };
    // Le bandeau de charge annonce ce que le joueur doit tenir en mémoire. En
    // mode images il compte des OBJETS, y compris pendant l'interférence :
    // sinon il affichait « 0 digits », la séquence de chiffres n'existant pas.
    final loadChip = !widget.mode.playsDigits
        ? '${_objects.length} objects'
        : _isMissionB
        ? '${_objects.length} objects'
        : _isDistraction
        ? '${_sequence.length} digits'
        : '$_length digits';
    final rightChip = 'Level $_level';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GameHeader(
            onPause: _openMenu,
            affordance: _pauseAllowance.affordance,
          ),
          const SizedBox(height: AppSpacing.base),
          // Trois pastilles de largeur variable (phase / charge / niveau) : en
          // [Row] elles débordaient de ~96 px sur un écran de 320. Un [Wrap]
          // les fait passer à la ligne au lieu de les rogner.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GameRuleChip(
                label: phaseLabel,
                color: Colors.white,
                filled: true,
              ),
              _DarkChip(label: loadChip),
              _DarkChip(label: rightChip),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: switch (_stage) {
              _Stage.observeSequence => _ObserveView(
                digit: _showingDigit ? _sequence[_revealIndex] : null,
                index: _revealIndex,
                total: _sequence.length,
                reduceMotion: _reduceMotion,
              ),
              // Le jeu des IMAGES ne montre jamais de chiffres — la question
              // arithmétique appartient au seul jeu des chiffres.
              _Stage.distraction when !widget.mode.playsDigits =>
                _ObjectDistractionView(
                  challenge: _objectChallenge,
                  objectCount: _objects.length,
                  secondsLeft: _distractSecondsLeft,
                  totalSeconds: _distractSeconds,
                  answered: _challengeAnswered,
                  onPick: _answerObjectChallenge,
                ),
              _Stage.distraction => _DistractionView(
                question: _distractQuestionText,
                choices: _distractChoices,
                secondsLeft: _distractSecondsLeft,
                totalSeconds: _distractSeconds,
                reminder: 'Hold the ${_sequence.length} digits in mind',
                onPick: _pickDistraction,
              ),
              _Stage.recallSameOrder ||
              _Stage.recallReverseOrder => _RecallView(
                entry: _entry,
                length: _recallLength,
                reverse: _stage == _Stage.recallReverseOrder,
                // Le rappel direct qui suit l'interférence EST le rappel
                // « après distraction » : c'est la consigne à afficher.
                afterDistraction:
                    _roundHadDistraction && _stage == _Stage.recallSameOrder,
                onKey: _onKey,
                onBackspace: _onBackspace,
                onValidate: _onValidate,
              ),
              _Stage.observeObjects => _ObjectsPhaseView(
                order: _shownOrder,
                languageCode: _lang,
                countdown: Duration(
                  milliseconds: MemoryQuestConfig.objectObservationMs(
                    _objects.length,
                    playerFactor: _playerFactor,
                  ),
                ),
                title: 'Memorize the starting order',
                subtitle:
                    'Watch the objects carefully. You will restore this order later.',
              ),
              _Stage.manipulateObjects => _ObjectsPhaseView(
                order: _shownOrder,
                languageCode: _lang,
                highlightA: _highlightA,
                highlightB: _highlightB,
                title: 'Watch the manipulations',
                subtitle:
                    'Objects are moving. Keep the STARTING order in mind, not the new one.',
              ),
              _Stage.restoreOrder => _RestoreView(
                board: _board,
                ranking: _ranking,
                languageCode: _lang,
                secondsLeft: (_restoreMsLeft / 1000).ceil(),
                progress: _restoreProgress,
                enabled: !_inputLocked,
                onToggleRank: _toggleRank,
                onValidate: _validateRestore,
              ),
              _ => _FeedbackView(correct: _lastCorrect),
            },
          ),
        ],
      ),
    );
  }
}

// ── Header + chips ──────────────────────────────────────────────────────────

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.onPause, required this.affordance});

  final VoidCallback onPause;

  /// Fenêtre de pause encore disponible : sinon le bouton disparaît, la règle
  /// étant qu'il n'y a plus de pause du tout jusqu'à la fin de la partie.
  /// Pause ou sortie : le bouton change d'icône une fois la fenêtre consommée,
  /// il ne disparaît plus. Voir [GameMenuAffordance].
  final GameMenuAffordance affordance;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // [Expanded] et non [Spacer] : le titre doit CÉDER de la place au
        // bouton pause. Sur un écran de 320 px, « Working Memory Mission » à sa
        // largeur naturelle poussait le bouton hors du cadre (débordement 14 px).
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investigate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineLarge.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
              Text(
                'Working Memory Mission',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Cible tactile ≥ 48×48 (WCAG).
        Semantics(
          button: true,
          label: affordance.semanticsLabel,
          child: InkWell(
            onTap: onPause,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(affordance.icon, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.titleSmall.copyWith(
          color: Colors.white,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ── Observe (encodage séquentiel) ────────────────────────────────────────────

class _ObserveView extends StatelessWidget {
  const _ObserveView({
    required this.digit,
    required this.index,
    required this.total,
    required this.reduceMotion,
  });

  final int? digit; // null = blanc ISI
  final int index;
  final int total;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    // Seul le chiffre apparaît et disparaît ; le cadre blanc, lui, ne bouge
    // jamais. Auparavant c'était la carte entière qui portait la clé de
    // l'AnimatedSwitcher : le fond était rejoué à chaque chiffre, si bien que le
    // cadre clignotait en même temps que le nombre. Le repère visuel doit rester
    // fixe — c'est lui qui dit au candidat où regarder pendant tout l'encodage.
    final glyph = Text(
      digit?.toString() ?? '',
      key: ValueKey(digit == null ? 'isi-$index' : 'digit-$index'),
      style: const TextStyle(
        color: ZennytGamePalette.ink,
        fontSize: 96,
        fontWeight: FontWeight.w800,
      ),
    );

    final card = Container(
      key: const ValueKey('digit-frame'),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: reduceMotion
          ? glyph
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: glyph,
            ),
    );

    return Column(
      children: [
        Expanded(child: card),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Digit ${index + 1} of $total',
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            // Le texte doit pouvoir se rétrécir : à sa largeur naturelle il
            // débordait de 146 px sur un écran de 320.
            Flexible(
              child: Text(
                'Watch carefully. Input is locked.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Recall (clavier numérique) ───────────────────────────────────────────────

class _RecallView extends StatelessWidget {
  const _RecallView({
    required this.entry,
    required this.length,
    required this.reverse,
    required this.onKey,
    required this.onBackspace,
    required this.onValidate,
    this.afterDistraction = false,
  });

  final List<int> entry;
  final int length;
  final bool reverse;
  final bool afterDistraction;
  final ValueChanged<int> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final full = entry.length == length;
    // Titre + slots + pavé + Valider dépassent la hauteur utile d'un petit
    // écran (débordement de 130 px sur 320×568). On garde la répartition
    // aérée quand la place existe, et on défile quand elle manque : le
    // [Spacer] d'origine, lui, ne pouvait qu'écraser ou déborder.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: _content(full)),
        ),
      ),
    );
  }

  Widget _content(bool full) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Meme consigne de manche que du cote des images : meme vert, meme
        // clignotement unique. Elle etait en blanc plat, sans appel — or c'est
        // ici que l'ordre bascule du direct a l'inverse, et rien ne signalait
        // le changement. [MemoryPrompt] rejoue son clignotement a chaque
        // nouveau texte : le passage SAME -> REVERSE se remarque de lui-meme.
        MemoryPrompt(
          afterDistraction
              ? 'Now recall the digits you memorized'
              : reverse
              ? 'Type the sequence in REVERSE order'
              : 'Type the sequence in the SAME order',
        ),
        const SizedBox(height: AppSpacing.base),
        // Slots de saisie (l'original reste caché).
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: List.generate(length, (i) {
            final filled = i < entry.length;
            return Container(
              width: 44,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: filled ? 1 : 0.16),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                filled ? '${entry[i]}' : '',
                style: const TextStyle(
                  color: ZennytGamePalette.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Keypad(onKey: onKey, onBackspace: onBackspace),
        const SizedBox(height: AppSpacing.base),
        GamePrimaryButton(
          label: 'Validate',
          onPressed: full ? onValidate : null,
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey, required this.onBackspace});

  final ValueChanged<int> onKey;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {int? digit, VoidCallback? onTap}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Semantics(
            button: true,
            label: digit != null ? 'Digit $digit' : label,
            child: InkWell(
              key: ValueKey(digit != null ? 'kp-$digit' : 'kp-back'),
              onTap: onTap ?? (digit != null ? () => onKey(digit) : null),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                height: 56, // ≥ 48 px
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: label == '⌫'
                    ? const Icon(Icons.backspace_outlined, color: Colors.white)
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) => Row(children: children);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([for (var d = 1; d <= 3; d++) key('$d', digit: d)]),
        row([for (var d = 4; d <= 6; d++) key('$d', digit: d)]),
        row([for (var d = 7; d <= 9; d++) key('$d', digit: d)]),
        row([
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: const SizedBox(),
            ),
          ),
          key('0', digit: 0),
          key('⌫', onTap: onBackspace),
        ]),
      ],
    );
  }
}

// ── Feedback (icône + texte, jamais couleur seule) ──────────────────────────

class _FeedbackView extends StatelessWidget {
  const _FeedbackView({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            correct ? 'Well recalled' : 'Sequence noted',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mission B — objets : observation / manipulation ─────────────────────────

/// Couleur des trois consignes qui portent l'enjeu de la manche : « Memorize
/// the starting order » à l'observation, « Watch the manipulations » pendant la
/// distraction, « Restore the STARTING order » au rappel.
///
/// Retour client : les faire ressortir « pour que le joueur fasse attention ».
/// Une seule constante pour les trois écrans — les consignes qui se répondent
/// doivent se ressembler, et c'est ici qu'on essaie d'autres teintes.
///
/// Vert retenu par le client, l'ambre et le rouge ayant été écartés à l'essai.
/// Sur l'indigo du plateau (#5B4FE8) il tient 3,2:1, au-dessus du seuil de 3:1
/// qu'un titre demande — le rouge, lui, plafonnait à 2,0:1.
/// Budget des tâches parasites (s) — 5–10 s pour une question rapide.
///
/// Au niveau du fichier et non dans l'état de l'écran : les vues en ont besoin
/// pour dessiner la barre de temps, et deux valeurs qui divergeraient
/// donneraient une barre qui ne correspond plus au rebours.
const int _distractSeconds = 8;

/// Dimensions de référence d'une carte d'objet (échelle 1).
///
/// Publiques parce que [memoryObjectTileScaleFor] l'est : sans elles, un test
/// ne peut pas vérifier que la grille tient dans la place annoncée.
const double kMemoryObjectTileWidth = 84;
const double kMemoryObjectTileHeight = 120;

/// Gouttière entre deux cartes d'objets. Ne suit PAS l'échelle : c'est
/// l'espace minimal pour que deux cartes se distinguent, il n'a aucune raison
/// de rétrécir avec elles.
const double _objectTileGap = 12;

/// Plus grande échelle de carte permettant d'afficher [count] cartes dans
/// [available], sans défilement.
///
/// Retour client : « on veut simplement agrandir la taille des cartes des
/// images ». L'échelle était une constante par palier (1,0 jusqu'à 6 objets,
/// puis 0,82, puis 0,68) — elle ignorait donc la place disponible et rapetissait
/// les cartes même sur un grand écran. Ici on essaie chaque découpage en
/// colonnes et on garde celui qui donne les plus grandes cartes.
///
/// Le plafond [_maxObjectTileScale] existe pour qu'un niveau à 3 objets ne
/// produise pas trois cartes démesurées : au-delà, l'image ne gagne plus rien en
/// lisibilité et la grille perd son air de grille.
double memoryObjectTileScaleFor({
  required int count,
  required Size available,
  double gap = _objectTileGap,
}) {
  if (count <= 0 || available.width <= 0 || available.height <= 0) return 1;
  var best = _minObjectTileScale;
  var bestRows = count;
  for (var columns = 1; columns <= count; columns++) {
    final rows = (count / columns).ceil();
    final byWidth =
        (available.width - gap * (columns - 1)) /
        (columns * kMemoryObjectTileWidth);
    final byHeight =
        (available.height - gap * (rows - 1)) /
        (rows * kMemoryObjectTileHeight);
    final fit = math
        .min(byWidth, byHeight)
        .clamp(_minObjectTileScale, _maxObjectTileScale);
    // À taille égale — le cas dès que le plafond est atteint — on préfère le
    // découpage qui tient en moins de rangées : plus large, plus compact, et
    // sans rangée orpheline.
    if (fit > best + 0.001 ||
        ((fit - best).abs() <= 0.001 && rows < bestRows)) {
      best = fit;
      bestRows = rows;
    }
  }
  return best;
}

/// En dessous, l'image d'un objet (52 × 0,62 ≈ 32 px) cesse d'être
/// identifiable : mieux vaut faire défiler que montrer des vignettes illisibles.
const double _minObjectTileScale = 0.62;
const double _maxObjectTileScale = 1.9;

class _ObjectsPhaseView extends StatelessWidget {
  const _ObjectsPhaseView({
    required this.order,
    required this.languageCode,
    required this.title,
    required this.subtitle,
    this.highlightA = -1,
    this.highlightB = -1,
    this.countdown,
  });

  final List<MemoryObject> order;
  final String languageCode;
  final String title;
  final String subtitle;
  final int highlightA;
  final int highlightB;

  /// Durée de la phase quand elle est chronométrée (mémorisation). `null` pour
  /// les phases dont la fin ne dépend pas du joueur — les manipulations, qu'il
  /// n'a qu'à regarder : leur donner un rebours suggérerait une échéance à
  /// tenir alors qu'il n'y a rien à faire.
  final Duration? countdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MemoryPrompt(title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0,
          ),
        ),
        if (countdown != null) ...[
          const SizedBox(height: AppSpacing.md),
          // Animée sur la durée exacte de la phase plutôt que pilotée par un
          // Timer : l'attente est déjà un `Future.delayed`, un second compteur
          // pourrait en diverger et montrer une barre pleine sur un écran qui
          // vient de basculer.
          TweenAnimationBuilder<double>(
            key: ValueKey(order.length),
            tween: Tween<double>(begin: 1, end: 0),
            duration: countdown!,
            builder: (context, value, _) =>
                GameTimerBar(progress: value, color: ZennytGamePalette.cyan),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // Centré quand ça tient, défilable au-delà (jusqu'à 12 objets).
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = memoryObjectTileScaleFor(
                count: order.length,
                available: constraints.biggest,
              );
              return Center(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: _objectTileGap,
                    runSpacing: _objectTileGap,
                    children: [
                      for (var i = 0; i < order.length; i++)
                        _ObjectTile(
                          object: order[i],
                          position: i + 1,
                          languageCode: languageCode,
                          highlight: i == highlightA || i == highlightB,
                          scale: scale,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        const _LockedBar(),
      ],
    );
  }
}

// ── Mission B — restauration (classement au clic) ──────────────────────────

/// Reconstruction de l'ordre initial : **une seule grille, un rang par appui**.
///
/// Le glisser-déposer a été retiré (retour client). Il imposait deux zones —
/// réserve et emplacements — qui se partageaient l'écran, donc des cartes
/// réduites à 84 px et, sur petit gabarit, un empilement à faire défiler. Ici
/// les cartes ne bougent plus : elles reçoivent un rang, et occupent toute la
/// place disponible.
class _RestoreView extends StatelessWidget {
  const _RestoreView({
    required this.board,
    required this.ranking,
    required this.languageCode,
    required this.secondsLeft,
    required this.progress,
    required this.enabled,
    required this.onToggleRank,
    required this.onValidate,
  });

  final List<MemoryObject> board;
  final List<MemoryObject> ranking;
  final String languageCode;

  /// Secondes restantes avant la validation d'office.
  final int secondsLeft;

  /// Fraction de temps restante, pour la barre.
  final double progress;

  final bool enabled;
  final ValueChanged<MemoryObject> onToggleRank;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final complete = ranking.length == board.length;
    return Column(
      children: [
        const MemoryPrompt('Restore the STARTING order'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap the objects in their starting order. Tap a numbered object '
          'again to clear its rank.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GameTimerBar(
          progress: progress,
          label: '${secondsLeft}s left',
          // Les dernières secondes se signalent : le rebours valide d'office,
          // le joueur doit pouvoir l'anticiper plutôt que le subir.
          color: secondsLeft <= 3
              ? ZennytGamePalette.error
              : ZennytGamePalette.success,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = memoryObjectTileScaleFor(
                count: board.length,
                available: constraints.biggest,
              );
              return Center(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: _objectTileGap,
                    runSpacing: _objectTileGap,
                    children: [
                      for (final obj in board)
                        _ObjectTile(
                          object: obj,
                          languageCode: languageCode,
                          // Rang choisi par le joueur, ou rien s'il ne l'a pas
                          // encore classé.
                          position: _rankOf(obj),
                          ranked: true,
                          scale: scale,
                          onTap: enabled ? () => onToggleRank(obj) : null,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        GamePrimaryButton(
          label: 'Validate',
          onPressed: complete && enabled ? onValidate : null,
        ),
      ],
    );
  }

  int? _rankOf(MemoryObject obj) {
    final at = ranking.indexWhere((o) => o.id == obj.id);
    return at < 0 ? null : at + 1;
  }
}

class _ObjectTile extends StatelessWidget {
  const _ObjectTile({
    required this.object,
    required this.languageCode,
    this.position,
    this.ranked = false,
    this.highlight = false,
    this.onTap,
    this.scale = 1.0,
  });

  final MemoryObject object;
  final String languageCode;

  /// Numéro affiché en haut de la carte : le rang réel pendant l'observation,
  /// le rang CHOISI par le joueur pendant la restauration. `null` = aucun.
  final int? position;

  /// Le numéro est un choix du joueur (restauration) et non une donnée de
  /// l'énoncé (observation) : la pastille se colore pour le dire.
  final bool ranked;

  final bool highlight;
  final VoidCallback? onTap;

  /// Facteur d'échelle appliqué à toute la carte, calculé par
  /// [_objectTileScaleFor] d'après la place réellement disponible.
  final double scale;

  /// Dimensions de référence d'une carte (échelle 1).
  ///
  /// ⚠️ [_baseHeight] doit garder de la marge sur la hauteur RÉELLE du contenu
  /// (padding + pastille + image + libellé) : la carte a une taille fixe, donc
  /// tout rognage se paie en `RenderFlex overflow` — d'autant plus aux échelles
  /// réduites, où les arrondis jouent contre nous.
  static const double _baseWidth = kMemoryObjectTileWidth;
  static const double _baseHeight = kMemoryObjectTileHeight;
  static const double _baseImage = 52;
  static const double _basePadding = 6;
  static const double _baseBadge = 20;

  @override
  Widget build(BuildContext context) {
    final rank = position;
    // Carte translucide « givrée » (plus de fond blanc plein) : les objets 2.5D
    // ressortent directement sur le fond violet.
    final tile = Container(
      width: _baseWidth * scale,
      height: _baseHeight * scale,
      padding: EdgeInsets.symmetric(
        vertical: _basePadding * scale,
        horizontal: _basePadding * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: rank != null && ranked ? 0.24 : 0.16,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: highlight || (rank != null && ranked)
              ? ZennytGamePalette.magenta
              : Colors.white.withValues(alpha: 0.28),
          width: highlight || (rank != null && ranked) ? 3 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // La gouttière du numéro est TOUJOURS réservée : sans cela, classer un
          // objet ferait sauter son image et son libellé d'une vingtaine de
          // pixels sous le doigt qui vient de le toucher.
          SizedBox(
            height: _baseBadge * scale,
            child: rank == null
                ? null
                : Center(
                    child: _RankBadge(rank: rank, ranked: ranked, scale: scale),
                  ),
          ),
          SizedBox(height: 2 * scale),
          Image.asset(
            object.assetPath,
            width: _baseImage * scale,
            height: _baseImage * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 4 * scale),
          Text(
            object.label(languageCode),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Sur une carte à taille fixe, laisser le libellé suivre le
            // textScale système le ferait déborder ; la carte reste lisible car
            // l'image porte l'essentiel, et Semantics annonce le nom complet.
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final label = object.label(languageCode);
    if (onTap == null) {
      return Semantics(label: label, child: tile);
    }
    return Semantics(
      button: true,
      label: rank == null ? label : '$label, rank $rank',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: tile,
      ),
    );
  }
}

/// Le « petit numéro affiché en haut de l'objet » demandé par le client.
class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.ranked,
    required this.scale,
  });

  final int rank;
  final bool ranked;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = _ObjectTile._baseBadge * scale;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ranked
            ? ZennytGamePalette.magenta
            : Colors.white.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * scale,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LockedBar extends StatelessWidget {
  const _LockedBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: ZennytGamePalette.ink,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Input locked',
            style: AppTypography.titleSmall.copyWith(
              color: Colors.white,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phase de distraction (calme, fond assombri, rappel mémoire visible) ─────

/// Interférence du jeu d'IMAGES — **une épreuve par niveau, tirée au hasard**
/// entre « trouver l'intrus » et « pièce manquante ».
///
/// Les visuels sont des glyphes monochromes dédiés
/// (`assets/J’investigue/distractors/`), teintés avec la palette des jeux : les
/// objets 2.5D du catalogue sont multicolores et ne peuvent pas être reteintés,
/// donc ne permettent pas de faire varier la COULEUR — l'un des quatre traits
/// sur lesquels l'intrus doit pouvoir se distinguer.
///
/// **Aucun chiffre** n'apparaît ici : c'est la règle du jeu des images.
class _ObjectDistractionView extends StatelessWidget {
  const _ObjectDistractionView({
    required this.challenge,
    required this.objectCount,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.answered,
    required this.onPick,
  });

  final MemoryDistractionChallenge? challenge;
  final int objectCount;
  final int secondsLeft;

  /// Budget total de l'épreuve, en secondes — la barre a besoin du dénominateur.
  ///
  /// Passé par l'appelant et non lu sur une constante de l'écran : la vue est
  /// aussi montée avec d'autres budgets (captures), et une barre calculée sur le
  /// mauvais total reste bloquée à plein.
  final int totalSeconds;

  final bool answered;
  final ValueChanged<int> onPick;

  /// Teintes des glyphes, prises dans la palette des jeux.
  ///
  /// Aucune ne doit être proche du fond du plateau (`gameBlue`, un bleu-violet) :
  /// un glyphe de la couleur du fond disparaît, et l'épreuve devient
  /// indéchiffrable. C'est pourquoi `gameBlue` et le violet voisin en sont
  /// exclus au profit d'un ambre et d'un lilas clair, qui ressortent tous deux.
  static const List<Color> palette = [
    ZennytGamePalette.magenta,
    ZennytGamePalette.cyan,
    ZennytGamePalette.success,
    ZennytGamePalette.ruleOrange,
    Color(0xFFFBC02D), // ambre
    Color(0xFFC9A6FF), // lilas clair
  ];

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    if (c == null) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          c.kind == MemoryDistractionKind.oddOneOut
              ? 'Find the odd one out'
              : 'Complete the pattern',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Hold the $objectCount objects in mind',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GameTimerBar(
          progress: totalSeconds <= 0 ? 0 : secondsLeft / totalSeconds,
          label: '${secondsLeft}s',
          color: secondsLeft <= 3
              ? ZennytGamePalette.error
              : ZennytGamePalette.success,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: switch (c) {
            OddOneOutChallenge() => _OddOneOutBoard(
              challenge: c,
              answered: answered,
              onPick: onPick,
            ),
            PuzzlePieceChallenge() => _PuzzleBoard(
              challenge: c,
              answered: answered,
              onPick: onPick,
            ),
          },
        ),
      ],
    );
  }
}

/// Grille d'éléments presque identiques : une seule case diffère.
class _OddOneOutBoard extends StatelessWidget {
  const _OddOneOutBoard({
    required this.challenge,
    required this.answered,
    required this.onPick,
  });

  final OddOneOutChallenge challenge;
  final bool answered;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // Grille bornée en largeur : sans contrainte, les cases s'étirent sur
        // toute la largeur et la troisième rangée sort de l'écran.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: challenge.cells.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: challenge.columns,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (context, i) {
              final cell = challenge.cells[i];
              return _GlyphTile(
                key: ValueKey('odd-cell-$i'),
                glyph: cell.glyph,
                pattern: cell.pattern,
                colorIndex: cell.colorIndex,
                quarterTurns: cell.quarterTurns,
                scale: cell.scale,
                // Le retour n'apparaît qu'APRÈS la réponse : le souligner avant
                // donnerait l'épreuve.
                revealed: answered && cell.isOdd,
                onTap: answered ? null : () => onPick(i),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Motif régulier troué : il faut désigner la pièce qui le complète.
class _PuzzleBoard extends StatelessWidget {
  const _PuzzleBoard({
    required this.challenge,
    required this.answered,
    required this.onPick,
  });

  final PuzzlePieceChallenge challenge;
  final bool answered;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Le motif, avec son trou.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenge.tiles.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: challenge.gridSide,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemBuilder: (context, i) {
                if (i == challenge.missingIndex) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 26,
                      ),
                    ),
                  );
                }
                final tile = challenge.tiles[i];
                return _GlyphTile(
                  glyph: tile.glyph,
                  pattern: MemoryPattern.none,
                  colorIndex: tile.colorIndex,
                  quarterTurns: tile.quarterTurns,
                  scale: 1,
                  revealed: false,
                  onTap: null,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pick the missing piece',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < challenge.options.length; i++)
                SizedBox(
                  width: 68,
                  height: 68,
                  child: _GlyphTile(
                    key: ValueKey('puzzle-option-$i'),
                    glyph: challenge.options[i].glyph,
                    pattern: MemoryPattern.none,
                    colorIndex: challenge.options[i].colorIndex,
                    quarterTurns: challenge.options[i].quarterTurns,
                    scale: 1,
                    revealed: answered && challenge.options[i].isCorrect,
                    onTap: answered ? null : () => onPick(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Une case d'épreuve : glyphe teinté, motif éventuel, rotation, échelle.
class _GlyphTile extends StatelessWidget {
  const _GlyphTile({
    super.key,
    required this.glyph,
    required this.pattern,
    required this.colorIndex,
    required this.quarterTurns,
    required this.scale,
    required this.revealed,
    required this.onTap,
  });

  final MemoryGlyph glyph;
  final MemoryPattern pattern;
  final int colorIndex;
  final int quarterTurns;
  final double scale;
  final bool revealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _ObjectDistractionView
        .palette[colorIndex % _ObjectDistractionView.palette.length];
    final patternAsset = pattern.assetPath;
    return Semantics(
      button: onTap != null,
      label: '${glyph.name} tile',
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: revealed
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.22),
                width: revealed ? 3 : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Transform.scale(
                scale: scale,
                child: RotatedBox(
                  quarterTurns: quarterTurns,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        glyph.assetPath,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
                      if (patternAsset != null)
                        SvgPicture.asset(
                          patternAsset,
                          colorFilter: ColorFilter.mode(
                            Colors.white.withValues(alpha: 0.85),
                            BlendMode.srcIn,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DistractionView extends StatelessWidget {
  const _DistractionView({
    required this.question,
    required this.choices,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.reminder,
    required this.onPick,
  });

  final String question;
  final List<int> choices;
  final int secondsLeft;

  /// Budget total de la question, en secondes — dénominateur de la barre.
  final int totalSeconds;

  final String reminder;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rappel mémoire — reste visible pendant la distraction.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reminder,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Quick check',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GameTimerBar(
          progress: totalSeconds <= 0 ? 0 : secondsLeft / totalSeconds,
          label: '${secondsLeft}s',
          color: secondsLeft <= 3
              ? ZennytGamePalette.error
              : ZennytGamePalette.success,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          ),
          child: Text(
            question,
            style: const TextStyle(
              color: ZennytGamePalette.ink,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (final c in choices) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Semantics(
                    button: true,
                    label: 'Answer $c',
                    child: InkWell(
                      key: ValueKey('choice-$c'),
                      onTap: () => onPick(c),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Container(
                        height: 56, // ≥ 48 px
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Text(
                          '$c',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

// ── Intro (reprend la structure Move Fast) ──────────────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.onStart,
    required this.onBack,
    required this.mode,
  });
  final VoidCallback onStart;
  final VoidCallback onBack;
  final InvestigateMode mode;

  @override
  Widget build(BuildContext context) => GameWelcomePage(
    title: switch (mode) {
      InvestigateMode.digits => 'Memory Quest · Digits',
      InvestigateMode.images => 'Memory Quest · Images',
      InvestigateMode.full => 'Memory Quest',
    },
    logoAsset: 'assets/games icons/Memory Quest transparent.png',
    mission: switch (mode) {
      InvestigateMode.images =>
        'Observe les images, puis retrouve leur ordre de départ.',
      InvestigateMode.digits =>
        'Mémorise les chiffres, puis restitue-les dans le bon ordre.',
      InvestigateMode.full =>
        'Mémorise les chiffres et les images, puis retrouve leur ordre.',
    },
    contextText: switch (mode) {
      InvestigateMode.digits =>
        'Une séquence apparaît, puis disparaît. Garde-la en tête pour la restituer dans les deux sens.',
      InvestigateMode.images =>
        'Les images changent de place. Ton défi : garder leur premier ordre en mémoire.',
      InvestigateMode.full =>
        'Chiffres et images mettent ta mémoire à l’épreuve. Garde le fil malgré les interruptions.',
    },
    journey: switch (mode) {
      InvestigateMode.digits => const ['Observe', 'Retiens', 'Restitue'],
      InvestigateMode.images => const ['Observe', 'Retiens', 'Classe'],
      InvestigateMode.full => const ['Observe', 'Retiens', 'Restitue'],
    },
    leading: _BackButton(onPressed: onBack),
    startLabel: 'Start mission',
    onStart: onStart,
  );
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.composite,
    required this.points,
    required this.maxPoints,
    required this.submitting,
    required this.sameScore,
    required this.reverseScore,
    required this.restoreScore,
    required this.distractionScore,
    required this.distractionQuestionCorrect,
    required this.highestLength,
    required this.onReplay,
    required this.onBack,
  });

  final int composite;
  final int? points;
  final int? maxPoints;
  final bool submitting;
  final int sameScore;
  final int reverseScore;
  final int? restoreScore; // null si la Mission B n'a pas été jouée
  final int? distractionScore; // null si la distraction n'a pas été jouée
  final bool distractionQuestionCorrect;
  final int highestLength;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // Modèle commun des écrans de résultats ([GameResultsTemplate]).
    return GameResultsTemplate(
      onBack: onBack,
      gameName: 'Memory Quest',
      pending: submitting,
      scoreLabel: 'Memory score',
      scorePercent: composite,
      points: points,
      maxPoints: maxPoints,
      stats: [
        GameResultStat(
          label: 'Same order',
          value: '$sameScore/5',
          color: ZennytGamePalette.success,
        ),
        GameResultStat(label: 'Reverse', value: '$reverseScore/5'),
        restoreScore == null
            ? GameResultStat(
                label: 'Best span',
                value: '$highestLength',
                color: ZennytGamePalette.magenta,
              )
            : GameResultStat(
                label: 'Restore',
                value: '$restoreScore/5',
                color: ZennytGamePalette.magenta,
              ),
      ],
      insight:
          'You recalled sequences up to $highestLength digits. '
          'Same-order recall is usually easier than reverse recall, '
          'which loads working memory more.'
          '${restoreScore == null ? '' : ' In the object task you restored '
                    'the starting order despite the manipulations you watched.'}'
          '${distractionScore == null ? '' : ' After a distraction you recalled '
                    '$distractionScore/5, and the quick check was '
                    '${distractionQuestionCorrect ? 'correct' : 'missed'}.'}'
          ' Indicative score — not a diagnosis.',
      primaryLabel: 'Replay',
      onPrimary: onReplay,
      secondaryLabel: 'Back to games',
      onSecondary: onBack,
    );
  }
}

// ── Petits composants ────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ZennytGamePalette.mist,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(Icons.chevron_left, color: ZennytGamePalette.blue),
        ),
      ),
    );
  }
}

/// Rendu isolé d'une tâche parasite — **relecture visuelle uniquement**.
///
/// Les deux épreuves ne sont atteignables en jeu qu'au niveau 3, après deux
/// niveaux joués : les capturer par ce point d'entrée évite de dérouler toute
/// une partie pour relire un écran.
@visibleForTesting
Widget debugObjectDistractionView({
  required MemoryDistractionChallenge challenge,
  required int objectCount,
  required int secondsLeft,
  int? totalSeconds,
}) => _ObjectDistractionView(
  challenge: challenge,
  objectCount: objectCount,
  secondsLeft: secondsLeft,
  totalSeconds: totalSeconds ?? secondsLeft,
  answered: false,
  onPick: (_) {},
);
