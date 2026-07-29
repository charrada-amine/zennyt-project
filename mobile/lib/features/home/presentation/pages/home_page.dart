// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/theme/app_color_scheme.dart';
import 'package:zennyt/shared/widgets/platform_app_bar.dart';
import 'package:zennyt/shared/widgets/platform_scaffold.dart';
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

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
        leading: GestureDetector(
          onTap: () => context.push(AppRoutes.profileSettings),
          child: Icon(
            AppConstants.isCupertino
                ? CupertinoIcons.line_horizontal_3
                : Icons.menu,
            color: context.colors.textPrimary,
            size: 28,
          ),
        ),
        actions: [
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
            child: postsAsync.when(
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
              error: (error, _) => Center(child: Text(AppLocalizations.of(context).homeError(error.toString()))),
            ),
          ),
        ],
      ),
    );
  }
}
