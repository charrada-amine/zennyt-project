import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/memory_object.dart';
import '../../domain/entities/memory_quest_metrics.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/score_breakdown.dart';
import '../games_providers.dart';
import '../widgets/game_system_components.dart';
import '../widgets/score_detail_panel.dart';

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
    @visibleForTesting this.seed,
    @visibleForTesting this.onMissionBReady,
    @visibleForTesting this.onDistractionReady,
  });

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

enum _Stage {
  intro,
  tutorial,
  observeSequence,
  recallSameOrder,
  recallReverseOrder,
  observeObjects,
  manipulateObjects,
  restoreOrder,
  distractionEncode,
  distraction,
  recallAfterDistraction,
  feedback,
  results,
}

class _InvestigateScreenState extends ConsumerState<InvestigateScreen> {
  // Session serveur (mock hors-ligne / backend) : le score fait autorité côté repo.
  Future<GameSession>? _sessionStart;
  GameSession? _serverSession;
  bool _submitting = false;

  // ── Timers (data-driven, cf. handoff §6/§8) ──────────────────────────────
  static const int _digitVisibleMs = 900; // affichage d'un chiffre
  static const int _isiMs = 250; // blanc inter-stimulus (input verrouillé)
  static const int _feedbackMs = 250;

  // ── Progression Digit Span ───────────────────────────────────────────────
  static const int _startLength = 4;
  static const int _maxLength = 9;

  late final math.Random _random =
      widget.seed == null ? math.Random() : math.Random(widget.seed!);

  _Stage _stage = _Stage.intro;
  bool _paused = false;

  // Round courant.
  int _length = _startLength;
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

  // ── Mission B — manipulation d'objets (niveau 1) ─────────────────────────
  static const int _bObjectCount = 4; // 4 objets au niveau 1
  static const int _bManipulations = 2; // 2 manipulations automatiques
  static const int _observeObjectsMs = 5000; // « 5 sec »
  static const int _manipStepMs = 750;

  List<MemoryObject> _objects = const []; // ordre INITIAL à restaurer
  List<MemoryObject> _shownOrder = const []; // ordre affiché (observe/manipulation)
  int _highlightA = -1;
  int _highlightB = -1;
  List<MemoryObject?> _slots = const []; // restauration (tap-to-place)
  List<MemoryObject> _pool = const [];
  int _restoreCorrect = 0;
  bool _missionBDone = false;
  int _objToken = 0; // annule une phase objet en cours (pause/dispose)

  // ── Phase de distraction (résistance à l'interférence) ────────────────────
  static const int _distractLength = 4; // séquence à protéger
  static const int _distractSeconds = 8; // 5–10 s (question rapide)

  List<int> _distractSeq = const []; // séquence encodée avant la distraction
  String _distractQuestionText = '';
  int _distractQuestionAnswer = 0; // réponse correcte de la question
  List<int> _distractChoices = const [];
  bool _distractQuestionCorrect = false;
  int _distractSecondsLeft = 0;
  Timer? _distractTimer;
  int _afterDistractObserved = 0;
  int _afterDistractCorrect = 0;
  bool _distractionDone = false;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  bool get _inputLocked =>
      _paused ||
      _stage == _Stage.observeSequence ||
      _stage == _Stage.observeObjects ||
      _stage == _Stage.manipulateObjects ||
      _stage == _Stage.distractionEncode ||
      _stage == _Stage.feedback;

  /// Longueur du rappel courant (Mission A vs rappel après distraction).
  int get _recallLength =>
      _stage == _Stage.recallAfterDistraction ? _distractSeq.length : _length;

  @override
  void dispose() {
    _seqToken++; // stoppe toute observation planifiée
    _objToken++;
    _distractTimer?.cancel();
    super.dispose();
  }

  // ── Cycle de jeu ─────────────────────────────────────────────────────────

  void _startMission() {
    setState(() {
      _length = _startLength;
      _observedDigits = 0;
      _correctSameDigits = 0;
      _correctReverseDigits = 0;
      _highestLength = 0;
      _missionBDone = false;
      _restoreCorrect = 0;
      _objects = const [];
      _distractionDone = false;
      _afterDistractObserved = 0;
      _afterDistractCorrect = 0;
      _distractQuestionCorrect = false;
      _serverSession = null;
      _submitting = false;
    });
    _distractTimer?.cancel();
    // Démarre la session côté repo (mock hors-ligne / backend online).
    _sessionStart = ref.read(gamesRepositoryProvider).startSession(GameType.memoryQuest);
    _beginRound();
  }

  void _beginRound() {
    _sequence = List<int>.generate(_length, (_) => _random.nextInt(10));
    _entry.clear();
    setState(() {
      _stage = _Stage.observeSequence;
      _revealIndex = 0;
      _showingDigit = false;
    });
    _runObservation();
  }

  Future<void> _runObservation() async {
    final token = ++_seqToken;
    // Court délai avant le 1er chiffre (état calme, pas de flash).
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (var i = 0; i < _sequence.length; i++) {
      if (!mounted || token != _seqToken) return;
      setState(() {
        _revealIndex = i;
        _showingDigit = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: _digitVisibleMs));
      if (!mounted || token != _seqToken) return;
      setState(() => _showingDigit = false); // ISI (blanc, input verrouillé)
      await Future<void>.delayed(const Duration(milliseconds: _isiMs));
    }
    if (!mounted || token != _seqToken) return;
    setState(() {
      _observedDigits += _sequence.length;
      _entry.clear();
      _stage = _Stage.recallSameOrder;
    });
  }

  void _onKey(int digit) {
    if (_inputLocked || _entry.length >= _recallLength) return;
    setState(() => _entry.add(digit));
  }

  void _onBackspace() {
    if (_inputLocked || _entry.isEmpty) return;
    setState(() => _entry.removeLast());
  }

  void _onValidate() {
    if (_inputLocked || _entry.length != _recallLength) return;

    if (_stage == _Stage.recallAfterDistraction) {
      _afterDistractObserved += _distractSeq.length;
      _afterDistractCorrect += _matchingDigits(_entry, _distractSeq);
      _distractionDone = true;
      _finishAndSubmit(); // fin de mission → soumission au repo
      return;
    }

    if (_stage == _Stage.recallSameOrder) {
      _correctSameDigits += _matchingDigits(_entry, _sequence);
      setState(() {
        _stage = _Stage.recallReverseOrder;
        _entry.clear();
      });
      return;
    }

    // recallReverseOrder → fin du round.
    final reversed = _sequence.reversed.toList();
    _correctReverseDigits += _matchingDigits(_entry, reversed);
    final roundPerfect =
        _entry.length == reversed.length && _listEquals(_entry, reversed);
    // Un round « réussi » = rappel inverse parfait (la charge la plus élevée).
    if (roundPerfect) _highestLength = math.max(_highestLength, _length);
    _lastCorrect = roundPerfect;

    setState(() => _stage = _Stage.feedback);
    Future<void>.delayed(const Duration(milliseconds: _feedbackMs + 550), () {
      if (!mounted) return;
      if (roundPerfect && _length < _maxLength) {
        _length++;
        _beginRound();
      } else {
        _beginMissionB(); // Mission A terminée → manipulation d'objets
      }
    });
  }

  // ── Mission B — manipulation d'objets ────────────────────────────────────

  void _beginMissionB() {
    final pool = List<MemoryObject>.of(kMemoryObjectLibrary)..shuffle(_random);
    _objects = pool.take(_bObjectCount).toList(); // ordre INITIAL à mémoriser
    _shownOrder = List<MemoryObject>.of(_objects);
    _highlightA = -1;
    _highlightB = -1;
    widget.onMissionBReady?.call(_objects); // hook de test
    setState(() => _stage = _Stage.observeObjects);
    _runObserveThenManipulate();
  }

  Future<void> _runObserveThenManipulate() async {
    final token = ++_objToken;
    // Phase d'observation (ordre initial visible, saisie verrouillée).
    await Future<void>.delayed(const Duration(milliseconds: _observeObjectsMs));
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
      await Future<void>.delayed(const Duration(milliseconds: _manipStepMs));
      if (!mounted || token != _objToken) return;
      setState(() {
        final tmp = _shownOrder[a];
        _shownOrder[a] = _shownOrder[b];
        _shownOrder[b] = tmp;
      });
      await Future<void>.delayed(const Duration(milliseconds: _manipStepMs));
    }

    if (!mounted || token != _objToken) return;
    // Restauration : l'utilisateur reconstruit l'ORDRE INITIAL (pas l'état final).
    setState(() {
      _highlightA = -1;
      _highlightB = -1;
      _slots = List<MemoryObject?>.filled(_objects.length, null);
      _pool = List<MemoryObject>.of(_objects)..shuffle(_random);
      _stage = _Stage.restoreOrder;
    });
  }

  void _placeFromPool(MemoryObject obj) {
    if (_inputLocked) return;
    final slot = _slots.indexOf(null);
    if (slot < 0) return;
    setState(() {
      _slots[slot] = obj;
      _pool.remove(obj);
    });
  }

  void _removeFromSlot(int slot) {
    if (_inputLocked || _slots[slot] == null) return;
    setState(() {
      _pool.add(_slots[slot]!);
      _slots[slot] = null;
    });
  }

  void _validateRestore() {
    if (_inputLocked || _slots.contains(null)) return;
    _restoreCorrect = 0;
    for (var i = 0; i < _objects.length; i++) {
      if (_slots[i]?.id == _objects[i].id) _restoreCorrect++;
    }
    _missionBDone = true;
    _beginDistraction(); // Mission B terminée → phase de distraction
  }

  // ── Phase de distraction ─────────────────────────────────────────────────

  void _beginDistraction() {
    _distractSeq = List<int>.generate(_distractLength, (_) => _random.nextInt(10));
    _entry.clear();
    // Question rapide : addition simple a + b.
    final a = 1 + _random.nextInt(9);
    final b = 1 + _random.nextInt(9);
    _distractQuestionAnswer = a + b;
    _distractQuestionText = '$a + $b = ?';
    _distractChoices = _buildChoices(_distractQuestionAnswer);
    _distractQuestionCorrect = false;
    widget.onDistractionReady?.call(_distractSeq, _distractQuestionAnswer);
    setState(() {
      _stage = _Stage.distractionEncode;
      _revealIndex = 0;
      _showingDigit = false;
    });
    _runDistractionEncode();
  }

  List<int> _buildChoices(int answer) {
    final set = <int>{answer};
    while (set.length < 3) {
      final delta = 1 + _random.nextInt(3);
      set.add(_random.nextBool() ? answer + delta : answer - delta);
    }
    final list = set.toList()..shuffle(_random);
    return list;
  }

  Future<void> _runDistractionEncode() async {
    final token = ++_seqToken;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (var i = 0; i < _distractSeq.length; i++) {
      if (!mounted || token != _seqToken) return;
      setState(() {
        _revealIndex = i;
        _showingDigit = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: _digitVisibleMs));
      if (!mounted || token != _seqToken) return;
      setState(() => _showingDigit = false);
      await Future<void>.delayed(const Duration(milliseconds: _isiMs));
    }
    if (!mounted || token != _seqToken) return;
    _startDistractionCountdown();
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

  void _pickDistraction(int choice) {
    if (_stage != _Stage.distraction) return;
    _distractQuestionCorrect = choice == _distractQuestionAnswer;
    _endDistraction();
  }

  void _endDistraction() {
    _distractTimer?.cancel();
    _entry.clear();
    setState(() => _stage = _Stage.recallAfterDistraction);
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
    );
  }

  Future<void> _finishAndSubmit() async {
    setState(() {
      _stage = _Stage.results;
      _submitting = true;
    });
    try {
      final session = await (_sessionStart ??=
          ref.read(gamesRepositoryProvider).startSession(GameType.memoryQuest));
      final updated = await ref.read(gamesRepositoryProvider).submitResult(
            sessionId: session.id,
            miniGame: MiniGame.memoryQuestCore,
            metrics: _buildMetrics(),
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

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  Future<void> _openPause() async {
    if (_stage == _Stage.intro ||
        _stage == _Stage.tutorial ||
        _stage == _Stage.results) {
      return;
    }
    _seqToken++; // gèle les phases verrouillées en cours
    _objToken++;
    _distractTimer?.cancel();
    setState(() => _paused = true);
    final action = await showDialog<_PauseAction>(
      context: context,
      barrierColor: ZennytGamePalette.ink.withValues(alpha: 0.82),
      builder: (_) => const _PauseDialog(),
    );
    if (!mounted) return;
    if (action == _PauseAction.exit) {
      context.go(AppRoutes.games);
      return;
    }
    setState(() => _paused = false);
    // Reprise : on rejoue la phase (verrouillée) courante depuis son début.
    if (_stage == _Stage.observeSequence) {
      _beginRound();
    } else if (_stage == _Stage.observeObjects ||
        _stage == _Stage.manipulateObjects) {
      _beginMissionB();
    } else if (_stage == _Stage.distractionEncode ||
        _stage == _Stage.distraction) {
      _beginDistraction();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  bool get _isDark =>
      _stage != _Stage.intro &&
      _stage != _Stage.tutorial &&
      _stage != _Stage.results;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == _Stage.intro ||
          _stage == _Stage.results,
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
          onStart: () => setState(() => _stage = _Stage.tutorial),
          onBack: () => context.go(AppRoutes.games),
        ),
      _Stage.tutorial => _TutorialView(
          onStart: _startMission,
          onBack: () => setState(() => _stage = _Stage.intro),
        ),
      _Stage.observeSequence ||
      _Stage.recallSameOrder ||
      _Stage.recallReverseOrder ||
      _Stage.observeObjects ||
      _Stage.manipulateObjects ||
      _Stage.restoreOrder ||
      _Stage.distractionEncode ||
      _Stage.distraction ||
      _Stage.recallAfterDistraction ||
      _Stage.feedback =>
        _buildGameplay(),
      _Stage.results => _ResultsView(
          // Le composite fait autorité côté repo (mock/backend) ; repli local.
          composite:
              _serverSession?.lastAttempt?.score.normalized.round() ?? _compositeScore,
          submitting: _submitting,
          breakdown: _serverSession?.scoreBreakdown ?? const [],
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

  bool get _isDistraction =>
      _stage == _Stage.distractionEncode ||
      _stage == _Stage.distraction ||
      _stage == _Stage.recallAfterDistraction;

  Widget _buildGameplay() {
    final phaseLabel = switch (_stage) {
      _Stage.observeSequence => 'Memorize',
      _Stage.recallSameOrder => 'Recall',
      _Stage.recallReverseOrder => 'Recall ↺',
      _Stage.observeObjects => 'Observation',
      _Stage.manipulateObjects => 'Manipulation',
      _Stage.restoreOrder => 'Restore',
      _Stage.distractionEncode => 'Memorize',
      _Stage.distraction => 'Distraction',
      _Stage.recallAfterDistraction => 'Recall',
      _ => 'Check',
    };
    final loadChip = _isMissionB
        ? '${_objects.length} objects'
        : _isDistraction
            ? '${_distractSeq.length} digits'
            : '$_length digits';
    final rightChip = _isMissionB
        ? 'Mission B'
        : _isDistraction
            ? 'Focus'
            : 'Span $_highestLength';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GameHeader(onPause: _openPause),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              GameRuleChip(
                label: phaseLabel,
                color: Colors.white,
                filled: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              _DarkChip(label: loadChip),
              const Spacer(),
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
              _Stage.distractionEncode => _ObserveView(
                  digit: _showingDigit ? _distractSeq[_revealIndex] : null,
                  index: _revealIndex,
                  total: _distractSeq.length,
                  reduceMotion: _reduceMotion,
                ),
              _Stage.distraction => _DistractionView(
                  question: _distractQuestionText,
                  choices: _distractChoices,
                  secondsLeft: _distractSecondsLeft,
                  reminder: 'Hold the ${_distractSeq.length} digits in mind',
                  onPick: _pickDistraction,
                ),
              _Stage.recallSameOrder ||
              _Stage.recallReverseOrder ||
              _Stage.recallAfterDistraction =>
                _RecallView(
                  entry: _entry,
                  length: _recallLength,
                  reverse: _stage == _Stage.recallReverseOrder,
                  afterDistraction: _stage == _Stage.recallAfterDistraction,
                  onKey: _onKey,
                  onBackspace: _onBackspace,
                  onValidate: _onValidate,
                ),
              _Stage.observeObjects => _ObjectsPhaseView(
                  order: _shownOrder,
                  languageCode: _lang,
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
                  slots: _slots,
                  pool: _pool,
                  languageCode: _lang,
                  onPlace: _placeFromPool,
                  onRemove: _removeFromSlot,
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
  const _GameHeader({required this.onPause});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Investigate',
              style: AppTypography.headlineLarge.copyWith(
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
            Text(
              'Working Memory Mission',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Cible tactile ≥ 48×48 (WCAG).
        Semantics(
          button: true,
          label: 'Pause',
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
              child: const Icon(Icons.pause_rounded, color: Colors.white),
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
    final card = Container(
      key: ValueKey(digit == null ? 'isi-$index' : 'digit-$index'),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Text(
        digit?.toString() ?? '',
        style: const TextStyle(
          color: ZennytGamePalette.ink,
          fontSize: 96,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Column(
      children: [
        Expanded(
          child: reduceMotion
              ? card
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: card,
                ),
        ),
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
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Watch carefully. Input is locked.',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                letterSpacing: 0,
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
    return Column(
      children: [
        Text(
          afterDistraction
              ? 'Now recall the digits you memorized'
              : reverse
                  ? 'Type the sequence in REVERSE order'
                  : 'Type the sequence in the SAME order',
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            letterSpacing: 0,
          ),
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
        const Spacer(),
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

    Widget row(List<Widget> children) =>
        Row(children: children);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([for (var d = 1; d <= 3; d++) key('$d', digit: d)]),
        row([for (var d = 4; d <= 6; d++) key('$d', digit: d)]),
        row([for (var d = 7; d <= 9; d++) key('$d', digit: d)]),
        row([
          Expanded(child: Padding(padding: const EdgeInsets.all(5), child: const SizedBox())),
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

class _ObjectsPhaseView extends StatelessWidget {
  const _ObjectsPhaseView({
    required this.order,
    required this.languageCode,
    required this.title,
    required this.subtitle,
    this.highlightA = -1,
    this.highlightB = -1,
  });

  final List<MemoryObject> order;
  final String languageCode;
  final String title;
  final String subtitle;
  final int highlightA;
  final int highlightB;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < order.length; i++)
              _ObjectTile(
                object: order[i],
                position: i + 1,
                languageCode: languageCode,
                highlight: i == highlightA || i == highlightB,
              ),
          ],
        ),
        const Spacer(),
        const _LockedBar(),
      ],
    );
  }
}

// ── Mission B — restauration (tap-to-place) ─────────────────────────────────

class _RestoreView extends StatelessWidget {
  const _RestoreView({
    required this.slots,
    required this.pool,
    required this.languageCode,
    required this.onPlace,
    required this.onRemove,
    required this.onValidate,
  });

  final List<MemoryObject?> slots;
  final List<MemoryObject> pool;
  final String languageCode;
  final ValueChanged<MemoryObject> onPlace;
  final ValueChanged<int> onRemove;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final full = !slots.contains(null);
    return Column(
      children: [
        Text(
          'Restore the STARTING order',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tap an object to place it in the next slot. Tap a slot to remove it.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Emplacements cibles (ordre à reconstruire).
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < slots.length; i++)
              _ObjectTile(
                object: slots[i],
                position: i + 1,
                languageCode: languageCode,
                onTap: slots[i] == null ? null : () => onRemove(i),
              ),
          ],
        ),
        const Spacer(),
        // Réserve d'objets (mélangée).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final obj in pool)
                _ObjectTile(
                  object: obj,
                  languageCode: languageCode,
                  onTap: () => onPlace(obj),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        GamePrimaryButton(
          label: 'Validate',
          onPressed: full ? onValidate : null,
        ),
      ],
    );
  }
}

class _ObjectTile extends StatelessWidget {
  const _ObjectTile({
    required this.object,
    required this.languageCode,
    this.position,
    this.highlight = false,
    this.onTap,
  });

  final MemoryObject? object; // null = emplacement vide
  final String languageCode;
  final int? position;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final obj = object;
    final tile = Container(
      width: 78,
      height: 96,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: obj == null ? Colors.white.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: highlight
            ? Border.all(color: ZennytGamePalette.magenta, width: 3)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (position != null)
            Text(
              '$position',
              style: TextStyle(
                color: obj == null ? Colors.white : ZennytGamePalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 2),
          if (obj != null)
            Image.asset(
              obj.asset,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.category_outlined,
                size: 34,
                color: ZennytGamePalette.muted,
              ),
            )
          else
            const SizedBox(height: 34),
          const SizedBox(height: 4),
          Text(
            obj?.label(languageCode) ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: obj == null ? Colors.white : ZennytGamePalette.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: obj?.label(languageCode), child: tile);
    }
    return Semantics(
      button: true,
      label: obj?.label(languageCode) ?? 'Empty slot',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: tile,
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

class _DistractionView extends StatelessWidget {
  const _DistractionView({
    required this.question,
    required this.choices,
    required this.secondsLeft,
    required this.reminder,
    required this.onPick,
  });

  final String question;
  final List<int> choices;
  final int secondsLeft;
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
              const Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
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
          'Quick check · ${secondsLeft}s',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0,
          ),
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
  const _IntroView({required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: AppSpacing.base),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 150,
                  child: GameRuleChip(
                    label: 'Working Memory',
                    color: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Memory\nMission',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Memorize clues, keep them in mind, then restore the correct order.',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(child: ResultStatTile(label: 'Goal', value: 'Memory')),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Duration',
                  value: '8-12 min',
                  valueColor: ZennytGamePalette.magenta,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: ResultStatTile(label: 'Format', value: '2 missions')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GamePanel(
            borderColor: ZennytGamePalette.gameBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objective',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Observe, memorize, then recall a sequence or restore the object order.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The mission changes phases: observe, recall, then manipulate objects. Input stays locked while you watch.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          GamePrimaryButton(label: 'Start mission', onPressed: onStart),
        ],
      ),
    );
  }
}

// ── Tutorial (instructions avant le test) ────────────────────────────────────

class _TutorialView extends StatelessWidget {
  const _TutorialView({required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: GamePanel(
          backgroundColor: ZennytGamePalette.mist,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ZennytGamePalette.magenta),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: ZennytGamePalette.blue,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: AppTypography.bodyLarge.copyWith(
                        color: ZennytGamePalette.muted,
                        letterSpacing: 0,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: AppSpacing.base),
          Text(
            'How memory works',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          step(Icons.visibility_outlined, 'Observe',
              'Digits appear one at a time for a short moment. Just watch.'),
          step(Icons.keyboard_alt_outlined, 'Recall',
              'Type the digits back in the same order, then in reverse order.'),
          step(Icons.swap_horiz_rounded, 'Objects',
              'Then memorize objects, watch them get moved, and restore the STARTING order.'),
          step(Icons.psychology_outlined, 'Distraction',
              'Sometimes a quick question interrupts you — keep the answer in mind and recall after.'),
          step(Icons.lock_outline_rounded, 'Input lock',
              'You cannot answer while stimuli are shown — it keeps the test fair.'),
          const SizedBox(height: AppSpacing.lg),
          GamePrimaryButton(label: 'I am ready', onPressed: onStart),
        ],
      ),
    );
  }
}

// ── Results (métriques + résumé texte neutre) ───────────────────────────────

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.composite,
    required this.submitting,
    required this.breakdown,
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
  final bool submitting;
  final List<ScoreBreakdownLine> breakdown;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onPressed: onBack),
          ),
          Text(
            'Results',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          Text(
            submitting ? 'Scoring…' : 'Indicative score — not a diagnosis',
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
                  'Memory score',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '$composite%',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 56,
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
                  label: 'Same order',
                  value: '$sameScore/5',
                  valueColor: ZennytGamePalette.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(label: 'Reverse', value: '$reverseScore/5'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: restoreScore == null
                    ? ResultStatTile(
                        label: 'Best span',
                        value: '$highestLength',
                        valueColor: ZennytGamePalette.magenta,
                      )
                    : ResultStatTile(
                        label: 'Restore',
                        value: '$restoreScore/5',
                        valueColor: ZennytGamePalette.magenta,
                      ),
              ),
            ],
          ),
          if (distractionScore != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ResultStatTile(
                    label: 'After distraction',
                    value: '$distractionScore/5',
                    valueColor: ZennytGamePalette.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ResultStatTile(
                    label: 'Quick check',
                    value: distractionQuestionCorrect ? 'Correct' : 'Missed',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ResultStatTile(
                    label: 'Best span',
                    value: '$highestLength',
                    valueColor: ZennytGamePalette.magenta,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          GamePanel(
            backgroundColor: ZennytGamePalette.mist,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: AppTypography.titleMedium.copyWith(
                    color: ZennytGamePalette.blue,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You recalled sequences up to $highestLength digits. '
                  'Same-order recall is usually easier than reverse recall, '
                  'which loads working memory more.'
                  '${restoreScore == null ? '' : ' In the object task you restored '
                      'the starting order despite the manipulations you watched.'}'
                  '${distractionScore == null ? '' : ' You then held digits in mind '
                      'while answering a quick question — a measure of distraction resistance.'}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ZennytGamePalette.muted,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            ScoreDetailPanel(lines: breakdown),
          ],
          const SizedBox(height: AppSpacing.xxl),
          GamePrimaryButton(label: 'Replay', onPressed: onReplay),
          const SizedBox(height: AppSpacing.md),
          GameOutlineButton(label: 'Back to games', onPressed: onBack),
        ],
      ),
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

enum _PauseAction { resume, exit }

class _PauseDialog extends StatelessWidget {
  const _PauseDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paused',
              style: AppTypography.displayMedium.copyWith(
                color: ZennytGamePalette.blue,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'The game timer and the sequence are frozen.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: ZennytGamePalette.muted,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GamePrimaryButton(
              label: 'Resume',
              onPressed: () => Navigator.of(context).pop(_PauseAction.resume),
            ),
            const SizedBox(height: AppSpacing.md),
            GameOutlineButton(
              label: 'Exit mission',
              onPressed: () => Navigator.of(context).pop(_PauseAction.exit),
            ),
          ],
        ),
      ),
    );
  }
}
