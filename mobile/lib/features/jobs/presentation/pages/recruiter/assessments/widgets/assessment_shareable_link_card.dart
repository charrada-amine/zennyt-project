import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
const _kViolet = Color(0xFF5B4EF5);
const _kCardBg = Color(0xFFF7F6FF);
const _kBorderColor = Color(0xFFC7D2FE);

class AssessmentShareableLinkCard extends StatelessWidget {
  final Assessment assessment;

  const AssessmentShareableLinkCard({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: _kViolet, size: 18),
              SizedBox(width: 8),
              Text(
                'Shareable link',
                style: TextStyle(color: Color(0xFF1E1E38), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              assessment.shareableLink!,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kViolet),
              minimumSize: const Size(0, 40),
            ),
            icon: const Icon(Icons.copy, color: _kViolet, size: 16),
            label: const Text('Copy link', style: TextStyle(color: _kViolet)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: assessment.shareableLink!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied!'), backgroundColor: Color(0xFF2AC052)),
              );
            },
          ),
        ],
      ),
    );
  }
}
