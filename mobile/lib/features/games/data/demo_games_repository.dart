import '../domain/config/decision_provisional_rules.dart';
import '../domain/entities/decision_form.dart';
import '../domain/entities/decision_metrics.dart';
import '../domain/entities/device_calibration.dart';
import '../domain/entities/emotional_radar.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/game_score.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/mini_game.dart';
import '../domain/entities/score_breakdown.dart';
import 'games_mock_repository.dart';

/// Repository de **DÉMO** — n'existe que pour l'APK de revue client.
///
/// Il ajoute les vidéos illustratives Radar de la démo et le contenu
/// « Je décide », qui refuse
/// normalement de tourner hors ligne : sa banque de 120 items et sa clé de
/// correction ne sont pas embarquées dans l'application, et le mock lève plutôt
/// que d'inventer des scénarios.
///
/// ⚠️ **Les scores produits ici n'ont AUCUNE valeur psychométrique.** Les
/// vignettes et la clé de correction ci-dessous sont écrites pour faire vivre
/// le parcours à l'écran, pas pour mesurer quoi que ce soit. Elles n'ont été
/// validées par personne.
///
/// ⚠️ **Ce fichier EST atteint par l'application principale.** Une version
/// précédente de ce commentaire affirmait le contraire — « référencé seulement
/// par `lib/main_games_demo.dart`, donc ni `main.dart` ni le backend ne le
/// voient ». C'était faux à deux titres : `lib/main_games_demo.dart` n'existe
/// pas, et [gamesRepositoryProvider] renvoie cette classe dès que
/// [kLot1DemoBuild] vaut `true` — sa valeur actuelle. `main.dart` passe donc
/// par ici, et c'est cette clé de correction embarquée qui note le candidat.
///
/// Ce qui protège réellement la notation serveur, ce n'est pas ce fichier :
/// c'est [kLot1DemoBuild]. Le remettre à `false` rebranche
/// [GamesRepositoryImpl] et rend à ce fichier son statut de code inerte. Tant
/// qu'il vaut `true`, **aucun score produit par ce build ne doit être présenté
/// comme une mesure**.
///
/// Voir `lib/features/games/presentation/games_providers.dart` (sélection du
/// dépôt) et `lib/core/router/app_router.dart` (déclaration du drapeau).
class DemoGamesRepository extends GamesMockRepository {
  DemoGamesRepository();

  // PROVISOIRE — à valider : footage illustratif autorisé pour la démo,
  // jamais un nouveau stimulus validé. IDs, prompts et notation V25 restent
  // ceux de GamesMockRepository / EmotionalRadarScoringService.java.
  static const _radarClips = <int, (String, String)>{
    1: ('phone_call.mp4', 'A woman listens to a phone call in her apartment.'),
    2: ('night_apartment.mp4', 'A woman walks through her apartment at night.'),
    3: (
      'park_bench.mp4',
      'A child sits alone on a park bench, moving his feet.',
    ),
  };

  @override
  Future<EmotionalRadarSceneSet> emotionalRadarScenes(String sessionId) async {
    final original = await super.emotionalRadarScenes(sessionId);
    return EmotionalRadarSceneSet(
      totalScenes: original.totalScenes,
      maxPoints: original.maxPoints,
      emotions: original.emotions,
      scenes: original.scenes
          .map((scene) {
            final clip = _radarClips[scene.sceneOrder];
            if (clip == null) return scene;
            return EmotionalRadarScene(
              id: scene.id,
              sceneOrder: scene.sceneOrder,
              mediaType: SceneMediaType.video,
              promptText: scene.promptText,
              instructionText: scene.instructionText,
              mediaUrl: 'assets/games_demo/emotional_radar/${clip.$1}',
              altText: clip.$2,
              transcript:
                  'Silent illustrative footage. ${clip.$2} '
                  'Use the written situation to answer; the footage is not an exact reenactment.',
            );
          })
          .toList(growable: false),
    );
  }

  /// Clé de correction locale : `itemId` → (`optionId` → points /3).
  ///
  /// Tenue ici, et nulle part ailleurs, pour que la suppression de ce fichier
  /// suffise à faire disparaître toute trace de correction embarquée.
  static final Map<String, Map<String, int>> _answerKey = {
    for (final item in _demoItems) item.itemId: item.pointsByOption,
  };

  @override
  Future<DecisionForm> decisionItems(
    String sessionId, {
    String language = 'fr',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return DecisionForm(
      formCode: 'DEMO-A',
      itemsPerDimension: _itemsPerDimension,
      items: _demoItems.map((i) => i.toFormItem()).toList(),
    );
  }

  @override
  Future<GameSession> submitResult({
    required String sessionId,
    required MiniGame miniGame,
    required GameMetrics metrics,
    DeviceCalibration? deviceCalibration,
  }) async {
    final session = await super.submitResult(
      sessionId: sessionId,
      miniGame: miniGame,
      metrics: metrics,
      deviceCalibration: deviceCalibration,
    );
    if (miniGame != MiniGame.decisionCore || metrics is! DecisionMetrics) {
      return session;
    }
    // Le mock a enregistré la partie avec un score « Non scoré hors ligne » :
    // on remplace ce dernier essai par une note de démo.
    return _withDemoDecisionScore(session, metrics);
  }

  GameSession _withDemoDecisionScore(
    GameSession session,
    DecisionMetrics metrics,
  ) {
    // Points par dimension : 6 items × 3 points = 18, l'échelle que l'écran de
    // résultats attend (`maxPoints ?? 18` par dimension).
    final pointsByDimension = {
      for (final dimension in DecisionDimension.values) dimension: 0,
    };
    for (final answer in metrics.items) {
      if (!answer.answered) continue;
      final option = answer.selectedOptionId;
      if (option == null) continue;
      final points = _answerKey[answer.itemId]?[option] ?? 0;
      pointsByDimension[answer.dimension] =
          (pointsByDimension[answer.dimension] ?? 0) + points;
    }

    final raw = pointsByDimension.values.fold<int>(0, (a, b) => a + b);
    final max = DecisionDimension.values.length * _maxPointsPerDimension;
    final normalized = max == 0 ? 0.0 : raw * 100 / max;
    final score = GameScore(
      rawPoints: normalized.round(),
      maxPoints: 100,
      normalized: normalized,
      level: _levelFor(normalized),
    );

    final attempts = [
      ...session.attempts.where((a) => a.miniGame != MiniGame.decisionCore),
      GameAttempt(
        miniGame: MiniGame.decisionCore,
        score: score,
        recordedAt: DateTime.now(),
      ),
    ];

    return GameSession(
      id: session.id,
      gameType: session.gameType,
      status: session.status,
      compositeRaw: score.rawPoints,
      compositeMax: 100,
      normalized: normalized,
      attempts: attempts,
      startedAt: session.startedAt,
      completedAt: session.completedAt ?? DateTime.now(),
      scoreBreakdown: _breakdown(pointsByDimension),
      reflectivePauseIndicators: session.reflectivePauseIndicators,
      continuousAttentionIndicators: session.continuousAttentionIndicators,
      coordinationIndicators: session.coordinationIndicators,
      objectLocationIndicators: session.objectLocationIndicators,
    );
  }

  /// Une ligne `criterion` par dimension — c'est la forme que
  /// `DecisionProfile.fromSession` relit pour bâtir le radar.
  List<ScoreBreakdownLine> _breakdown(Map<DecisionDimension, int> byDimension) {
    return [
      const ScoreBreakdownLine(
        kind: ScoreBreakdownKind.note,
        label:
            'Build de DÉMO : items et correction embarqués, sans valeur '
            'psychométrique. La notation réelle reste calculée par le serveur.',
      ),
      for (final dimension in DecisionDimension.values)
        ScoreBreakdownLine(
          kind: ScoreBreakdownKind.criterion,
          label: dimension.wire,
          detail: 'notation provisoire (démo)',
          points: byDimension[dimension] ?? 0,
          maxPoints: _maxPointsPerDimension,
        ),
    ];
  }

  /// Niveau affiché, délégué à la couche provisoire.
  ///
  /// Les seuils étaient recopiés ici — 75 / 55 / 40 — face aux 75 / 60 / 45 de
  /// [DecisionProvisionalRules]. Un même score tombait donc « Normal » d'un côté
  /// et « Borderline » de l'autre, sur cinq points d'écart. Seul le seuil 75
  /// vient de la fiche du psychologue ; les deux autres sont déduits, et c'est
  /// la couche provisoire qui porte cette traçabilité. Elle fait donc foi, ici
  /// comme ailleurs.
  static String _levelFor(double normalized) =>
      DecisionProvisionalRules.levelForScw(normalized);
}

const int _itemsPerDimension = 6;
const int _maxPointsPerDimension = _itemsPerDimension * 3;

/// Item de démo : vignette, options et points associés.
class _DemoItem {
  const _DemoItem({
    required this.itemId,
    required this.dimension,
    required this.vignette,
    required this.task,
    required this.options,
    this.format = DecisionItemFormat.standard,
    this.pairId,
    this.timeLimitMs,
  });

  final String itemId;
  final DecisionDimension dimension;
  final String vignette;
  final String task;

  /// Libellé → points /3, dans l'ordre d'affichage.
  final List<(String, int)> options;
  final DecisionItemFormat format;
  final String? pairId;
  final int? timeLimitMs;

  String _optionId(int index) => '$itemId-o${index + 1}';

  Map<String, int> get pointsByOption => {
    for (var i = 0; i < options.length; i++) _optionId(i): options[i].$2,
  };

  DecisionFormItem toFormItem() => DecisionFormItem(
    itemId: itemId,
    dimension: dimension,
    format: format,
    vignette: vignette,
    task: task,
    pairId: pairId,
    timeLimitMs: timeLimitMs,
    options: [
      for (var i = 0; i < options.length; i++)
        DecisionFormOption(optionId: _optionId(i), label: options[i].$1),
    ],
  );
}

/// 30 items — 6 par dimension, comme une vraie forme.
///
/// Écrits pour la démo : ils illustrent les trois formats (standard, décision
/// chronométrée, paire de cohérence) afin que le client voie tout le parcours.
final List<_DemoItem> _demoItems = [
  ..._analytical,
  ..._risk,
  ..._quick,
  ..._stability,
  ..._control,
];

// Les vignettes sont en ANGLAIS, comme le reste de l'interface.
//
// Elles étaient écrites en français alors que les trois écrans de « Je décide »
// sont en anglais : le candidat lisait « Choose what feels most natural » puis
// « Un livrable est attendu vendredi ». Les deux langues cohabitaient sur le
// même écran. La traduction ne touche que la prose — identifiants, dimensions,
// formats, budgets de temps, paires et points restent inchangés, donc la
// notation de démo produit exactement les mêmes scores qu'avant.
//
// Ce n'est pas de la localisation : l'application n'en fait pas encore, ni ici
// ni ailleurs dans ce module (voir `app_fr.arb` / `app_en.arb`, présents et
// inutilisés). C'est une mise en cohérence, en attendant.

// ── II — Analyse des contraintes ──────────────────────────────────────────
final _analytical = <_DemoItem>[
  _DemoItem(
    itemId: 'II-1',
    dimension: DecisionDimension.ii,
    vignette:
        'A deliverable is due on Friday. While preparing it, you find that two '
        'of the figures supplied by another team contradict each other.',
    task: 'What do you do first?',
    options: const [
      ('Establish which of the two sources governs before going further', 3),
      ('Use the more conservative figure and flag it in a note', 2),
      ('Rerun the calculation with both values to see the gap', 1),
      ('Ship it with whichever figure arrived last', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-2',
    dimension: DecisionDimension.ii,
    vignette:
        'You are handed a project with a tight budget, a short deadline and a '
        'high quality bar. The three do not hold together.',
    task: 'How do you approach it?',
    options: const [
      ('Have someone rule explicitly on which of the three gives way', 3),
      ('Propose a reduced scope that respects all three', 2),
      ('Start, and raise the problem when it materialises', 1),
      ('Absorb the gap through overtime', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-3',
    dimension: DecisionDimension.ii,
    vignette:
        'Two suppliers answer your tender. The cheaper one has weaker '
        'references on this particular kind of work.',
    task: 'What do you base your choice on?',
    options: const [
      ('Total cost over time, including the risk of redoing the work', 3),
      ('The references, negotiating the stronger bidder\'s price down', 2),
      ('The quoted price, accepting closer supervision', 1),
      ('The impression left by the pitch meeting', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-4',
    dimension: DecisionDimension.ii,
    vignette:
        'An internal procedure strikes you as needlessly heavy. You are not '
        'sure you know why it exists.',
    task: 'What is your approach?',
    options: const [
      ('Find out why it was put in place before proposing anything', 3),
      ('Propose a lighter version as a trial', 2),
      ('Apply it unchanged', 1),
      ('Work around it whenever it slows things down', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-5',
    dimension: DecisionDimension.ii,
    vignette:
        'A tracking metric has been sliding for three months, while user '
        'feedback stays good.',
    task: 'How do you handle the discrepancy?',
    options: const [
      ('Check what the metric actually measures', 3),
      ('Cross-check against a second metric before concluding', 2),
      ('Trust the user feedback', 1),
      ('Wait for the next monthly review', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-6',
    dimension: DecisionDimension.ii,
    vignette:
        'You are asked for an opinion on a file you have just received, in a '
        'meeting that starts in ten minutes.',
    task: 'What do you do?',
    options: const [
      ('Give a provisional view and name what you are missing', 3),
      ('Ask for the point to be taken at the end of the meeting', 2),
      ('Give a firm opinion based on what you have read', 1),
      ('Go along with whoever speaks first', 0),
    ],
  ),
];

// ── ER — Équilibre du risque ──────────────────────────────────────────────
final _risk = <_DemoItem>[
  _DemoItem(
    itemId: 'ER-1',
    dimension: DecisionDimension.er,
    vignette:
        'Two supplier options: one guarantees a 5% saving, the other offers a '
        '20% saving with a one-in-three chance of falling through.',
    task: 'Which do you take?',
    options: const [
      ('The guaranteed one — failure costs more than the upside gains', 3),
      ('The risky one, with a fallback prepared', 2),
      ('The risky one — the expected value is higher', 1),
      ('Toss a coin, to avoid losing time', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-2',
    dimension: DecisionDimension.er,
    vignette:
        'An investment can be deferred by six months. Deferring reduces the '
        'uncertainty but lets a competitor get ahead.',
    task: 'What do you decide?',
    options: const [
      ('Commit a limited share now, the rest once you have measured', 3),
      ('Defer, and watch the competitor closely', 2),
      ('Commit the full amount straight away', 1),
      ('Drop the project', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-3',
    dimension: DecisionDimension.er,
    vignette:
        'A rare but costly failure can be insured against, for a premium worth '
        'a tenth of the potential loss.',
    task: 'What do you decide?',
    options: const [
      ('Insure — the loss is only bearable once covered', 3),
      ('Insure partially, with a high excess', 2),
      ('Skip the insurance and set the money aside', 1),
      ('Do nothing — the failure is rare', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-4',
    dimension: DecisionDimension.er,
    vignette:
        'A small-scale test gives an encouraging result, on a sample too small '
        'to conclude from.',
    task: 'What do you do next?',
    options: const [
      ('Widen the test before any rollout', 3),
      ('Roll out on a scope you can reverse', 2),
      ('Roll out everywhere — the signal is positive', 1),
      ('Stop: the result is not proven', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-5',
    dimension: DecisionDimension.er,
    vignette:
        'You can lock in a modest gain now, or carry on with a real chance of '
        'losing everything.',
    task: 'What do you do?',
    options: const [
      ('Lock it in — a total loss is not something you can absorb', 3),
      ('Carry on, with a stopping threshold set in advance', 2),
      ('Carry on with no threshold, watching closely', 1),
      ('Carry on and raise the stake', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-6',
    dimension: DecisionDimension.er,
    vignette:
        'A decision commits the team for a year. The missing information will '
        'only be available in two weeks.',
    task: 'How do you proceed?',
    options: const [
      ('Wait: two weeks weigh little against a year', 3),
      ('Decide now, with a review clause', 2),
      ('Decide now — waiting would stall the team', 1),
      ('Delegate the decision to avoid making the call', 0),
    ],
  ),
];

// ── DT — Décision sous contrainte de temps ────────────────────────────────
final _quick = <_DemoItem>[
  _DemoItem(
    itemId: 'DT-1',
    dimension: DecisionDimension.dt,
    format: DecisionItemFormat.temporalDecision,
    timeLimitMs: 15000,
    vignette:
        'An alert reports an incident on the production service. Three actions '
        'are available right now.',
    task: 'Which do you trigger?',
    options: const [
      ('Roll back to the last known stable version', 3),
      ('Isolate the suspect component and observe', 2),
      ('Find the cause before doing anything', 1),
      ('Wait for a second report to confirm', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-2',
    dimension: DecisionDimension.dt,
    format: DecisionItemFormat.temporalDecision,
    timeLimitMs: 15000,
    vignette:
        'An important client wants a firm answer before the meeting ends, on a '
        'point you only partly command.',
    task: 'What do you answer?',
    options: const [
      ('Commit on what you command, defer the rest', 3),
      ('Ask for a short, reasoned delay', 2),
      ('Commit to all of it rather than lose the client', 1),
      ('Stay vague', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-3',
    dimension: DecisionDimension.dt,
    vignette:
        'Two urgent tasks land at once; only one can be finished before the '
        'deadline.',
    task: 'What do you decide on?',
    options: const [
      ('What follows from NOT doing each of them', 3),
      ('The nearest deadline', 2),
      ('Whichever finishes fastest', 1),
      ('Whichever the most insistent person asked for', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-4',
    dimension: DecisionDimension.dt,
    format: DecisionItemFormat.temporalDecision,
    timeLimitMs: 12000,
    vignette: 'During a presentation, a figure on screen looks wrong to you.',
    task: 'What do you do in the moment?',
    options: const [
      ('Flag the doubt without breaking the thread', 3),
      ('Note it and check straight afterwards', 2),
      ('Interrupt to correct it immediately', 1),
      ('Say nothing', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-5',
    dimension: DecisionDimension.dt,
    vignette:
        'You must choose between shipping on time with a known minor defect, '
        'or shipping late with none.',
    task: 'Which do you take?',
    options: const [
      ('Ship on time, documenting the defect and its fix', 3),
      ('Ship late — quality comes first', 2),
      ('Ship on time without mentioning the defect', 1),
      ('Put the decision off to the last minute', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-6',
    dimension: DecisionDimension.dt,
    vignette:
        'A meeting is bogging down. The point to settle has not moved for '
        'twenty minutes.',
    task: 'What do you propose?',
    options: const [
      ('Name the disagreement and set who decides, with a date', 3),
      ('Move the point to a dedicated meeting', 2),
      ('Let the discussion run on', 1),
      ('Decide alone, without consulting', 0),
    ],
  ),
];

// ── CS — Stabilité des choix (paires de cohérence) ────────────────────────
final _stability = <_DemoItem>[
  _DemoItem(
    itemId: 'CS-1a',
    dimension: DecisionDimension.cs,
    format: DecisionItemFormat.coherencePair,
    pairId: 'CS-1',
    vignette:
        'You choose between two schedules: A finishes early but ties up '
        'everyone; B finishes later while protecting the other workstreams.',
    task: 'Which do you take?',
    options: const [
      ('B, because the other workstreams have deadlines too', 3),
      ('A — this project\'s deadline comes first', 2),
      ('A, and push the others back afterwards', 1),
      ('Let the team choose', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-1b',
    dimension: DecisionDimension.cs,
    format: DecisionItemFormat.coherencePair,
    pairId: 'CS-1',
    vignette:
        'The same situation, framed differently: schedule B protects the other '
        'workstreams, schedule A puts them on hold.',
    task: 'Which do you take this time?',
    options: const [
      ('B, as before', 3),
      ('A, owning the change of mind', 2),
      ('A, unrelated to the previous question', 1),
      ('No preference', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-2',
    dimension: DecisionDimension.cs,
    vignette:
        'You settled this last week. A colleague comes back with the same '
        'arguments and nothing new.',
    task: 'How do you respond?',
    options: const [
      ('Hold the decision and restate what it rests on', 3),
      ('Hold it, and offer a dated review point', 2),
      ('Reopen the discussion to protect the relationship', 1),
      ('Change your mind to close the subject', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-3',
    dimension: DecisionDimension.cs,
    vignette:
        'New, verified information contradicts a decision you defended '
        'publicly.',
    task: 'What do you do?',
    options: const [
      ('Revise the decision and explain what changed', 3),
      ('Revise quietly, without revisiting it', 2),
      ('Hold — reversing would weaken your position', 1),
      ('Dispute how reliable the new information is', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-4',
    dimension: DecisionDimension.cs,
    vignette:
        'Two comparable cases come up three months apart. You turned the first '
        'one down.',
    task: 'How do you handle the second?',
    options: const [
      ('Apply the same criterion, or explain why it has moved', 3),
      ('Take it on its own merits, with no reference to the first', 2),
      ('Accept it — the context has probably changed', 1),
      ('Refuse it, on principle of consistency', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-5',
    dimension: DecisionDimension.cs,
    vignette:
        'Your decision is criticised by someone whose view matters to you, '
        'without any technical argument.',
    task: 'What is your answer?',
    options: const [
      ('Ask for the specific argument before considering a move', 3),
      ('Hold, while acknowledging the disagreement', 2),
      ('Soften the decision to spare the relationship', 1),
      ('Reverse the decision', 0),
    ],
  ),
];

// ── RE — Maîtrise de soi / récompense différée ────────────────────────────
final _control = <_DemoItem>[
  _DemoItem(
    itemId: 'RE-1',
    dimension: DecisionDimension.re,
    vignette:
        'A modest bonus is available this month, or double that in six months '
        'if you let the case mature.',
    task: 'Which do you choose?',
    options: const [
      ('Wait: the gain doubles for a bearable delay', 3),
      ('Wait, securing a partial advance', 2),
      ('Take it now — the future is uncertain', 1),
      ('Take it now without thinking about it', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-2',
    dimension: DecisionDimension.re,
    vignette:
        'A message irritates you during an already heavy day. The reply could '
        'go out right now.',
    task: 'What do you do?',
    options: const [
      ('Hold the reply and read it back once you have cooled off', 3),
      ('Reply briefly, without addressing the substance', 2),
      ('Reply immediately, weighing your words', 1),
      ('Reply immediately, in the tone you received', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-3',
    dimension: DecisionDimension.re,
    vignette:
        'A shortcut would save you two days, at the cost of technical debt '
        'someone will have to repay.',
    task: 'What do you decide?',
    options: const [
      ('Refuse the shortcut if nobody can repay the debt', 3),
      ('Take it, scheduling the repayment explicitly', 2),
      ('Take it — debt is normal', 1),
      ('Take it without mentioning it', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-4',
    dimension: DecisionDimension.re,
    vignette:
        'You are close to finishing a task when another, more urgent one comes '
        'in.',
    task: 'How do you arbitrate?',
    options: const [
      ('Switch to the urgent one after noting where you stopped', 3),
      ('Finish the current task — it is nearly done', 2),
      ('Run both at once', 1),
      ('Carry on without looking at the urgent one', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-5',
    dimension: DecisionDimension.re,
    vignette:
        'A result proves you right. There is an opening to point it out to a '
        'colleague who had disagreed.',
    task: 'What do you do?',
    options: const [
      ('Nothing: the matter is closed, raising it adds nothing', 3),
      ('Share the result without making it personal', 2),
      ('Mention it out loud, as a joke', 1),
      ('Bring it up in front of the team', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-6',
    dimension: DecisionDimension.re,
    vignette:
        'A course that pays off in the medium term falls during a period of '
        'heavy workload.',
    task: 'What do you decide?',
    options: const [
      ('Go, reorganising the workload in advance', 3),
      ('Go partially, for the key sessions', 2),
      ('Postpone it to the next run', 1),
      ('Cancel it', 0),
    ],
  ),
];
