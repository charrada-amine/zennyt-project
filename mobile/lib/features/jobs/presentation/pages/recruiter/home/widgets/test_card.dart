import 'package:flutter/material.dart';

import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
class TestCard extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TestCard({
    super.key,
    required this.assessment,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 106,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF5046E5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.white, size: 26),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                assessment.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
