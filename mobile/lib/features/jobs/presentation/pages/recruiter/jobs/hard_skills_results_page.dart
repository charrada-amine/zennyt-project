import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/features/jobs/domain/entities/test_attempt.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

/// Résultats hard-skills d'une offre (maquette 191, recruteur propriétaire).
///
/// Agrégat serveur (`GET /job-offers/{id}/test-results/summary`) + page de
/// résultats jointe aux candidats (`GET /job-offers/{id}/test-results`).
/// Le détail par question (`.../test-results/{candidateId}`) s'ouvre au tap.
class HardSkillsResultsPage extends ConsumerWidget {
  final String jobId;
  const HardSkillsResultsPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobOfferDetailProvider(jobId));
    final summaryAsync = ref.watch(jobTestResultsSummaryProvider(jobId));
    final resultsAsync = ref.watch(jobTestResultsProvider(jobId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: CustomAppBar(title: 'Hard Skills Scores', onBack: () => context.pop()),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(jobTestResultsProvider(jobId));
          ref.invalidate(jobTestResultsSummaryProvider(jobId));
          await ref.read(jobTestResultsProvider(jobId).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            jobAsync.when(
              loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SizedBox.shrink(),
              data: (job) => _JobHeaderCard(
                title: job.title,
                subtitle: '${job.companyName.isEmpty ? job.locationDisplay : job.companyName} · ${job.locationDisplay}',
                salary: job.salaryMin > 0
                    ? '\$${(job.salaryMin / 1000).toStringAsFixed(0)}K'
                    : null,
                chips: [job.contractType.label, job.experienceLevel.label],
              ),
            ),
            const SizedBox(height: 18),
            summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => _SummaryRow(summary: s),
            ),
            const SizedBox(height: 20),
            resultsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Color(0xFFE53935)),
                    const SizedBox(height: 8),
                    const Text('Failed to load results.', style: TextStyle(color: Color(0xFF64748B))),
                    TextButton(
                      onPressed: () => ref.invalidate(jobTestResultsProvider(jobId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (page) => page.content.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No candidate has taken this assessment yet.',
                          style: TextStyle(color: Color(0xFF8A90A2)),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Results of the Candidates (${page.totalElements})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                        ),
                        const SizedBox(height: 12),
                        ...page.content.map(
                          (r) => _ResultTile(
                            item: r,
                            onTap: () => _showDetail(context, ref, jobId, r.candidate.id),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref, String jobId, String candidateId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CandidateDetailSheet(jobId: jobId, candidateId: candidateId),
    );
  }
}

class _JobHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? salary;
  final List<String> chips;
  const _JobHeaderCard({
    required this.title,
    required this.subtitle,
    required this.salary,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
              ),
              if (salary != null)
                Text(salary!,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final TestResultsSummary summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(value: '${summary.candidateCount}', label: 'Candidates'),
        const SizedBox(width: 12),
        _SummaryCard(value: '${summary.passedCount}', label: 'Passed'),
        const SizedBox(width: 12),
        _SummaryCard(value: '${summary.successRate}%', label: 'Success rate'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6ECF7)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF11428D))),
            Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final TestResultListItem item;
  final VoidCallback onTap;
  const _ResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final passed = item.passed;
    final color = passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6ECF7)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _Avatar(url: item.candidate.avatarUrl, name: item.candidate.fullName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.candidate.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(
                        item.completedAt != null
                            ? item.completedAt!.toLocal().toString().split(' ').first
                            : item.status.label,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    passed ? 'Passed' : 'Failed',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: item.percentage / 100,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${item.percentage}%',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateDetailSheet extends ConsumerWidget {
  final String jobId;
  final String candidateId;
  const _CandidateDetailSheet({required this.jobId, required this.candidateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(jobTestResultDetailProvider((jobOfferId: jobId, candidateId: candidateId)));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scroll) => async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Failed to load the correction.')),
        data: (detail) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Avatar(url: detail.candidate.avatarUrl, name: detail.candidate.fullName),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(detail.candidate.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
                ),
                Text('${detail.percentage}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: detail.passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            ...detail.answerBreakdown.asMap().entries.map((e) {
              final a = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: a.isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Q${e.key + 1}. ',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                        Expanded(
                          child: Text(a.questionText,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                        ),
                        Icon(
                          a.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 18,
                          color: a.isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!a.isCorrect)
                      Text('Selected: ${a.selectedAnswer}',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFFEF4444))),
                    Text('Correct: ${a.correctAnswer}',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF16A34A))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  const _Avatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFEEF2FF),
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF11428D)))
          : null,
    );
  }
}
