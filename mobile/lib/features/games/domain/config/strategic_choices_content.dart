/// Réglages de présentation de l'expérience Strategic Choices.
///
/// Les 80 situations vivent dans `strategic_choices_bank.json`. Ce fichier ne
/// garde que les réglages de présentation et la liste des huit stratégies.
///
/// Le mobile transmet les choix bruts. Le serveur applique la cotation 0-3
/// provisoire et renvoie le score ; le client ne calcule aucun résultat métier.
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
  /// stratégie à sa cotation dans la banque et au serveur.
  final String wire;
}
