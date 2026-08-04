import 'package:flutter/material.dart';

import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
const _kViolet = Color(0xFF5B4EF5);
const _kCardBg = Color(0xFFF7F6FF);
const _kBorderColor = Color(0xFFC7D2FE);

class AssessmentQuestionCard extends StatelessWidget {
  final int index;
  final Question question;

  const AssessmentQuestionCard({super.key, required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionIndex(index: index),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.text,
                  style: const TextStyle(color: Color(0xFF1E1E38), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...question.options.asMap().entries.map(
                (opt) => _OptionItem(
                  label: opt.value,
                  isCorrect: opt.key == question.correctOptionIndex,
                ),
              ),
        ],
      ),
    );
  }
}

class _QuestionIndex extends StatelessWidget {
  final int index;
  const _QuestionIndex({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: _kViolet, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final String label;
  final bool isCorrect;

  const _OptionItem({required this.label, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFDCFCE7) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: isCorrect ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isCorrect ? const Color(0xFF1E293B) : const Color(0xFF475569),
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
