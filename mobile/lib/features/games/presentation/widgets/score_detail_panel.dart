import 'package:flutter/material.dart';

import '../../domain/entities/score_breakdown.dart';
import 'game_system_components.dart';

/// Panneau « détail du score » — affiche, comme des logs, d'où viennent les
/// points. Le contenu vient tel quel du backend/mock (mêmes métriques, même
/// barème) ; ce widget ne fait que le mettre en forme, ligne par ligne.
class ScoreDetailPanel extends StatelessWidget {
  const ScoreDetailPanel({super.key, required this.lines});

  final List<ScoreBreakdownLine> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // fond « console »
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ZennytGamePalette.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détail du score',
            style: TextStyle(
              color: Color(0xFF7DD3FC),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          for (final line in lines) _LineRow(line: line),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final ScoreBreakdownLine line;

  static const _mono = 'monospace';

  @override
  Widget build(BuildContext context) {
    switch (line.kind) {
      case ScoreBreakdownKind.note:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '# ${line.label}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: _mono,
              fontStyle: FontStyle.italic,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        );
      case ScoreBreakdownKind.info:
        return _row(
          left: line.detail == null ? line.label : '${line.label} : ${line.detail}',
          right: '',
          color: const Color(0xFFCBD5E1),
        );
      case ScoreBreakdownKind.criterion:
        final left = line.detail == null
            ? line.label
            : '${line.label} (${line.detail})';
        return _row(
          left: left,
          right: _pts(),
          color: const Color(0xFFE2E8F0),
        );
      case ScoreBreakdownKind.subtotal:
        return Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: _row(left: '= ${line.label}', right: _pts(), color: const Color(0xFFFACC15), bold: true),
        );
      case ScoreBreakdownKind.total:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: _row(left: line.label, right: _pts(), color: const Color(0xFF4ADE80), bold: true),
          ),
        );
    }
  }

  String _pts() {
    if (line.points == null) return '';
    return line.maxPoints == null ? '${line.points}' : '${line.points}/${line.maxPoints}';
  }

  Widget _row({
    required String left,
    required String right,
    required Color color,
    bool bold = false,
  }) {
    final style = TextStyle(
      color: color,
      fontFamily: _mono,
      fontSize: 12.5,
      height: 1.35,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(left, style: style)),
          if (right.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(right, style: style),
          ],
        ],
      ),
    );
  }
}
