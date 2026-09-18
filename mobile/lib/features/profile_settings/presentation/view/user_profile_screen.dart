import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';
import '../widgets/candidate_overview_tab.dart';
import '../widgets/candidate_portfolio_tab.dart';
import '../widgets/profile_header_section.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import 'recruiter_profile_view.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../../core/enums/user_role.dart';
import '../../cv_autofill/presentation/widgets/cv_source_bottom_sheet.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

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
      appBar: CustomAppBar(
        title: 'Profile',
        trailingAction: IconButton.filledTonal(
          tooltip: 'Auto Fill Profile',
          icon: const AppIcon(HugeIcons.strokeRoundedDocumentValidation),
          onPressed: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (_) => CvSourceBottomSheet(cvUrl: profileState.cvUrl),
          ),
        ),
      ),
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

  Widget _buildProfileHeader(
    BuildContext context,
    AppColorScheme colors,
    CandidateProfileState state,
    CandidateProfileViewModel viewModel,
  ) {
    final user = ref.watch(authControllerProvider).value;
    return ProfileIdentityCard(
      name: state.name,
      imageUrl: state.avatarUrl,
      fallbackSeed: user?.email,
      subtitle: state.role,
      metadata: state.location,
      actions: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.editProfile),
            icon: const AppIcon(HugeIcons.strokeRoundedPencilEdit01, size: 18),
            label: const Text('Edit Profile'),
          ),
          PopupMenuButton<bool>(
            tooltip: 'Resume AI visibility',
            onSelected: viewModel.toggleResumeAiVisibility,
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Show')),
              PopupMenuItem(value: false, child: Text('Hide')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    state.isResumeAiVisible
                        ? HugeIcons.strokeRoundedView
                        : HugeIcons.strokeRoundedViewOff,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Resume AI'),
                  const AppIcon(HugeIcons.strokeRoundedArrowDown01, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftSkillsScore(
    AppColorScheme colors,
    CandidateProfileState profileState,
    CandidateProfileViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PopupMenuButton<bool>(
            tooltip: 'Soft skills visibility',
            onSelected: viewModel.toggleSoftSkillsVisibility,
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text('Show')),
              PopupMenuItem(value: false, child: Text('Hide')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'SOFT SKILLS SCORE',
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.textSecondary,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  AppIcon(
                    profileState.isSoftSkillsVisible
                        ? HugeIcons.strokeRoundedView
                        : HugeIcons.strokeRoundedViewOff,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  const AppIcon(HugeIcons.strokeRoundedArrowDown01, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: profileState.isSoftSkillsVisible ? 1 : .3,
            duration: AppMotion.duration(context, AppMotion.settle),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: profileState.softSkillsScore / 100,
                      minHeight: 10,
                      backgroundColor: colors.inputFill,
                      valueColor: AlwaysStoppedAnimation(colors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${profileState.softSkillsScore}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate._tabBar != _tabBar;
  }
}
