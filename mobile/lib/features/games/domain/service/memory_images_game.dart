import 'dart:math' as math;

import 'package:clock/clock.dart';

import '../config/memory_quest_config.dart';
import '../entities/memory_distraction.dart';
import '../entities/memory_object.dart';
import '../entities/memory_quest_metrics.dart';
import 'memory_distraction_factory.dart';

/// Phase courante d'une partie de **MemoryQuest · Images**.
enum MemoryImagesPhase {
  /// Les objets sont montrés dans leur ordre initial.
  memorize,

  /// Tâche parasite chronométrée
  /// (niveau ≥ [MemoryQuestConfig.imagesDistractionMinLevel]).
  distraction,

  /// Le joueur reconstitue l'ordre initial.
  answer,

  /// Partie terminée sur un échec (deux tentatives ratées au même niveau).
  gameOver,

  /// Partie terminée en ayant franchi le dernier niveau.
  completed,
}

/// Issue d'une tâche parasite.
enum MemoryDistractionOutcome { solved, wrong, timedOut }

/// Moteur de **MemoryQuest · Images** — logique pure, sans Flutter.
///
/// Déroulé d'un niveau :
/// `mémorisation → (distraction) → réponse → validation → niveau suivant`
///
/// Ce que la classe garantit, et que le jeu exigeait :
/// * aucune logique de chiffres, aucune restitution inversée ;
/// * la tâche parasite est **indépendante** de la mémorisation — elle ne porte
///   sur aucun des objets à retenir, et son résultat ne modifie pas l'ordre à
///   restituer ;
/// * elle est **toujours chronométrée** : expiration = échec, jamais d'accès
///   illimité ;
/// * deux tentatives par niveau, la seconde ratée termine la partie.
///
/// L'horloge vient de `package:clock`, donc les délais sont pilotables en test.
class MemoryImagesGame {
  MemoryImagesGame({
    math.Random? random,
    MemoryDistractionFactory? factory,
    List<MemoryObject> catalog = kMemoryObjectLibrary,
  })  : _random = random ?? math.Random(),
        _catalog = catalog,
        _sequencer = MemoryDistractionSequencer(
          factory: factory ?? const MemoryDistractionFactory(),
        );

  final math.Random _random;
  final List<MemoryObject> _catalog;
  /// Choisit le type de chaque épreuve en bornant les séries : un tirage
  /// brut donnait « intrus » cinq fois d'affilée sur une partie.
  final MemoryDistractionSequencer _sequencer;

  // ── État ────────────────────────────────────────────────────────────────
  int _level = 1;
  int _levelAttempts = 0;
  int _errors = 0;
  MemoryImagesPhase _phase = MemoryImagesPhase.memorize;
  List<MemoryObject> _objects = const [];
  MemoryDistractionChallenge? _challenge;
  DateTime? _distractionStartedAt;
  DateTime? _answerStartedAt;

  final List<MemoryTaskResult> _tasks = [];
  int _restoreCorrectTotal = 0;
  int _objectsObservedTotal = 0;
  int _challengesPlayed = 0;
  int _challengesSolved = 0;
  int _challengeTimeouts = 0;
  int _afterDistractionObserved = 0;
  int _afterDistractionCorrect = 0;
  bool _distractionPlayed = false;

  int get level => _level;
  MemoryImagesPhase get phase => _phase;

  /// Ordre initial à mémoriser puis à restituer.
  List<MemoryObject> get objects => List.unmodifiable(_objects);

  /// Tâche parasite en cours, `null` hors de la phase [MemoryImagesPhase.distraction].
  MemoryDistractionChallenge? get challenge => _challenge;

  /// Tentatives restantes sur le niveau courant.
  int get attemptsLeft =>
      MemoryQuestConfig.maxFailuresPerLevel - _levelAttempts;

  int get errors => _errors;
  bool get isOver =>
      _phase == MemoryImagesPhase.gameOver ||
      _phase == MemoryImagesPhase.completed;

  /// Progression dans le parcours, dans [0, 1].
  double get progress =>
      ((_level - 1) / MemoryQuestConfig.totalLevels).clamp(0.0, 1.0);

  /// Durée de mémorisation du niveau courant.
  int get memorizeMs =>
      MemoryQuestConfig.objectObservationMs(_objects.length);

  /// La tâche parasite est-elle due à ce niveau ?
  bool get distractionDue =>
      MemoryQuestConfig.imagesDistractionActiveAtLevel(_level);

  // ── Cycle de jeu ────────────────────────────────────────────────────────

  /// Démarre (ou redémarre) une partie au niveau 1.
  void start() {
    _level = 1;
    _levelAttempts = 0;
    _errors = 0;
    _tasks.clear();
    _restoreCorrectTotal = 0;
    _objectsObservedTotal = 0;
    _challengesPlayed = 0;
    _challengesSolved = 0;
    _challengeTimeouts = 0;
    _afterDistractionObserved = 0;
    _afterDistractionCorrect = 0;
    _distractionPlayed = false;
    _sequencer.reset();
    _beginLevel();
  }

  void _beginLevel() {
    final count = MemoryQuestConfig.objectCountForLevel(_level);
    final pool = List<MemoryObject>.of(_catalog)..shuffle(_random);
    _objects = pool.take(count).toList(growable: false);
    _objectsObservedTotal += _objects.length;
    _challenge = null;
    _distractionStartedAt = null;
    _answerStartedAt = null;
    _phase = MemoryImagesPhase.memorize;
  }

  /// Fin de la mémorisation : enchaîne sur la tâche parasite si le niveau en
  /// prévoit une, sinon directement sur la réponse.
  void endMemorization() {
    _requirePhase(MemoryImagesPhase.memorize);
    if (distractionDue) {
      _challenge = _sequencer.next(_level, _random);
      _distractionStartedAt = clock.now();
      _challengesPlayed++;
      _distractionPlayed = true;
      _phase = MemoryImagesPhase.distraction;
      return;
    }
    _beginAnswer();
  }

  /// Millisecondes restantes sur la tâche parasite (0 si expirée ou hors phase).
  int get distractionRemainingMs {
    final challenge = _challenge;
    final startedAt = _distractionStartedAt;
    if (challenge == null || startedAt == null) return 0;
    final elapsed = clock.now().difference(startedAt).inMilliseconds;
    final left = challenge.timeLimitMs - elapsed;
    return left < 0 ? 0 : left;
  }

  bool get distractionExpired => distractionRemainingMs <= 0;

  /// Répond à la tâche parasite. Une réponse arrivée après l'expiration est
  /// traitée comme un dépassement, quelle que soit sa justesse : le chronomètre
  /// prime, sinon la contrainte de temps ne mesurerait rien.
  MemoryDistractionOutcome answerDistraction(int optionIndex) {
    _requirePhase(MemoryImagesPhase.distraction);
    final challenge = _challenge!;
    final elapsed =
        clock.now().difference(_distractionStartedAt!).inMilliseconds;
    final expired = elapsed > challenge.timeLimitMs;
    final correct = !expired && optionIndex == challenge.solutionIndex;

    if (correct) {
      _challengesSolved++;
    } else {
      _errors++;
      if (expired) _challengeTimeouts++;
    }
    _tasks.add(MemoryTaskResult(
      kind: MemoryTaskKind.distractionChallenge,
      correct: correct ? 1 : 0,
      total: 1,
      responseTimeMs: elapsed,
      level: _level,
    ));
    _beginAnswer();
    return expired
        ? MemoryDistractionOutcome.timedOut
        : (correct
            ? MemoryDistractionOutcome.solved
            : MemoryDistractionOutcome.wrong);
  }

  /// Le chronomètre a expiré sans réponse : la tâche est perdue et le jeu
  /// enchaîne sur la restitution.
  MemoryDistractionOutcome expireDistraction() {
    _requirePhase(MemoryImagesPhase.distraction);
    final challenge = _challenge!;
    _errors++;
    _challengeTimeouts++;
    _tasks.add(MemoryTaskResult(
      kind: MemoryTaskKind.distractionChallenge,
      correct: 0,
      total: 1,
      responseTimeMs: challenge.timeLimitMs + 1,
      level: _level,
    ));
    _beginAnswer();
    return MemoryDistractionOutcome.timedOut;
  }

  void _beginAnswer() {
    _challenge = null;
    _distractionStartedAt = null;
    _answerStartedAt = clock.now();
    _phase = MemoryImagesPhase.answer;
  }

  /// Ordre proposé par le joueur. Renvoie `true` si le niveau est réussi.
  ///
  /// Réussite → niveau suivant (ou fin du parcours). Échec → seconde tentative
  /// sur le MÊME niveau ; au second échec, la partie s'arrête.
  bool submitOrder(List<MemoryObject> proposed) {
    _requirePhase(MemoryImagesPhase.answer);
    var correct = 0;
    for (var i = 0; i < _objects.length && i < proposed.length; i++) {
      if (proposed[i].id == _objects[i].id) correct++;
    }
    _restoreCorrectTotal += correct;

    final elapsed =
        clock.now().difference(_answerStartedAt!).inMilliseconds;
    // Quand une tâche parasite a coupé le niveau, cette restitution EST la
    // restitution « après distraction » : une seule tâche est journalisée,
    // sinon le même essai pèserait deux fois dans la moyenne du composite.
    final afterDistraction = _distractionPlayedThisLevel;
    if (afterDistraction) {
      _afterDistractionObserved += _objects.length;
      _afterDistractionCorrect += correct;
    }
    _tasks.add(MemoryTaskResult(
      kind: afterDistraction
          ? MemoryTaskKind.afterDistraction
          : MemoryTaskKind.restore,
      correct: correct,
      total: _objects.length,
      responseTimeMs: elapsed,
      level: _level,
    ));

    final perfect = correct == _objects.length;
    if (!perfect) {
      _errors++;
      _levelAttempts++;
      if (_levelAttempts >= MemoryQuestConfig.maxFailuresPerLevel) {
        _phase = MemoryImagesPhase.gameOver;
        return false;
      }
      _beginLevel(); // même niveau, nouveau tirage d'objets
      return false;
    }

    if (_level >= MemoryQuestConfig.totalLevels) {
      _phase = MemoryImagesPhase.completed;
      return true;
    }
    _level++;
    _levelAttempts = 0;
    _beginLevel();
    return true;
  }

  bool get _distractionPlayedThisLevel => distractionDue;

  // ── Sortie vers le backend ──────────────────────────────────────────────

  /// Mesures de la partie, dans le format déjà utilisé par le module.
  ///
  /// Aucun point n'est calculé ici : le barème reste serveur (ou mock), le
  /// client n'envoie que des mesures. `mode = images` indique au serveur qu'il
  /// ne doit attendre ni chiffre observé ni restitution inversée.
  MemoryQuestMetrics buildMetrics() => MemoryQuestMetrics(
        mode: MemoryQuestMode.images,
        objectCount: _objectsObservedTotal,
        restoreCorrect: _restoreCorrectTotal,
        distractionPlayed: _distractionPlayed,
        distractionChallengesPlayed: _challengesPlayed,
        distractionChallengesSolved: _challengesSolved,
        distractionTimeouts: _challengeTimeouts,
        afterDistractionObserved: _afterDistractionObserved,
        afterDistractionCorrect: _afterDistractionCorrect,
        finalLevel: _level,
        sessionCompleted: isOver,
        tasks: List.unmodifiable(_tasks),
      );

  void _requirePhase(MemoryImagesPhase expected) {
    if (_phase != expected) {
      throw StateError('Phase attendue $expected, phase courante $_phase');
    }
  }
}
