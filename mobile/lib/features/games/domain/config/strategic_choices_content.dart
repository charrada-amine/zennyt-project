/// Front-only content for the Strategic Choices experience.
///
/// Les situations vivent désormais dans `strategic_choices_bank.json` — les 60
/// fiches CS-001 à CS-060 du client — et non plus ici : ce fichier ne garde que
/// les réglages de présentation et la liste des huit stratégies.
///
/// La banque apporte une cotation 0-3 par stratégie, mais elle n'est PAS
/// branchée sur un score : le document la donne lui-même comme « établie
/// indépendamment du script du psychologue », reconstruite par inférence à
/// partir des seuls titres, et trois fiches attendent une validation. Le client
/// ne calcule donc toujours aucun résultat psychométrique.
final class StrategicChoicesContent {
  StrategicChoicesContent._();

  static const reflectionDuration = Duration(seconds: 3);
  static const savedTransitionDuration = Duration(milliseconds: 700);

  static const strategies = <StrategicChoiceStrategy>[
    StrategicChoiceStrategy.avoidFlee,
    StrategicChoiceStrategy.ruminate,
    StrategicChoiceStrategy.breathePause,
    StrategicChoiceStrategy.cognitiveReappraisal,
    StrategicChoiceStrategy.assertiveCommunication,
    StrategicChoiceStrategy.humor,
    StrategicChoiceStrategy.seekSupport,
    StrategicChoiceStrategy.directAction,
  ];
}

enum StrategicChoiceStrategy {
  avoidFlee('Avoid / flee', 'AVOID_FLEE'),
  ruminate('Ruminate', 'RUMINATE'),
  breathePause('Breathe / pause', 'BREATHE_PAUSE'),
  cognitiveReappraisal('Cognitive reappraisal', 'COGNITIVE_REAPPRAISAL'),
  assertiveCommunication('Assertive communication', 'ASSERTIVE_COMMUNICATION'),
  humor('Humor', 'HUMOR'),
  seekSupport('Seek support', 'SEEK_SUPPORT'),
  directAction('Direct action', 'DIRECT_ACTION');

  const StrategicChoiceStrategy(this.label, this.wire);

  final String label;

  /// Nom stable, indépendant du libellé affiché : c'est lui qui relie une
  /// stratégie à sa cotation dans la banque et, un jour, au serveur.
  final String wire;
}
