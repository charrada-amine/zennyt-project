import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileModalBase extends StatelessWidget {
  const ProfileModalBase({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.onCancel,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.scaffoldBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Save',
                    onPressed: () {
                      onSave();
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Cancel',
                    outlined: true,
                    onPressed: () {
                      if (onCancel != null) onCancel!();
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExperienceModal extends ConsumerStatefulWidget {
  const ExperienceModal({super.key, this.jobPosition});

  final JobPosition? jobPosition;

  @override
  ConsumerState<ExperienceModal> createState() => _ExperienceModalState();
}

class _ExperienceModalState extends ConsumerState<ExperienceModal> {
  late TextEditingController _positionController;
  late TextEditingController _companyController;
  late TextEditingController _startYearController;
  late TextEditingController _endYearController;

  @override
  void initState() {
    super.initState();
    _positionController = TextEditingController(text: widget.jobPosition?.position ?? '');
    _companyController = TextEditingController(text: widget.jobPosition?.company ?? '');
    _startYearController = TextEditingController(text: widget.jobPosition?.startYear ?? '');
    _endYearController = TextEditingController(text: widget.jobPosition?.endYear ?? '');
  }

  @override
  void dispose() {
    _positionController.dispose();
    _companyController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalBase(
      title: widget.jobPosition == null ? 'Add experience' : 'Edit the job position',
      onSave: () {
        final newJob = JobPosition(
          id: widget.jobPosition?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          position: _positionController.text,
          company: _companyController.text,
          startYear: _startYearController.text,
          endYear: _endYearController.text,
        );
        final viewModel = ref.read(candidateProfileProvider.notifier);
        if (widget.jobPosition == null) {
          viewModel.addJobPosition(newJob);
        } else {
          viewModel.updateJobPosition(newJob);
        }
      },
      children: [
        AppTextField(
          label: 'Position',
          hint: 'Add a position',
          controller: _positionController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Company',
          hint: 'Add a company',
          controller: _companyController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Start year',
          hint: 'Add year',
          controller: _startYearController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'End year',
          hint: 'Add year (empty = present)',
          controller: _endYearController,
        ),
      ],
    );
  }
}

class CertificationModal extends ConsumerStatefulWidget {
  const CertificationModal({super.key, this.certification});

  final Certification? certification;

  @override
  ConsumerState<CertificationModal> createState() => _CertificationModalState();
}

class _CertificationModalState extends ConsumerState<CertificationModal> {
  late TextEditingController _typeController;
  late TextEditingController _orgController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.certification?.title ?? '');
    _orgController = TextEditingController(text: widget.certification?.organization ?? '');
    _yearController = TextEditingController(text: widget.certification?.year ?? '');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _orgController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalBase(
      title: widget.certification == null ? 'Add certification' : 'Edit certification',
      onSave: () {
        final newCert = Certification(
          id: widget.certification?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: _typeController.text,
          organization: _orgController.text,
          year: _yearController.text,
        );
        final viewModel = ref.read(candidateProfileProvider.notifier);
        if (widget.certification == null) {
          viewModel.addCertification(newCert);
        } else {
          viewModel.updateCertification(newCert);
        }
      },
      children: [
        AppTextField(
          label: 'Certification type',
          hint: 'Add a certification',
          controller: _typeController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Organization',
          hint: 'Add an organization',
          controller: _orgController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Year',
          hint: 'Add year',
          controller: _yearController,
        ),
      ],
    );
  }
}

class EducationModal extends ConsumerStatefulWidget {
  const EducationModal({super.key, this.education});

  final Education? education;

  @override
  ConsumerState<EducationModal> createState() => _EducationModalState();
}

class _EducationModalState extends ConsumerState<EducationModal> {
  late TextEditingController _degreeController;
  late TextEditingController _schoolController;
  late TextEditingController _startYearController;
  late TextEditingController _endYearController;

  @override
  void initState() {
    super.initState();
    _degreeController = TextEditingController(text: widget.education?.degree ?? '');
    _schoolController = TextEditingController(text: widget.education?.university ?? '');
    _startYearController = TextEditingController(text: widget.education?.startYear ?? '');
    _endYearController = TextEditingController(text: widget.education?.endYear ?? '');
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _schoolController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalBase(
      title: widget.education == null ? 'Add education' : 'Edit education',
      onSave: () {
        final newEdu = Education(
          id: widget.education?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          degree: _degreeController.text,
          university: _schoolController.text,
          startYear: _startYearController.text,
          endYear: _endYearController.text,
        );
        final viewModel = ref.read(candidateProfileProvider.notifier);
        if (widget.education == null) {
          viewModel.addEducation(newEdu);
        } else {
          viewModel.updateEducation(newEdu);
        }
      },
      children: [
        AppTextField(
          label: 'Degree',
          hint: 'Add a degree',
          controller: _degreeController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'School / university',
          hint: 'Add school / university',
          controller: _schoolController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Start year',
          hint: 'Add year',
          controller: _startYearController,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'End year',
          hint: 'Add year (empty = present)',
          controller: _endYearController,
        ),
      ],
    );
  }
}

class TechnicalSkillsModal extends ConsumerStatefulWidget {
  const TechnicalSkillsModal({super.key});

  @override
  ConsumerState<TechnicalSkillsModal> createState() => _TechnicalSkillsModalState();
}

class _TechnicalSkillsModalState extends ConsumerState<TechnicalSkillsModal> {
  late TextEditingController _skillController;
  late List<String> _skills;

  @override
  void initState() {
    super.initState();
    _skillController = TextEditingController();
    // Copy the current skills from the provider
    _skills = List.from(ref.read(candidateProfileProvider).skills);
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ProfileModalBase(
      title: 'Technical skills',
      onSave: () {
        ref.read(candidateProfileProvider.notifier).updateSkills(_skills);
      },
      children: [
        AppTextField(
          label: 'Add a skill',
          hint: 'React, TypeScript, etc.',
          controller: _skillController,
          onSubmitted: (_) => _addSkill(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSkill,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Skills',
          style: AppTypography.titleSmall.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _skills.map((skill) {
            return Chip(
              label: Text(skill, style: AppTypography.bodySmall.copyWith(color: colors.textPrimary)),
              backgroundColor: colors.border.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide.none,
              deleteIcon: Icon(Icons.close, size: 14, color: colors.textSecondary),
              onDeleted: () => _removeSkill(skill),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class YearsOfExperienceModal extends ConsumerStatefulWidget {
  const YearsOfExperienceModal({super.key});

  @override
  ConsumerState<YearsOfExperienceModal> createState() => _YearsOfExperienceModalState();
}

class _YearsOfExperienceModalState extends ConsumerState<YearsOfExperienceModal> {
  late TextEditingController _yearsController;

  @override
  void initState() {
    super.initState();
    _yearsController = TextEditingController(text: ref.read(candidateProfileProvider).yearsOfExperience);
  }

  @override
  void dispose() {
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileModalBase(
      title: 'Professional background',
      onSave: () {
        ref.read(candidateProfileProvider.notifier).updateYearsOfExperience(_yearsController.text);
      },
      children: [
        AppTextField(
          label: 'Years of Experience',
          hint: 'e.g., 2 years',
          controller: _yearsController,
        ),
      ],
    );
  }
}

class AboutMeModal extends ConsumerStatefulWidget {
  const AboutMeModal({super.key});

  @override
  ConsumerState<AboutMeModal> createState() => _AboutMeModalState();
}

class _AboutMeModalState extends ConsumerState<AboutMeModal> {
  late TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    _aboutController = TextEditingController(
      text: ref.read(candidateProfileProvider).aboutMe,
    );
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ProfileModalBase(
      title: 'About me',
      onSave: () {
        ref
            .read(candidateProfileProvider.notifier)
            .saveAboutMe(_aboutController.text.trim());
      },
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: _aboutController,
            maxLines: 6,
            minLines: 4,
            maxLength: 500,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Tell recruiters about yourself — your strengths, passions, and what makes you unique…',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: colors.textSecondary.withValues(alpha: 0.6),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              counterStyle: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
