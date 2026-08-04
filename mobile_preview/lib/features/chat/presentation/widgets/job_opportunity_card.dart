import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_summary.dart';

/// Carte "Job Opportunity" affichée en haut de la conversation, avec
/// Confirm / Reject (style maquette).
class JobOpportunityCard extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const JobOpportunityCard({
    super.key,
    required this.chat,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E6EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Job Opportunity',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy)),
            const Spacer(),
            Text('Explore offer',
                style: const TextStyle(
                    color: AppTheme.brandBlue, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(
              'We are offering a ${chat.offerRole ?? 'position'} with a salary of '
              '${chat.offerSalary ?? ''}.',
              style: const TextStyle(color: AppTheme.navy, height: 1.4)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22A06B),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: onConfirm,
                child: const Text('Confirm offer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFD9DAE5))),
                onPressed: onReject,
                child: const Text('Reject offer',
                    style: TextStyle(color: AppTheme.navy)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
