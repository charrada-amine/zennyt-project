import 'decision_metrics.dart';

/// Format d'un item « Je Décide » — miroir de `DecisionItemFormat` du contrat.
///
/// Détermine la règle de notation SERVEUR ; le client ne s'en sert que pour
/// l'affichage (chronomètre sur `temporalDecision`, appariement sur
/// `coherencePair`).
enum DecisionItemFormat {
  standard('STANDARD'),
  temporalDecision('TEMPORAL_DECISION'),
  coherencePair('COHERENCE_PAIR');

  final String wire;
  const DecisionItemFormat(this.wire);

  static DecisionItemFormat fromWire(String value) =>
      DecisionItemFormat.values.firstWhere((f) => f.wire == value);
}

/// Une option proposée. **Ne porte ni qualité, ni score** : la correction reste
/// serveur, le client n'envoie que l'`optionId` choisi.
class DecisionFormOption {
  const DecisionFormOption({required this.optionId, required this.label});

  final String optionId;
  final String label;

  factory DecisionFormOption.fromJson(Map<String, dynamic> json) =>
      DecisionFormOption(
        optionId: json['optionId'] as String,
        label: json['label'] as String,
      );
}

/// Un item prêt à afficher, servi par
/// `GET /games/sessions/{id}/decision/items`.
class DecisionFormItem {
  const DecisionFormItem({
    required this.itemId,
    required this.dimension,
    required this.format,
    required this.vignette,
    required this.task,
    required this.options,
    this.pairId,
    this.timeLimitMs,
  });

  final String itemId;
  final DecisionDimension dimension;
  final DecisionItemFormat format;

  /// Situation à lire. Déjà résolue serveur : les items chronométrés réutilisent
  /// la vignette de leur homologue non chronométré.
  final String vignette;
  final String task;
  final List<DecisionFormOption> options;

  /// Identifiant de paire (`CS-1` pour `CS-1a` et `CS-1b`), sinon `null`.
  final String? pairId;

  /// Temps imparti — présent uniquement sur `temporalDecision`.
  final int? timeLimitMs;

  bool get isTimed => format == DecisionItemFormat.temporalDecision;

  factory DecisionFormItem.fromJson(Map<String, dynamic> json) =>
      DecisionFormItem(
        itemId: json['itemId'] as String,
        dimension: DecisionDimension.fromWire(json['dimension'] as String),
        format: DecisionItemFormat.fromWire(json['format'] as String),
        vignette: json['vignette'] as String,
        task: json['task'] as String,
        pairId: json['pairId'] as String?,
        timeLimitMs: (json['timeLimitMs'] as num?)?.toInt(),
        options: (json['options'] as List<dynamic>)
            .map((o) => DecisionFormOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

/// Forme de passation assignée à une session : 30 items, 6 par dimension.
///
/// La forme est tirée SERVEUR à la création de la session. [formCode] est
/// informatif — la notation relit toujours la forme portée par la session, donc
/// le renvoyer ne permet pas d'en changer.
class DecisionForm {
  const DecisionForm({
    required this.formCode,
    required this.itemsPerDimension,
    required this.items,
  });

  final String formCode;
  final int itemsPerDimension;
  final List<DecisionFormItem> items;

  int get totalItems => items.length;

  factory DecisionForm.fromJson(Map<String, dynamic> json) => DecisionForm(
    formCode: json['formCode'] as String,
    itemsPerDimension: json['itemsPerDimension'] as int,
    items: (json['items'] as List<dynamic>)
        .map((i) => DecisionFormItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}
