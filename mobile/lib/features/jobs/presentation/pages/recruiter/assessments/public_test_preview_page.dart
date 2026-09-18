import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/features/jobs/domain/entities/public_assessment.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

/// Recruiter preview of the public projection of a shared test
/// (`GET /tests/{token}`) — exactly what a candidate opening the shareable link
/// sees, with no correct answers. Design references 216 (preview) and 306
/// (question screen).
class PublicTestPreviewPage extends ConsumerWidget {
  final String token;
  const PublicTestPreviewPage({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(publicTestProvider(token));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Test preview', onBack: () => context.pop()),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link_off_rounded, color: Color(0xFFE53935), size: 34),
                const SizedBox(height: 12),
                const Text(
                  'This test link is invalid or no longer available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(publicTestProvider(token)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (test) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6ECF7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Meta(icon: Icons.list_alt_rounded, label: '${test.questionCount} questions'),
                      const SizedBox(width: 18),
                      _Meta(
                        icon: Icons.timer_outlined,
                        label: '${(test.timeLimitSeconds / 60).ceil()} min',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...test.questions.map((q) => _QuestionCard(question: q)),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final PublicAssessmentQuestion question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final options = question.options;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${question.order}. ${question.text}',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(options[i], style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
