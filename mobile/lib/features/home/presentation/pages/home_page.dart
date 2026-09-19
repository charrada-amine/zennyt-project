// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:zennyt/shared/widgets/zennyt_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/shared/widgets/platform_app_bar.dart';
import 'package:zennyt/shared/widgets/platform_scaffold.dart';
import '../providers/home_providers.dart';
import '../widgets/profile_row.dart';
import '../widgets/post_card.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

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

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);

    return PlatformScaffold(
      backgroundColor: context.colors.panelBackground,
      appBar: PlatformAppBar(
        // Marque : Zennyt (« Progress Careers » n'était qu'un nom provisoire).
        title: const ZennytLogo(
          axis: Axis.horizontal,
          showTagline: true,
          size: 30,
        ),
        showBack: false,
        leading: GestureDetector(
          onTap: () => context.push(AppRoutes.profileSettings),
          child: AppIcon(
            HugeIcons.strokeRoundedMenu01,
            color: context.colors.textPrimary,
            size: 28,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.chats),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 42,
              height: 42,
              // Pas d'ombre : la barre d'app la coupait en un carré gris.
              decoration: BoxDecoration(
                color: const Color(0xFFD02F7C).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: AppIcon(
                  HugeIcons.strokeRoundedMessage01,
                  size: 22,
                  color: Color(0xFFD02F7C),
                ),
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
            child: RefreshIndicator.adaptive(
              onRefresh: _onRefresh,
              child: postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    final l10n = AppLocalizations.of(context);
                    final colors = context.colors;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          32,
                          56,
                          32,
                          32 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: AppIcon(
                                  HugeIcons.strokeRoundedNews,
                                  color: colors.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.emptyFeedTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.emptyFeedBody,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.push('/create-post'),
                              icon: const AppIcon(
                                HugeIcons.strokeRoundedAdd01,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(l10n.shareAProject),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final hasMore = ref.watch(postsFeedHasMoreProvider);

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: 8,
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: posts.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
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
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, _) => Center(child: Text(AppLocalizations.of(context).homeError(error.toString()))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
