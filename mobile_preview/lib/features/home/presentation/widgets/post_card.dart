import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/feed_post.dart';

/// Carte d'une publication du fil — reproduit la maquette Home.
class PostCard extends StatelessWidget {
  final FeedPost post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (post.text != null) ...[
            const SizedBox(height: 12),
            Text(post.text!,
                style: const TextStyle(
                    fontSize: 14, height: 1.4, color: Color(0xFF2B2F3A))),
          ],
          if (post.linkUrl != null) ...[
            const SizedBox(height: 6),
            Text(post.linkUrl!,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.link)),
          ],
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, child, p) => p == null
                      ? child
                      : Container(
                          color: const Color(0xFFEEF1F6),
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))),
                  errorBuilder: (c, e, s) => Container(
                    color: const Color(0xFFEEF1F6),
                    child: const Icon(Icons.image_outlined,
                        color: AppTheme.muted, size: 40),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('${post.comments} Comments    ${post.shares} Shares',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.hairline),
          const SizedBox(height: 6),
          _actions(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
            radius: 20, backgroundImage: NetworkImage(post.authorAvatarUrl)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: post.authorName,
                      style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  if (post.coauthors != null)
                    TextSpan(
                        text: ' ${post.coauthors}',
                        style: const TextStyle(
                            color: AppTheme.muted, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.schedule, size: 12, color: AppTheme.muted),
                const SizedBox(width: 4),
                Text(post.timeAgo,
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              ]),
            ],
          ),
        ),
        const Icon(Icons.more_horiz, color: AppTheme.muted),
      ],
    );
  }

  Widget _actions() {
    return Row(
      children: [
        _iconBtn(Icons.thumb_up_alt_outlined),
        const SizedBox(width: 18),
        _iconBtn(Icons.mode_comment_outlined),
        const SizedBox(width: 18),
        _iconBtn(Icons.share_outlined),
        const Spacer(),
        Flexible(
          child: Text(post.likedBy,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon) =>
      Icon(icon, size: 22, color: AppTheme.navy);
}
