import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../viewmodel/recruiter_profile_viewmodel.dart';
import '../widgets/profile_header_section.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class RecruiterProfileView extends ConsumerWidget {
  const RecruiterProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);
    final userState = ref.watch(authControllerProvider);
    final user = userState.value;
    final recruiterState = ref.watch(recruiterProfileProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: const CustomAppBar(title: 'Profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: hPadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(context, colors, user, recruiterState.value),
              const SizedBox(height: AppSpacing.xl),
              _buildCompanyInformation(context, colors, recruiterState.value),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Divider(height: 1, thickness: 1),
              ),
              _buildAboutMe(context, colors, recruiterState.value),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppColorScheme colors,
    user,
    profile,
  ) {
    final fullName = user != null
        ? '${user.firstName} ${user.lastName}'
        : 'Recruiter Name';
    final jobTitle = profile?.jobTitle ?? '';
    final companyName = profile?.companyName ?? '';

    return ProfileIdentityCard(
      name: fullName,
      imageUrl: user?.profileImageUrl,
      fallbackSeed: user?.email,
      subtitle: jobTitle,
      metadata: companyName,
      actions: FilledButton.icon(
        onPressed: () => context.pushNamed('recruiterEditProfile'),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit Profile'),
      ),
    );
  }

  Widget _buildCompanyInformation(
    BuildContext context,
    AppColorScheme colors,
    profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Company information',
              style: AppTypography.titleMedium.copyWith(
                color: colors.textDarkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                context.pushNamed('recruiterEditProfile');
              },
              icon: Icon(
                Icons.edit_outlined,
                color: colors.textSecondary,
                size: 20,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildInfoRow(
          colors,
          'Company size',
          profile?.companySize ?? '—',
          Icons.people_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoRow(
          colors,
          'Field of work',
          profile?.fieldOfWork ?? '—',
          Icons.work_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoRow(
          colors,
          'Company location',
          profile?.companyLocation ?? '—',
          Icons.location_on_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInfoRow(
          colors,
          'Company Registration Number (EIN)',
          profile?.companyRegistrationNumber ?? '—',
          Icons.verified_outlined,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    AppColorScheme colors,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.textDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMe(BuildContext context, AppColorScheme colors, profile) {
    final aboutMe = profile?.aboutMe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About me',
          style: AppTypography.titleMedium.copyWith(
            color: colors.textDarkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                (aboutMe == null || aboutMe.isEmpty)
                    ? 'Introduce yourself and your company. Add a few words about the people you are looking for.'
                    : aboutMe,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textDarkBlue,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              top: -8,
              right: 8,
              child: Icon(
                Icons.format_quote_rounded,
                size: 80,
                color: colors.primary.withValues(alpha: 0.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: InkWell(
            onTap: () {
              context.pushNamed('recruiterEditProfile');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colors.cardSurface,
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit content',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textDarkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
