import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/cv_autofill_providers.dart';
import '../widgets/cv_section_card.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../presentation/viewmodel/candidate_profile_viewmodel.dart';
import '../../domain/cv_parsed_data.dart';
import '../../../../../shared/widgets/zennyt_loader.dart';
import '../../../../../core/localization/l10n_extension.dart';
import '../../../../../core/theme/theme.dart';

class CvReviewScreen extends ConsumerStatefulWidget {
  const CvReviewScreen({super.key});

  @override
  ConsumerState<CvReviewScreen> createState() => _CvReviewScreenState();
}

class _CvReviewScreenState extends ConsumerState<CvReviewScreen> {
  CvParsedData? _editedData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(cvAutofillViewModelProvider);
      if (state.data != null) {
        setState(() {
          _editedData = state.data;
        });
      }
    });
  }

  InputDecoration _fieldDecoration(String label, {IconData? prefixIcon}) {
    final colors = context.colors;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: colors.textMuted)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: colors.cardSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  Future<void> _handleSave() async {
    if (_editedData == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(candidateProfileProvider.notifier).saveParsedCvData(_editedData!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(context.l10n.cvReviewSaveSuccess)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(cvAutofillViewModelProvider.notifier).reset();
        context.go(AppRoutes.profileSettings);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(context.l10n.cvReviewSaveFailed(e.toString()))),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cvAutofillViewModelProvider);
    final data = _editedData ?? state.data;
    if (data == null) {
      return Scaffold(
        body: Center(child: ZennytLoader()),
      );
    }

    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            _buildTopBar(colors),
            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAiBanner(colors).animate().fade(duration: 400.ms).slideY(begin: -0.05),
                    const SizedBox(height: 20),
                    _buildBasicInfoSection(data, colors).animate().fade(delay: 100.ms).slideY(begin: 0.05),
                    const SizedBox(height: 16),
                    if (data.skills.isNotEmpty) ...[
                      _buildSkillsSection(data, colors).animate().fade(delay: 200.ms).slideY(begin: 0.05),
                      const SizedBox(height: 16),
                    ],
                    if (data.positions.isNotEmpty) ...[
                      _buildExperienceSection(data, colors).animate().fade(delay: 300.ms).slideY(begin: 0.05),
                      const SizedBox(height: 16),
                    ],
                    if (data.education.isNotEmpty) ...[
                      _buildEducationSection(data, colors).animate().fade(delay: 400.ms).slideY(begin: 0.05),
                      const SizedBox(height: 16),
                    ],
                    if (data.certifications.isNotEmpty) ...[
                      _buildCertificationsSection(data, colors).animate().fade(delay: 500.ms).slideY(begin: 0.05),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    _buildSaveButton(colors).animate().fade(delay: 600.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.backButtonIcon),
            style: IconButton.styleFrom(
              backgroundColor: colors.backButtonBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.backButtonBorder),
              ),
              fixedSize: const Size(40, 40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.cvReviewTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAiBanner(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.cvReviewBannerText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BASIC INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBasicInfoSection(CvParsedData data, AppColorScheme colors) {
    return CvSectionCard(
      title: context.l10n.cvReviewBasicInfo,
      icon: Icons.person_outline,
      iconColor: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: data.currentPosition,
            decoration: _fieldDecoration(
              context.l10n.cvReviewCurrentPositionHint,
              prefixIcon: Icons.work_outline,
            ),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
            onChanged: (val) => _editedData = _editedData!.copyWith(currentPosition: val),
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: data.yearsOfExperience?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              context.l10n.cvReviewExperienceYearsHint,
              prefixIcon: Icons.timeline,
            ),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
            onChanged: (val) => _editedData = _editedData!.copyWith(yearsOfExperience: int.tryParse(val)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: data.aboutMe,
            maxLines: 3,
            decoration: _fieldDecoration(
              context.l10n.cvReviewAboutMeHint,
              prefixIcon: Icons.notes,
            ),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
            onChanged: (val) => _editedData = _editedData!.copyWith(aboutMe: val),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SKILLS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSkillsSection(CvParsedData data, AppColorScheme colors) {
    return CvSectionCard(
      title: context.l10n.cvReviewSkills,
      icon: Icons.lightbulb_outline,
      iconColor: AppColors.secondary,
      itemCount: data.skills.length,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: data.skills.map((s) => Chip(
          label: Text(
            s.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: colors.primary,
            ),
          ),
          backgroundColor: colors.primary.withValues(alpha: 0.06),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          deleteIcon: Icon(Icons.close, size: 16, color: colors.primary.withValues(alpha: 0.5)),
          onDeleted: () {
            setState(() {
              final newSkills = List<CvParsedSkill>.from(data.skills)..remove(s);
              _editedData = _editedData!.copyWith(skills: newSkills);
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPERIENCE SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildExperienceSection(CvParsedData data, AppColorScheme colors) {
    return CvSectionCard(
      title: context.l10n.cvReviewExperience,
      icon: Icons.work_outline,
      iconColor: AppColors.success,
      itemCount: data.positions.length,
      child: Column(
        children: data.positions.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return _buildTimelineItem(
            accentColor: AppColors.success,
            isLast: i == data.positions.length - 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: p.title,
                  decoration: _fieldDecoration(context.l10n.cvReviewJobTitle),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary),
                  onChanged: (val) {
                    final newPos = List<CvParsedPosition>.from(data.positions);
                    newPos[i] = p.copyWith(title: val);
                    _editedData = _editedData!.copyWith(positions: newPos);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: p.companyName,
                  decoration: _fieldDecoration(context.l10n.cvReviewCompanyName, prefixIcon: Icons.business),
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  onChanged: (val) {
                    final newPos = List<CvParsedPosition>.from(data.positions);
                    newPos[i] = p.copyWith(companyName: val);
                    _editedData = _editedData!.copyWith(positions: newPos);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: p.startDate,
                        decoration: _fieldDecoration(context.l10n.cvReviewStartDate, prefixIcon: Icons.calendar_today),
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        onChanged: (val) {
                          final newPos = List<CvParsedPosition>.from(data.positions);
                          newPos[i] = p.copyWith(startDate: val);
                          _editedData = _editedData!.copyWith(positions: newPos);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: p.current ? context.l10n.cvReviewPresent : p.endDate,
                        decoration: _fieldDecoration(context.l10n.cvReviewEndDate, prefixIcon: Icons.event),
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        onChanged: (val) {
                          final newPos = List<CvParsedPosition>.from(data.positions);
                          newPos[i] = p.copyWith(
                            endDate: val.toLowerCase() == context.l10n.cvReviewPresent.toLowerCase() ? null : val,
                            current: val.toLowerCase() == context.l10n.cvReviewPresent.toLowerCase(),
                          );
                          _editedData = _editedData!.copyWith(positions: newPos);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDUCATION SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEducationSection(CvParsedData data, AppColorScheme colors) {
    return CvSectionCard(
      title: context.l10n.cvReviewEducation,
      icon: Icons.school_outlined,
      iconColor: AppColors.info,
      itemCount: data.education.length,
      child: Column(
        children: data.education.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return _buildTimelineItem(
            accentColor: AppColors.info,
            isLast: i == data.education.length - 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: e.degree,
                  decoration: _fieldDecoration(context.l10n.cvReviewDegree),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary),
                  onChanged: (val) {
                    final newEdu = List<CvParsedEducation>.from(data.education);
                    newEdu[i] = e.copyWith(degree: val);
                    _editedData = _editedData!.copyWith(education: newEdu);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: e.school,
                  decoration: _fieldDecoration(context.l10n.cvReviewSchool, prefixIcon: Icons.account_balance),
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  onChanged: (val) {
                    final newEdu = List<CvParsedEducation>.from(data.education);
                    newEdu[i] = e.copyWith(school: val);
                    _editedData = _editedData!.copyWith(education: newEdu);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: e.startDate,
                        decoration: _fieldDecoration(context.l10n.cvReviewStartYear, prefixIcon: Icons.calendar_today),
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        onChanged: (val) {
                          final newEdu = List<CvParsedEducation>.from(data.education);
                          newEdu[i] = e.copyWith(startDate: val);
                          _editedData = _editedData!.copyWith(education: newEdu);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: e.endDate,
                        decoration: _fieldDecoration(context.l10n.cvReviewEndYear, prefixIcon: Icons.event),
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        onChanged: (val) {
                          final newEdu = List<CvParsedEducation>.from(data.education);
                          newEdu[i] = e.copyWith(endDate: val);
                          _editedData = _editedData!.copyWith(education: newEdu);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CERTIFICATIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCertificationsSection(CvParsedData data, AppColorScheme colors) {
    return CvSectionCard(
      title: context.l10n.cvReviewCertifications,
      icon: Icons.verified_outlined,
      iconColor: AppColors.warning,
      itemCount: data.certifications.length,
      child: Column(
        children: data.certifications.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return _buildTimelineItem(
            accentColor: AppColors.warning,
            isLast: i == data.certifications.length - 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: c.title,
                  decoration: _fieldDecoration(context.l10n.cvReviewCertificationTitle),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary),
                  onChanged: (val) {
                    final newCerts = List<CvParsedCertification>.from(data.certifications);
                    newCerts[i] = c.copyWith(title: val);
                    _editedData = _editedData!.copyWith(certifications: newCerts);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: c.issuer,
                  decoration: _fieldDecoration(context.l10n.cvReviewIssuer, prefixIcon: Icons.corporate_fare),
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  onChanged: (val) {
                    final newCerts = List<CvParsedCertification>.from(data.certifications);
                    newCerts[i] = c.copyWith(issuer: val);
                    _editedData = _editedData!.copyWith(certifications: newCerts);
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMELINE ITEM (reusable for experience, education, certifications)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimelineItem({
    required Color accentColor,
    required bool isLast,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline bar
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Form fields
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSaveButton(AppColorScheme colors) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: _isSaving ? null : _handleSave,
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.cvReviewSaving,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.cvReviewSaveBtn,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
