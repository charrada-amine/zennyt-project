import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/upload/file_picking.dart';
import '../../../../core/upload/upload_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/full_screen_loader.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../viewmodel/recruiter_profile_viewmodel.dart';
import '../widgets/profile_avatar.dart';

class RecruiterEditProfileScreen extends ConsumerStatefulWidget {
  const RecruiterEditProfileScreen({super.key});

  @override
  ConsumerState<RecruiterEditProfileScreen> createState() =>
      _RecruiterEditProfileScreenState();
}

class _RecruiterEditProfileScreenState extends ConsumerState<RecruiterEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _companySizeCtrl;
  late final TextEditingController _fieldOfWorkCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _einCtrl;
  late final TextEditingController _aboutMeCtrl;
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _missionCtrl;
  late final TextEditingController _visionCtrl;
  late final TextEditingController _keyDiffCtrl;
  late final TextEditingController _cultureCtrl;
  late final TextEditingController _whyJoinCtrl;

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(recruiterProfileProvider).value;
    _jobTitleCtrl = TextEditingController(text: profile?.jobTitle ?? '');
    _companyNameCtrl = TextEditingController(text: profile?.companyName ?? '');
    _companySizeCtrl = TextEditingController(text: profile?.companySize ?? '');
    _fieldOfWorkCtrl = TextEditingController(text: profile?.fieldOfWork ?? '');
    _locationCtrl = TextEditingController(text: profile?.companyLocation ?? '');
    _einCtrl = TextEditingController(text: profile?.companyRegistrationNumber ?? '');
    _aboutMeCtrl = TextEditingController(text: profile?.aboutMe ?? '');
    _aboutCtrl = TextEditingController(text: profile?.about ?? '');
    _missionCtrl = TextEditingController(text: profile?.mission ?? '');
    _visionCtrl = TextEditingController(text: profile?.vision ?? '');
    _keyDiffCtrl = TextEditingController(text: profile?.keyDifferentiators ?? '');
    _cultureCtrl = TextEditingController(text: profile?.cultureWorkEnvironment ?? '');
    _whyJoinCtrl = TextEditingController(text: profile?.whyJoinUs ?? '');
  }

  @override
  void dispose() {
    _jobTitleCtrl.dispose();
    _companyNameCtrl.dispose();
    _companySizeCtrl.dispose();
    _fieldOfWorkCtrl.dispose();
    _locationCtrl.dispose();
    _einCtrl.dispose();
    _aboutMeCtrl.dispose();
    _aboutCtrl.dispose();
    _missionCtrl.dispose();
    _visionCtrl.dispose();
    _keyDiffCtrl.dispose();
    _cultureCtrl.dispose();
    _whyJoinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(recruiterProfileProvider.notifier).updateProfile(
            jobTitle: _jobTitleCtrl.text,
            companyName: _companyNameCtrl.text,
            companySize: _companySizeCtrl.text,
            fieldOfWork: _fieldOfWorkCtrl.text,
            companyLocation: _locationCtrl.text,
            companyRegistrationNumber: _einCtrl.text,
            aboutMe: _aboutMeCtrl.text,
            about: _aboutCtrl.text,
            mission: _missionCtrl.text,
            vision: _visionCtrl.text,
            keyDifferentiators: _keyDiffCtrl.text,
            cultureWorkEnvironment: _cultureCtrl.text,
            whyJoinUs: _whyJoinCtrl.text,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorGeneric),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Avatar upload (reuses the same endpoint as PersonalInformationsScreen) ──
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final filePicker = ref.read(filePickingProvider);
      final pickedFile = await filePicker.pickImage(
        fromCamera: source == ImageSource.camera,
      );

      if (pickedFile == null || pickedFile.bytes == null) return;

      setState(() => _isUploadingAvatar = true);
      final repo = ref.read(authRepositoryProvider);
      await repo.uploadAvatar(pickedFile.bytes!, pickedFile.name);

      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.avatarUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorGeneric),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── Company logo upload ──
  Future<void> _pickAndUploadCompanyLogo(ImageSource source) async {
    try {
      final filePicker = ref.read(filePickingProvider);
      final pickedFile = await filePicker.pickImage(
        fromCamera: source == ImageSource.camera,
      );

      if (pickedFile == null || pickedFile.bytes == null) return;

      setState(() => _isUploadingLogo = true);
      final upload = ref.read(uploadServiceProvider);
      final logoUrl = await upload.upload(pickedFile, kind: UploadKind.companyLogo);

      if (logoUrl != null) {
        // Update the recruiter profile with the new logo URL
        final profile = ref.read(recruiterProfileProvider).value;
        if (profile != null) {
          await ref.read(recruiterProfileProvider.notifier).updateProfile(
                jobTitle: profile.jobTitle,
                companyName: profile.companyName,
                companySize: profile.companySize,
                fieldOfWork: profile.fieldOfWork,
                companyLocation: profile.companyLocation,
                companyRegistrationNumber: profile.companyRegistrationNumber,
                companyLogoUrl: logoUrl,
                aboutMe: profile.aboutMe,
                about: profile.about,
                mission: profile.mission,
                vision: profile.vision,
                keyDifferentiators: profile.keyDifferentiators,
                cultureWorkEnvironment: profile.cultureWorkEnvironment,
                whyJoinUs: profile.whyJoinUs,
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company logo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorGeneric),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  void _showImagePickerSheet({required bool isLogo}) {
    final l10n = context.l10n;
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.choosePhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                isLogo
                    ? _pickAndUploadCompanyLogo(ImageSource.gallery)
                    : _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                isLogo
                    ? _pickAndUploadCompanyLogo(ImageSource.camera)
                    : _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            if (!isLogo)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: colors.error),
                title: Text(l10n.removePhoto, style: TextStyle(color: colors.error)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  setState(() => _isUploadingAvatar = true);
                  try {
                    final repo = ref.read(authRepositoryProvider);
                    await repo.deleteAvatar();
                    await ref.read(authControllerProvider.notifier).refreshUser();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.avatarRemoved)),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.errorGeneric),
                          backgroundColor: colors.error,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isUploadingAvatar = false);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);
    final user = ref.watch(authControllerProvider).value;
    final recruiterProfile = ref.watch(recruiterProfileProvider).value;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
            _buildTopBar(context, colors),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hPadding,
                  vertical: AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Avatar + Company Logo ──
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // User avatar
                            GestureDetector(
                              onTap: () => _showImagePickerSheet(isLogo: false),
                              child: Stack(
                                children: [
                                  ProfileAvatar(
                                    imageUrl: user?.profileImageUrl,
                                    size: 80,
                                    fallbackSeed: user?.email,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: colors.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.scaffoldBg,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Company logo
                            GestureDetector(
                              onTap: () => _showImagePickerSheet(isLogo: true),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.inputFill,
                                      border: Border.all(
                                        color: colors.border,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: recruiterProfile?.companyLogoUrl != null &&
                                            recruiterProfile!.companyLogoUrl!.isNotEmpty
                                        ? Image.network(
                                            recruiterProfile.companyLogoUrl!,
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.business_rounded,
                                              size: 28,
                                              color: colors.textSecondary,
                                            ),
                                          )
                                        : Icon(
                                            Icons.business_rounded,
                                            size: 28,
                                            color: colors.textSecondary,
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.scaffoldBg,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Profile photo & Company logo',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Recruiter Information — fieldOfWork belongs to recruiter ──
                      Text('Recruiter Information',
                          style: AppTypography.titleMedium.copyWith(
                              color: colors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _jobTitleCtrl,
                        label: 'Job title',
                        hintText: 'e.g., HR Manager',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _fieldOfWorkCtrl,
                        label: 'Field of work',
                        hintText: 'e.g., IT / Software',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _aboutMeCtrl,
                        label: 'About me',
                        hintText: 'Write a short bio...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // ── Company Information ──
                      Text('Company Information',
                          style: AppTypography.titleMedium.copyWith(
                              color: colors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _companyNameCtrl,
                        label: 'Company name',
                        hintText: 'e.g., Acme Corp',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _companySizeCtrl,
                        label: 'Company size',
                        hintText: 'e.g., 50-200 employees',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _locationCtrl,
                        label: 'Company location',
                        hintText: 'e.g., New York, NY',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _einCtrl,
                        label: 'Company Registration Number (EIN)',
                        hintText: 'e.g., 12-3456789',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _aboutCtrl,
                        label: 'About — Who we are?',
                        hintText: 'Describe your company...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _missionCtrl,
                        label: 'Mission',
                        hintText: 'Company mission...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _visionCtrl,
                        label: 'Vision',
                        hintText: 'Company vision...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _keyDiffCtrl,
                        label: 'What makes us different?',
                        hintText: 'Key differentiators...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _cultureCtrl,
                        label: 'Culture & work environment',
                        hintText: 'Describe culture...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _whyJoinCtrl,
                        label: 'Why join us?',
                        hintText: 'Why candidates should join...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(
                        label: 'Save changes',
                        loading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
        if (_isLoading || _isUploadingAvatar || _isUploadingLogo)
          const FullScreenLoader(),
      ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppColorScheme colors) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: colors.divider,
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Edit profile',
            style: AppTypography.titleLarge.copyWith(
              color: colors.textDarkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleSmall.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: AppTypography.bodyLarge.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                AppTypography.bodyLarge.copyWith(color: colors.textSecondary),
            filled: true,
            fillColor: colors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
