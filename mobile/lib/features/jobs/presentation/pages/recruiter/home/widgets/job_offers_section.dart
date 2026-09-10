import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
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
                  child: const Icon(
                    Icons.add_circle_outline,
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
          child: CircularProgressIndicator(color: Color(0xFF5046E5)),
        ),
      );
    }

    if (jobsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 20, color: Color(0xFFE53935)),
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

  String _salaryShort() {
    final v = job.salaryMin >= 1000
        ? '${(job.salaryMin / 1000).toStringAsFixed(0)}K'
        : job.salaryMin.toInt().toString();
    return '\$$v/${job.currency.contains('Mo') ? 'Mo' : 'Yr'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 24, right: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Center(
                    child: Text(
                      job.companyName.isNotEmpty
                          ? job.companyName[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        fontSize: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${job.companyName} • ${job.city}, ${job.country}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _salaryShort(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  _timeAgo(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                _TagChip(label: job.fieldOfWork),
                const SizedBox(width: 6),
                _TagChip(label: job.contractType.label),
              ],
            ),
            // F16/F19/F29 (FITSCORE_REMEDIATION.md §3): the backend already
            // computes/contracts hardSkillsAlert but no client read it before —
            // a recruiter saw a bare offer card with no signal at all, whether
            // this senior technical role was missing a QCM or was a creative
            // role correctly evaluated by portfolio.
            if (job.hardSkillsAlert != HardSkillsAlertLevel.none) ...[
              const SizedBox(height: 10),
              _HardSkillsAlertBanner(level: job.hardSkillsAlert),
            ],
          ],
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
  IconData get _icon =>
      level == HardSkillsAlertLevel.portfolioBased ? Icons.palette_outlined : Icons.info_outline;

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
          Icon(_icon, size: 14, color: _color),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
