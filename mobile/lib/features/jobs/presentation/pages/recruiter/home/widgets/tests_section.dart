import 'package:flutter/material.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'add_test_card.dart';
import 'share_bottom_sheet.dart';
import 'test_card.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_spinner.dart';

class TestsSection extends StatelessWidget {
  final AsyncValue<List<Assessment>> assessmentsAsync;
  const TestsSection({super.key, required this.assessmentsAsync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Tests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pushNamed(AppRoutes.nManageTests),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF21438A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TestsBody(assessmentsAsync: assessmentsAsync),
        ],
      ),
    );
  }
}

class _TestsBody extends StatelessWidget {
  final AsyncValue<List<Assessment>> assessmentsAsync;
  const _TestsBody({required this.assessmentsAsync});

  @override
  Widget build(BuildContext context) {
    if (assessmentsAsync.hasError) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(HugeIcons.strokeRoundedCloudSlowWind, size: 18, color: Color(0xFFE53935)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Failed to load tests.',
                    style: TextStyle(color: Color(0xFFE53935), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final assessments = assessmentsAsync.value ?? [];

    // Aucun test : une vraie invitation plutôt qu'une tuile « + » isolée.
    if (!assessmentsAsync.isLoading && assessments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: _NoTestsCard(),
      );
    }

    return SizedBox(
      height: 110,
      child: assessmentsAsync.isLoading
          ? const Center(
              child: AppSpinner(
                color: Color(0xFF21438A),
                strokeWidth: 2.5,
              ),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                AddTestCard(
                  onTap: () => context.pushNamed(AppRoutes.nCreateAssessment),
                ),
                const SizedBox(width: 12),
                ...assessments.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TestCard(
                      assessment: a,
                      onTap: () => context.pushNamed(
                        AppRoutes.nAssessmentDetail,
                        pathParameters: {'assessmentId': a.id},
                      ),
                      onLongPress: () =>
                          ShareAssessmentBottomSheet.show(context, a),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NoTestsCard extends StatelessWidget {
  const _NoTestsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        key: const ValueKey('tests-empty-create'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.pushNamed(AppRoutes.nCreateAssessment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD12E7D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: AppIcon(
                    HugeIcons.strokeRoundedQuiz01,
                    color: Color(0xFFD12E7D),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create your first hard-skills test',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Attach it to an offer to score candidates on the technical side too.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFD12E7D),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppIcon(HugeIcons.strokeRoundedAdd01, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
