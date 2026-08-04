import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
class AssessmentPreviewSheet extends StatelessWidget {
  final Assessment assessment;
  final ValueChanged<String> onSelected;

  const AssessmentPreviewSheet({
    super.key,
    required this.assessment,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    required Assessment assessment,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AssessmentPreviewSheet(assessment: assessment, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                assessment.title,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF21438A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Assessment Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Number of Questions:', value: '${assessment.questions.length}'),
            const _DetailRow(label: 'Time per Question:', value: '2 min'),
            _DetailRow(label: 'Total Duration:', value: assessment.durationDisplay),
            const _DetailRow(
              label: 'Format:',
              value: 'Multiple choice questions (MCQ)',
            ),
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: 180,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    onSelected(assessment.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21438A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Select',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
