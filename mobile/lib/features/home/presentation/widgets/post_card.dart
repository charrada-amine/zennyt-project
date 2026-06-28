import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/feed_post.dart';
import 'feed_avatar.dart';

/// A single feed post: header (author / time / menu), optional text, link and
/// image, the comments/shares line, and the like/comment/share action row.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.hPadding});

  final FeedPost post;
  final double hPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPadding,
        AppSpacing.base,
        hPadding,
        AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post, colors: colors),
          if (post.text != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.text!,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
          if (post.link != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              post.link!,
              style: AppTypography.bodyMedium.copyWith(color: colors.info),
            ),
          ],
          if (post.image != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: CachedNetworkImage(
                imageUrl: post.image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(height: 200, color: colors.inputFill),
                errorWidget: (_, _, _) => Container(
                  height: 200,
                  color: colors.inputFill,
                  child: Icon(Icons.image_outlined, color: colors.textMuted),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '${post.comments} ${AppStrings.comments} . ${post.shares} ${AppStrings.shares}',
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, thickness: 1, color: colors.divider),
          const SizedBox(height: AppSpacing.sm),
          _PostActions(likedBy: post.likedBy, colors: colors),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.colors});

  final FeedPost post;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedAvatar(url: post.avatar, radius: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      post.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (post.others != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      post.others!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.timeAgo,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _PostMenu(colors: colors),
      ],
    );
  }
}

class _PostMenu extends StatelessWidget {
  const _PostMenu({required this.colors});

  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
      color: colors.cardSurface,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      position: PopupMenuPosition.under,
      onSelected: (_) {},
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'report',
          child: _MenuRow(
            icon: Icons.outlined_flag_rounded,
            label: AppStrings.report,
          ),
        ),
        PopupMenuItem(
          value: 'hide',
          child: _MenuRow(
            icon: Icons.visibility_off_outlined,
            label: AppStrings.hide,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconMd, color: colors.iconDefault),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({required this.likedBy, required this.colors});

  final String likedBy;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.thumb_up_alt_outlined,
          size: 22,
          color: colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.lg),
        Icon(
          Icons.mode_comment_outlined,
          size: 22,
          color: colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.lg),
        Transform.flip(
          flipX: true,
          child: Icon(
            Icons.reply_rounded,
            size: 24,
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            likedBy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
