import '../domain/config/emotional_radar_config.dart';
import '../domain/config/emotional_radar_provisional_rules.dart';
import '../domain/config/memory_quest_config.dart';
import '../domain/config/move_fast_config.dart';
import '../domain/config/reflective_pause_config.dart';
import '../domain/entities/continuous_attention_metrics.dart';
import '../domain/entities/coordination_tracking_metrics.dart';
import '../domain/entities/decision_form.dart';
import '../domain/entities/device_calibration.dart';
import '../domain/entities/emotional_radar.dart';
import '../domain/entities/game_score.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/game_type.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/memory_quest_metrics.dart';
import '../domain/entities/mini_game.dart';
import '../domain/entities/object_location_metrics.dart';
import '../domain/entities/move_fast_metrics.dart';
import '../domain/entities/planifik_metrics.dart';
import '../domain/entities/prevision_puzzle_metrics.dart';
import '../domain/entities/reflective_pause_metrics.dart';
import '../domain/entities/score_breakdown.dart';
import '../domain/entities/task_scheduling_metrics.dart';
import '../domain/repositories/games_repository.dart';
import 'continuous_attention_scoring.dart';
import 'coordination_tracking_scoring.dart';
import 'object_location_scoring.dart';

/// [GamesRepository] MOCK — permet de jouer en totale autonomie, sans backend.
///
/// Elle maintient l'état des sessions en mémoire et reproduit le barème serveur
/// (fiche « Je planifie ») pour renvoyer un score cohérent. Le jour de
/// l'intégration, on remplace cette source par [GamesRepositoryImpl] dans
/// `games_providers.dart` — rien d'autre ne change (ni contrôleur, ni Flame).
///
/// ⚠️ PARITÉ MOCK ⇄ BACKEND. Les méthodes `_scoreOptimalPath` / `_scoreMoveFast`
/// / `_scorePrevisionPuzzle` sont le MIROIR EXACT du barème serveur
/// `backend/.../games/domain/service/PlanifikScoringService.java`
/// (+ constantes `MoveFastConfig` / `OptimalPathConfig` / `PrevisionPuzzleConfig`).
/// Toute modification de barème DOIT être répercutée dans les deux fichiers
/// DANS LA MÊME PR.
///
/// ⚠️ EXCEPTION ASSUMÉE — « Je Décide » n'a PAS de barème miroir ici, et n'en
/// aura pas. Noter un item suppose de connaître la qualité de chaque option :
/// c'est la clé de correction des 120 items du psychologue. L'embarquer dans le
/// binaire mobile la rendrait extractible, et le test perdrait toute valeur en
/// recrutement. Le mock renvoie donc un attempt NON SCORÉ (0/100, niveau
/// « Non scoré hors ligne ») et `decisionItems` échoue explicitement : « Je
/// Décide » exige le backend. Ce n'est pas une régression de parité — c'est le
/// seul comportement compatible avec « les scores ne quittent jamais le
/// serveur ». Le moteur `decision_scoring.dart` reste dans le dépôt comme
/// miroir documentaire du barème serveur, couvert par son test ; il n'est
/// volontairement branché sur aucun chemin d'exécution.
class GamesMockRepository implements GamesRepository {
  final Map<String, GameSession> _sessions = {};
  int _counter = 0;

  // « Je Décide » — voir l'exception de parité en tête de fichier : aucun barème
  // local, la notation appartient au serveur.
  static GameScore _unscoredDecisionAttempt() => const GameScore(
    rawPoints: 0,
    maxPoints: 100,
    normalized: 0,
    level: 'Non scoré hors ligne',
  );

  static List<ScoreBreakdownLine> _decisionBreakdown() => const [
    ScoreBreakdownLine(
      kind: ScoreBreakdownKind.note,
      label:
          'Partie enregistrée mais non notée : « Je Décide » est corrigé côté '
          'serveur. La clé de correction des 120 items n\'est jamais embarquée '
          'dans l\'application.',
    ),
  ];
  static const _continuousAttentionScoring = ContinuousAttentionScoring();
  static const _coordinationTrackingScoring = CoordinationTrackingScoring();
  static const _objectLocationScoring = ObjectLocationScoring();

  // Config « Chemin Optimal » — miroir de OptimalPathConfig (backend).
  static const double _optimalPathTolerance = 0.10; // optimal_path_tolerance
  static const int _maxAttempts = 3; // max_attempts

  @override
  Future<GameSession> startSession(GameType gameType) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 150),
    ); // simule le réseau
    final id = 'mock-session-${++_counter}';
    final session = GameSession(
      id: id,
      gameType: gameType,
      status: 'IN_PROGRESS',
      compositeRaw: 0,
      compositeMax: _remainingStaticMax(gameType, const []),
      normalized: 0,
      attempts: const [],
      startedAt: DateTime.now(),
    );
    _sessions[id] = session;
    return session;
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    // Accepté pour parité d'interface ; le mock ne calcule pas d'indicateurs
    // corrigés (le calibrage n'affecte pas le score).
    DeviceCalibration? deviceCalibration,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final current = _sessions[sessionId];
    if (current == null) {
      throw StateError('Session mock introuvable : $sessionId');
    }

    if (miniGame == MiniGame.continuousAttentionCore) {
      if (current.gameType != GameType.continuousAttention) {
        throw StateError(
          '${MiniGame.continuousAttentionCore.wire} does not belong to '
          '${current.gameType.wire}',
        );
      }
      if (current.status != 'IN_PROGRESS' ||
          current.attempts.any(
            (attempt) => attempt.miniGame == MiniGame.continuousAttentionCore,
          )) {
        throw StateError(
          'Continuous-attention result already recorded for $sessionId',
        );
      }
    }
    if (miniGame == MiniGame.coordinationTrackingCore) {
      if (current.gameType != GameType.visuomotorCoordination) {
        throw StateError(
          '${MiniGame.coordinationTrackingCore.wire} does not belong to '
          '${current.gameType.wire}',
        );
      }
      if (current.status != 'IN_PROGRESS' ||
          current.attempts.any(
            (attempt) => attempt.miniGame == MiniGame.coordinationTrackingCore,
          )) {
        throw StateError(
          'Coordination-tracking result already recorded for $sessionId',
        );
      }
    }
    if (miniGame == MiniGame.objectLocationBindingCore) {
      if (current.gameType != GameType.visuospatialMemory) {
        throw StateError(
          '${MiniGame.objectLocationBindingCore.wire} does not belong to '
          '${current.gameType.wire}',
        );
      }
      if (current.status != 'IN_PROGRESS' ||
          current.attempts.any(
            (attempt) => attempt.miniGame == MiniGame.objectLocationBindingCore,
          )) {
        throw StateError(
          'Object-location result already recorded for $sessionId',
        );
      }
    }

    final continuousAttentionResult =
        miniGame == MiniGame.continuousAttentionCore
        ? _continuousAttentionScoring.score(
            sessionId: sessionId,
            metrics: metrics as ContinuousAttentionMetrics,
          )
        : null;
    final coordinationTrackingResult =
        miniGame == MiniGame.coordinationTrackingCore
        ? _coordinationTrackingScoring.score(
            metrics as CoordinationTrackingMetrics,
          )
        : null;
    final objectLocationResult = miniGame == MiniGame.objectLocationBindingCore
        ? _objectLocationScoring.score(
            sessionId: sessionId,
            metrics: metrics as ObjectLocationMetrics,
          )
        : null;
    if (continuousAttentionResult != null &&
        !continuousAttentionResult.indicators.sessionValid) {
      final audited = GameSession(
        id: current.id,
        gameType: current.gameType,
        status: current.status,
        compositeRaw: current.compositeRaw,
        compositeMax: current.compositeMax,
        normalized: current.normalized,
        attempts: current.attempts,
        startedAt: current.startedAt,
        completedAt: current.completedAt,
        scoreBreakdown: _continuousAttentionBreakdown(
          continuousAttentionResult.indicators,
          continuousAttentionResult.score,
        ),
        reflectivePauseIndicators: current.reflectivePauseIndicators,
        continuousAttentionIndicators: continuousAttentionResult.indicators,
        coordinationIndicators: current.coordinationIndicators,
      );
      _sessions[sessionId] = audited;
      return audited;
    }
    if (coordinationTrackingResult != null &&
        !coordinationTrackingResult.indicators.sessionValid) {
      final audited = GameSession(
        id: current.id,
        gameType: current.gameType,
        status: current.status,
        compositeRaw: current.compositeRaw,
        compositeMax: current.compositeMax,
        normalized: current.normalized,
        attempts: current.attempts,
        startedAt: current.startedAt,
        completedAt: current.completedAt,
        scoreBreakdown: _coordinationTrackingBreakdown(
          coordinationTrackingResult.indicators,
          coordinationTrackingResult.score,
        ),
        reflectivePauseIndicators: current.reflectivePauseIndicators,
        continuousAttentionIndicators: current.continuousAttentionIndicators,
        coordinationIndicators: coordinationTrackingResult.indicators,
        objectLocationIndicators: current.objectLocationIndicators,
      );
      _sessions[sessionId] = audited;
      return audited;
    }
    if (objectLocationResult != null &&
        !objectLocationResult.indicators.sessionValid) {
      final audited = GameSession(
        id: current.id,
        gameType: current.gameType,
        status: current.status,
        compositeRaw: current.compositeRaw,
        compositeMax: current.compositeMax,
        normalized: current.normalized,
        attempts: current.attempts,
        startedAt: current.startedAt,
        completedAt: current.completedAt,
        scoreBreakdown: _objectLocationBreakdown(
          objectLocationResult.indicators,
          objectLocationResult.score,
        ),
        reflectivePauseIndicators: current.reflectivePauseIndicators,
        continuousAttentionIndicators: current.continuousAttentionIndicators,
        coordinationIndicators: current.coordinationIndicators,
        objectLocationIndicators: objectLocationResult.indicators,
      );
      _sessions[sessionId] = audited;
      return audited;
    }
    final score = switch (miniGame) {
      MiniGame.optimalPath => _scoreOptimalPath(metrics as PlanifikMetrics),
      MiniGame.previsionPuzzle => _scorePrevisionPuzzle(
        metrics as PrevisionPuzzleMetrics,
      ),
      MiniGame.moveFastCore => _scoreMoveFast(metrics as MoveFastMetrics),
      MiniGame.memoryQuestCore => _scoreMemoryQuest(
        metrics as MemoryQuestMetrics,
        deviceCalibration?.calibrationOffsetMs ?? 0.0,
      ),
      MiniGame.taskScheduling => _scoreTaskScheduling(
        metrics as TaskSchedulingMetrics,
      ),
      // Voir l'exception de parité en tête de fichier : hors ligne, la partie
      // est enregistrée mais pas notée.
      MiniGame.decisionCore => _unscoredDecisionAttempt(),
      // Emotional Radar : le score vient des réponses notées à la validation de
      // chaque scène (`_emotionalRadarAnswers`), jamais des métriques reçues —
      // exactement comme le backend. Les métriques n'apportent que les temps.
      MiniGame.emotionalRadarCore => _scoreEmotionalRadar(sessionId),
      MiniGame.reflectivePauseCore => _scoreReflectivePause(
        metrics as ReflectivePauseMetrics,
      ),
      MiniGame.continuousAttentionCore => continuousAttentionResult!.score,
      MiniGame.coordinationTrackingCore => coordinationTrackingResult!.score,
      MiniGame.objectLocationBindingCore => objectLocationResult!.score,
    };
    final attempts = [
      ...current.attempts,
      GameAttempt(miniGame: miniGame, score: score, recordedAt: DateTime.now()),
    ];
    final raw = attempts.fold<int>(0, (sum, a) => sum + a.score.rawPoints);
    final complete =
        miniGame == MiniGame.moveFastCore ||
        miniGame == MiniGame.memoryQuestCore ||
        miniGame == MiniGame.decisionCore ||
        miniGame == MiniGame.continuousAttentionCore ||
        miniGame == MiniGame.coordinationTrackingCore ||
        miniGame == MiniGame.objectLocationBindingCore ||
        attempts.length >= _expectedMiniGames(current.gameType);
    final max = complete
        ? attempts.fold<int>(0, (sum, a) => sum + a.score.maxPoints)
        : attempts.fold<int>(0, (sum, a) => sum + a.score.maxPoints) +
              _remainingStaticMax(current.gameType, attempts);

    final updated = GameSession(
      id: current.id,
      gameType: current.gameType,
      status: complete ? 'COMPLETED' : current.status,
      compositeRaw: raw,
      compositeMax: max,
      normalized: max == 0 ? 0 : raw * 100.0 / max,
      attempts: attempts,
      startedAt: current.startedAt,
      completedAt: complete ? DateTime.now() : current.completedAt,
      scoreBreakdown: _buildBreakdown(miniGame, metrics, score, sessionId),
      reflectivePauseIndicators: miniGame == MiniGame.reflectivePauseCore
          ? _reflectivePauseIndicators(metrics as ReflectivePauseMetrics, score)
          : current.reflectivePauseIndicators,
      continuousAttentionIndicators:
          miniGame == MiniGame.continuousAttentionCore
          ? continuousAttentionResult!.indicators
          : current.continuousAttentionIndicators,
      coordinationIndicators: miniGame == MiniGame.coordinationTrackingCore
          ? coordinationTrackingResult!.indicators
          : current.coordinationIndicators,
      objectLocationIndicators: miniGame == MiniGame.objectLocationBindingCore
          ? objectLocationResult!.indicators
          : current.objectLocationIndicators,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Barème « Chemin Optimal » (sur 10) — identique au PlanifikScoringService backend.
  ///
  /// Chaque niveau est noté /10 puis agrégé par MOYENNE ARRONDIE (un seul Attempt
  /// par mini-jeu). ⚠️ Agrégation par moyenne à valider avec le psychologue.
  GameScore _scoreOptimalPath(PlanifikMetrics m) {
    final total = m.levels.fold<int>(
      0,
      (sum, l) => sum + _scoreOptimalPathLevel(l),
    );
    final average = m.levels.isEmpty ? 0.0 : total / m.levels.length;
    final points = average.round().clamp(0, 10).toInt();

    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: _interpretMiniGame(points),
    );
  }

  /// Note un niveau /10 selon le barème de la fiche (miroir du backend).
  int _scoreOptimalPathLevel(PlanifikLevelMetrics l) {
    var points = 0;
    final deviation = (l.pathLength - l.optimalLength).abs() / l.optimalLength;
    if (deviation <= _optimalPathTolerance) points += 4;
    points += _attemptScore(l.attempts);
    points += switch (l.costlyZonesAvoided) {
      CostlyZonesAvoided.total => 2,
      CostlyZonesAvoided.partial => 1, // raffinement à valider
      CostlyZonesAvoided.none => 0,
    };
    points += switch (l.secondaryObjectivesReached) {
      SecondaryObjectivesReached.yes => 1,
      SecondaryObjectivesReached.partial => 0, // règle à valider
      SecondaryObjectivesReached.no => 0,
    };
    return points;
  }

  /// Bandes /10 par mini-jeu (0–3 / 4–6 / 7–10) — provisoires, non validées.
  String _interpretMiniGame(int points) {
    if (points <= 3) return 'Très faible';
    if (points <= 6) return 'Moyen';
    return 'Bon à excellent';
  }

  // ── « J'investigue » (MEMORY_QUEST) — miroir de MemoryQuestScoringService ──

  GameScore _scoreMemoryQuest(
    MemoryQuestMetrics m,
    double calibrationOffsetMs,
  ) {
    final tasks = <int>[];
    if (m.tasks.isNotEmpty) {
      // Avec timings : une tâche dépassant le timeout ajusté du calibrage est
      // voidée (note 0) ; le calibrage remonte le seuil (miroir backend).
      for (final t in m.tasks) {
        // Une tâche PARASITE est jugée sur SON budget, qui dépend du niveau —
        // le seuil générique la voiderait alors qu'elle a été résolue dans les
        // temps.
        final timedOut = t.kind == MemoryTaskKind.distractionChallenge
            ? MemoryQuestConfig.isDistractionTimedOut(
                t.responseTimeMs,
                t.level,
                calibrationOffsetMs,
              )
            : MemoryQuestConfig.isTaskTimedOut(
                t.responseTimeMs,
                calibrationOffsetMs,
              );
        tasks.add(timedOut ? 0 : _taskScore(t.accuracy));
      }
    } else {
      // Repli sur les agrégats plats : on ne note que les tâches que le mode a
      // réellement fait jouer. Une partie d'images n'a ni rappel direct ni
      // rappel inverse — les compter à 0 écraserait le composite.
      if (m.mode.playsDigits) {
        tasks
          ..add(_taskScore(m.sameAccuracy))
          ..add(_taskScore(m.reverseAccuracy));
      }
      if (m.missionBPlayed) tasks.add(_taskScore(m.restoreAccuracy));
      if (m.distractionPlayed) {
        tasks.add(_taskScore(m.afterDistractionAccuracy));
      }
      if (m.distractionChallengesPlayed > 0) {
        tasks.add(_taskScore(m.distractionSolveRate));
      }
    }
    final avg = tasks.isEmpty
        ? 0.0
        : tasks.reduce((a, b) => a + b) / tasks.length;
    final composite = (avg / 5 * 100).round();
    return GameScore(
      rawPoints: composite,
      maxPoints: 100,
      normalized: composite.toDouble(),
      level: _interpretMemoryQuest(composite),
    );
  }

  int _taskScore(double accuracy) => (accuracy.clamp(0.0, 1.0) * 5).round();

  String _interpretMemoryQuest(int composite) {
    if (composite < 40) return 'Très faible';
    if (composite < 60) return 'Moyen faible';
    if (composite < 75) return 'Moyen';
    if (composite < 90) return 'Bon';
    return 'Excellent';
  }

  /// Barème « Ordonnancement de tâches » — miroir EXACT du backend
  /// (PlanifikScoringService.scoreTaskScheduling / TaskSchedulingConfig).
  /// Dépendances 3/0 + contraintes 3/0 + cohérence 0–2 + réajustements (dérivé).
  GameScore _scoreTaskScheduling(TaskSchedulingMetrics m) {
    var points = 0;
    if (m.dependenciesRespected) points += 3;
    if (m.timeConstraintsRespected) points += 3;
    points += m.planningCoherence.clamp(0, 2);
    points += _adjustmentScore(m.adjustmentCount);
    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: _interpretMiniGame(points),
    );
  }

  /// <2 réajustements → 2 pts · 2 à 4 → 1 pt · >4 → 0 pt (⚠️ 2 est inclus dans 2-4).
  int _adjustmentScore(int count) {
    if (count < 2) return 2;
    if (count <= 4) return 1;
    return 0;
  }

  GameScore _scoreMoveFast(MoveFastMetrics m) {
    final points = _replayMoveFastScore(m.correctResponses);
    final maxPoints = _replayMoveFastScore(
      List<bool>.filled(m.correctResponses.length, true),
    );
    final normalized = points * 100.0 / maxPoints;
    // Bandes centralisées dans MoveFastConfig (source unique côté mobile).
    return GameScore(
      rawPoints: points,
      maxPoints: maxPoints,
      normalized: normalized,
      level: MoveFastConfig.interpretMoveFast(normalized),
    );
  }

  /// Barème CATÉGORIEL « Predictive Puzzle » — miroir EXACT du backend
  /// (PrevisionPuzzleConfig). Chaque niveau /10, puis moyenne arrondie.
  GameScore _scorePrevisionPuzzle(PrevisionPuzzleMetrics m) {
    final total = m.levels.fold<int>(0, (sum, l) => sum + _scorePuzzleLevel(l));
    final average = m.levels.isEmpty ? 0.0 : total / m.levels.length;
    final points = average.round().clamp(0, 10).toInt();

    return GameScore(
      rawPoints: points,
      maxPoints: 10,
      normalized: points * 10.0,
      level: _interpretMiniGame(points),
    );
  }

  /// Score /10 d'un niveau : 1er essai + erreurs de séquence + coups superflus.
  int _scorePuzzleLevel(PrevisionPuzzleLevelMetrics l) {
    final firstTry = l.firstTrySuccess ? 4 : 0;
    final seqErrors = l.sequenceErrors == 0
        ? 3
        : l.sequenceErrors <= 2
        ? 2
        : 1;
    final ratio = l.optimalMoves <= 0
        ? 0.0
        : (l.plannedMoves - l.optimalMoves) / l.optimalMoves;
    final extra = ratio < 0.10
        ? 3
        : ratio < 0.25
        ? 2
        : 1;
    return firstTry + seqErrors + extra;
  }

  /// Points « nombre d'essais » — miroir de OptimalPathConfig.attemptScore :
  /// 1 essai = _maxAttempts pts, −1 par essai supplémentaire, plancher 1.
  int _attemptScore(int attempts) {
    final capped = attempts < _maxAttempts ? attempts : _maxAttempts;
    final points = _maxAttempts + 1 - capped;
    return points < 1 ? 1 : points;
  }

  int _replayMoveFastScore(Iterable<bool> responses) =>
      _replayMoveFast(responses).total;

  /// Rejeu de l'escalade + décomposition — miroir de MoveFastConfig.replay.
  ({int gamePoints, int finalMultiplier, int finalBonus, int total})
  _replayMoveFast(Iterable<bool> responses) {
    var points = 0;
    var multiplier = 1;
    var streakCounter = 0;

    for (final correct in responses) {
      if (correct) {
        points += 50 * multiplier;
        streakCounter++;
        if (streakCounter == 4) {
          streakCounter = 0;
          multiplier = (multiplier + 1).clamp(1, 10).toInt();
        }
      } else if (streakCounter > 0) {
        streakCounter = 0;
      } else {
        multiplier = (multiplier - 1).clamp(1, 10).toInt();
      }
    }

    final bonus = 250 * multiplier;
    return (
      gamePoints: points,
      finalMultiplier: multiplier,
      finalBonus: bonus,
      total: points + bonus,
    );
  }

  // ── Détail du score (panneau) — miroir EXACT de ScoreBreakdownService ──────

  List<ScoreBreakdownLine> _buildBreakdown(
    MiniGame miniGame,
    GameMetrics metrics,
    GameScore score,
    // Emotional Radar est le seul jeu dont le détail vient des réponses notées
    // et non des métriques : il lui faut la session pour les retrouver.
    String sessionId,
  ) {
    return switch (miniGame) {
      MiniGame.moveFastCore => _breakdownMoveFast(
        metrics as MoveFastMetrics,
        score,
      ),
      MiniGame.optimalPath => _breakdownOptimalPath(
        metrics as PlanifikMetrics,
        score,
      ),
      MiniGame.taskScheduling => _breakdownTaskScheduling(
        metrics as TaskSchedulingMetrics,
        score,
      ),
      MiniGame.previsionPuzzle => _breakdownPrevision(
        metrics as PrevisionPuzzleMetrics,
        score,
      ),
      MiniGame.memoryQuestCore => _breakdownMemoryQuest(
        metrics as MemoryQuestMetrics,
        score,
      ),
      MiniGame.decisionCore => _decisionBreakdown(),
      MiniGame.emotionalRadarCore => _breakdownEmotionalRadar(sessionId, score),
      MiniGame.reflectivePauseCore => _breakdownReflectivePause(
        metrics as ReflectivePauseMetrics,
        score,
      ),
      MiniGame.continuousAttentionCore => _breakdownContinuousAttention(
        metrics as ContinuousAttentionMetrics,
        score,
        sessionId,
      ),
      MiniGame.coordinationTrackingCore => _breakdownCoordinationTracking(
        metrics as CoordinationTrackingMetrics,
        score,
      ),
      MiniGame.objectLocationBindingCore => _breakdownObjectLocation(
        metrics as ObjectLocationMetrics,
        score,
        sessionId,
      ),
    };
  }

  List<ScoreBreakdownLine> _breakdownObjectLocation(
    ObjectLocationMetrics metrics,
    GameScore score,
    String sessionId,
  ) {
    final report = _objectLocationScoring
        .score(sessionId: sessionId, metrics: metrics)
        .indicators;
    return _objectLocationBreakdown(report, score);
  }

  List<ScoreBreakdownLine> _objectLocationBreakdown(
    ObjectLocationIndicators report,
    GameScore score,
  ) {
    String percent(double value) => '${value.toStringAsFixed(1)} %';
    return [
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Score provisoire = placements exacts / objets administrés, '
            'avec un seul arrondi. Permutations, distance et temps restent '
            'descriptifs.',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Placements exacts',
        detail:
            '${report.exactPlacementCount}/${report.administeredObjectCount} '
            '(${percent(report.exactAccuracyPercent)})',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Empan atteint',
        detail: '${report.span} objets',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Permutations / erreurs proches / éloignées',
        detail:
            '${report.swapCount} / ${report.localErrorCount} / '
            '${report.globalErrorCount}',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Distance moyenne',
        detail:
            '${report.averageDisplacementCells.toStringAsFixed(2)} cellules',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Validité technique',
        detail: report.sessionValid
            ? 'valide'
            : report.validityIssues.join(', '),
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Score descriptif',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  List<ScoreBreakdownLine> _breakdownCoordinationTracking(
    CoordinationTrackingMetrics metrics,
    GameScore score,
  ) {
    final report = _coordinationTrackingScoring.score(metrics).indicators;
    return _coordinationTrackingBreakdown(report, score);
  }

  List<ScoreBreakdownLine> _coordinationTrackingBreakdown(
    CoordinationTrackingIndicators report,
    GameScore score,
  ) {
    String percent(double value) => '${value.toStringAsFixed(1)} %';
    return [
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Score provisoire = précision globale mesurée, arrondie une fois '
            'au demi-point supérieur. Les sous-précisions et la distance '
            'restent descriptives.',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Précision globale',
        detail: percent(report.overallAccuracyPercent),
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Vitesse lente / rapide',
        detail:
            '${percent(report.slowAccuracyPercent)} / '
            '${percent(report.fastAccuracyPercent)}',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Segments longs / courts',
        detail:
            '${percent(report.longSegmentAccuracyPercent)} / '
            '${percent(report.shortSegmentAccuracyPercent)}',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Distance moyenne au centre',
        detail: report.averageCenterDistance.toStringAsFixed(1),
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Validité technique',
        detail: report.sessionValid
            ? 'valide'
            : report.validityIssues.join(', '),
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Score descriptif',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  List<ScoreBreakdownLine> _breakdownContinuousAttention(
    ContinuousAttentionMetrics metrics,
    GameScore score,
    String sessionId,
  ) {
    final report = _continuousAttentionScoring
        .score(sessionId: sessionId, metrics: metrics)
        .indicators;
    return _continuousAttentionBreakdown(report, score);
  }

  List<ScoreBreakdownLine> _continuousAttentionBreakdown(
    ContinuousAttentionIndicators report,
    GameScore score,
  ) {
    return [
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Score provisoire = moyenne de la balanced accuracy X_TEST et '
            'AX_TEST, arrondie une seule fois. Entraînement, temps, d-prime '
            'et biais c sont hors score.',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'X_TEST — balanced accuracy',
        detail: '${report.xPhase.balancedAccuracyPercent} %',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'AX_TEST — balanced accuracy',
        detail: '${report.axPhase.balancedAccuracyPercent} %',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Validité technique',
        detail: report.sessionValid
            ? 'valide'
            : report.validityIssues.join(', '),
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Score descriptif',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  List<ScoreBreakdownLine> _breakdownReflectivePause(
    ReflectivePauseMetrics metrics,
    GameScore score,
  ) {
    final report = _reflectivePauseIndicators(metrics, score);
    final total = metrics.moments.length;
    final controlled = metrics.moments
        .where((m) => m.minimumTimerReached)
        .length;
    final nonImpulsive = metrics.moments
        .where((m) => ReflectivePauseConfig.isNonImpulsive(m.selectedResponse))
        .length;
    final stepBack = metrics.moments
        .where(
          (m) => ReflectivePauseConfig.isRecommended(
            m.momentId,
            m.selectedResponse,
          ),
        )
        .length;
    return [
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Temps contrôlé /3 + réponses non impulsives /4 + '
            'capacité à prendre du recul /3 ; la somme est arrondie une fois.',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Controlled reaction time',
        detail: '$controlled/$total → ${report.controlledReactionTimeScore}/3',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Non-impulsive responses',
        detail: '$nonImpulsive/$total → ${report.nonImpulsiveResponsesScore}/4',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Ability to step back',
        detail: '$stepBack/$total → ${report.abilityToStepBackScore}/3',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Total',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  /// Miroir de `ScoreBreakdownService.emotionalRadar` (backend).
  List<ScoreBreakdownLine> _breakdownEmotionalRadar(
    String sessionId,
    GameScore score,
  ) {
    final answers =
        _emotionalRadarAnswers[sessionId] ?? const <_MockGradedAnswer>[];
    return [
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Chaque scène vaut ${EmotionalRadarConfig.pointsPerScene} points : '
            'émotion de base ${EmotionalRadarConfig.emotionPoints}, '
            'nuance ${EmotionalRadarConfig.nuancePoints}, '
            'intensité ${EmotionalRadarConfig.intensityPoints} '
            '(écart 0 → 2 pts · écart 1 → 1 pt · écart ≥ 2 → 0).',
      ),
      for (final a in answers) ...[
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'Scène ${a.sceneOrder} — Émotion de base',
          detail:
              '${a.selectedEmotion.label} / attendu ${a.expectedEmotion.label}',
          points: a.emotionPoints,
          maxPoints: EmotionalRadarConfig.emotionPoints,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'Scène ${a.sceneOrder} — Nuance',
          detail: '${a.selectedNuance} / attendu ${a.expectedNuance}',
          points: a.nuancePoints,
          maxPoints: EmotionalRadarConfig.nuancePoints,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: 'Scène ${a.sceneOrder} — Intensité',
          detail:
              '${a.selectedIntensity} / attendu ${a.expectedIntensity} '
              '(écart ${(a.expectedIntensity - a.selectedIntensity).abs()})',
          points: a.intensityPoints,
          maxPoints: EmotionalRadarConfig.intensityPoints,
        ),
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.subtotal,
          label: 'Scène ${a.sceneOrder}',
          points: a.points,
          maxPoints: EmotionalRadarConfig.pointsPerScene,
        ),
      ],
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Total (${answers.length} scènes)',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  List<ScoreBreakdownLine> _breakdownMemoryQuest(
    MemoryQuestMetrics m,
    GameScore score,
  ) {
    final lines = <ScoreBreakdownLine>[
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Chaque tâche est notée sur 5 ; le score = moyenne des tâches '
            'jouées, ramenée sur 100.',
      ),
      _crit(
        'Rappel même ordre',
        _pct(m.sameAccuracy),
        _taskScore(m.sameAccuracy),
        5,
      ),
      _crit(
        'Rappel inverse',
        _pct(m.reverseAccuracy),
        _taskScore(m.reverseAccuracy),
        5,
      ),
    ];
    if (m.missionBPlayed) {
      lines.add(
        _crit(
          "Restauration d'objets",
          _pct(m.restoreAccuracy),
          _taskScore(m.restoreAccuracy),
          5,
        ),
      );
    }
    if (m.distractionPlayed) {
      lines
        ..add(
          _crit(
            'Rappel après distraction',
            _pct(m.afterDistractionAccuracy),
            _taskScore(m.afterDistractionAccuracy),
            5,
          ),
        )
        ..add(
          ScoreBreakdownLine(
            kind: ScoreBreakdownKind.info,
            label: 'Question rapide',
            detail: m.distractionQuestionCorrect ? 'correcte' : 'manquée',
          ),
        );
    }
    lines.add(
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Composite',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    );
    return lines;
  }

  List<ScoreBreakdownLine> _breakdownMoveFast(
    MoveFastMetrics m,
    GameScore score,
  ) {
    final replay = _replayMoveFast(m.correctResponses);
    final correct = m.correctResponses.where((c) => c).length;
    return [
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Chaque bonne réponse = 50 × multiplicateur ; +1 au multiplicateur '
            'toutes les 4 bonnes réponses d\'affilée.',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Bonnes réponses',
        detail: '$correct',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Multiplicateur atteint',
        detail: '×${replay.finalMultiplier}',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Points de jeu',
        detail: '${replay.gamePoints}',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.info,
        label: 'Bonus de fin',
        detail: '×${replay.finalMultiplier} × 250 = ${replay.finalBonus}',
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Total',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  List<ScoreBreakdownLine> _breakdownOptimalPath(
    PlanifikMetrics m,
    GameScore score,
  ) {
    final lines = <ScoreBreakdownLine>[];
    final n = m.levels.length;
    for (var i = 0; i < n; i++) {
      final l = m.levels[i];
      final deviation =
          (l.pathLength - l.optimalLength).abs() / l.optimalLength;
      final optimalPts = deviation <= _optimalPathTolerance ? 4 : 0;
      final attemptsPts = _attemptScore(l.attempts);
      final zonesPts = switch (l.costlyZonesAvoided) {
        CostlyZonesAvoided.total => 2,
        CostlyZonesAvoided.partial => 1,
        CostlyZonesAvoided.none => 0,
      };
      final secondaryPts = switch (l.secondaryObjectivesReached) {
        SecondaryObjectivesReached.yes => 1,
        SecondaryObjectivesReached.partial => 0,
        SecondaryObjectivesReached.no => 0,
      };
      final levelScore = optimalPts + attemptsPts + zonesPts + secondaryPts;
      if (n > 1) {
        lines.add(
          ScoreBreakdownLine(
            kind: ScoreBreakdownKind.info,
            label: 'Niveau ${i + 1}',
          ),
        );
      }
      lines
        ..add(_crit('Chemin optimal (±10 %)', _pct(deviation), optimalPts, 4))
        ..add(_crit('Essais', '${l.attempts}', attemptsPts, 3))
        ..add(
          _crit(
            'Zones coûteuses évitées',
            _zonesLabel(l.costlyZonesAvoided),
            zonesPts,
            2,
          ),
        )
        ..add(
          _crit(
            'Objectif secondaire',
            _secondaryLabel(l.secondaryObjectivesReached),
            secondaryPts,
            1,
          ),
        )
        ..add(
          ScoreBreakdownLine(
            kind: ScoreBreakdownKind.subtotal,
            label: 'Niveau ${i + 1}',
            points: levelScore,
            maxPoints: 10,
          ),
        );
    }
    lines.add(
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Moyenne des $n niveaux',
        points: score.rawPoints,
        maxPoints: 10,
      ),
    );
    return lines;
  }

  List<ScoreBreakdownLine> _breakdownPrevision(
    PrevisionPuzzleMetrics m,
    GameScore score,
  ) {
    final lines = <ScoreBreakdownLine>[];
    final n = m.levels.length;
    for (var i = 0; i < n; i++) {
      final l = m.levels[i];
      final firstTryPts = l.firstTrySuccess ? 4 : 0;
      final seqPts = l.sequenceErrors == 0
          ? 3
          : l.sequenceErrors <= 2
          ? 2
          : 1;
      final ratio = l.optimalMoves <= 0
          ? 0.0
          : (l.plannedMoves - l.optimalMoves) / l.optimalMoves;
      final safeRatio = ratio < 0 ? 0.0 : ratio;
      final extraPts = safeRatio < 0.10
          ? 3
          : safeRatio < 0.25
          ? 2
          : 1;
      final levelScore = firstTryPts + seqPts + extraPts;
      if (n > 1) {
        lines.add(
          ScoreBreakdownLine(
            kind: ScoreBreakdownKind.info,
            label: 'Niveau ${i + 1}',
            detail: '${l.discCount} disques',
          ),
        );
      }
      lines
        ..add(
          _crit(
            'Réussi du 1er coup',
            l.firstTrySuccess ? 'oui' : 'non',
            firstTryPts,
            4,
          ),
        )
        ..add(_crit('Erreurs de séquence', '${l.sequenceErrors}', seqPts, 3))
        ..add(_crit('Coups superflus', _pct(safeRatio), extraPts, 3))
        ..add(
          ScoreBreakdownLine(
            kind: ScoreBreakdownKind.subtotal,
            label: 'Niveau ${i + 1}',
            points: levelScore,
            maxPoints: 10,
          ),
        );
    }
    lines.add(
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Moyenne des $n niveaux',
        points: score.rawPoints,
        maxPoints: 10,
      ),
    );
    return lines;
  }

  List<ScoreBreakdownLine> _breakdownTaskScheduling(
    TaskSchedulingMetrics m,
    GameScore score,
  ) {
    final coherenceLabel = switch (m.planningCoherence) {
      2 => 'clair',
      1 => 'partiel',
      _ => 'désordonné',
    };
    return [
      _crit(
        'Dépendances respectées',
        m.dependenciesRespected ? 'oui' : 'non',
        m.dependenciesRespected ? 3 : 0,
        3,
      ),
      _crit(
        'Contraintes horaires',
        m.timeConstraintsRespected ? 'oui' : 'non',
        m.timeConstraintsRespected ? 3 : 0,
        3,
      ),
      _crit(
        'Cohérence du planning',
        coherenceLabel,
        m.planningCoherence.clamp(0, 2),
        2,
      ),
      _crit(
        'Réajustements',
        '${m.adjustmentCount}',
        _adjustmentScore(m.adjustmentCount),
        2,
      ),
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.total,
        label: 'Total',
        points: score.rawPoints,
        maxPoints: score.maxPoints,
      ),
    ];
  }

  ScoreBreakdownLine _crit(String label, String detail, int points, int max) =>
      ScoreBreakdownLine(
        kind: ScoreBreakdownKind.criterion,
        label: label,
        detail: detail,
        points: points,
        maxPoints: max,
      );

  String _pct(double ratio) => '${(ratio * 100).round()} %';

  String _zonesLabel(CostlyZonesAvoided v) => switch (v) {
    CostlyZonesAvoided.total => 'évitement total',
    CostlyZonesAvoided.partial => 'évitement partiel',
    CostlyZonesAvoided.none => 'non évitées',
  };

  String _secondaryLabel(SecondaryObjectivesReached v) => switch (v) {
    SecondaryObjectivesReached.yes => 'atteint',
    SecondaryObjectivesReached.partial => 'partiel',
    SecondaryObjectivesReached.no => 'manqué',
  };

  int _expectedMiniGames(GameType gameType) {
    return switch (gameType) {
      // Planifik = 3 mini-jeux jouables (OPTIMAL_PATH + TASK_SCHEDULING +
      // PREVISION_PUZZLE) — miroir du backend (MiniGame.isPlayable()). Profil /30.
      GameType.planifik => 3,
      GameType.moveFast => 1,
      GameType.memoryQuest =>
        1, // « J'investigue » = un composite (A+B+distraction)
      GameType.decision => 0,
      // Emotional Radar (max dynamique /27 actuellement) + Reflective Pause /10.
      GameType.emotionalRegulation => 2,
      GameType.continuousAttention => 1,
      GameType.visuomotorCoordination => 1,
      GameType.visuospatialMemory => 1,
    };
  }

  static int _remainingStaticMax(
    GameType gameType,
    List<GameAttempt> attempts,
  ) {
    final recorded = attempts.map((attempt) => attempt.miniGame).toSet();
    return switch (gameType) {
      GameType.planifik =>
        (recorded.contains(MiniGame.optimalPath) ? 0 : 10) +
            (recorded.contains(MiniGame.taskScheduling) ? 0 : 10) +
            (recorded.contains(MiniGame.previsionPuzzle) ? 0 : 10),
      // Barèmes dynamiques : le maximum réel vient de l'Attempt une fois joué.
      GameType.moveFast => 0,
      GameType.memoryQuest =>
        recorded.contains(MiniGame.memoryQuestCore) ? 0 : 100,
      GameType.decision => 0,
      GameType.emotionalRegulation =>
        recorded.contains(MiniGame.reflectivePauseCore) ? 0 : 10,
      GameType.continuousAttention =>
        recorded.contains(MiniGame.continuousAttentionCore) ? 0 : 100,
      GameType.visuomotorCoordination =>
        recorded.contains(MiniGame.coordinationTrackingCore) ? 0 : 100,
      GameType.visuospatialMemory =>
        recorded.contains(MiniGame.objectLocationBindingCore) ? 0 : 100,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // « Reflective Pause » — miroir EXACT de ReflectivePauseScoringService.java
  // ══════════════════════════════════════════════════════════════════════════

  GameScore _scoreReflectivePause(ReflectivePauseMetrics metrics) {
    _validateReflectivePause(metrics);
    final report = _reflectivePauseIndicators(
      metrics,
      const GameScore(
        rawPoints: 0,
        maxPoints: ReflectivePauseConfig.totalMax,
        normalized: 0,
        level: '',
      ),
    );
    final points = ReflectivePauseConfig.totalScore(
      report.controlledReactionTimeScore,
      report.nonImpulsiveResponsesScore,
      report.abilityToStepBackScore,
    );
    return GameScore(
      rawPoints: points,
      maxPoints: ReflectivePauseConfig.totalMax,
      normalized: points * 10.0,
      level: ReflectivePauseConfig.interpret(points),
    );
  }

  ReflectivePauseIndicators _reflectivePauseIndicators(
    ReflectivePauseMetrics metrics,
    GameScore score,
  ) {
    final total = metrics.moments.length;
    final controlled = metrics.moments
        .where((m) => m.minimumTimerReached)
        .length;
    final nonImpulsive = metrics.moments
        .where((m) => ReflectivePauseConfig.isNonImpulsive(m.selectedResponse))
        .length;
    final stepBack = metrics.moments
        .where(
          (m) => ReflectivePauseConfig.isRecommended(
            m.momentId,
            m.selectedResponse,
          ),
        )
        .length;
    final averageMs = total == 0
        ? 0
        : (metrics.moments.fold<int>(
                    0,
                    (sum, moment) => sum + moment.responseTimeMs,
                  ) /
                  total)
              .round();
    return ReflectivePauseIndicators(
      momentsPlayed: total,
      controlledReactionTimeScore: ReflectivePauseConfig.criterionScore(
        controlled,
        total,
        ReflectivePauseConfig.controlledReactionMax,
      ),
      nonImpulsiveResponsesScore: ReflectivePauseConfig.criterionScore(
        nonImpulsive,
        total,
        ReflectivePauseConfig.nonImpulsiveMax,
      ),
      abilityToStepBackScore: ReflectivePauseConfig.criterionScore(
        stepBack,
        total,
        ReflectivePauseConfig.stepBackMax,
      ),
      impulsiveChoiceCount: total - nonImpulsive,
      averageResponseTimeMs: averageMs,
      level: score.level,
    );
  }

  void _validateReflectivePause(ReflectivePauseMetrics metrics) {
    if (metrics.moments.length != ReflectivePauseConfig.totalMoments) {
      throw ArgumentError(
        'Reflective Pause exige exactement '
        '${ReflectivePauseConfig.totalMoments} moments.',
      );
    }
    final ids = <String>{};
    for (final moment in metrics.moments) {
      if (!ReflectivePauseConfig.recommended.containsKey(moment.momentId)) {
        throw ArgumentError(
          'Moment Reflective Pause inconnu: ${moment.momentId}',
        );
      }
      if (!ids.add(moment.momentId)) {
        throw ArgumentError(
          'Moment Reflective Pause dupliqué: ${moment.momentId}',
        );
      }
      final reachedFromTime =
          moment.responseTimeMs >= ReflectivePauseConfig.minimumPauseMs;
      if (moment.minimumTimerReached != reachedFromTime) {
        throw ArgumentError(
          'minimumTimerReached incohérent avec responseTimeMs',
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // « Emotional Radar » — miroir EXACT du barème serveur
  // (`EmotionalRadarScoringService` + `EmotionalRadarConfig`).
  //
  // Le mock ne peut pas répliquer le catalogue servi par le backend : il embarque
  // les 3 scènes rédigées pour rester jouable hors-ligne. La CLÉ DE CORRECTION
  // reste ici, dans la couche data — l'écran ne la voit jamais et doit passer par
  // `answerEmotionalRadarScene`, exactement comme avec le vrai backend.
  // ══════════════════════════════════════════════════════════════════════════

  /// Réponses notées par session — équivalent de `games.emotional_radar_answers`.
  final Map<String, List<_MockGradedAnswer>> _emotionalRadarAnswers = {};

  /// Les 3 scènes rédigées (planche « Developer handoff »).
  ///
  /// ⚠️ Scène 3 : la table du handoff dit « Joy → Triumph → 4 », mais les
  /// planches Dark Mode + Responsive (tablette ET desktop) disent
  /// « Sadness → Empathic pain → 3 ». Trois planches contre une → cette dernière
  /// est retenue, comme côté backend (migration V25).
  static final List<_MockScene> _mockScenes = [
    _MockScene(
      id: 'a1e5c7d2-0000-4000-8000-000000000001',
      order: 1,
      mediaType: SceneMediaType.dialogue,
      prompt: 'Friend: "I am sorry, I have to cancel tonight."',
      instruction:
          'Observe the situation, then identify the emotional pattern.',
      expectedEmotion: BasicEmotion.sadness,
      expectedNuance: 'DISAPPOINTMENT',
      expectedIntensity: 3,
      explanation:
          'Disappointment belongs to the sadness family because the situation '
          'involves an unmet expectation.',
    ),
    _MockScene(
      id: 'a1e5c7d2-0000-4000-8000-000000000002',
      order: 2,
      mediaType: SceneMediaType.text,
      prompt: 'You hear a strange noise at night while alone at home.',
      instruction:
          'Observe the situation, then identify the emotional pattern.',
      expectedEmotion: BasicEmotion.fear,
      expectedNuance: 'ANXIETY',
      expectedIntensity: 4,
      explanation:
          'Anxiety appears when the threat is uncertain, invisible, or not yet '
          'confirmed.',
    ),
    _MockScene(
      id: 'a1e5c7d2-0000-4000-8000-000000000003',
      order: 3,
      mediaType: SceneMediaType.image,
      prompt: 'A child cries alone in a quiet courtyard.',
      instruction: 'Observe the image, then identify the emotional pattern.',
      altText: 'A child crying alone in a quiet courtyard.',
      expectedEmotion: BasicEmotion.sadness,
      expectedNuance: 'EMPATHIC_PAIN',
      expectedIntensity: 3,
      explanation:
          "Empathic pain is sadness felt for someone else's distress rather "
          "than one's own.",
    ),
  ];

  @override
  Future<DecisionForm> decisionItems(String sessionId, {String language = 'fr'}) {
    // Servir les 30 items supposerait d'embarquer la banque du psychologue dans
    // l'application. On échoue clairement plutôt que d'inventer des scénarios :
    // « Je Décide » est le seul jeu du module qui exige le backend.
    throw UnsupportedError(
      '« Je Décide » nécessite le backend : la banque de 120 items et sa clé de '
      'correction ne sont pas embarquées dans l\'application.',
    );
  }

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return EmotionalRadarSceneSet(
      totalScenes: _mockScenes.length,
      maxPoints: EmotionalRadarConfig.maxPointsFor(_mockScenes.length),
      emotions: emotionalRadarNuanceCatalog,
      scenes: _mockScenes.map((s) => s.toScene()).toList(),
    );
  }

  @override
  Future<EmotionalRadarFeedback> answerEmotionalRadarScene({
    required String sessionId,
    required String sceneId,
    required BasicEmotion emotion,
    required String nuanceKey,
    required int intensity,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final scene = _mockScenes.firstWhere(
      (s) => s.id == sceneId,
      orElse: () => throw StateError('Scène mock introuvable : $sceneId'),
    );

    // Miroir de EmotionalRadarScoringService.grade(...)
    final emotionOk = emotion == scene.expectedEmotion;
    final nuanceOk =
        scene.expectedNuance.toUpperCase() == nuanceKey.toUpperCase();

    final emotionPts = emotionOk ? EmotionalRadarConfig.emotionPoints : 0;
    final nuancePts = nuanceOk ? EmotionalRadarConfig.nuancePoints : 0;
    final intensityPts = EmotionalRadarConfig.intensityScore(
      scene.expectedIntensity,
      intensity,
    );
    var scenePoints = emotionPts + nuancePts + intensityPts;

    final perfect =
        emotionOk &&
        nuanceOk &&
        intensityPts == EmotionalRadarConfig.intensityPoints;
    if (EmotionalRadarConfig.gradientBonusEnabled && perfect) {
      scenePoints += EmotionalRadarConfig.gradientBonusPoints;
    }

    // Upsert par (session, scène) : re-valider ne double pas les points.
    final answers = _emotionalRadarAnswers.putIfAbsent(sessionId, () => []);
    answers.removeWhere((a) => a.sceneId == sceneId);
    answers.add(
      _MockGradedAnswer(
        sceneId: sceneId,
        sceneOrder: scene.order,
        selectedEmotion: emotion,
        selectedNuance: nuanceKey,
        selectedIntensity: intensity,
        expectedEmotion: scene.expectedEmotion,
        expectedNuance: scene.expectedNuance,
        expectedIntensity: scene.expectedIntensity,
        emotionPoints: emotionPts,
        nuancePoints: nuancePts,
        intensityPoints: intensityPts,
        points: scenePoints,
      ),
    );
    answers.sort((a, b) => a.sceneOrder.compareTo(b.sceneOrder));

    final total = answers.fold<int>(0, (sum, a) => sum + a.points);

    return EmotionalRadarFeedback(
      correct: emotionOk && nuanceOk,
      expectedEmotion: scene.expectedEmotion,
      expectedNuance: scene.expectedNuance,
      suggestedIntensity: scene.expectedIntensity,
      explanation: scene.explanation,
      emotionPoints: emotionPts,
      nuancePoints: nuancePts,
      intensityPoints: intensityPts,
      scenePoints: scenePoints,
      totalPoints: total,
      answeredScenes: answers.length,
    );
  }

  /// Score = somme des réponses notées, comme le backend.
  GameScore _scoreEmotionalRadar(String sessionId) {
    final answers = _emotionalRadarAnswers[sessionId] ?? const [];
    if (answers.isEmpty) {
      throw StateError(
        'Aucune scène validée : le score Emotional Radar ne peut pas être calculé.',
      );
    }
    final raw = answers.fold<int>(0, (sum, a) => sum + a.points);
    final max = EmotionalRadarConfig.maxPointsFor(answers.length);
    final normalized = raw * 100.0 / max;
    return GameScore(
      rawPoints: raw,
      maxPoints: max,
      normalized: normalized,
      level: EmotionalRadarConfig.interpret(normalized),
    );
  }
}

/// Scène du catalogue mock — porte la clé de correction, comme la base côté serveur.
class _MockScene {
  const _MockScene({
    required this.id,
    required this.order,
    required this.mediaType,
    required this.prompt,
    required this.instruction,
    required this.expectedEmotion,
    required this.expectedNuance,
    required this.expectedIntensity,
    required this.explanation,
    this.altText,
  });

  final String id;
  final int order;
  final SceneMediaType mediaType;
  final String prompt;
  final String instruction;
  final BasicEmotion expectedEmotion;
  final String expectedNuance;
  final int expectedIntensity;
  final String explanation;
  final String? altText;

  /// Projection expurgée — miroir de `EmotionalRadarDtos.SceneResponse.from`.
  EmotionalRadarScene toScene() => EmotionalRadarScene(
    id: id,
    sceneOrder: order,
    mediaType: mediaType,
    promptText: prompt,
    instructionText: instruction,
    altText: altText,
  );
}

/// Réponse notée conservée par le mock (équivalent d'une ligne persistée
/// dans `games.emotional_radar_answers`).
class _MockGradedAnswer {
  const _MockGradedAnswer({
    required this.sceneId,
    required this.sceneOrder,
    required this.selectedEmotion,
    required this.selectedNuance,
    required this.selectedIntensity,
    required this.expectedEmotion,
    required this.expectedNuance,
    required this.expectedIntensity,
    required this.emotionPoints,
    required this.nuancePoints,
    required this.intensityPoints,
    required this.points,
  });

  final String sceneId;
  final int sceneOrder;
  final BasicEmotion selectedEmotion;
  final String selectedNuance;
  final int selectedIntensity;
  final BasicEmotion expectedEmotion;
  final String expectedNuance;
  final int expectedIntensity;
  final int emotionPoints;
  final int nuancePoints;
  final int intensityPoints;
  final int points;
}
