import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';
import '../widgets/candidate_overview_tab.dart';
import '../widgets/candidate_portfolio_tab.dart';
import '../widgets/profile_avatar.dart';
import 'recruiter_profile_view.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../../core/enums/user_role.dart';
import '../../cv_autofill/presentation/widgets/cv_source_bottom_sheet.dart';
import '../../../navigation/presentation/viewmodel/nav_tab_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authControllerProvider);
    if (userState.value?.role == UserRole.recruiter) {
      return const RecruiterProfileView();
    }

    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);
    final profileState = ref.watch(candidateProfileProvider);
    final viewModel = ref.read(candidateProfileProvider.notifier);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(context, colors),
                      const SizedBox(height: AppSpacing.xl),
                      _buildProfileHeader(
                        context,
                        colors,
                        profileState,
                        viewModel,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSoftSkillsScore(colors, profileState, viewModel),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: colors.primary,
                    unselectedLabelColor: colors.textSecondary,
                    indicatorColor: colors.primary,
                    indicatorWeight: 3,
                    labelStyle: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppTypography.titleSmall,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Portfolio'),
                    ],
                  ),
                  colors.scaffoldBg,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              const CandidateOverviewTab(),
              // Portfolio Tab
              const CandidatePortfolioTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppColorScheme colors) {
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
            onPressed: () {
              if (Responsive.isDesktop(context)) {
                ref.read(navTabProvider.notifier).select(0); // Go back to Home tab
              } else {
                context.pop();
              }
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.backButtonIcon,
              size: 20,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Profile',
          style: AppTypography.titleLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            // Get the current profile state
            final state = ref.read(candidateProfileProvider);
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => CvSourceBottomSheet(cvUrl: state.cvUrl),
            );
          },
          icon: Icon(Icons.document_scanner_outlined, color: colors.primary),
          tooltip: 'Auto Fill Profile',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppColorScheme colors,
    CandidateProfileState state,
    CandidateProfileViewModel viewModel,
  ) {
    final user = ref.watch(authControllerProvider).value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        ProfileAvatar(imageUrl: state.avatarUrl, size: 70, fallbackSeed: user?.email),
        const SizedBox(width: AppSpacing.md),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.name,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.textDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.role,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.location,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Edit Profile',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Resume AI Dropdown
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: colors.primary, size: 24),
            ),
            const SizedBox(height: 4),
            PopupMenuButton<bool>(
              child: Row(
                children: [
                  Text('Resume AI', style: AppTypography.labelSmall),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      Icon(
                        state.isResumeAiVisible
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: state.isResumeAiVisible
                            ? colors.primary
                            : colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Show'),
                      const Spacer(),
                      const Icon(Icons.visibility_outlined, size: 20),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      Icon(
                        !state.isResumeAiVisible
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !state.isResumeAiVisible
                            ? colors.primary
                            : colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Hide'),
                      const Spacer(),
                      const Icon(Icons.visibility_off_outlined, size: 20),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => viewModel.toggleResumeAiVisibility(value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoftSkillsScore(
    AppColorScheme colors,
    CandidateProfileState profileState,
    CandidateProfileViewModel viewModel,
  ) {
    return Column(
      children: [
        Row(
          children: [
            PopupMenuButton<bool>(
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: colors.scaffoldBg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SOFT SKILLS SCORE',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: true,
                  child: Row(
                    children: [
                      Icon(
                        profileState.isSoftSkillsVisible
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: profileState.isSoftSkillsVisible
                            ? colors.primary
                            : colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Show',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: false,
                  child: Row(
                    children: [
                      Icon(
                        !profileState.isSoftSkillsVisible
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !profileState.isSoftSkillsVisible
                            ? colors.primary
                            : colors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hide',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.visibility_off_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) =>
                  viewModel.toggleSoftSkillsVisibility(value),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AnimatedOpacity(
                opacity: profileState.isSoftSkillsVisible ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: profileState.softSkillsScore / 100,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedOpacity(
              opacity: profileState.isSoftSkillsVisible ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${profileState.softSkillsScore}%',
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
