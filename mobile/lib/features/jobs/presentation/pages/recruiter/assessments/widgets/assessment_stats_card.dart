import 'package:flutter/material.dart';

import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
const _kViolet = Color(0xFF5B4EF5);
const _kStatCardColor = Color(0x26FFFFFF);

class AssessmentStatsCard extends StatelessWidget {
  final Assessment assessment;
  final String labelQuestions;
  final String labelDuration;
  final String labelMax;

  const AssessmentStatsCard({
    super.key,
    required this.assessment,
    required this.labelQuestions,
    required this.labelDuration,
    required this.labelMax,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _kViolet, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assessment.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.quiz_outlined,
                  label: labelQuestions,
                  value: '${assessment.questions.length}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.timer_outlined,
                  label: labelDuration,
                  value: assessment.durationDisplay,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.list_alt_outlined,
                  label: labelMax,
                  value: '${assessment.maxQuestions}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: _kStatCardColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
