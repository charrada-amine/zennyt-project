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
  avoidFlee('Éviter / fuir', 'AVOID_FLEE'),
  ruminate('Ruminer', 'RUMINATE'),
  breathePause('Respirer / pause', 'BREATHE_PAUSE'),
  cognitiveReappraisal('Recadrage cognitif', 'COGNITIVE_REAPPRAISAL'),
  assertiveCommunication('Communication assertive', 'ASSERTIVE_COMMUNICATION'),
  humor('Humour', 'HUMOR'),
  seekSupport('Chercher du soutien', 'SEEK_SUPPORT'),
  directAction('Action directe', 'DIRECT_ACTION');

  const StrategicChoiceStrategy(this.label, this.wire);

  final String label;

  /// Nom stable, indépendant du libellé affiché : c'est lui qui relie une
  /// stratégie à sa cotation dans la banque et au serveur.
  final String wire;
}
