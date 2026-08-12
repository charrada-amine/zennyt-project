/// Front-only content for the Strategic Choices experience.
///
/// The handoff provides the public situations and strategy labels, but no
/// validated scoring model. Consequently this catalogue deliberately contains
/// no "optimal", "secondary" or "trap" keys and must never be used to infer a
/// psychometric result on the client.
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

  static const situations = <StrategicChoiceSituation>[
    StrategicChoiceSituation(
      id: 'STRATEGIC_01',
      type: 'Conflict',
      prompt: 'A colleague criticizes your work in front of the whole team.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_02',
      type: 'Failure',
      prompt: 'You fail an important exam or goal after weeks of preparation.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_03',
      type: 'Delay',
      prompt:
          'You are blocked in transport and arrive late to a decisive interview.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_04',
      type: 'Criticism',
      prompt:
          'Your manager gives negative feedback on a project you thought was successful.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_05',
      type: 'Conflict',
      prompt:
          'A close person cancels an important commitment at the last minute for the third time.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_06',
      type: 'Overload',
      prompt:
          'You receive three professional emergencies at the same time with the same deadline.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_07',
      type: 'Failure',
      prompt: 'A project you carried for one year is abandoned by leadership.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_08',
      type: 'Criticism',
      prompt: 'A public social media comment questions your competence.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_09',
      type: 'Delay',
      prompt:
          'A supplier does not deliver on time, putting a client commitment at risk.',
    ),
    StrategicChoiceSituation(
      id: 'STRATEGIC_10',
      type: 'Conflict',
      prompt:
          'Two team members argue openly during a meeting you are facilitating.',
    ),
  ];
}

enum StrategicChoiceStrategy {
  avoidFlee('Avoid / flee'),
  ruminate('Ruminate'),
  breathePause('Breathe / pause'),
  cognitiveReappraisal('Cognitive reappraisal'),
  assertiveCommunication('Assertive communication'),
  humor('Humor'),
  seekSupport('Seek support'),
  directAction('Direct action');

  const StrategicChoiceStrategy(this.label);

  final String label;
}

final class StrategicChoiceSituation {
  const StrategicChoiceSituation({
    required this.id,
    required this.type,
    required this.prompt,
  });

  final String id;
  final String type;
  final String prompt;
}
