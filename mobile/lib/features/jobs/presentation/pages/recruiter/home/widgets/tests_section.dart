import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'add_test_card.dart';
import 'share_bottom_sheet.dart';
import 'test_card.dart';

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Your Tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1B4B),
              ),
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
                Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFE53935)),
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

    return SizedBox(
      height: 110,
      child: assessmentsAsync.isLoading
          ? const Center(
              child: CircularProgressIndicator(
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
