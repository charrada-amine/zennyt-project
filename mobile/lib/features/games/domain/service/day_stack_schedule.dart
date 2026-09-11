/// Moteur d'ordonnancement du « Planning journalier ».
///
/// Transforme l'ORDRE choisi par le joueur en un vrai planning horaire : heures
/// de début, temps morts, collisions, violations. C'est ce que le jeu n'avait
/// pas — il n'alignait que des créneaux numérotés, sans horloge — et sans quoi
/// trois des quatre composantes du barème client ne peuvent pas être calculées.
///
/// ## Le modèle : séquentiel, avec attentes
///
/// Les tâches s'enchaînent dans l'ordre du joueur, à partir de l'ouverture de
/// la journée. Avant chacune, le moteur attend qu'elle soit AUTORISÉE à
/// commencer : sa fenêtre ouverte, son heure d'ancrage atteinte, ses prérequis
/// terminés et leur repos écoulé. Cette attente est le **temps mort** — c'est
/// exactement ce que la composante « cohérence séquentielle » mesure.
///
/// ## Trois interprétations, que le référentiel laisse ouvertes
///
/// Elles sont isolées ici pour être discutées, pas noyées dans le code :
///
/// 1. **Collision.** Le référentiel dit « 1 pt si aucune collision » sans la
///    définir. Dans un planning purement séquentiel, deux tâches ne peuvent pas
///    se chevaucher — le critère serait toujours acquis, donc inutile. On
///    retient donc : une collision est un **bloc horaire fixe qui ne peut pas
///    démarrer à son heure parce que le planning est déjà occupé à ce
///    moment-là**. C'est la seule lecture qui rende le critère discriminant.
///
/// 2. **Le repos passif bloque-t-il le créneau ?** Question explicitement
///    ouverte au référentiel (« marinade, séchage du béton »). Ici le repos
///    n'occupe PAS le planning : il retarde seulement les tâches qui en
///    dépendent. C'est l'hypothèse la plus favorable au joueur, et la plus
///    proche du métier — on ne reste pas devant une marinade.
///
/// 3. **Ouverture de la journée.** La source ne la donne pas. Elle est déduite
///    des contraintes — fenêtres, ancrages, et aussi échéances : deux tâches
///    doivent être finies « Avant 8h » dans des univers dont la première
///    fenêtre n'ouvre qu'à 8h00. Voir [dayStackStartOf].
library;

import '../entities/day_stack_bank.dart';

/// Ouverture par défaut quand un univers n'a aucune contrainte d'heure.
const int kDayStackDefaultStartMin = 8 * 60;

/// Nature d'une violation constatée sur un planning.
enum DayStackViolationKind {
  /// Tâche placée avant l'un de ses prérequis.
  dependency,

  /// Prérequis terminé, mais son repos obligatoire n'était pas écoulé.
  restNotElapsed,

  /// Tâche hors de sa fenêtre, de son échéance ou de son ancrage.
  timing,

  /// Bloc horaire fixe empêché de démarrer à l'heure par une tâche en cours.
  collision,
}

/// Une violation, rattachée à la tâche qui la porte.
class DayStackViolation {
  const DayStackViolation({
    required this.kind,
    required this.taskId,
    this.otherTaskId,
    required this.detail,
  });

  final DayStackViolationKind kind;
  final String taskId;

  /// Prérequis concerné, pour les violations de dépendance.
  final String? otherTaskId;

  final String detail;

  @override
  String toString() => '${kind.name}($taskId): $detail';
}

/// Une tâche posée sur l'horloge.
class DayStackPlacement {
  const DayStackPlacement({
    required this.taskId,
    required this.startMin,
    required this.endMin,
    required this.readyMin,
    required this.waitBeforeMin,
  });

  final String taskId;

  /// Début du travail actif.
  final int startMin;

  /// Fin du travail actif — le planning est libre ensuite.
  final int endMin;

  /// Moment où les dépendants peuvent démarrer : [endMin] plus le repos passif.
  final int readyMin;

  /// Attente subie avant de pouvoir commencer. C'est le temps mort.
  final int waitBeforeMin;
}

/// Le planning calculé, et tout ce que le barème devra lire.
class DayStackSchedule {
  const DayStackSchedule({
    required this.dayStartMin,
    required this.placements,
    required this.violations,
    required this.totalWorkMin,
    required this.deadTimeMin,
    required this.timingConstraintCount,
    required this.timingConstraintsRespected,
    required this.dependencyEdgeCount,
    required this.dependencyEdgesRespected,
  });

  final int dayStartMin;
  final List<DayStackPlacement> placements;
  final List<DayStackViolation> violations;

  /// Somme des durées de travail — le repos passif n'y entre pas.
  final int totalWorkMin;

  /// Total des attentes.
  final int deadTimeMin;

  /// n RÉEL de contraintes horaires de l'univers.
  ///
  /// Le référentiel y insiste : diviser par une constante rendrait deux
  /// passations incomparables, puisque n varie de 5 à 7 selon l'univers.
  final int timingConstraintCount;
  final int timingConstraintsRespected;

  final int dependencyEdgeCount;
  final int dependencyEdgesRespected;

  bool get hasCollision =>
      violations.any((v) => v.kind == DayStackViolationKind.collision);

  /// Fin du dernier travail, ou l'ouverture si le planning est vide.
  int get endMin => placements.isEmpty ? dayStartMin : placements.last.endMin;

  /// Part de temps mort sur l'amplitude occupée.
  ///
  /// Rapportée à l'amplitude (ouverture → fin) et non à la somme des durées :
  /// c'est l'amplitude qui contient réellement les trous.
  double get deadTimeRatio {
    final span = endMin - dayStartMin;
    if (span <= 0) return 0;
    return deadTimeMin / span;
  }

  DayStackPlacement? placementOf(String taskId) {
    for (final p in placements) {
      if (p.taskId == taskId) return p;
    }
    return null;
  }
}

/// Ouverture de journée déduite des contraintes de l'univers.
///
/// Deux familles d'heures la déterminent :
///
/// - les débuts de fenêtre et d'ancrage, évidemment ;
/// - **les échéances**, moins évidemment. Deux tâches de la banque doivent être
///   terminées « Avant 8h » alors que la première fenêtre de leur univers
///   n'ouvre qu'à 8h00 : ouvrir à 8h les rendrait impossibles à tenir, même
///   faites en premier. L'ouverture recule donc jusqu'à ce que toute échéance
///   soit atteignable.
///
/// Rien n'est inventé ici : l'ouverture est déduite des données, pas choisie.
int dayStackStartOf(DayStackUniverse universe) {
  final candidates = <int>[
    for (final task in universe.tasks)
      if (task.constraint.startMin != null) task.constraint.startMin!,
    for (final task in universe.tasks)
      if (task.constraint.beforeMin != null)
        task.constraint.beforeMin! - task.durationMin,
  ];
  if (candidates.isEmpty) return kDayStackDefaultStartMin;
  return candidates.reduce((a, b) => a < b ? a : b);
}

/// Pose [order] sur l'horloge et relève tout ce qui cloche.
///
/// [order] est l'ordre choisi par le joueur — les identifiants de tâches, dans
/// l'ordre des créneaux. Les tâches absentes ne sont simplement pas planifiées ;
/// c'est ce qui permet d'évaluer un planning PARTIEL, en cours de partie, et
/// donc de signaler une erreur au moment où elle apparaît.
DayStackSchedule buildDayStackSchedule({
  required DayStackUniverse universe,
  required List<String> order,
  int? dayStartMin,
}) {
  final start = dayStartMin ?? dayStackStartOf(universe);
  final placements = <DayStackPlacement>[];
  final violations = <DayStackViolation>[];
  final done = <String, DayStackPlacement>{};

  var cursor = start;
  var deadTime = 0;
  var work = 0;

  for (final id in order) {
    final task = universe.byId(id);
    final c = task.constraint;

    // ── Quand cette tâche a-t-elle le droit de commencer ? ─────────────────
    var earliest = cursor;

    for (final dep in task.deps) {
      final placed = done[dep];
      if (placed == null) {
        // Le prérequis n'est pas encore au planning : c'est une violation
        // directe au sens du référentiel — « tâche lancée sans que son
        // prérequis soit terminé ».
        violations.add(
          DayStackViolation(
            kind: DayStackViolationKind.dependency,
            taskId: id,
            otherTaskId: dep,
            detail: 'placée avant son prérequis',
          ),
        );
        continue;
      }
      if (placed.readyMin > earliest) {
        // Le repos passif du prérequis n'est pas écoulé : on attend, et cette
        // attente compte comme du temps mort.
        earliest = placed.readyMin;
      }
    }

    final anchored = c.kind == DayStackConstraintKind.anchor;
    final windowed = c.kind == DayStackConstraintKind.window;
    if ((anchored || windowed) && c.startMin != null && c.startMin! > earliest) {
      earliest = c.startMin!;
    }

    // ── Collision : un bloc fixe qui ne peut pas démarrer à l'heure ────────
    //
    // Le planning était déjà occupé au moment où ce bloc devait commencer. La
    // tâche en cours et le bloc se disputent la même minute — c'est bien un
    // chevauchement, même si la pose séquentielle l'empêche d'être visible.
    if (c.fixedBlock && c.startMin != null && cursor > c.startMin!) {
      violations.add(
        DayStackViolation(
          kind: DayStackViolationKind.collision,
          taskId: id,
          detail: 'bloc fixe empêché de démarrer à l\'heure',
        ),
      );
    }

    final wait = earliest - cursor;
    final taskStart = earliest;
    final taskEnd = taskStart + task.durationMin;

    deadTime += wait > 0 ? wait : 0;
    work += task.durationMin;

    final placement = DayStackPlacement(
      taskId: id,
      startMin: taskStart,
      endMin: taskEnd,
      readyMin: taskEnd + task.restMin,
      waitBeforeMin: wait > 0 ? wait : 0,
    );
    placements.add(placement);
    done[id] = placement;
    cursor = taskEnd;
  }

  // ── Contraintes horaires : respectées ou non, une fois tout posé ─────────
  var timingTotal = 0;
  var timingOk = 0;
  for (final task in universe.tasks) {
    final c = task.constraint;
    if (!c.hasTiming) continue;
    // Le défaut connu — bloc fixe sans heure — ne peut être ni respecté ni
    // violé : il sort du dénominateur plutôt que de compter comme un échec.
    if (c.kind == DayStackConstraintKind.unspecified) continue;
    timingTotal++;

    final p = done[task.id];
    if (p == null) continue; // non planifiée : contrainte non satisfaite

    final ok = switch (c.kind) {
      DayStackConstraintKind.window =>
        p.startMin >= (c.startMin ?? 0) && p.endMin <= (c.endMin ?? 1 << 30),
      DayStackConstraintKind.deadline => p.endMin <= (c.beforeMin ?? 1 << 30),
      DayStackConstraintKind.anchor =>
        (p.startMin - (c.startMin ?? 0)).abs() <= (c.toleranceMin ?? 0),
      DayStackConstraintKind.relative => _relativeRespected(c, p, done),
      DayStackConstraintKind.minDelay => _minDelayRespected(
        task,
        universe,
        done,
      ),
      DayStackConstraintKind.unspecified ||
      DayStackConstraintKind.none => true,
    };
    if (ok) {
      timingOk++;
    } else {
      violations.add(
        DayStackViolation(
          kind: DayStackViolationKind.timing,
          taskId: task.id,
          detail: c.raw ?? c.kind.name,
        ),
      );
    }
  }

  // ── Dépendances : ratio sur les ARÊTES, comme le demande le barème ───────
  var edges = 0;
  var edgesOk = 0;
  for (final task in universe.tasks) {
    for (final dep in task.deps) {
      edges++;
      final here = done[task.id];
      final before = done[dep];
      if (here == null || before == null) continue;
      if (before.endMin <= here.startMin) edgesOk++;
    }
  }

  return DayStackSchedule(
    dayStartMin: start,
    placements: List.unmodifiable(placements),
    violations: List.unmodifiable(violations),
    totalWorkMin: work,
    deadTimeMin: deadTime,
    timingConstraintCount: timingTotal,
    timingConstraintsRespected: timingOk,
    dependencyEdgeCount: edges,
    dependencyEdgesRespected: edgesOk,
  );
}

/// « Avant la réunion » : cette tâche doit être terminée avant que la tâche
/// visée ne commence.
bool _relativeRespected(
  DayStackConstraint c,
  DayStackPlacement p,
  Map<String, DayStackPlacement> done,
) {
  final target = done[c.beforeTaskId];
  if (target == null) return false;
  return p.endMin <= target.startMin;
}

/// Délai minimum avant la suite — deux formes dans la banque, une seule règle.
///
/// Le délai se compte depuis le DÉBUT de la tâche, et c'est ce qui réconcilie
/// les deux cas :
///
/// - `marinade` — 20 min de travail puis 60 min de repos : le délai est le
///   repos, qui s'ajoute au travail. Dépendants au plus tôt à début + 80.
/// - `sechage_beton` — 120 min de durée, « Mini. 2h avant la suite » : ici le
///   délai EST la tâche. Le compter après sa fin exigerait quatre heures là où
///   le métier en demande deux, et rendait l'univers injouable.
bool _minDelayRespected(
  DayStackTask task,
  DayStackUniverse universe,
  Map<String, DayStackPlacement> done,
) {
  final here = done[task.id];
  if (here == null) return false;
  final delay = task.constraint.minDelayMin ?? task.restMin;
  for (final other in universe.tasks) {
    if (!other.deps.contains(task.id)) continue;
    final p = done[other.id];
    if (p == null) return false;
    if (p.startMin - here.startMin < delay) return false;
  }
  return true;
}
