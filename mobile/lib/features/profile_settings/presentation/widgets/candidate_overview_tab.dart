import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';
import 'profile_modals.dart';

class CandidateOverviewTab extends ConsumerWidget {
  const CandidateOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(candidateProfileProvider);
    final colors = context.colors;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: colors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(candidateProfileProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(context, colors, 'Looking for'),
          const SizedBox(height: AppSpacing.sm),
          _buildLookingForContent(colors, state.lookingFor),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionHeader(
            context,
            colors,
            'Skills',
            onAdd: () {
              showDialog(
                context: context,
                builder: (context) => const TechnicalSkillsModal(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSkillsContent(context, colors, state.skills),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionHeader(
            context,
            colors,
            'Professional background',
            onEdit: () {
              showDialog(
                context: context,
                builder: (context) => const YearsOfExperienceModal(),
              );
            },
          ),
          _buildYearsOfExperience(colors, state.yearsOfExperience),
          const SizedBox(height: AppSpacing.lg),

          _buildSectionHeader(
            context,
            colors,
            'Job Positions',
            onAdd: () {
              showDialog(
                context: context,
                builder: (context) => const ExperienceModal(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildJobPositions(context, ref, colors, state.jobPositions),
          const SizedBox(height: AppSpacing.lg),

          _buildSectionHeader(
            context,
            colors,
            'Certifications',
            onAdd: () {
              showDialog(
                context: context,
                builder: (context) => const CertificationModal(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCertifications(context, ref, colors, state.certifications),
          const SizedBox(height: AppSpacing.lg),

          _buildSectionHeader(
            context,
            colors,
            'Education',
            onAdd: () {
              showDialog(
                context: context,
                builder: (context) => const EducationModal(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildEducation(context, ref, colors, state.education),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionHeader(
            context,
            colors,
            'About me',
            onEdit: () {
              showDialog(
                context: context,
                builder: (context) => const AboutMeModal(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAboutMeContent(context, colors, state.aboutMe),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    AppColorScheme colors,
    String title, {
    VoidCallback? onEdit,
    VoidCallback? onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: colors.textSecondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add, color: colors.textSecondary, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildLookingForContent(AppColorScheme colors, LookingFor lookingFor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoPair(
                colors,
                lookingFor.jobPosition,
                'Job position',
              ),
            ),
            Expanded(
              child: _buildInfoPair(
                colors,
                lookingFor.workplaceType,
                'Type of workplace',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildInfoPair(colors, lookingFor.jobType, 'Type of job'),
            ),
            Expanded(
              child: _buildInfoPair(
                colors,
                lookingFor.targetLocation,
                'Target job location',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoPair(AppColorScheme colors, String value, String label) {
    final isEmpty = value.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEmpty ? 'Not set' : value,
          style: AppTypography.titleSmall.copyWith(
            color: isEmpty
                ? colors.textSecondary.withValues(alpha: 0.5)
                : colors.primary,
            fontWeight: FontWeight.w600,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSkillsContent(
    BuildContext context,
    AppColorScheme colors,
    List<String> skills,
  ) {
    if (skills.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.code_rounded,
        title: 'No skills added yet',
        subtitle: 'Tap + to showcase your technical expertise',
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
          ),
          child: Text(
            skill,
            style: AppTypography.bodySmall.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearsOfExperience(AppColorScheme colors, String years) {
    final isEmpty = years.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Years of Experience',
          style: AppTypography.titleSmall.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isEmpty ? 'Not specified yet' : years,
          style: AppTypography.bodyMedium.copyWith(
            color: isEmpty
                ? colors.textSecondary.withValues(alpha: 0.5)
                : colors.textSecondary,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildJobPositions(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    List<JobPosition> jobs,
  ) {
    if (jobs.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.work_outline_rounded,
        title: 'No positions added yet',
        subtitle: 'Tap + to highlight your professional journey',
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: jobs.map((job) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors
                    .inputFill, // Using inputFill for a subtle pro look without borders
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.position,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.company,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.startYear} - ${job.endYear.isEmpty ? "Présent" : job.endYear}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCardActions(
                    context,
                    colors,
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) => ExperienceModal(jobPosition: job),
                      );
                    },
                    onDelete: () {
                      ref
                          .read(candidateProfileProvider.notifier)
                          .removeJobPosition(job.id);
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCertifications(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    List<Certification> certs,
  ) {
    if (certs.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.workspace_premium_outlined,
        title: 'No certifications yet',
        subtitle: 'Tap + to add your professional credentials',
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: certs.map((cert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert.title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cert.organization,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cert.year,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCardActions(
                    context,
                    colors,
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            CertificationModal(certification: cert),
                      );
                    },
                    onDelete: () {
                      ref
                          .read(candidateProfileProvider.notifier)
                          .removeCertification(cert.id);
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEducation(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    List<Education> edus,
  ) {
    if (edus.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.school_outlined,
        title: 'No education added yet',
        subtitle: 'Tap + to add your academic background',
      );
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: edus.map((edu) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.degree,
                          style: AppTypography.bodyMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          edu.university,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${edu.startYear} - ${edu.endYear.isEmpty ? "Présent" : edu.endYear}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCardActions(
                    context,
                    colors,
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) => EducationModal(education: edu),
                      );
                    },
                    onDelete: () {
                      ref
                          .read(candidateProfileProvider.notifier)
                          .removeEducation(edu.id);
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardActions(
    BuildContext context,
    AppColorScheme colors, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          icon: Icon(
            Icons.edit_outlined,
            color: colors.textSecondary,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            color: colors.textSecondary,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildAboutMeContent(
    BuildContext context,
    AppColorScheme colors,
    String aboutMe,
  ) {
    if (aboutMe.isEmpty) {
      return _buildEmptyState(
        colors,
        icon: Icons.person_outline_rounded,
        title: 'Tell your story',
        subtitle: 'Tap edit to introduce yourself to recruiters',
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        aboutMe,
        style: AppTypography.bodyMedium.copyWith(
          color: colors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppColorScheme colors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: colors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
