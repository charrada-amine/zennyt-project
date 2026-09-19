import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'widgets/assessment_question_card.dart';
import 'widgets/assessment_shareable_link_card.dart';
import 'widgets/assessment_stats_card.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_dialog.dart';

class AssessmentDetailPage extends ConsumerWidget {
  final String assessmentId;
  const AssessmentDetailPage({super.key, required this.assessmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssessment = ref.watch(assessmentDetailProvider(assessmentId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: asyncAssessment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load this test.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(assessmentDetailProvider(assessmentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (assessment) => _AssessmentDetailBody(assessment: assessment, assessmentId: assessmentId),
      ),
    );
  }
}

class _AssessmentDetailBody extends ConsumerWidget {
  final Assessment assessment;
  final String assessmentId;

  const _AssessmentDetailBody({required this.assessment, required this.assessmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Assessment',
        onBack: () => context.pop(),
        trailingAction: Row(
          children: [
            GestureDetector(
              onTap: () => _confirmDelete(context, ref),
              child: Container(
                width: 40,
                height: 40,
                decoration: kAppBarButtonDecoration(),
                child: const AppIcon(HugeIcons.strokeRoundedDelete02, color: Color(0xFFE53935), size: 20),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await context.pushNamed(
                  AppRoutes.nEditAssessment,
                  pathParameters: {'assessmentId': assessment.id},
                  extra: assessment,
                );
                ref.invalidate(assessmentDetailProvider(assessmentId));
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: kAppBarButtonDecoration(),
                child: const AppIcon(HugeIcons.strokeRoundedPencilEdit01, color: Color(0xFF21438A), size: 20),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            AssessmentStatsCard(
              assessment: assessment,
              labelQuestions: 'Questions',
              labelDuration: 'Duration',
              labelMax: 'Max',
            ),
            const SizedBox(height: 24),
            if (assessment.shareableLink != null) ...[
              AssessmentShareableLinkCard(assessment: assessment),
              const SizedBox(height: 24),
            ],
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Questions (${assessment.questions.length})',
                style: const TextStyle(color: Color(0xFF1E1E38), fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ...assessment.questions.asMap().entries.map(
                  (e) => AssessmentQuestionCard(index: e.key, question: e.value),
                ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete this test?',
      message: 'This removes the assessment from your tests. It cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(assessmentsProvider.notifier).deleteAssessment(assessment.id);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete this test.')),
        );
      }
    }
  }
}
