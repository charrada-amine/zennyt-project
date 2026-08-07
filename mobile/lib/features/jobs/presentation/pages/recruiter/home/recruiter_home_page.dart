import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/job_offers_section.dart';
import 'widgets/tests_section.dart';

/// Le hub opérationnel du recruteur — porté depuis REC-04
/// (mobile/zennyt/features/jobs), branché sur le backend intégré : ses tests
/// (assessments) et ses offres d'emploi, chacun avec un "+" de création.
class RecruiterHomePage extends ConsumerWidget {
  const RecruiterHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobOffersProvider);
    final assessmentsAsync = ref.watch(assessmentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HomeAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(jobOffersProvider.notifier).refresh();
          await ref.read(assessmentsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TestsSection(assessmentsAsync: assessmentsAsync),
            ),
            SliverToBoxAdapter(
              child: Container(height: 6, color: const Color(0xFFF1F5F9)),
            ),
            SliverToBoxAdapter(
              child: JobOffersSection(jobsAsync: jobsAsync),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
