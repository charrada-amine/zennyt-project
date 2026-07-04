import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/avatar/avatar_service.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/upload/file_picking.dart';
import '../../../../core/upload/picked_file.dart';
import '../../../../core/upload/upload_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/signup/viewmodel/signup_viewmodel.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/role_tabs.dart';
import '../../../../core/theme/theme.dart';
import '../viewmodel/profile_setup_viewmodel.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  /// One controller per backend field; persists across role switches.
  final Map<ProfileField, TextEditingController> _controllers = {
    for (final f in ProfileField.values) f: TextEditingController(),
  };

  late String _avatarUrl;
  PickedFile? _avatarImage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final email = ref.read(signupViewModelProvider).email;
    _avatarUrl = ref.read(avatarServiceProvider).defaultFor(email);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _value(ProfileField field) {
    final text = _controllers[field]?.text.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<void> _pickAvatar() async {
    final picking = ref.read(filePickingProvider);
    final choice = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: context.colors.cardSurface,
      builder: (_) => const _AvatarActionSheet(),
    );
    if (choice == null) return;
    switch (choice) {
      case _AvatarAction.camera:
        final file = await picking.pickImage(fromCamera: true);
        if (file != null) setState(() => _avatarImage = file);
      case _AvatarAction.gallery:
        final file = await picking.pickImage();
        if (file != null) setState(() => _avatarImage = file);
      case _AvatarAction.shuffle:
        setState(() {
          _avatarImage = null;
          _avatarUrl = ref.read(avatarServiceProvider).random();
        });
    }
  }

  Future<void> _pickCv() async {
    final file = await ref.read(filePickingProvider).pickPdf();
    if (file != null) {
      ref.read(profileSetupViewModelProvider.notifier).setCvFile(file);
    }
  }

  Future<void> _pickCompanyLogo() async {
    final file = await ref.read(filePickingProvider).pickImageDocument();
    if (file != null) {
      ref.read(profileSetupViewModelProvider.notifier).setCompanyLogoFile(file);
    }
  }

  String? _validate(ProfileSetupState setup) {
    if (setup.role == UserRole.recruiter) {
      final missing =
          _value(ProfileField.jobTitle) == null ||
          _value(ProfileField.companyName) == null ||
          _value(ProfileField.companySize) == null ||
          _value(ProfileField.companyLocation) == null ||
          _value(ProfileField.companyRegistrationNumber) == null ||
          (setup.fieldOfWork == null || setup.fieldOfWork!.isEmpty);
      if (missing) return AppStrings.fillRequiredFields;
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final signup = ref.read(signupViewModelProvider);
    final setup = ref.read(profileSetupViewModelProvider);

    final validationError = _validate(setup);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _submitting = true);
    final upload = ref.read(uploadServiceProvider);

    // Resolve avatar: a personal photo (uploaded once a backend exists) falls
    // back to the generated avatar URL, which persists today.
    String? avatarUrl = _avatarUrl;
    if (_avatarImage != null) {
      final uploaded = await upload.upload(
        _avatarImage!,
        kind: UploadKind.avatar,
      );
      avatarUrl = uploaded ?? _avatarUrl;
    }

    String? cvUrl;
    if (setup.cvFile != null) {
      cvUrl = await upload.upload(setup.cvFile!, kind: UploadKind.cv);
    }
    String? logoUrl;
    if (setup.companyLogoFile != null) {
      logoUrl = await upload.upload(
        setup.companyLogoFile!,
        kind: UploadKind.companyLogo,
      );
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeSignUp(
            firstName: signup.firstName,
            lastName: signup.lastName,
            email: signup.email,
            password: signup.password,
            role: setup.role,
            termsAccepted: signup.termsAccepted,
            phoneNumber: signup.phone,
            city: signup.city,
            country: signup.country,
            profileImageUrl: avatarUrl,
            school: _value(ProfileField.school),
            educationLevel: _value(ProfileField.educationLevel),
            fieldOfWork: setup.fieldOfWork,
            lastPositionHeld: _value(ProfileField.lastPositionHeld),
            cvFileUrl: cvUrl,
            jobTitle: _value(ProfileField.jobTitle),
            companyName: _value(ProfileField.companyName),
            companySize: _value(ProfileField.companySize),
            companyLocation: _value(ProfileField.companyLocation),
            companyRegistrationNumber: _value(
              ProfileField.companyRegistrationNumber,
            ),
            companyLogoUrl: logoUrl,
          );
      if (mounted) context.go(AppRoutes.home);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupViewModelProvider);
    final viewModel = ref.read(profileSetupViewModelProvider.notifier);
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: CenteredConstrainedBox(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              hPadding,
              AppSpacing.xxxl,
              hPadding,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.addInfoTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                RoleTabs(selected: state.role, onChanged: viewModel.setRole),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: _AvatarPicker(
                    avatarUrl: _avatarUrl,
                    pickedImage: _avatarImage,
                    onTap: _pickAvatar,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final item in state.formItems) ...[
                  _FormRow(
                    item: item,
                    controllers: _controllers,
                    fieldOfWork: state.fieldOfWork,
                    cvFileName: state.cvFile?.name,
                    logoFileName: state.companyLogoFile?.name,
                    onFieldOfWorkTap: () => context.push(AppRoutes.fieldOfWork),
                    onPickCv: _pickCv,
                    onPickLogo: _pickCompanyLogo,
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: PrimaryButton(
                      label: AppStrings.signUp,
                      outlined: true,
                      loading: _submitting,
                      onPressed: _submit,
                    ),
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

enum _AvatarAction { camera, gallery, shuffle }

class _AvatarActionSheet extends StatelessWidget {
  const _AvatarActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text(AppStrings.takePhoto),
            onTap: () => Navigator.pop(context, _AvatarAction.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text(AppStrings.chooseFromGallery),
            onTap: () => Navigator.pop(context, _AvatarAction.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.shuffle_rounded),
            title: const Text(AppStrings.shuffleAvatar),
            onTap: () => Navigator.pop(context, _AvatarAction.shuffle),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.item,
    required this.controllers,
    required this.fieldOfWork,
    required this.cvFileName,
    required this.logoFileName,
    required this.onFieldOfWorkTap,
    required this.onPickCv,
    required this.onPickLogo,
  });

  final ProfileFormItem item;
  final Map<ProfileField, TextEditingController> controllers;
  final String? fieldOfWork;
  final String? cvFileName;
  final String? logoFileName;
  final VoidCallback onFieldOfWorkTap;
  final VoidCallback onPickCv;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      TextFormItem(:final hint, :final field) => AppTextField(
        key: ValueKey('text:$hint'),
        hint: hint,
        controller: controllers[field],
      ),
      FieldOfWorkFormItem() => _FieldOfWorkSelector(
        value: fieldOfWork,
        onTap: onFieldOfWorkTap,
      ),
      UploadFormItem(:final label, :final kind) => _UploadRow(
        label: label,
        fileName: kind == UploadItemKind.cv ? cvFileName : logoFileName,
        onTap: kind == UploadItemKind.cv ? onPickCv : onPickLogo,
      ),
    };
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatarUrl,
    required this.pickedImage,
    required this.onTap,
  });

  final String avatarUrl;
  final PickedFile? pickedImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = AppSpacing.avatarXxl / 2;
    final ImageProvider provider = pickedImage?.bytes != null
        ? MemoryImage(pickedImage!.bytes!)
        : CachedNetworkImageProvider(avatarUrl);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: AppSpacing.avatarXxl,
        height: AppSpacing.avatarXxl,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: colors.border,
              backgroundImage: provider,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colors.actionCardFilled,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: AppSpacing.iconSm,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldOfWorkSelector extends StatelessWidget {
  const _FieldOfWorkSelector({required this.value, required this.onTap});

  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        height: AppSpacing.inputFieldHeight,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          0,
          AppSpacing.sm,
          0,
        ),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: colors.border, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : AppStrings.fieldOfWork,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: hasValue ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSpacing.iconMd,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({
    required this.label,
    required this.fileName,
    required this.onTap,
  });

  final String label;
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasFile = fileName != null;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        Divider(color: colors.divider, thickness: 1, height: 1),
        const SizedBox(height: AppSpacing.base),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFile
                      ? Icons.description_outlined
                      : Icons.file_upload_outlined,
                  size: AppSpacing.iconMd,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    hasFile ? fileName! : label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (hasFile) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.check_circle,
                    size: AppSpacing.iconSm,
                    color: colors.success,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}
