import '../domain/entities/decision_metrics.dart';

/// Jalon de parcours de « Je Décide » : une dimension franchie.
///
/// Les écrans de transition affichaient ces jalons **en dur** — le médaillon
/// « RN », le titre « Risk Navigator » et deux pastilles allumées sur cinq,
/// quelle que soit la dimension réellement terminée. Un joueur arrivé au
/// scénario 25 sur 30, qui venait donc d'en franchir quatre, voyait toujours la
/// deuxième annoncée et 2/5 de progression.
///
/// La table vit ici, et non dans une vue, parce que trois écrans la lisent :
/// l'écran de jalon, l'écran de badge et — à terme — l'écran de résultats.
class DecisionMilestone {
  const DecisionMilestone({required this.code, required this.name});

  /// Sigle du médaillon (« RN »).
  final String code;

  /// Nom affiché du jalon (« Risk Navigator »).
  final String name;
}

/// Un jalon par dimension, dans l'ordre du parcours.
///
/// ⚠️ **Trois de ces cinq noms sont à valider.** « Risk Navigator » et
/// « Steady Explorer » existaient déjà dans l'application ; les trois autres
/// n'existaient nulle part — les écrans n'affichaient jamais que ces deux-là.
/// Ils sont écrits ici dans la même famille (un rôle, pas un score) et suivent
/// les sigles déjà dessinés. À reprendre avec le client ou le psychologue : ce
/// sont les seuls libellés de ce fichier que personne n'a encore approuvés.
const Map<DecisionDimension, DecisionMilestone> kDecisionMilestones = {
  // Intégration d'information — analyse des contraintes.
  DecisionDimension.ii: DecisionMilestone(
    code: 'AE',
    name: 'Analytical Explorer', // à valider
  ),
  // Équilibre du risque.
  DecisionDimension.er: DecisionMilestone(
    code: 'RN',
    name: 'Risk Navigator', // déjà dans l'app
  ),
  // Décision sous contrainte de temps.
  DecisionDimension.dt: DecisionMilestone(
    code: 'QC',
    name: 'Quick Chooser', // à valider
  ),
  // Stabilité des choix.
  DecisionDimension.cs: DecisionMilestone(
    code: 'SE',
    name: 'Steady Explorer', // déjà dans l'app
  ),
  // Maîtrise de soi / récompense différée.
  DecisionDimension.re: DecisionMilestone(
    code: 'SP',
    name: 'Self Pacer', // à valider
  ),
};

/// Jalon d'une dimension. Toutes les dimensions en ont un : la table couvre
/// [DecisionDimension.values] au complet, et un test le verrouille.
DecisionMilestone milestoneOf(DecisionDimension dimension) =>
    kDecisionMilestones[dimension]!;
