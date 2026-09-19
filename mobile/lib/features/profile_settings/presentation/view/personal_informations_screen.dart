import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/app_locations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/zennyt_switch.dart';
import '../../../../shared/widgets/full_screen_loader.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/upload/file_picking.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../../core/avatar/avatar_service.dart';
import '../widgets/account_change_otp_dialog.dart';

import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/app_select.dart';

class PersonalInformationsScreen extends ConsumerStatefulWidget {
  const PersonalInformationsScreen({super.key});

  @override
  ConsumerState<PersonalInformationsScreen> createState() =>
      _PersonalInformationsScreenState();
}

class _PersonalInformationsScreenState
    extends ConsumerState<PersonalInformationsScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  String? _country;

  bool _displayCurrentCity = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    _cityController = TextEditingController(text: user?.city ?? '');
    _country = user?.country;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final user = ref.read(authControllerProvider).value;
    final repo = ref.read(authRepositoryProvider);
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    final emailChanged =
        user != null && newEmail.isNotEmpty && newEmail.toLowerCase() != user.email.toLowerCase();
    final phoneChanged = user != null && newPhone.isNotEmpty && newPhone != (user.phone ?? '');

    setState(() => _isLoading = true);

    try {
      // Common profile fields first. The phone number is kept as-is here: a phone
      // change is a separate OTP-confirmed flow below.
      await repo.updateMe(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: user?.phone,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        country: _country,
      );

      if (emailChanged) {
        await repo.requestEmailChange(newEmail);
        if (!mounted) return;
        final verified = await AccountChangeOtpDialog.show(
          context,
          title: 'Verify your new email',
          subtitle: 'We sent a confirmation code to $newEmail',
          onVerify: repo.verifyEmailChange,
          onResend: () => repo.requestEmailChange(newEmail),
        );
        if (verified != true) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      if (phoneChanged) {
        await repo.requestPhoneChange(newPhone);
        if (!mounted) return;
        final verified = await AccountChangeOtpDialog.show(
          context,
          title: 'Verify your new phone number',
          subtitle: 'SMS is not available yet — the code was sent to your e-mail address.',
          onVerify: repo.verifyPhoneChange,
          onResend: () => repo.requestPhoneChange(newPhone),
        );
        if (verified != true) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      await ref.read(authControllerProvider.notifier).refreshUser();

      if (mounted) {
        await _showChangesSavedDialog();
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showChangesSavedDialog() {
    final colors = context.colors;
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colors.scaffoldBg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(HugeIcons.strokeRoundedTick02, color: colors.success, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'Changes saved',
                style: AppTypography.titleLarge.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: AppSpacing.lg,
                  ),
                  child: _TopBar(title: l10n.personalInformations),
                ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    Center(
                      child: Stack(
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final user = ref
                                  .watch(authControllerProvider)
                                  .value;
                              final imageUrl = user?.effectiveAvatarUrl ??
                                  ref.read(avatarServiceProvider).defaultFor('');
                              return CircleAvatar(
                                radius: 48,
                                backgroundColor: colors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                backgroundImage: NetworkImage(imageUrl),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _showAvatarOptions(context, colors, l10n),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.scaffoldBg,
                                    width: 2,
                                  ),
                                ),
                                child: const AppIcon(
                                  HugeIcons.strokeRoundedCamera01,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _buildInputField(
                      colors: colors,
                      label: l10n.firstName,
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildInputField(
                      colors: colors,
                      label: l10n.lastName,
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildInputField(
                      colors: colors,
                      label: l10n.emailHyphen,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildInputField(
                      colors: colors,
                      label: l10n.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _buildCountryDropdown(colors, l10n),
                    const SizedBox(height: AppSpacing.md),

                    _buildInputField(
                      colors: colors,
                      label: l10n.city,
                      controller: _cityController,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildLocationToggle(colors, l10n),

                    const SizedBox(height: AppSpacing.xxl),

                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary, // Dark blue
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.saveChanges,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (_isLoading) const FullScreenLoader(),
      ],
      ),
    );
  }

  Widget _buildInputField({
    required AppColorScheme colors,
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: AppTypography.bodyMedium.copyWith(
              color: readOnly ? colors.textSecondary : colors.primary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
              suffixIconConstraints: suffixIcon != null
                  ? const BoxConstraints(minWidth: 24, minHeight: 24)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown(AppColorScheme colors, dynamic l10n) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.country,
              style: AppTypography.labelSmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: AppSelect<String>(
              value: _country,
              options: AppLocations.countries,
              labelOf: (country) => country,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
              chevronColor: colors.chevron,
              onChanged: (newValue) => setState(() => _country = newValue),
              material: DropdownButton<String>(
                value: _country,
                isExpanded: true,
                isDense: true,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    color: colors.chevron,
                  ),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _country = newValue;
                  });
                },
                items: AppLocations.countries.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle(AppColorScheme colors, dynamic l10n) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentLocation,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.displayCurrentCity,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28,
            child: ZennytSwitch(
              value: _displayCurrentCity,
              onChanged: (val) {
                setState(() {
                  _displayCurrentCity = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(
    BuildContext context,
    AppColorScheme colors,
    dynamic l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colors.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 24, bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(
                HugeIcons.strokeRoundedAlbum02,
                color: colors.primary,
              ),
              title: Text(
                l10n.choosePhoto,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedCamera01, color: colors.primary),
              title: Text(
                l10n.takePhoto,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedDelete02, color: colors.error),
              title: Text(
                l10n.removePhoto,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  setState(() => _isLoading = true);
                  final repo = ref.read(authRepositoryProvider);
                  await repo.deleteAvatar();
                  await ref.read(authControllerProvider.notifier).refreshUser();
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.avatarRemoved)));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorGeneric),
                        backgroundColor: colors.error,
                      ),
                    );
                  }
                } finally {
                  if (context.mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final filePicker = ref.read(filePickingProvider);
      final pickedFile = await filePicker.pickImage(
        fromCamera: source == ImageSource.camera,
      );

      if (pickedFile == null || pickedFile.bytes == null) return;

      setState(() => _isLoading = true);
      final repo = ref.read(authRepositoryProvider);
      await repo.uploadAvatar(pickedFile.bytes!, pickedFile.name);

      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.avatarUpdated)));
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.backButtonBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.backButtonBorder, width: 1),
          ),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: AppIcon(
              HugeIcons.strokeRoundedArrowLeft02,
              color: colors.backButtonIcon,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleLarge.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 60),
      ],
    );
  }
}
