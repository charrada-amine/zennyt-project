import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/features/home/domain/entities/comment.dart';
import 'package:zennyt/shared/providers/internet_provider.dart';
import 'package:zennyt/features/home/presentation/providers/home_providers.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import 'package:zennyt/core/theme/theme.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String postId;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final isConnected = await checkInternetWithLoader(context, ref);
    if (!isConnected) return;

    final user = ref.read(currentUserProvider).value;
    final authUser = ref.read(authControllerProvider).value;
    if (user == null && authUser == null) return;

    final authorName = (authUser?.fullName.trim().isNotEmpty ?? false)
        ? authUser!.fullName.trim()
        : (user?.name ?? 'User');

    final avatarUrl = authUser?.effectiveAvatarUrl ??
        (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
            ? user.avatarUrl
            : const AvatarService().defaultFor(authorName));

    setState(() => _isSubmitting = true);

    try {
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.postId,
        authorId: user?.id ?? authUser?.id ?? '',
        authorName: (authUser?.fullName.trim().isNotEmpty ?? false)
            ? authUser!.fullName.trim()
            : (user?.name ?? 'User'),
        authorAvatarUrl: avatarUrl,
        content: text,
        createdAt: DateTime.now(),
      );

      await ref.read(addCommentProvider)(comment);

      _controller.clear();

      ref.invalidate(commentsProvider(widget.postId));
      ref.invalidate(postsProvider);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.timeAgoMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeAgoHours(diff.inHours);
    return l10n.dateFormatted(
      date.day.toString().padLeft(2, '0'),
      date.month.toString().padLeft(2, '0'),
      date.year.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final user = ref.watch(currentUserProvider).value;
    final authUser = ref.watch(authControllerProvider).value;

    final effectiveAvatarUrl = authUser?.effectiveAvatarUrl ??
        (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
            ? user.avatarUrl
            : const AvatarService().defaultFor('zennyt'));

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.cardSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l10n.commentsTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Divider(color: colors.divider, height: 16),
                Expanded(
                  child: commentsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        l10n.errorText,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return ListView(
                          controller: scrollController,
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  l10n.noCommentsYet,
                                  style: TextStyle(color: colors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 10),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];

                          final isMyComment = (authUser != null &&
                                  (c.authorId == authUser.id ||
                                      c.authorName.trim().toLowerCase() ==
                                          authUser.fullName.trim().toLowerCase())) ||
                              (user != null &&
                                  (c.authorId == user.id ||
                                      c.authorName.trim().toLowerCase() ==
                                          user.name.trim().toLowerCase()));

                          final commentAvatarUrl = (c.authorAvatarUrl != null &&
                                  c.authorAvatarUrl!.isNotEmpty)
                              ? c.authorAvatarUrl!
                              : (isMyComment
                                  ? (authUser?.effectiveAvatarUrl ??
                                      const AvatarService().defaultFor(c.authorName))
                                  : const AvatarService().defaultFor(c.authorName));
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.inputFill,
                              backgroundImage: NetworkImage(commentAvatarUrl),
                            ),
                            title: Text(
                              c.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              c.content,
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            trailing: Text(
                              _formatDate(context, c.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                      left: 14,
                      right: 14,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.inputFill,
                          backgroundImage: NetworkImage(effectiveAvatarUrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.inputFill,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _controller,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.commentPlaceholder,
                                hintStyle: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
                                ),
                              )
                            : TextButton(
                                onPressed: _submitComment,
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.primary,
                                ),
                                child: Text(
                                  l10n.postLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
