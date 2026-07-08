/// Type d'une ligne du détail du score. Aligné sur ScoreBreakdownLine.kind
/// du contrat games.openapi.yaml.
enum ScoreBreakdownKind { note, info, criterion, subtotal, total }

/// Une ligne du DÉTAIL du score (panneau « d'où viennent mes points »).
///
/// Calculée côté serveur (ou mock) à partir des mêmes métriques et du même
/// barème que le score — le client ne fait que l'afficher.
class ScoreBreakdownLine {
  const ScoreBreakdownLine({
    required this.kind,
    required this.label,
    this.detail,
    this.points,
    this.maxPoints,
  });

  final ScoreBreakdownKind kind;
  final String label;
  final String? detail;
  final int? points;
  final int? maxPoints;

  factory ScoreBreakdownLine.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdownLine(
      kind: _kindFromWire(json['kind'] as String?),
      label: (json['label'] as String?) ?? '',
      detail: json['detail'] as String?,
      points: (json['points'] as num?)?.toInt(),
      maxPoints: (json['maxPoints'] as num?)?.toInt(),
    );
  }

  static ScoreBreakdownKind _kindFromWire(String? wire) {
    switch (wire) {
      case 'NOTE':
        return ScoreBreakdownKind.note;
      case 'INFO':
        return ScoreBreakdownKind.info;
      case 'CRITERION':
        return ScoreBreakdownKind.criterion;
      case 'SUBTOTAL':
        return ScoreBreakdownKind.subtotal;
      case 'TOTAL':
        return ScoreBreakdownKind.total;
      default:
        return ScoreBreakdownKind.info;
    }
  }
}
