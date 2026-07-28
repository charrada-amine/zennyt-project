// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/utils/link_extractor.dart';
import 'package:zennyt/features/home/presentation/widgets/CommentsBottomSheet.dart';
import 'package:zennyt/shared/providers/internet_provider.dart';
import 'package:zennyt/shared/widgets/no_connection_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/avatar/avatar_service.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/like_post.dart';
import '../../domain/usecases/unlike_post.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/home_providers.dart';
import 'poll_post_widget.dart';

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late bool _isLiked;
  late int _likesCount;

  String _formatTimeAgo(BuildContext context, DateTime? createdAt, String fallbackTimeAgo) {
    if (createdAt == null) return fallbackTimeAgo;
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAt.toUtc());

    if (diff.inSeconds < 60) {
      return l10n.justNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.timeAgoMinutes(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.timeAgoHours(diff.inHours);
    }
    if (diff.inDays < 30) {
      return l10n.timeAgoDays(diff.inDays);
    }
    if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return l10n.timeAgoMonths(months);
    }
    final years = diff.inDays ~/ 365;
    return l10n.timeAgoYears(years);
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likesCount = int.tryParse(widget.post.likesCount) ?? 0;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _isLiked = widget.post.isLikedByMe;
      _likesCount = int.tryParse(widget.post.likesCount) ?? 0;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openCommentsSheet() async {
    final isConnected = await checkInternetWithLoader(context, ref);
    if (!isConnected) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(postId: widget.post.id),
    );
  }

  Widget _buildContentWithLinks(String text) {
    final links = LinkExtractor.extractLinks(text);
    final children = <TextSpan>[];
    int currentPos = 0;

    for (final link in links) {
      final linkIndex = text.indexOf(link, currentPos);
      if (linkIndex > currentPos) {
        children.add(TextSpan(
          text: text.substring(currentPos, linkIndex),
          style: TextStyle(color: context.colors.textPrimary),
        ));
      }

      if (linkIndex > 0 && !text.substring(0, linkIndex).endsWith('\n')) {
        children.add(const TextSpan(text: '\n'));
      }

      children.add(TextSpan(
        text: link,
        style: TextStyle(color: context.colors.linkColor),
        recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(link),
      ));
      currentPos = linkIndex + link.length;

      while (currentPos < text.length &&
          (text[currentPos] == ' ' || text[currentPos] == '\t')) {
        currentPos++;
      }

      if (currentPos < text.length &&
          !text.substring(currentPos).startsWith('\n')) {
        children.add(const TextSpan(text: '\n'));
      }
    }

    if (currentPos < text.length) {
      children.add(TextSpan(
        text: text.substring(currentPos),
        style: TextStyle(color: context.colors.textPrimary),
      ));
    }

    return RichText(text: TextSpan(children: children));
  }

  Widget _buildMediaItem(PostMedia media) {
    switch (media.type) {
      case MediaType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: media.url,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: context.colors.mediaErrorBg,
              child: Center(
                  child: Icon(Icons.image, color: context.colors.textMuted)),
            ),
            placeholder: (context, url) => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        );
      case MediaType.video:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 250,
            color: context.colors.textPrimary,
            child: Center(
              child: Icon(Icons.play_circle_outline,
                  color: context.colors.cardSurface, size: 64),
            ),
          ),
        );
      case MediaType.document:
        final String downloadLink = media.url;

        return GestureDetector(
          onTap: () => _launchUrl(downloadLink),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.documentBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file,
                    size: 48, color: context.colors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Uri.parse(downloadLink).pathSegments.isNotEmpty
                        ? Uri.parse(downloadLink).pathSegments.last
                        : 'document',
                    style: TextStyle(color: context.colors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.download, color: AppColors.iconColor),
              ],
            ),
          ),
        );
    }
  }

  Future<void> toggleLike() async {
    final isConnected = await checkInternetWithLoader(context, ref);
    if (!isConnected) return;

    final l10n = AppLocalizations.of(context);
    final currentUserAsync = ref.read(currentUserProvider);
    if (currentUserAsync.value == null) return;

    final userId = currentUserAsync.value!.id;
    final wasLiked = _isLiked;
    final currentUser = currentUserAsync.value!;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      if (wasLiked) {
        await ref.read(unlikePostProvider)(
          UnlikePostParams(postId: widget.post.id, userId: userId),
        );
      } else {
        await ref.read(likePostProvider)(
          LikePostParams(postId: widget.post.id, userId: userId),
        );
      }

      if (!wasLiked && currentUser.id != widget.post.authorId) {
        final notification = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: widget.post.authorId,
          title: l10n.newLike,
          subtitle: l10n.likedYourPost(currentUser.name),
          createdAt: DateTime.now(),
          type: NotificationType.newLike,
          isRead: false,
          contactName: currentUser.name,
        );
        await ref.read(createNotificationUseCaseProvider)(notification);
        ref.invalidate(notificationsProvider);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likesCount = wasLiked ? _likesCount + 1 : _likesCount - 1;
      });
      print('failed to toggle like');
    }
  }

  Future<void> hidePost() async {
    final isConnected = await checkInternetWithLoader(context, ref);
    if (!isConnected) return;

    try {
      await ref
          .read(userPostPreferencesProvider.notifier)
          .hidePost(widget.post.id);
    } catch (_) {
      if (mounted) {
        print('failed to hide post');
      }
    }
  }

  Future<void> blockAuthor() async {
    final isConnected = await checkInternetWithLoader(context, ref);
    if (!isConnected) return;

    try {
      await ref
          .read(userPostPreferencesProvider.notifier)
          .blockAuthor(widget.post.authorId);
      if (mounted) {
        print('author blocked successfully');
      }
    } catch (_) {
      if (mounted) {
        print('failed to block author');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(
                url: widget.post.authorAvatarUrl.isNotEmpty
                    ? widget.post.authorAvatarUrl
                    : const AvatarService().defaultFor(widget.post.authorName),
                size: 60,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.post.authorName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (widget.post.isMultipleAuthors)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              l10n.andTwoOthers,
                              style: TextStyle(
                                  color: colors.textMuted, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Image.asset('assets/images/world.png',
                            width: 16, height: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(context, widget.post.createdAt, widget.post.timeAgo),
                          style:
                              TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  AppConstants.isCupertino
                      ? CupertinoIcons.ellipsis
                      : Icons.more_horiz,
                  color: colors.textMuted,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: blockAuthor,
                    child: Row(
                      children: [
                        Image.asset('assets/images/block.png',
                            width: 16, height: 16),
                        const SizedBox(width: 8),
                        Text(l10n.block,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.iconColor)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: hidePost,
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.eyeSlash,
                            color: AppColors.iconColor, size: 14),
                        const SizedBox(width: 8),
                        Text(l10n.hide,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.iconColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.post.content != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildContentWithLinks(widget.post.content!),
            ),
          if (widget.post.media.isNotEmpty)
            ...widget.post.media.map(
              (media) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMediaItem(media),
              ),
            ),
          if (widget.post.poll != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PollPostWidget(
                  postId: widget.post.id, poll: widget.post.poll!),
            ),
          const SizedBox(height: 12),
          Text(
            l10n.commentsAndShares(widget.post.commentsCount, widget.post.sharesCount),
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: toggleLike,
                child: FaIcon(
                  _isLiked
                      ? FontAwesomeIcons.solidThumbsUp
                      : FontAwesomeIcons.thumbsUp,
                  color: AppColors.iconColor,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openCommentsSheet,
                child: const FaIcon(
                  FontAwesomeIcons.commentDots,
                  color: AppColors.iconColor,
                ),
              ),
              const SizedBox(width: 10),
              AppConstants.isCupertino
                  ? const Icon(CupertinoIcons.arrowshape_turn_up_right,
                      color: AppColors.iconColor)
                  : const FaIcon(FontAwesomeIcons.share,
                      color: AppColors.iconColor),
              const Spacer(),
              Flexible(
                flex: 2,
                child: Text(
                  l10n.likedByAndOthers('Anna', _likesCount.toString()),
                  style: TextStyle(color: colors.textMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}