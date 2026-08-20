// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/core/utils/responsive.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/theme/app_color_scheme.dart';
import 'package:zennyt/shared/widgets/platform_app_bar.dart';
import 'package:zennyt/shared/widgets/platform_scaffold.dart';
import 'package:zennyt/core/theme/app_typography.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import 'package:zennyt/features/navigation/presentation/viewmodel/nav_tab_provider.dart';
import 'package:zennyt/features/notifications/presentation/providers/notification_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/profile_row.dart';
import '../widgets/post_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(postsProvider);
    await ref.read(postsProvider.future);
  }

  Widget _buildFeedContent(AsyncValue<List<dynamic>> postsAsync) {
    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context).noPostsToShow,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textMuted),
              ),
            ),
          );
        }

        final hasMore = ref.watch(postsFeedHasMoreProvider);

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
              top: 8, left: 16, right: 16, bottom: 16),
          itemCount: posts.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final post = posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(post: post),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
          child: Text(AppLocalizations.of(context).homeError(error.toString()))),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    final colors = context.colors;
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
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View all',
            style: AppTypography.bodySmall.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotsIndicator(int count, int activeIndex, AppColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Container(
          width: isActive ? 12 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? colors.accent : colors.textSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildJobCard({
    required AppColorScheme colors,
    required String matchPercent,
    required String company,
    required String role,
    required String location,
    required List<String> tags,
    required String salary,
    required bool isActive,
  }) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? colors.accent : colors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  matchPercent,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              Icon(
                Icons.more_vert,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: const Center(
                  child: Icon(Icons.business, size: 14, color: Colors.blue),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  company,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            role,
            style: AppTypography.titleSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: colors.textSecondary),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  location,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...tags.map((tag) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.inputFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    salary,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSuggestionCard({
    required AppColorScheme colors,
    required String matchPercent,
    required String name,
    required String location,
    required String role,
    required List<String> tags,
    required bool isActive,
  }) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? colors.accent : colors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  matchPercent,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              Icon(
                Icons.more_vert,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.border,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 14),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 10, color: colors.textSecondary),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            role,
            style: AppTypography.titleSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tags
                  .map((tag) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.inputFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncreaseChancesCard(AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withOpacity(0.12),
            colors.accent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Increase your chances',
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Complete your profile and get up to 3x more profile views.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: 0.75,
                      backgroundColor: colors.textSecondary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      strokeWidth: 5,
                    ),
                  ),
                  Text(
                    '75%',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Complete profile',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);
    final isDesktop = Responsive.isDesktop(context);

    if (isDesktop) {
      final user = ref.watch(authControllerProvider).value;
      final colors = context.colors;

      return PlatformScaffold(
        backgroundColor: colors.panelBackground,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left/Middle Column (Feed) ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      'Home',
                      style: AppTypography.headlineLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const ProfileRow(),
                  const SizedBox(height: 16),
                  Divider(
                    color: colors.divider,
                    height: 1,
                    thickness: 1,
                  ),
                  Expanded(
                    child: _buildFeedContent(postsAsync),
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────────────────────
            VerticalDivider(
              color: colors.divider,
              width: 1,
              thickness: 1,
            ),

            // ── Right Side Panel ───────────────────────────────────────────
            Container(
              width: 380,
              color: colors.panelBackground,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top user details / notification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Notification icon — fixed: goes to Notifications (7), dot only if unread
                        GestureDetector(
                          onTap: () => ref.read(navTabProvider.notifier).select(7),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.inputFill,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: colors.textSecondary,
                                  size: 24,
                                ),
                              ),
                              if (ref.watch(notificationsProvider).maybeWhen(
                                    data: (list) => list.any((n) => !n.isRead),
                                    orElse: () => false,
                                  ))
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Profile Card
                        GestureDetector(
                          onTap: () => ref.read(navTabProvider.notifier).select(5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: user != null
                                    ? NetworkImage(user.effectiveAvatarUrl)
                                    : null,
                                backgroundColor: colors.border,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user?.fullName ?? 'Millie Brown',
                                        style: AppTypography.titleSmall.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Online',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colors.textSecondary.withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Search and filter row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: colors.textSecondary,
                                  size: 20,
                                ),
                                hintText: 'Search',
                                hintStyle: AppTypography.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: colors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Filters',
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Job suggestions Section
                    _buildSectionHeader('Job suggestions', () {}),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 170,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildJobCard(
                            colors: colors,
                            matchPercent: '100% Fit',
                            company: 'Google Inc',
                            role: 'Developper',
                            location: 'California, USA',
                            tags: ['Lead', 'Full-time', 'On-site'],
                            salary: r'$25K/Mo',
                            isActive: true,
                          ),
                          const SizedBox(width: 12),
                          _buildJobCard(
                            colors: colors,
                            matchPercent: '99% Fit',
                            company: 'Google Inc',
                            role: 'Engineer DEV',
                            location: 'California, USA',
                            tags: ['Lead', 'Full-time', 'Hybrid'],
                            salary: r'$30K/Mo',
                            isActive: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDotsIndicator(2, 0, colors),
                    const SizedBox(height: 32),

                    // You might know Section
                    _buildSectionHeader('You might know', () {}),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 170,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildUserSuggestionCard(
                            colors: colors,
                            matchPercent: '100% Fit',
                            name: 'Alberta Flores',
                            location: 'California, USA',
                            role: 'Developper | Senior',
                            tags: ['Contract', 'Internationally', 'Immediately'],
                            isActive: true,
                          ),
                          const SizedBox(width: 12),
                          _buildUserSuggestionCard(
                            colors: colors,
                            matchPercent: '99% Fit',
                            name: 'Kristin Watson',
                            location: 'California, USA',
                            role: 'Engineer DEV | Senior',
                            tags: ['Contract', 'Internationally', 'Immediately'],
                            isActive: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDotsIndicator(2, 0, colors),
                    const SizedBox(height: 32),

                    // Increase your chances
                    _buildIncreaseChancesCard(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PlatformScaffold(
      backgroundColor: context.colors.panelBackground,
      appBar: PlatformAppBar(
        title: SizedBox(
          height: 48,
          width: 150,
          child: Image.asset(
            'assets/images/progress_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        showBack: false,
        leading: Responsive.isDesktop(context)
            ? null
            : GestureDetector(
                onTap: () => context.push(AppRoutes.profileSettings),
                child: Icon(
                  AppConstants.isCupertino
                      ? CupertinoIcons.line_horizontal_3
                      : Icons.menu,
                  color: context.colors.textPrimary,
                  size: 28,
                ),
              ),
        actions: Responsive.isDesktop(context)
            ? null
            : [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.chats),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.cardSurface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/chat.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
              ],
      ),
      body: Column(
        children: [
          const ProfileRow(),
          const SizedBox(height: 16),
          Divider(
            color: context.colors.divider,
            height: 1,
            thickness: 2,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildFeedContent(postsAsync),
            ),
          ),
        ],
      ),
    );
  }
}
