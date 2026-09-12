/// Banque de tâches du « Planning journalier » (Day Stack).
///
/// Sept univers de 11 ou 12 tâches, chacune rédigée en quatre variantes pour
/// qu'un candidat qui retombe sur le même univers n'y retrouve pas les mêmes
/// formulations.
///
/// **Ce que ce modèle rend explicite, et que la source client laissait en
/// prose** — c'est là que se jouent les erreurs d'intégration :
///
/// - Les dépendances arrivaient en LIBELLÉS. Elles sont ici des identifiants,
///   comme le référentiel l'exige : « résoudre par identifiant de tâche, jamais
///   par le libellé tiré aléatoirement ». Un libellé de la source contient des
///   virgules — « Commander le matériel (chaises, son, déco) » — qu'un
///   découpage naïf transformait en trois fausses dépendances.
/// - Les durées (« 20 min + 60 min repos ») sont séparées en temps de travail
///   et temps de repos.
/// - Les contraintes horaires, cinq formes distinctes en prose, sont typées et
///   exprimées en minutes depuis minuit.
library;

/// Priorité affichée d'une tâche. Aucune incidence sur le barème à ce stade.
enum DayStackPriority { critical, high, medium, none }

/// Forme d'une contrainte horaire.
///
/// Le référentiel client en annonce trois ; la banque en contient cinq. Les
/// deux manquantes — [deadline] et [minDelay] — représentent à elles seules
/// douze des quarante-quatre contraintes, elles ne pouvaient pas être traitées
/// comme des cas particuliers des autres.
enum DayStackConstraintKind {
  /// Aucune contrainte horaire.
  none,

  /// Fenêtre absolue : « Livraison 7h-8h ».
  window,

  /// Échéance absolue : « Avant 9h30 », « Deadline 17h00 ».
  deadline,

  /// Ancrage strict : « Démarre à 12h00 pile », tolérance ±5 min.
  anchor,

  /// Échéance relative à une autre tâche : « Avant la réunion ».
  relative,

  /// Délai minimum avant la suite : « Repos mini. 1h avant cuisson ».
  minDelay,

  /// Bloc horaire fixe dont l'heure manque dans la source.
  ///
  /// Un seul cas, signalé par le client lui-même : `trajet_nouveau_logement`.
  /// Conservé tel quel plutôt que comblé par une heure inventée — une heure
  /// arbitraire produirait un score faux sans que personne ne le remarque.
  unspecified,
}

/// Contrainte horaire d'une tâche, en minutes depuis minuit.
class DayStackConstraint {
  const DayStackConstraint({
    required this.kind,
    required this.fixedBlock,
    this.startMin,
    this.endMin,
    this.beforeMin,
    this.toleranceMin,
    this.beforeTaskId,
    this.minDelayMin,
    this.raw,
  });

  final DayStackConstraintKind kind;

  /// « Bloc horaire fixe » dans la source.
  ///
  /// Un modificateur, pas un type : il se combine avec une fenêtre
  /// (« Salle 10h-11h · Bloc horaire fixe »), une échéance
  /// (« Deadline 17h30 · Bloc horaire fixe ») ou un ancrage. Le traiter comme
  /// un type à part aurait forcé à choisir lequel des deux perdre.
  final bool fixedBlock;

  final int? startMin;
  final int? endMin;
  final int? beforeMin;

  /// Tolérance d'un ancrage strict — ±5 min au référentiel.
  final int? toleranceMin;

  /// Cible d'une échéance relative, résolue en identifiant.
  final String? beforeTaskId;

  final int? minDelayMin;

  /// Texte d'origine, conservé pour l'affichage et la traçabilité.
  final String? raw;

  bool get hasTiming => kind != DayStackConstraintKind.none;

  factory DayStackConstraint.fromJson(Map<String, dynamic> json) {
    final kind = DayStackConstraintKind.values.firstWhere(
      (k) => k.name == json['kind'],
      orElse: () => throw FormatException('contrainte inconnue : ${json['kind']}'),
    );
    return DayStackConstraint(
      kind: kind,
      fixedBlock: json['fixedBlock'] as bool? ?? false,
      startMin: (json['startMin'] as num?)?.toInt(),
      endMin: (json['endMin'] as num?)?.toInt(),
      beforeMin: (json['beforeMin'] as num?)?.toInt(),
      toleranceMin: (json['toleranceMin'] as num?)?.toInt(),
      beforeTaskId: json['beforeTaskId'] as String?,
      minDelayMin: (json['minDelayMin'] as num?)?.toInt(),
      raw: json['raw'] as String?,
    );
  }
}

/// Une tâche à ordonnancer.
class DayStackTask {
  const DayStackTask({
    required this.id,
    required this.variants,
    required this.durationMin,
    required this.restMin,
    required this.deps,
    required this.priority,
    required this.constraint,
    this.category,
    this.icon,
  });

  final String id;

  /// Les quatre rédactions du même libellé.
  final List<String> variants;

  /// Temps de travail actif, en minutes.
  final int durationMin;

  /// Temps de repos passif qui suit (marinade, séchage). 0 si aucun.
  ///
  /// Séparé du travail parce que le référentiel laisse ouverte la question de
  /// savoir s'il bloque le créneau ou si d'autres tâches peuvent s'y glisser —
  /// question à trancher avec le psychologue. Les confondre trancherait à sa
  /// place.
  final int restMin;

  /// Prérequis, en identifiants.
  final List<String> deps;

  final DayStackPriority priority;
  final DayStackConstraint constraint;

  /// Famille visuelle — une couleur de badge.
  final String? category;

  /// Nom d'icône Tabler proposé par le client.
  final String? icon;

  /// Libellé tiré pour une session.
  ///
  /// Le tirage porte sur le LIBELLÉ seul : durée, dépendances et contraintes ne
  /// bougent jamais, sinon deux sessions du même univers ne seraient plus
  /// comparables.
  /// Libellé tiré pour cette tâche, à partir de la graine de la manche.
  ///
  /// La graine est mélangée à l'IDENTIFIANT de la tâche : chaque tâche tire
  /// donc sa variante indépendamment, comme le demande le document du client —
  /// « tirer aléatoirement UNE variante PAR ÉTAPE à chaque nouvelle session » —
  /// et comme le client l'a reconfirmé.
  ///
  /// Sans ce mélange, une seule graine servait tout le plateau : les douze
  /// tâches affichaient toutes la même variante, ce qui ne faisait que quatre
  /// feuilles possibles par univers au lieu de 4¹².
  ///
  /// Le tirage reste STABLE pour une graine donnée : les libellés ne changent
  /// pas sous les yeux du joueur pendant qu'il réordonne.
  String variantAt(int seed) =>
      variants[_avalanche(seed * 0x9E3779B1 ^ id.hashCode) % variants.length];

  /// Brassage de bits (finaliseur MurmurHash3).
  ///
  /// Un simple `(seed ^ hash) % 4` ne regardait que les DEUX DERNIERS bits de
  /// la graine : les bits de poids fort n'atteignaient jamais le reste de la
  /// division, et tout le plateau restait déterminé par `seed & 3` — quatre
  /// feuilles possibles, quel que soit le nombre de tâches. Le finaliseur
  /// propage les bits hauts vers les bas, si bien que chaque graine donne une
  /// combinaison différente.
  static int _avalanche(int x) {
    var h = x & 0xFFFFFFFF;
    h = ((h ^ (h >> 16)) * 0x85EBCA6B) & 0xFFFFFFFF;
    h = ((h ^ (h >> 13)) * 0xC2B2AE35) & 0xFFFFFFFF;
    return (h ^ (h >> 16)) & 0xFFFFFFFF;
  }

  factory DayStackTask.fromJson(Map<String, dynamic> json) {
    final variants = (json['variants'] as List<dynamic>).cast<String>();
    if (variants.isEmpty) {
      throw FormatException('tâche ${json['id']} sans libellé');
    }
    return DayStackTask(
      id: json['id'] as String,
      variants: List.unmodifiable(variants),
      durationMin: (json['durationMin'] as num).toInt(),
      restMin: (json['restMin'] as num?)?.toInt() ?? 0,
      deps: List.unmodifiable((json['deps'] as List<dynamic>).cast<String>()),
      priority: DayStackPriority.values.firstWhere(
        (p) => p.name == (json['priority'] as String).toLowerCase(),
        orElse: () => DayStackPriority.none,
      ),
      constraint: DayStackConstraint.fromJson(
        json['constraint'] as Map<String, dynamic>,
      ),
      category: json['category'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

/// Un univers thématique et ses tâches.
class DayStackUniverse {
  const DayStackUniverse({
    required this.id,
    required this.name,
    required this.tasks,
  });

  final String id;
  final String name;
  final List<DayStackTask> tasks;

  /// Nombre réel de contraintes horaires de cet univers.
  ///
  /// Le référentiel insiste : la composante « gestion du temps » doit diviser
  /// par ce n-là, jamais par une constante — il varie de 5 à 7 selon l'univers,
  /// et une constante rendrait deux passations incomparables.
  int get timingConstraintCount =>
      tasks.where((t) => t.constraint.hasTiming).length;

  DayStackTask byId(String id) =>
      tasks.firstWhere((t) => t.id == id, orElse: () => throw StateError(id));

  factory DayStackUniverse.fromJson(Map<String, dynamic> json) =>
      DayStackUniverse(
        id: json['id'] as String,
        name: json['name'] as String,
        tasks: List.unmodifiable(
          (json['tasks'] as List<dynamic>).map(
            (t) => DayStackTask.fromJson(t as Map<String, dynamic>),
          ),
        ),
      );
}

/// La banque complète.
class DayStackBank {
  const DayStackBank({required this.version, required this.universes});

  final int version;
  final List<DayStackUniverse> universes;

  DayStackUniverse byId(String id) =>
      universes.firstWhere((u) => u.id == id, orElse: () => throw StateError(id));

  factory DayStackBank.fromJson(Map<String, dynamic> json) => DayStackBank(
    version: (json['version'] as num).toInt(),
    universes: List.unmodifiable(
      (json['universes'] as List<dynamic>).map(
        (u) => DayStackUniverse.fromJson(u as Map<String, dynamic>),
      ),
    ),
  );
}
