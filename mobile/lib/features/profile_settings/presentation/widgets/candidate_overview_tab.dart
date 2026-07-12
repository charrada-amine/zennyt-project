import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_selector/file_selector.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/upload/cv_file_validation.dart';
import '../view/cv_viewer_screen.dart';
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
          _buildAboutMeContent(context, colors, state.aboutMe),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionHeader(context, colors, 'My CV'),
          const SizedBox(height: AppSpacing.sm),
          _buildMyCvSection(context, ref, colors, state.cvUrl),
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

  Widget _buildMyCvSection(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
    String? cvUrl,
  ) {
    final hasCv = cvUrl != null && cvUrl.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCv ? colors.primary.withValues(alpha: 0.2) : colors.border,
        ),
        color: colors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header with gradient ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasCv
                    ? [
                        colors.primary.withValues(alpha: 0.08),
                        colors.primary.withValues(alpha: 0.03),
                      ]
                    : [colors.inputFill, colors.cardSurface],
              ),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasCv
                        ? colors.success.withValues(alpha: 0.12)
                        : colors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasCv ? Icons.description_rounded : Icons.note_add_rounded,
                    color: hasCv ? colors.success : colors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCv ? 'CV Ready' : 'Upload Your CV',
                        style: AppTypography.bodyLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCv
                            ? 'Visible to recruiters on your profile'
                            : 'PDF, DOC or DOCX • Max 5 MB',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                if (hasCv)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: colors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                if (hasCv) ...[
                  // View CV button
                  Expanded(
                    child: _CvActionButton(
                      icon: Icons.open_in_new_rounded,
                      label: 'View CV',
                      colors: colors,
                      isPrimary: false,
                      onTap: () => _onViewCv(context, colors, cvUrl),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // Upload / Replace CV button
                Expanded(
                  child: _CvActionButton(
                    icon: hasCv
                        ? Icons.swap_horiz_rounded
                        : Icons.cloud_upload_rounded,
                    label: hasCv ? 'Replace' : 'Upload CV',
                    colors: colors,
                    isPrimary: true,
                    onTap: () => _onUploadCv(context, ref, colors),
                  ),
                ),
                if (hasCv) ...[
                  const SizedBox(width: AppSpacing.sm),
                  // Delete CV button
                  _CvActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: '',
                    colors: colors,
                    isPrimary: false,
                    isDestructive: true,
                    isIconOnly: true,
                    onTap: () => _onDeleteCv(context, ref, colors),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onViewCv(BuildContext context, AppColorScheme colors, String cvUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CvViewerScreen(cvUrl: cvUrl)),
    );
  }

  void _onUploadCv(
    BuildContext context,
    WidgetRef ref,
    AppColorScheme colors,
  ) async {
    try {
      const XTypeGroup cvGroup = XTypeGroup(
        label: 'CV Documents',
        extensions: <String>['pdf', 'doc', 'docx'],
        mimeTypes: <String>[
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ],
      );
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[cvGroup],
      );

      if (file != null && context.mounted) {
        await CvFileValidation.validateUploadPath(file.path);
        if (!context.mounted) return;
        // Show loading indicator
        _showSnackBar(
          context,
          colors,
          icon: Icons.cloud_upload_rounded,
          message: 'Uploading your CV...',
          isError: false,
          duration: const Duration(seconds: 10),
        );

        await ref.read(candidateProfileProvider.notifier).uploadCv(file.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showSnackBar(
            context,
            colors,
            icon: Icons.check_circle_rounded,
            message: 'CV uploaded successfully!',
            isError: false,
          );
        }
      }
    } on CvFileValidationException catch (validationError) {
      if (context.mounted) {
        _showSnackBar(
          context,
          colors,
          icon: Icons.warning_amber_rounded,
          message: validationError.message,
          isError: true,
        );
      }
    } on ApiException catch (apiErr) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar(
          context,
          colors,
          icon: Icons.error_outline_rounded,
          message: apiErr.message,
          isError: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar(
          context,
          colors,
          icon: Icons.warning_amber_rounded,
          message: 'Upload failed. Please check your connection and try again.',
          isError: true,
        );
      }
    }
  }

  void _onDeleteCv(BuildContext context, WidgetRef ref, AppColorScheme colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete CV?'),
        content: const Text(
          'Your CV will be removed from your profile. Recruiters will no longer be able to view it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(candidateProfileProvider.notifier).deleteCv();
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    colors,
                    icon: Icons.check_circle_rounded,
                    message: 'CV deleted.',
                    isError: false,
                  );
                }
              } on ApiException catch (apiErr) {
                if (context.mounted) {
                  _showSnackBar(
                    context,
                    colors,
                    icon: Icons.error_outline_rounded,
                    message: apiErr.message,
                    isError: true,
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    AppColorScheme colors, {
    required IconData icon,
    required String message,
    required bool isError,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? colors.error : colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        duration: duration,
      ),
    );
  }
}

/// Premium action button used within the CV section.
class _CvActionButton extends StatelessWidget {
  const _CvActionButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.isPrimary,
    required this.onTap,
    this.isDestructive = false,
    this.isIconOnly = false,
  });

  final IconData icon;
  final String label;
  final AppColorScheme colors;
  final bool isPrimary;
  final bool isDestructive;
  final bool isIconOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    if (isDestructive) {
      bgColor = colors.error.withValues(alpha: 0.08);
      fgColor = colors.error;
      borderColor = colors.error.withValues(alpha: 0.25);
    } else if (isPrimary) {
      bgColor = colors.primary;
      fgColor = colors.onPrimary;
      borderColor = colors.primary;
    } else {
      bgColor = Colors.transparent;
      fgColor = colors.primary;
      borderColor = colors.primary.withValues(alpha: 0.3);
    }

    if (isIconOnly) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: fgColor, size: 20),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fgColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
