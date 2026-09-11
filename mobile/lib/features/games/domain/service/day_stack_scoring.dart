/// Barème /10 du « Planning journalier ».
///
/// Miroir Dart de `TaskSchedulingConfig` côté backend. Le serveur reste
/// l'autorité — le client n'envoie jamais de points — mais le mock hors ligne
/// doit produire exactement le même score, sans quoi une démonstration sans
/// serveur noterait autrement qu'une passation réelle.
///
/// Quatre composantes, selon le référentiel client :
/// dépendances (3) + gestion du temps (3) + cohérence séquentielle (2)
/// + autorégulation (2).
library;

/// Pénalité par violation DIRECTE — « tâche lancée sans prérequis terminé ».
///
/// Le référentiel la distingue d'un simple sous-optimum d'ordre : c'est une
/// erreur de règle (Tour de Londres, Shallice 1982).
const double kDayStackDirectViolationPenalty = 1.0;

/// Temps mort sous ce seuil → le point entier.
const double kDayStackDeadTimeFullPointRatio = 0.10;

/// Temps mort jusqu'à ce seuil → un demi-point ; au-delà → rien.
const double kDayStackDeadTimeHalfPointRatio = 0.25;

/// Jusqu'à ce total de corrections → 2 pts.
const int kDayStackSelfRegulationLowTotal = 1;

/// Jusqu'à ce total → 1 pt.
const int kDayStackSelfRegulationMidTotal = 3;

/// Au-delà de ce nombre de corrections RÉACTIVES → 0 pt.
const int kDayStackSelfRegulationReactiveLimit = 3;

/// Composante 1 — dépendances, sur 3 points.
///
/// `3 × (respectées / total) − 1 par violation directe`, plancher 0. Sans
/// arête de dépendance, la composante est acquise : on ne pénalise pas un
/// univers qui n'en a pas.
double dayStackDependencyScore(
  int respected,
  int total,
  int directViolations,
) {
  if (total <= 0) return 3.0;
  final ratio = 3.0 * respected / total;
  final penalised = ratio - kDayStackDirectViolationPenalty * directViolations;
  return penalised < 0 ? 0.0 : penalised;
}

/// Composante 2 — gestion du temps, sur 3 points.
///
/// `3 × (respectées / n)`, où n est le nombre RÉEL de contraintes horaires de
/// l'univers tiré. Le référentiel y insiste : n varie de 5 à 7, et diviser par
/// une constante rendrait deux passations incomparables.
double dayStackTimeScore(int respected, int constraintCount) {
  if (constraintCount <= 0) return 3.0;
  return 3.0 * respected / constraintCount;
}

/// Composante 3 — cohérence séquentielle, sur 2 points.
///
/// Un point si aucune collision, plus un point modulé par le temps mort :
/// moins de 10 % → 1 pt, 10 à 25 % → 0,5 pt, au-delà → 0.
double dayStackCoherenceScore(bool collisionFree, double deadTimeRatio) {
  var points = collisionFree ? 1.0 : 0.0;
  if (deadTimeRatio < kDayStackDeadTimeFullPointRatio) {
    points += 1.0;
  } else if (deadTimeRatio <= kDayStackDeadTimeHalfPointRatio) {
    points += 0.5;
  }
  return points;
}

/// Composante 4 — autorégulation, sur 2 points.
///
/// Le référentiel distingue les corrections PROACTIVES — décidées avant que le
/// jeu n'ait rien signalé — des RÉACTIVES, déclenchées par une erreur affichée.
/// Trop de réactives l'emporte sur le total : corriger seulement sous alerte ne
/// démontre pas la même autorégulation.
///
/// Les seuils du référentiel — 1 puis 3 corrections — ont été calibrés sur UN
/// planning. Une partie en enchaîne plusieurs et les compteurs en font la
/// somme : [plannings] met les seuils à l'échelle, sinon un barème de manche
/// s'appliquerait à un total de partie.
double dayStackSelfRegulationScore(
  int proactive,
  int reactive, [
  int plannings = 1,
]) {
  final n = plannings < 1 ? 1 : plannings;
  if (reactive > kDayStackSelfRegulationReactiveLimit * n) return 0.0;
  final total = proactive + reactive;
  if (total <= kDayStackSelfRegulationLowTotal * n) return 2.0;
  if (total <= kDayStackSelfRegulationMidTotal * n) return 1.0;
  return 0.0;
}
