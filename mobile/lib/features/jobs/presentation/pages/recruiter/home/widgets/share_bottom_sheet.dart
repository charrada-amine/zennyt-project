import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
class ShareAssessmentBottomSheet extends StatelessWidget {
  final Assessment assessment;

  const ShareAssessmentBottomSheet({super.key, required this.assessment});

  static void show(BuildContext context, Assessment assessment) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => ShareAssessmentBottomSheet(assessment: assessment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shareLink = assessment.shareableLink ?? 'https://www.zennyt.com/tests/';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              assessment.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Share this test with candidates via the link below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _CopyLinkButton(
              link: shareLink,
              onCopied: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied!'),
                    backgroundColor: Color(0xFFD12E7D),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyLinkButton extends StatelessWidget {
  final String link;
  final VoidCallback onCopied;
  const _CopyLinkButton({required this.link, required this.onCopied});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: link));
        onCopied();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD12E7D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          link,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
