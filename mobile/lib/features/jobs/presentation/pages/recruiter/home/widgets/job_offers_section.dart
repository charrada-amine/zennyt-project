import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_spinner.dart';

class JobOffersSection extends StatelessWidget {
  final AsyncValue<List<JobOffer>> jobsAsync;
  const JobOffersSection({super.key, required this.jobsAsync});

  @override
  Widget build(BuildContext context) {
    final jobs = jobsAsync.value ?? [];

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Job Offers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pushNamed(AppRoutes.nCreateJob),
                  child: const AppIcon(
                    HugeIcons.strokeRoundedAddCircle,
                    color: Color(0xFF21438A),
                  ),
                ),
              ],
            ),
          ),
          _JobListBody(jobsAsync: jobsAsync, jobs: jobs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _JobListBody extends StatelessWidget {
  final AsyncValue<List<JobOffer>> jobsAsync;
  final List<JobOffer> jobs;

  const _JobListBody({required this.jobsAsync, required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: AppSpinner(color: Color(0xFF5046E5)),
        ),
      );
    }

    if (jobsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(HugeIcons.strokeRoundedCloudSlowWind, size: 20, color: Color(0xFFE53935)),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Failed to load job offers.',
                style: TextStyle(color: Color(0xFFE53935), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (jobs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Text(
            'No job offers yet',
            style: TextStyle(color: Color(0xFF8A90A2), fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: jobs.length,
      itemBuilder: (context, i) => _JobOfferCard(
        job: jobs[i],
        onTap: () => context.pushNamed(
          AppRoutes.nJobDetail,
          pathParameters: {'jobId': jobs[i].id},
        ),
      ),
    );
  }
}

class _JobOfferCard extends StatelessWidget {
  final JobOffer job;
  final VoidCallback onTap;
  const _JobOfferCard({required this.job, required this.onTap});

  String _timeAgo() {
    final diff = DateTime.now().difference(job.postedAt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final location = [job.city, job.country].where((p) => p.trim().isNotEmpty).join(', ');
    final subtitle = [job.companyName, location].where((p) => p.trim().isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 24, right: 24),
      child: Material(
        color: colors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          (job.companyName.isNotEmpty ? job.companyName : job.title)[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                            ),
                          ],
                          // Fourchette complète (l'ancienne carte n'affichait que le minimum).
                          if (job.salaryDisplay.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              job.salaryDisplay,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
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
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TagChip(label: job.workplaceType.label),
                    _TagChip(label: job.contractType.label),
                    if (job.fieldOfWork.trim().isNotEmpty) _TagChip(label: job.fieldOfWork),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppIcon(HugeIcons.strokeRoundedUserMultiple, size: 15, color: colors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      job.applicantCount == 1 ? '1 applicant' : '${job.applicantCount} applicants',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(),
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
                // F16/F19/F29 (FITSCORE_REMEDIATION.md §3) : signal « QCM manquant ».
                if (job.hardSkillsAlert != HardSkillsAlertLevel.none) ...[
                  const SizedBox(height: 10),
                  _HardSkillsAlertBanner(level: job.hardSkillsAlert),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HardSkillsAlertBanner extends StatelessWidget {
  final HardSkillsAlertLevel level;
  const _HardSkillsAlertBanner({required this.level});

  /// F19 (FITSCORE_REMEDIATION.md §3 index F19) — PORTFOLIO_BASED reads as
  /// reassurance (F29, CdC §10 #8: "soft-only is a standard mode, not
  /// degraded"), never as an alarm; the other levels nudge the recruiter to
  /// attach a QCM, in increasing urgency.
  String get _message {
    switch (level) {
      case HardSkillsAlertLevel.portfolioBased:
        return 'Evaluated by portfolio — standard for this role, not missing data';
      case HardSkillsAlertLevel.strong:
        return 'No hard-skills test attached — strongly recommended for this role';
      case HardSkillsAlertLevel.moderate:
        return 'No hard-skills test attached — consider adding one';
      case HardSkillsAlertLevel.info:
      case HardSkillsAlertLevel.none:
        return 'No hard-skills test attached yet';
    }
  }

  Color get _color =>
      level == HardSkillsAlertLevel.portfolioBased ? const Color(0xFF0F766E) : const Color(0xFFB45309);
  Color get _background =>
      level == HardSkillsAlertLevel.portfolioBased ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
  AppIconData get _icon =>
      level == HardSkillsAlertLevel.portfolioBased ? HugeIcons.strokeRoundedPaintBoard : HugeIcons.strokeRoundedInformationCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _message,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
