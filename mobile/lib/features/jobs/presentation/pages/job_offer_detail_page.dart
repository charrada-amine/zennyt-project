import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/enums/user_role.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/auth/presentation/current_user_provider.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

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
                      icon: HugeIcons.strokeRoundedChartHistogram,
                      tooltip: 'Results',
                      onTap: () => context.pushNamed(
                        AppRoutes.nJobResults,
                        pathParameters: {'jobId': job.id},
                      ),
                    ),
                    const SizedBox(width: 8),
                    _IconButton(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
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
        // L'en-tête défile avec le contenu et les onglets restent épinglés : sur
        // un petit écran ou en grand texte, l'ancienne colonne figée écrasait la
        // description à quelques pixels.
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: _HeaderCard(job: job, isRecruiter: widget.isRecruiter),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedTabBar(controller: _tabs),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _DescriptionTab(
                  job: job,
                  leading: !widget.isRecruiter && job.assessmentId != null
                      ? _AssessmentCard(
                          job: job,
                          consent: _consent,
                          onConsent: (v) => setState(() => _consent = v),
                        )
                      : null,
                ),
                _CompanyTab(job: job),
              ],
            ),
          ),
        ),
        if (!widget.isRecruiter) _ApplyBar(job: job),
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    if (_salary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _salary,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ],
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

/// Onglets épinglés sous l'en-tête pendant le défilement.
class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  _PinnedTabBar({required this.controller});

  final TabController controller;

  static const double _height = 60;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _TabBar(controller: controller),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedTabBar oldDelegate) => oldDelegate.controller != controller;
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

  /// Carte affichée avant les sections (test hard skills du candidat).
  final Widget? leading;
  const _DescriptionTab({required this.job, this.leading});

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (leading != null) ...[leading!, const SizedBox(height: 20)],
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

/// Test hard skills attaché à l'offre : consentement, lancement, ou résultat.
class _AssessmentCard extends ConsumerWidget {
  final JobOffer job;
  final bool consent;
  final ValueChanged<bool> onConsent;
  const _AssessmentCard({required this.job, required this.consent, required this.onConsent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myTestResultProvider(job.id));

    return Container(
      key: const ValueKey('job-assessment-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF7)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  AppIcon(HugeIcons.strokeRoundedQuiz01, color: Color(0xFF11428D), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hard-skills test',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'This role includes a short test. You get a single attempt.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
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

/// Barre « Apply » du candidat, collée en bas de l'écran.
///
/// Postuler = swipe RIGHT sur l'offre (comme dans le deck Fits) : le recruteur
/// voit la candidature, et un match s'ouvre s'il avait déjà montré son intérêt.
class _ApplyBar extends ConsumerStatefulWidget {
  final JobOffer job;
  const _ApplyBar({required this.job});

  @override
  ConsumerState<_ApplyBar> createState() => _ApplyBarState();
}

class _ApplyBarState extends ConsumerState<_ApplyBar> {
  late MyApplication _status = widget.job.myApplication ?? MyApplication.none;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _ApplyBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fresh = widget.job.myApplication;
    if (fresh != null && fresh != oldWidget.job.myApplication) _status = fresh;
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final status = await ref.read(jobsRepositoryProvider).applyToJobOffer(
            widget.job.id,
            reconsider: _status == MyApplication.passed,
          );
      if (!mounted) return;
      setState(() => _status = status);
      messenger.showSnackBar(SnackBar(
        content: Text(status == MyApplication.matched
            ? "It's a match! ${widget.job.companyName.isEmpty ? 'The recruiter' : widget.job.companyName} is interested too."
            : 'Application sent. The recruiter will review your profile.'),
      ));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not send your application. Please try again.'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (_status) {
      MyApplication.applied => const _ApplicationStatus(
          key: ValueKey('job-apply-status-applied'),
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          color: Color(0xFF16A34A),
          title: 'Application sent',
          subtitle: "Waiting for the recruiter's answer.",
        ),
      MyApplication.matched => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ApplicationStatus(
              key: ValueKey('job-apply-status-matched'),
              icon: HugeIcons.strokeRoundedAgreement01,
              color: Color(0xFFD12E7D),
              title: "It's a match!",
              subtitle: 'The recruiter is interested in your profile too.',
            ),
            const SizedBox(height: 12),
            _BarButton(
              key: const ValueKey('job-open-chat'),
              label: 'Open chat',
              icon: HugeIcons.strokeRoundedMessage01,
              color: const Color(0xFFD12E7D),
              onPressed: () => context.push(AppRoutes.chats),
            ),
          ],
        ),
      MyApplication.passed => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ApplicationStatus(
              icon: HugeIcons.strokeRoundedCancelCircle,
              color: Color(0xFF64748B),
              title: 'You passed on this offer',
              subtitle: 'Changed your mind? You can still apply.',
            ),
            const SizedBox(height: 12),
            _BarButton(
              key: const ValueKey('job-apply'),
              label: 'Apply anyway',
              icon: HugeIcons.strokeRoundedSent,
              busy: _busy,
              onPressed: _apply,
            ),
          ],
        ),
      MyApplication.none => _BarButton(
          key: const ValueKey('job-apply'),
          label: 'Apply',
          icon: HugeIcons.strokeRoundedSent,
          busy: _busy,
          onPressed: _apply,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11428D).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_status), child: content),
          ),
        ),
      ),
    );
  }
}

class _ApplicationStatus extends StatelessWidget {
  final AppIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ApplicationStatus({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(child: AppIcon(icon, color: color, size: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final String label;
  final AppIconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool busy;
  const _BarButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFF11428D),
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ],
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
          AppIcon(passed ? HugeIcons.strokeRoundedCheckmarkCircle02 : HugeIcons.strokeRoundedCancelCircle, color: color),
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
  final AppIconData icon;
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
          child: AppIcon(icon, color: const Color(0xFF21438A), size: 20),
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
          const AppIcon(HugeIcons.strokeRoundedCloudSlowWind, color: Color(0xFFE53935), size: 32),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
