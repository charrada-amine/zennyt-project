import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';

class CandidatePortfolioTab extends ConsumerWidget {
  const CandidatePortfolioTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(candidateProfileProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          sliver: state.portfolioItems.isEmpty
              ? _buildEmptyState(context, colors)
              : _buildPopulatedState(context, colors, state.portfolioItems, ref),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorScheme colors) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.sharePost),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 32,
                  color: colors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No portfolio items yet',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to share your best work and projects',
              style: AppTypography.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedState(BuildContext context, AppColorScheme colors, List<PortfolioItem> items, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Portfolio',
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.sharePost),
                    icon: Icon(Icons.add, color: colors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }
          final itemIndex = index - 1;
          return _PortfolioCard(
            item: items[itemIndex],
            colors: colors,
            onDelete: () => ref.read(candidateProfileProvider.notifier).removePortfolioItem(items[itemIndex].id),
          );
        },
        childCount: items.length + 1,
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.item,
    required this.colors,
    required this.onDelete,
  });

  final PortfolioItem item;
  final AppColorScheme colors;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: colors.scaffoldBg,
                onSelected: (val) {
                  if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: colors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Delete', style: AppTypography.bodyMedium.copyWith(color: colors.error)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, color: colors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Share', style: AppTypography.bodyMedium.copyWith(color: colors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
