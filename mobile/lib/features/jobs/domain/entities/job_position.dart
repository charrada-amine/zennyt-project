import 'package:equatable/equatable.dart';

import 'job.dart';

/// Métier du référentiel Fit Score.
///
/// F06 (FITSCORE_REMEDIATION.md §3) — `jobPositionId` est obligatoire à la création
/// d'une offre depuis la suppression du repli IA : sans métier, la formule n'a aucune
/// pondération et l'offre resterait sans Fit Score. Le champ était bien envoyé, mais
/// aucun écran ne le renseignait — donc toujours `null`, donc toute création échouait.
class JobPosition extends Equatable {
  final String id;
  final String name;

  /// `null` = métier transverse, présent dans tous les secteurs.
  final String? sector;
  final String? profileType;

  /// F32 — mode de mesure du hard skills, propre au métier depuis V60.
  final String typeEvaluationHard;

  /// `false` = pondération « v1 », pas encore validée en atelier RH. Affiché tel quel
  /// au recruteur plutôt que masqué : un score bâti sur des poids non calibrés ne doit
  /// pas se présenter comme un score validé.
  final bool calibrated;

  /// Intitulé usuel par niveau. Les 4 bandes du CdC sont Junior/Senior/Lead/Manager,
  /// mais un chantier ne parle pas de « Lead » : il dit « Chef d'équipe ». Le serveur
  /// renvoie le libellé métier quand il existe, sinon le défaut.
  final Map<String, String> levelLabels;

  const JobPosition({
    required this.id,
    required this.name,
    this.sector,
    this.profileType,
    this.typeEvaluationHard = 'QCM',
    this.calibrated = false,
    this.levelLabels = const {},
  });

  factory JobPosition.fromJson(Map<String, dynamic> json) => JobPosition(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        sector: json['sector'] as String?,
        profileType: json['profileType'] as String?,
        typeEvaluationHard: json['typeEvaluationHard'] as String? ?? 'QCM',
        calibrated: json['calibrated'] as bool? ?? false,
        levelLabels: (json['levelLabels'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as String)),
      );

  /// Libellé d'affichage : le secteur lève l'ambiguïté entre métiers homonymes.
  String get label => sector == null ? name : '$name · $sector';

  /// Intitulé du niveau pour ce métier, avec repli sur la bande générique.
  String levelLabel(ExperienceLevel level) => levelLabels[level.value] ?? level.label;

  @override
  List<Object?> get props => [id, name, sector, profileType];
}

/// Pondération de référence pour un couple (profil métier, niveau).
///
/// F30 (FITSCORE_REMEDIATION.md §3) — `GET /job-role-profiles` existait, était au
/// contrat, et son javadoc annonçait servir « à pré-remplir les curseurs de pondération
/// du formulaire de création d'offre ». Aucun client ne l'appelait : l'endpoint était
/// construit et jamais consommé.
///
/// Lecture seule pour l'instant : les niveaux d'héritage 2 (entreprise) et 3 (offre)
/// sont reportés (décision D-E), donc il n'y a rien à ajuster — seulement à montrer au
/// recruteur ce que son choix de métier et de niveau implique réellement.
class JobRoleProfile extends Equatable {
  final String profileType;
  final ExperienceLevel level;
  final int softWeight;
  final int hardWeight;
  final int cognitiveFlexibilityWeight;
  final int workingMemoryWeight;
  final int decisionMakingWeight;
  final int executivePlanningWeight;
  final int emotionalRegulationWeight;
  final bool calibrated;

  const JobRoleProfile({
    required this.profileType,
    required this.level,
    required this.softWeight,
    required this.hardWeight,
    required this.cognitiveFlexibilityWeight,
    required this.workingMemoryWeight,
    required this.decisionMakingWeight,
    required this.executivePlanningWeight,
    required this.emotionalRegulationWeight,
    required this.calibrated,
  });

  factory JobRoleProfile.fromJson(Map<String, dynamic> json) => JobRoleProfile(
        profileType: json['profileType'] as String? ?? '',
        level: ExperienceLevel.fromString(json['level'] as String? ?? 'JUNIOR'),
        softWeight: (json['softWeight'] as num?)?.toInt() ?? 0,
        hardWeight: (json['hardWeight'] as num?)?.toInt() ?? 0,
        cognitiveFlexibilityWeight: (json['cognitiveFlexibilityWeight'] as num?)?.toInt() ?? 0,
        workingMemoryWeight: (json['workingMemoryWeight'] as num?)?.toInt() ?? 0,
        decisionMakingWeight: (json['decisionMakingWeight'] as num?)?.toInt() ?? 0,
        executivePlanningWeight: (json['executivePlanningWeight'] as num?)?.toInt() ?? 0,
        emotionalRegulationWeight: (json['emotionalRegulationWeight'] as num?)?.toInt() ?? 0,
        calibrated: json['calibrated'] as bool? ?? false,
      );

  /// Les 5 modules dans l'ordre du cahier des charges, prêts à afficher.
  List<MapEntry<String, int>> get moduleWeights => [
        MapEntry('Flexibilité cognitive', cognitiveFlexibilityWeight),
        MapEntry('Mémoire de travail', workingMemoryWeight),
        MapEntry('Prise de décision', decisionMakingWeight),
        MapEntry('Planification exécutive', executivePlanningWeight),
        MapEntry('Régulation émotionnelle', emotionalRegulationWeight),
      ];

  @override
  List<Object?> get props => [profileType, level];
}
