import '../config/strategic_choices_content.dart';

/// Support par lequel une situation « Choix Stratégiques » est présentée.
///
/// La banque contient 74 scènes vidéo et 6 messages écrits. Le support remonte
/// avec la réponse parce qu'il conditionne la façon dont le joueur a pris
/// connaissance de la situation.
enum StrategicChoiceMedium {
  video('VIDEO'),
  written('WRITTEN');

  const StrategicChoiceMedium(this.wire);

  final String wire;

  static StrategicChoiceMedium fromWire(String wire) => values.firstWhere(
    (m) => m.wire == wire,
    orElse: () => throw ArgumentError('support inconnu : $wire'),
  );
}

/// Une des huit stratégies proposées, avec sa cotation.
class StrategicChoiceOption {
  const StrategicChoiceOption({
    required this.strategy,
    required this.score,
    required this.rationale,
  });

  final StrategicChoiceStrategy strategy;

  /// Cotation du barème : 3 la plus pertinente, 0 contre-productive.
  final int score;

  /// Justification clinique. Non affichée pendant la partie.
  final String rationale;

  factory StrategicChoiceOption.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num).toInt();
    if (score < 0 || score > 3) {
      throw ArgumentError('cotation hors 0-3 : $score');
    }
    return StrategicChoiceOption(
      strategy: StrategicChoiceStrategy.values.firstWhere(
        (s) => s.wire == json['strategy'],
        orElse: () =>
            throw ArgumentError('stratégie inconnue : ${json['strategy']}'),
      ),
      score: score,
      rationale: json['rationale'] as String,
    );
  }
}

/// Une situation du barème « Choix Stratégiques » (CS-001 à CS-120).
class StrategicChoiceScenario {
  const StrategicChoiceScenario({
    required this.id,
    required this.title,
    required this.context,
    required this.scene,
    required this.medium,
    this.message,
    required this.needsPsychologistValidation,
    required this.choices,
  });

  final String id;
  final String title;

  /// Résumé du contexte, en une ligne.
  final String context;

  /// Description de la scène, telle que le barème l'a supposée.
  ///
  /// Tient lieu de scène jouable tant que la mini-vidéo n'existe pas.
  final String scene;

  final StrategicChoiceMedium medium;

  /// Texte littéral du message, pour les situations à support écrit.
  ///
  /// Les six situations écrites de la proposition le portent, ce qui les rend
  /// jouables sans attendre la production vidéo.
  final String? message;

  /// Fiche dont le document signale que le contexte inféré est ambigu.
  ///
  /// Le barème a été reconstruit à partir des seuls titres, sans visionnage :
  /// trois situations demandent explicitement une validation du psychologue
  /// avant d'être intégrées au barème. On garde le signal plutôt que de le
  /// perdre à la conversion.
  final bool needsPsychologistValidation;

  final List<StrategicChoiceOption> choices;

  int get bestScore =>
      choices.map((c) => c.score).reduce((a, b) => a > b ? a : b);

  /// Espérance d'une réponse au hasard — moyenne des huit cotations.
  ///
  /// C'est la ligne de base contre laquelle le score se lit. Sans elle, un
  /// 15/30 passerait pour « la moitié », alors que le hasard rapporte déjà
  /// 40 % du maximum sur cette banque.
  double get chanceBaseline =>
      choices.map((c) => c.score).reduce((a, b) => a + b) / choices.length;

  StrategicChoiceOption byStrategy(StrategicChoiceStrategy strategy) =>
      choices.firstWhere((c) => c.strategy == strategy);

  factory StrategicChoiceScenario.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final medium = StrategicChoiceMedium.fromWire(json['medium'] as String);
    final message = json['message'] as String?;
    if (medium == StrategicChoiceMedium.written &&
        (message == null || message.trim().isEmpty)) {
      throw ArgumentError('$id : message écrit manquant');
    }
    if (medium == StrategicChoiceMedium.video && message != null) {
      throw ArgumentError(
        '$id : une situation vidéo ne doit pas avoir de message',
      );
    }
    final choices = (json['choices'] as List)
        .map((c) => StrategicChoiceOption.fromJson(c as Map<String, dynamic>))
        .toList();
    if (choices.length != 8) {
      throw ArgumentError('$id : ${choices.length} stratégies au lieu de 8');
    }
    return StrategicChoiceScenario(
      id: id,
      title: json['title'] as String,
      context: json['context'] as String,
      scene: json['scene'] as String,
      medium: medium,
      message: message,
      needsPsychologistValidation:
          json['needsPsychologistValidation'] as bool? ?? false,
      choices: choices,
    );
  }
}

/// Banque complète des 80 situations « Choix Stratégiques ».
class StrategicChoicesBank {
  const StrategicChoicesBank({required this.scenarios});

  final List<StrategicChoiceScenario> scenarios;

  StrategicChoiceScenario byId(String id) =>
      scenarios.firstWhere((s) => s.id == id);

  factory StrategicChoicesBank.fromJson(Map<String, dynamic> json) {
    return StrategicChoicesBank(
      scenarios: (json['situations'] as List)
          .map(
            (s) => StrategicChoiceScenario.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
