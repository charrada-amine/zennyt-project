import 'dart:math' as math;

import 'reflective_pause_metrics.dart';

/// Support par lequel la situation arrive au joueur.
///
/// Le client attend « selon le scénario, une vidéo OU un message écrit ». Le
/// support est donc une donnée de la situation, pas un réglage d'écran — et il
/// part avec les mesures, puisqu'il conditionne la façon dont le joueur a pris
/// connaissance de la scène.
enum ReflectivePauseMedium {
  /// Interaction en face à face : une mini-vidéo la rejouera.
  video('VIDEO'),

  /// SMS, chat ou e-mail : le message s'affiche tel quel.
  written('WRITTEN');

  const ReflectivePauseMedium(this.wire);

  final String wire;

  static ReflectivePauseMedium fromWire(String wire) => values.firstWhere(
    (m) => m.wire == wire,
    orElse: () => throw ArgumentError('support inconnu : $wire'),
  );
}

/// Difficulté d'une situation, telle que cotée par le référentiel.
enum ReflectivePauseDifficulty {
  low('LOW'),
  moderate('MODERATE'),
  high('HIGH');

  const ReflectivePauseDifficulty(this.wire);

  final String wire;

  static ReflectivePauseDifficulty fromWire(String wire) => values.firstWhere(
    (d) => d.wire == wire,
    orElse: () => throw ArgumentError('difficulté inconnue : $wire'),
  );
}

/// Une des cinq réactions proposées, avec sa cotation.
class ReflectivePauseChoice {
  const ReflectivePauseChoice({
    required this.letter,
    required this.text,
    required this.responseType,
    required this.rationale,
    required this.score,
  });

  /// Lettre d'origine dans la banque (A à E).
  ///
  /// Conservée pour la traçabilité avec le document du client, JAMAIS pour
  /// ordonner l'affichage — voir [ReflectivePauseSituation.choicesInDisplayOrder].
  final String letter;

  final String text;
  final ReflectivePauseResponseType responseType;

  /// Justification clinique de la cotation. Non affichée pendant la partie.
  final String rationale;

  /// Cotation du référentiel, de 0 à 3.
  final int score;

  factory ReflectivePauseChoice.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num).toInt();
    if (score < 0 || score > 3) {
      throw ArgumentError('cotation hors 0-3 : $score');
    }
    return ReflectivePauseChoice(
      letter: json['letter'] as String,
      text: json['text'] as String,
      responseType: ReflectivePauseResponseType.values.firstWhere(
        (t) => t.wire == json['responseType'],
        orElse: () =>
            throw ArgumentError('réaction inconnue : ${json['responseType']}'),
      ),
      rationale: json['rationale'] as String,
      score: score,
    );
  }
}

/// Une situation de pression (TR-001 à TR-060).
class ReflectivePauseSituation {
  const ReflectivePauseSituation({
    required this.id,
    required this.title,
    required this.categoryNumber,
    required this.category,
    required this.difficulty,
    required this.pilotValidated,
    required this.capability,
    required this.context,
    required this.trigger,
    required this.question,
    required this.medium,
    required this.responseDeadlineSec,
    required this.wordsToRead,
    required this.choices,
  });

  final String id;
  final String title;
  final int categoryNumber;
  final String category;
  final ReflectivePauseDifficulty difficulty;

  /// Fiche pilote déjà validée par le psychologue (TR-001 à TR-005).
  final bool pilotValidated;

  final String capability;

  /// Texte présenté au joueur pour poser la scène.
  final String context;

  /// Événement qui déclenche la décision.
  final String trigger;

  /// Question affichée au moment de l'arrêt — « Que fait Léa maintenant ? ».
  final String question;

  final ReflectivePauseMedium medium;

  /// Délai de réponse propre à la situation.
  ///
  /// Calculé fiche par fiche sur le nombre de mots à lire — de 13 à 20 s selon
  /// la situation. Un délai unique pour les soixante pénaliserait les fiches
  /// les plus longues à lire, et n'en mesurerait alors que la vitesse de
  /// lecture.
  final int responseDeadlineSec;

  final int wordsToRead;

  final List<ReflectivePauseChoice> choices;

  /// Les cinq choix dans un ordre mélangé, stable pour une graine donnée.
  ///
  /// **Indispensable.** Dans la banque livrée, la position encode la catégorie :
  /// A est la réponse impulsive dans les soixante situations, B « respirer »,
  /// C « attendre ». Affichée telle quelle, la grille s'apprend en deux ou
  /// trois situations et le joueur obtient un bon score sans lire la scène —
  /// l'épreuve mesurerait alors la mémoire d'une position, pas le recul.
  ///
  /// La graine dépend de la session ET de la situation : l'ordre ne change pas
  /// sous les doigts du joueur pendant qu'il lit, mais il diffère d'une
  /// situation à l'autre et d'une passation à l'autre.
  List<ReflectivePauseChoice> choicesInDisplayOrder(int seed) {
    final shuffled = List<ReflectivePauseChoice>.of(choices);
    shuffled.shuffle(math.Random(seed ^ id.hashCode));
    return shuffled;
  }

  /// Meilleure cotation possible sur cette situation.
  int get bestScore =>
      choices.map((c) => c.score).reduce((a, b) => a > b ? a : b);

  ReflectivePauseChoice byResponseType(ReflectivePauseResponseType type) =>
      choices.firstWhere((c) => c.responseType == type);

  factory ReflectivePauseSituation.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List)
        .map((c) => ReflectivePauseChoice.fromJson(c as Map<String, dynamic>))
        .toList();
    if (choices.length != 5) {
      throw ArgumentError('${json['id']} : ${choices.length} choix au lieu de 5');
    }
    return ReflectivePauseSituation(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryNumber: (json['categoryNumber'] as num).toInt(),
      category: json['category'] as String,
      difficulty: ReflectivePauseDifficulty.fromWire(json['difficulty'] as String),
      pilotValidated: json['pilotValidated'] as bool? ?? false,
      capability: json['capability'] as String,
      context: json['context'] as String,
      trigger: json['trigger'] as String,
      question: json['question'] as String,
      medium: ReflectivePauseMedium.fromWire(json['medium'] as String),
      responseDeadlineSec: (json['responseDeadlineSec'] as num).toInt(),
      wordsToRead: (json['wordsToRead'] as num).toInt(),
      choices: choices,
    );
  }
}

/// Banque complète des 60 situations du « Temps Réflexif ».
class ReflectivePauseBank {
  const ReflectivePauseBank({required this.situations});

  final List<ReflectivePauseSituation> situations;

  ReflectivePauseSituation byId(String id) =>
      situations.firstWhere((s) => s.id == id);

  List<ReflectivePauseSituation> byDifficulty(
    ReflectivePauseDifficulty difficulty,
  ) => situations.where((s) => s.difficulty == difficulty).toList();

  factory ReflectivePauseBank.fromJson(Map<String, dynamic> json) {
    return ReflectivePauseBank(
      situations: (json['situations'] as List)
          .map((s) =>
              ReflectivePauseSituation.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
