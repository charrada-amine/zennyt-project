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
        trailingAction: GestureDetector(
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
            child: const Icon(Icons.edit_outlined, color: Color(0xFF21438A), size: 20),
          ),
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
}
