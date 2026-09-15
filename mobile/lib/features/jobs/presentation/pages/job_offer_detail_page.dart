import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/enums/user_role.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

/// Détail d'une offre d'emploi, partagé candidat / recruteur — remplace le
/// placeholder `_NotYetPortedPage` (`AppRoutes.jobDetail`, REC-04 non porté).
///
/// • Candidat (maquettes 92-95) : header entreprise, onglets Description /
///   Company, sections de l'offre, puis « Start assessment » si un test hard
///   skills est attaché (contrat `POST /job-offers/{id}/test-attempts`).
/// • Recruteur (maquettes 190/192) : mêmes onglets + stats candidats/réussite,
///   édition et accès aux résultats (`/jobs/:id/results`).
class JobOfferDetailPage extends ConsumerWidget {
  final String jobId;
  const JobOfferDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(jobOfferDetailProvider(jobId));
    final isRecruiter = ref.watch(currentUserProvider)?.role == UserRole.recruiter;

    return Scaffold(
      backgroundColor: Colors.white,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: 'Failed to load this job offer.',
          onRetry: () => ref.invalidate(jobOfferDetailProvider(jobId)),
        ),
        data: (job) => _JobOfferDetailBody(job: job, isRecruiter: isRecruiter),
      ),
    );
  }
}

class _JobOfferDetailBody extends ConsumerStatefulWidget {
  final JobOffer job;
  final bool isRecruiter;
  const _JobOfferDetailBody({required this.job, required this.isRecruiter});

  @override
  ConsumerState<_JobOfferDetailBody> createState() => _JobOfferDetailBodyState();
}

class _JobOfferDetailBodyState extends ConsumerState<_JobOfferDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _consent = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  JobOffer get job => widget.job;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(
          title: widget.isRecruiter ? 'Job Offer' : 'Job Detail',
          onBack: () => context.pop(),
          trailingAction: widget.isRecruiter
              ? Row(
                  children: [
                    _IconButton(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Results',
                      onTap: () => context.pushNamed(
                        AppRoutes.nJobResults,
                        pathParameters: {'jobId': job.id},
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onTap: () async {
                        await context.pushNamed(
                          AppRoutes.nEditJob,
                          pathParameters: {'jobId': job.id},
                          extra: job,
                        );
                        ref.invalidate(jobOfferDetailProvider(job.id));
                      },
                    ),
                  ],
                )
              : null,
        ),
        _HeaderCard(job: job, isRecruiter: widget.isRecruiter),
        _TabBar(controller: _tabs),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _DescriptionTab(job: job),
              _CompanyTab(job: job),
            ],
          ),
        ),
        if (!widget.isRecruiter) _CandidateFooter(job: job, consent: _consent, onConsent: (v) => setState(() => _consent = v)),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final JobOffer job;
  final bool isRecruiter;
  const _HeaderCard({required this.job, required this.isRecruiter});

  String get _initial {
    final source = job.companyName.isNotEmpty ? job.companyName : job.title;
    return source.isEmpty ? 'J' : source[0].toUpperCase();
  }

  String get _salary => job.salaryDisplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE6ECF7)),
                ),
                child: Center(
                  child: Text(
                    _initial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.companyName.isEmpty ? job.locationDisplay : '${job.companyName} · ${job.locationDisplay}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (_salary.isNotEmpty)
                Text(
                  _salary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: job.contractType.label),
              _Chip(label: job.workplaceType.label),
              _Chip(label: job.experienceLevel.label),
              if (job.openToInternational) const _Chip(label: 'International'),
            ],
          ),
          if (isRecruiter) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(value: '${job.applicantCount}', label: 'Applicants'),
                const SizedBox(width: 28),
                _Stat(
                  value: job.successRate == null ? '—' : '${job.successRate}%',
                  label: 'Success rate',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: const Color(0xFF11428D),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [Tab(text: 'Description'), Tab(text: 'Company')],
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  final JobOffer job;
  const _DescriptionTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final sections = <(String, String)>[
      ('About the job', job.description),
      ('Responsibilities', job.responsibilities),
      ('Minimum Qualifications', job.minimumQualifications),
      ('Preferred Qualifications', job.preferredQualifications),
      ('What We Offer', job.whatWeOffer),
      ('How to Apply', job.howToApply),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        for (final (title, body) in sections)
          if (body.trim().isNotEmpty) _Section(title: title, body: body),
      ],
    );
  }
}

class _CompanyTab extends StatelessWidget {
  final JobOffer job;
  const _CompanyTab({required this.job});

  @override
  Widget build(BuildContext context) {
    final body = job.companyInfo.trim().isNotEmpty
        ? job.companyInfo
        : 'No company information provided yet.';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        _Section(title: job.companyName.isEmpty ? 'Company' : job.companyName, body: body),
        const SizedBox(height: 8),
        _Section(title: 'Location', body: job.locationDisplay),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

class _CandidateFooter extends ConsumerWidget {
  final JobOffer job;
  final bool consent;
  final ValueChanged<bool> onConsent;
  const _CandidateFooter({required this.job, required this.consent, required this.onConsent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job.assessmentId == null) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(myTestResultProvider(job.id));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: async.when(
        loading: () => const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ),
        error: (_, _) => _startButton(context, ref, enabled: consent),
        data: (result) {
          if (result != null) {
            return _ResultBanner(
              passed: result.passed,
              percentage: result.percentage,
              status: result.status.label,
              onView: () => context.pushNamed(
                AppRoutes.jobTest,
                pathParameters: {'jobId': job.id},
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: consent,
                    activeColor: const Color(0xFF11428D),
                    onChanged: (v) => onConsent(v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I consent to take the hard-skills assessment for this role.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _startButton(context, ref, enabled: consent),
            ],
          );
        },
      ),
    );
  }

  Widget _startButton(BuildContext context, WidgetRef ref, {required bool enabled}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled
            ? () async {
                await context.pushNamed(
                  AppRoutes.jobTest,
                  pathParameters: {'jobId': job.id},
                );
                ref.invalidate(myTestResultProvider(job.id));
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF11428D),
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'Start assessment',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool passed;
  final int percentage;
  final String status;
  final VoidCallback onView;
  const _ResultBanner({
    required this.passed,
    required this.percentage,
    required this.status,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'Assessment passed' : 'Assessment not passed',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14),
                ),
                Text('Score $percentage% · $status',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          TextButton(onPressed: onView, child: const Text('View')),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: kAppBarButtonDecoration(),
          child: Icon(icon, color: const Color(0xFF21438A), size: 20),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFE53935), size: 32),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
