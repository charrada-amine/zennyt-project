import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recruiter_job_offer.dart';

class _Candidate {
  final String name, role, avatar, date;
  final int score;
  const _Candidate(this.name, this.role, this.avatar, this.score, this.date);
  bool get passed => score >= 60;
}

/// Résultats QCM des candidats pour une offre (mock).
class HardSkillsScoresPage extends StatelessWidget {
  final RecruiterJobOffer offer;
  const HardSkillsScoresPage({super.key, required this.offer});

  static const _candidates = [
    _Candidate('Anna Mary', 'UX/UI Designer', 'https://i.pravatar.cc/150?img=45', 92, 'January 24, 2025'),
    _Candidate('Kristin Watson', 'UX/UI Designer', 'https://i.pravatar.cc/150?img=31', 88, 'January 20, 2025'),
    _Candidate('Sophia Martin', 'Web Designer', 'https://i.pravatar.cc/150?img=20', 65, 'January 19, 2025'),
    _Candidate('Alberta Flores', 'UX/UI Designer', 'https://i.pravatar.cc/150?img=47', 58, 'January 18, 2025'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: const Text('Hard Skills Scores',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.brandBlue, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('G',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppTheme.brandBlue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('${offer.candidates} candidates · ${offer.successRate}% success',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Results of the Candidates (${offer.candidates})',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
          ),
          for (final c in _candidates) _row(context, c),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _Candidate c) {
    final color = c.score >= 85
        ? const Color(0xFF22A06B)
        : c.score >= 60
            ? const Color(0xFFE08A1E)
            : const Color(0xFFE53935);
    return InkWell(
      onTap: () => context.push('/candidate-profile'),
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(c.avatar)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  Text(c.role,
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: c.passed
                      ? const Color(0xFFE5F5EE)
                      : const Color(0xFFFCE9E9),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(c.passed ? 'Successful' : 'failed',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.passed
                          ? const Color(0xFF22A06B)
                          : const Color(0xFFE53935))),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Score QCM',
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
            const Spacer(),
            Text('${c.score}%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.score / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDEDF2),
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text('Test passed on ${c.date}',
              style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
        ],
      ),
      ),
    );
  }
}
