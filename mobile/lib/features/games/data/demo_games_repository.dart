import '../domain/entities/decision_form.dart';
import '../domain/entities/decision_metrics.dart';
import '../domain/entities/device_calibration.dart';
import '../domain/entities/game_metrics.dart';
import '../domain/entities/game_score.dart';
import '../domain/entities/game_session.dart';
import '../domain/entities/mini_game.dart';
import '../domain/entities/score_breakdown.dart';
import 'games_mock_repository.dart';

/// Repository de **DÉMO** — n'existe que pour l'APK de revue client.
///
/// Il ne diffère de [GamesMockRepository] que sur « Je décide », qui refuse
/// normalement de tourner hors ligne : sa banque de 120 items et sa clé de
/// correction ne sont pas embarquées dans l'application, et le mock lève plutôt
/// que d'inventer des scénarios.
///
/// ⚠️ **Les scores produits ici n'ont AUCUNE valeur psychométrique.** Les
/// vignettes et la clé de correction ci-dessous sont écrites pour faire vivre
/// le parcours à l'écran, pas pour mesurer quoi que ce soit. Elles n'ont été
/// validées par personne. Ce fichier n'est référencé que par
/// `lib/main_games_demo.dart` : ni `main.dart`, ni le mock de développement, ni
/// le backend ne le voient, donc la notation réelle reste intouchée.
class DemoGamesRepository extends GamesMockRepository {
  DemoGamesRepository();

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

  static String _levelFor(double normalized) {
    if (normalized >= 75) return 'Élevé';
    if (normalized >= 55) return 'Normal';
    if (normalized >= 40) return 'Borderline';
    return 'Fragile';
  }
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

// ── II — Analyse des contraintes ──────────────────────────────────────────
final _analytical = <_DemoItem>[
  _DemoItem(
    itemId: 'II-1',
    dimension: DecisionDimension.ii,
    vignette:
        'Un livrable est attendu vendredi. En le préparant, vous découvrez que '
        'deux des chiffres fournis par un autre service se contredisent.',
    task: 'Que faites-vous en premier ?',
    options: const [
      ('Identifier laquelle des deux sources fait foi avant de continuer', 3),
      ('Retenir le chiffre le plus prudent et le signaler en note', 2),
      ('Reprendre le calcul avec les deux valeurs pour voir l\'écart', 1),
      ('Livrer avec le chiffre reçu en dernier', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-2',
    dimension: DecisionDimension.ii,
    vignette:
        'On vous confie un projet avec un budget serré, une échéance courte et '
        'une exigence de qualité élevée. Les trois ne tiennent pas ensemble.',
    task: 'Comment abordez-vous la situation ?',
    options: const [
      ('Faire arbitrer explicitement laquelle des trois contraintes cède', 3),
      ('Proposer un périmètre réduit qui respecte les trois', 2),
      ('Commencer et signaler le problème dès qu\'il se matérialise', 1),
      ('Absorber l\'écart en heures supplémentaires', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-3',
    dimension: DecisionDimension.ii,
    vignette:
        'Deux prestataires répondent à votre appel d\'offres. Le moins cher a '
        'des références plus faibles sur ce type de mission précis.',
    task: 'Sur quoi fondez-vous votre choix ?',
    options: const [
      ('Le coût total sur la durée, risque de reprise inclus', 3),
      ('Les références, en négociant le prix du mieux-disant', 2),
      ('Le prix affiché, quitte à encadrer davantage', 1),
      ('L\'impression laissée par la présentation orale', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-4',
    dimension: DecisionDimension.ii,
    vignette:
        'Une procédure interne vous paraît inutilement lourde. Vous n\'êtes pas '
        'certain de connaître la raison de son existence.',
    task: 'Quelle est votre démarche ?',
    options: const [
      ('Chercher pourquoi elle a été mise en place avant de proposer', 3),
      ('Proposer une version allégée à titre d\'essai', 2),
      ('L\'appliquer sans rien changer', 1),
      ('La contourner quand elle ralentit le travail', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-5',
    dimension: DecisionDimension.ii,
    vignette:
        'Un indicateur de suivi se dégrade depuis trois mois, alors que les '
        'retours des utilisateurs restent bons.',
    task: 'Comment traitez-vous cet écart ?',
    options: const [
      ('Vérifier ce que l\'indicateur mesure réellement', 3),
      ('Croiser avec un second indicateur avant de conclure', 2),
      ('Faire confiance aux retours utilisateurs', 1),
      ('Attendre le prochain point mensuel', 0),
    ],
  ),
  _DemoItem(
    itemId: 'II-6',
    dimension: DecisionDimension.ii,
    vignette:
        'On vous demande un avis sur un dossier que vous venez de recevoir, '
        'dans une réunion qui commence dans dix minutes.',
    task: 'Que faites-vous ?',
    options: const [
      ('Annoncer un avis provisoire en nommant ce qu\'il vous manque', 3),
      ('Demander à traiter le point en fin de réunion', 2),
      ('Donner un avis ferme à partir de ce que vous avez lu', 1),
      ('Vous ranger à l\'avis du premier qui parle', 0),
    ],
  ),
];

// ── ER — Équilibre du risque ──────────────────────────────────────────────
final _risk = <_DemoItem>[
  _DemoItem(
    itemId: 'ER-1',
    dimension: DecisionDimension.er,
    vignette:
        'Deux options de fournisseur : l\'une garantit une économie de 5 %, '
        'l\'autre offre 20 % d\'économie avec une chance sur trois d\'échouer.',
    task: 'Laquelle retenez-vous ?',
    options: const [
      ('L\'option garantie, l\'échec coûtant plus que le gain espéré', 3),
      ('L\'option risquée, en préparant une solution de repli', 2),
      ('L\'option risquée, l\'espérance de gain étant supérieure', 1),
      ('Tirer au sort pour ne pas perdre de temps', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-2',
    dimension: DecisionDimension.er,
    vignette:
        'Un investissement peut être reporté de six mois. Le reporter réduit '
        'l\'incertitude mais laisse un concurrent prendre de l\'avance.',
    task: 'Quelle décision prenez-vous ?',
    options: const [
      ('Engager une part limitée maintenant, le reste après mesure', 3),
      ('Reporter et suivre le concurrent de près', 2),
      ('Engager la totalité tout de suite', 1),
      ('Abandonner le projet', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-3',
    dimension: DecisionDimension.er,
    vignette:
        'Une panne rare mais coûteuse peut être couverte par une assurance dont '
        'la prime représente un dixième du sinistre potentiel.',
    task: 'Que décidez-vous ?',
    options: const [
      ('Couvrir, le sinistre étant supportable seulement une fois assuré', 3),
      ('Couvrir partiellement, avec une franchise élevée', 2),
      ('Ne pas couvrir et provisionner la somme', 1),
      ('Ne rien faire, la panne étant rare', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-4',
    dimension: DecisionDimension.er,
    vignette:
        'Un test à petite échelle donne un résultat encourageant mais sur un '
        'échantillon trop faible pour conclure.',
    task: 'Quelle suite donnez-vous ?',
    options: const [
      ('Étendre le test avant tout déploiement', 3),
      ('Déployer sur un périmètre réversible', 2),
      ('Déployer partout, le signal étant positif', 1),
      ('Arrêter, le résultat n\'étant pas prouvé', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-5',
    dimension: DecisionDimension.er,
    vignette:
        'Vous pouvez sécuriser un gain immédiat modeste ou continuer, avec une '
        'possibilité réelle de tout perdre.',
    task: 'Que faites-vous ?',
    options: const [
      ('Sécuriser, la perte totale n\'étant pas absorbable', 3),
      ('Continuer en fixant à l\'avance un seuil d\'arrêt', 2),
      ('Continuer sans seuil, en surveillant', 1),
      ('Continuer et augmenter la mise', 0),
    ],
  ),
  _DemoItem(
    itemId: 'ER-6',
    dimension: DecisionDimension.er,
    vignette:
        'Une décision engage l\'équipe sur un an. L\'information manquante ne '
        'sera disponible que dans deux semaines.',
    task: 'Comment procédez-vous ?',
    options: const [
      ('Attendre : deux semaines pèsent peu face à un an', 3),
      ('Décider maintenant, avec une clause de révision', 2),
      ('Décider maintenant, l\'attente démobilisant l\'équipe', 1),
      ('Déléguer la décision pour ne pas trancher', 0),
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
        'Une alerte signale un incident sur le service en production. Trois '
        'actions sont possibles immédiatement.',
    task: 'Quelle action lancez-vous ?',
    options: const [
      ('Rétablir la dernière version stable connue', 3),
      ('Isoler le composant suspect et observer', 2),
      ('Chercher la cause avant toute action', 1),
      ('Attendre confirmation d\'un second signalement', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-2',
    dimension: DecisionDimension.dt,
    format: DecisionItemFormat.temporalDecision,
    timeLimitMs: 15000,
    vignette:
        'Un client important demande une réponse ferme avant la fin de la '
        'réunion, sur un point que vous maîtrisez partiellement.',
    task: 'Que répondez-vous ?',
    options: const [
      ('Vous engagez sur ce que vous maîtrisez, différez le reste', 3),
      ('Vous demandez un délai court et argumenté', 2),
      ('Vous vous engagez entièrement pour ne pas le perdre', 1),
      ('Vous restez évasif', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-3',
    dimension: DecisionDimension.dt,
    vignette:
        'Deux tâches urgentes tombent en même temps ; une seule peut être '
        'traitée avant l\'échéance.',
    task: 'Sur quel critère tranchez-vous ?',
    options: const [
      ('La conséquence de ne PAS traiter chacune', 3),
      ('L\'échéance la plus proche', 2),
      ('Celle qui se termine le plus vite', 1),
      ('Celle demandée par la personne la plus insistante', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-4',
    dimension: DecisionDimension.dt,
    format: DecisionItemFormat.temporalDecision,
    timeLimitMs: 12000,
    vignette:
        'Pendant une présentation, une donnée affichée vous semble fausse.',
    task: 'Que faites-vous sur le moment ?',
    options: const [
      ('Signaler le doute sans interrompre le fil', 3),
      ('Noter et vérifier juste après', 2),
      ('Interrompre pour corriger immédiatement', 1),
      ('Ne rien dire', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-5',
    dimension: DecisionDimension.dt,
    vignette:
        'Vous devez choisir entre livrer à l\'heure avec un défaut mineur connu '
        'ou livrer en retard sans défaut.',
    task: 'Quelle option retenez-vous ?',
    options: const [
      ('Livrer à l\'heure en documentant le défaut et sa correction', 3),
      ('Livrer en retard, la qualité primant', 2),
      ('Livrer à l\'heure sans mentionner le défaut', 1),
      ('Repousser la décision au dernier moment', 0),
    ],
  ),
  _DemoItem(
    itemId: 'DT-6',
    dimension: DecisionDimension.dt,
    vignette:
        'Une réunion s\'enlise. Le point à trancher n\'avance plus depuis '
        'vingt minutes.',
    task: 'Que proposez-vous ?',
    options: const [
      ('Nommer le désaccord et fixer qui tranche, avec une date', 3),
      ('Reporter le point à une réunion dédiée', 2),
      ('Laisser la discussion se poursuivre', 1),
      ('Trancher seul sans consulter', 0),
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
        'Vous choisissez entre deux plannings : A finit tôt mais mobilise tout '
        'le monde ; B finit plus tard en préservant les autres chantiers.',
    task: 'Que retenez-vous ?',
    options: const [
      ('B, parce que les autres chantiers ont aussi des échéances', 3),
      ('A, l\'échéance de ce projet primant', 2),
      ('A, quitte à décaler les autres ensuite', 1),
      ('Vous laissez l\'équipe choisir', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-1b',
    dimension: DecisionDimension.cs,
    format: DecisionItemFormat.coherencePair,
    pairId: 'CS-1',
    vignette:
        'Même situation, présentée autrement : le planning B protège les autres '
        'chantiers, le planning A les met en attente.',
    task: 'Que retenez-vous cette fois ?',
    options: const [
      ('B, comme précédemment', 3),
      ('A, en assumant le changement d\'avis', 2),
      ('A, sans lien avec la question précédente', 1),
      ('Indifférent', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-2',
    dimension: DecisionDimension.cs,
    vignette:
        'Vous aviez tranché la semaine dernière. Un collègue revient avec les '
        'mêmes arguments, sans élément nouveau.',
    task: 'Comment réagissez-vous ?',
    options: const [
      ('Maintenir la décision et rappeler ce qui la fonde', 3),
      ('Maintenir, en proposant un point de revue daté', 2),
      ('Rouvrir la discussion pour préserver la relation', 1),
      ('Changer d\'avis pour clore le sujet', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-3',
    dimension: DecisionDimension.cs,
    vignette:
        'Un élément nouveau et vérifié contredit une décision que vous avez '
        'défendue publiquement.',
    task: 'Que faites-vous ?',
    options: const [
      ('Réviser la décision et expliquer ce qui a changé', 3),
      ('Réviser discrètement, sans revenir dessus', 2),
      ('Maintenir, un revirement affaiblissant votre position', 1),
      ('Contester la fiabilité de l\'élément', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-4',
    dimension: DecisionDimension.cs,
    vignette:
        'Deux dossiers comparables se présentent à trois mois d\'intervalle. '
        'Vous aviez refusé le premier.',
    task: 'Comment traitez-vous le second ?',
    options: const [
      ('Appliquer le même critère, ou expliquer pourquoi il évolue', 3),
      ('Le traiter au cas par cas, sans référence au précédent', 2),
      ('L\'accepter, le contexte ayant probablement changé', 1),
      ('Le refuser par principe de cohérence', 0),
    ],
  ),
  _DemoItem(
    itemId: 'CS-5',
    dimension: DecisionDimension.cs,
    vignette:
        'Votre décision est critiquée par une personne dont l\'avis compte pour '
        'vous, sans argument technique.',
    task: 'Quelle est votre réponse ?',
    options: const [
      ('Demander l\'argument précis avant d\'envisager de bouger', 3),
      ('Maintenir, tout en reconnaissant le désaccord', 2),
      ('Assouplir la décision pour ménager la relation', 1),
      ('Revenir sur la décision', 0),
    ],
  ),
];

// ── RE — Maîtrise de soi / récompense différée ────────────────────────────
final _control = <_DemoItem>[
  _DemoItem(
    itemId: 'RE-1',
    dimension: DecisionDimension.re,
    vignette:
        'Une prime modeste est disponible ce mois-ci, ou le double dans six '
        'mois si vous laissez le dossier mûrir.',
    task: 'Que choisissez-vous ?',
    options: const [
      ('Attendre : le gain double pour un délai supportable', 3),
      ('Attendre, en sécurisant une avance partielle', 2),
      ('Prendre maintenant, l\'avenir étant incertain', 1),
      ('Prendre maintenant sans y réfléchir', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-2',
    dimension: DecisionDimension.re,
    vignette:
        'Un message vous agace pendant une journée déjà chargée. La réponse '
        'peut partir tout de suite.',
    task: 'Que faites-vous ?',
    options: const [
      ('Différer la réponse et la relire à froid', 3),
      ('Répondre brièvement, sans traiter le fond', 2),
      ('Répondre immédiatement, en pesant les mots', 1),
      ('Répondre immédiatement sur le ton reçu', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-3',
    dimension: DecisionDimension.re,
    vignette:
        'Un raccourci vous ferait gagner deux jours, au prix d\'une dette '
        'technique que quelqu\'un devra rembourser.',
    task: 'Quelle décision prenez-vous ?',
    options: const [
      ('Refuser le raccourci si personne ne peut rembourser la dette', 3),
      ('L\'accepter en planifiant explicitement le remboursement', 2),
      ('L\'accepter, la dette étant courante', 1),
      ('L\'accepter sans le mentionner', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-4',
    dimension: DecisionDimension.re,
    vignette:
        'Vous êtes proche du but sur une tâche, mais une autre, plus urgente, '
        'vient d\'arriver.',
    task: 'Comment arbitrez-vous ?',
    options: const [
      ('Basculer sur l\'urgente après avoir noté où vous en êtes', 3),
      ('Terminer la tâche en cours, elle est presque finie', 2),
      ('Mener les deux de front', 1),
      ('Continuer sans regarder l\'urgente', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-5',
    dimension: DecisionDimension.re,
    vignette:
        'Un résultat vous donne raison. L\'occasion se présente de le faire '
        'remarquer à un collègue qui s\'était opposé.',
    task: 'Que faites-vous ?',
    options: const [
      ('Rien : le sujet est clos, le relever n\'apporte rien', 3),
      ('Partager le résultat sans le personnaliser', 2),
      ('Le mentionner à l\'oral, sur le ton de la plaisanterie', 1),
      ('Le rappeler devant l\'équipe', 0),
    ],
  ),
  _DemoItem(
    itemId: 'RE-6',
    dimension: DecisionDimension.re,
    vignette:
        'Une formation utile à moyen terme se tient pendant une période de '
        'forte charge.',
    task: 'Quelle décision prenez-vous ?',
    options: const [
      ('Y aller en réorganisant la charge à l\'avance', 3),
      ('Y aller partiellement, sur les modules clés', 2),
      ('La reporter à la prochaine session', 1),
      ('L\'annuler', 0),
    ],
  ),
];
