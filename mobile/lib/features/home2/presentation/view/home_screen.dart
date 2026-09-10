import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/theme.dart';
import '../home_providers.dart';
import '../widgets/feed_top_bar.dart';
import '../widgets/new_project_row.dart';
import '../widgets/post_card.dart';

/// The Home tab: a social feed of posts. Hosted inside the app navigation.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.read(homeRepositoryProvider).getFeedPosts();
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FeedTopBar(hPadding: hPadding),
            Divider(height: 1, thickness: 1, color: colors.divider),
            NewProjectRow(hPadding: hPadding),
            Divider(height: 1, thickness: 1, color: colors.divider),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 8,
                    color: colors.dividerThick,
                  ),
                  itemBuilder: (context, index) =>
                      PostCard(post: posts[index], hPadding: hPadding),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
