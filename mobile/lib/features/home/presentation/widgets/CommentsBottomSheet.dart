import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/features/home/domain/entities/comment.dart';
import 'package:zennyt/shared/providers/internet_provider.dart';
import 'package:zennyt/features/home/presentation/providers/home_providers.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';

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

    final avatarUrl = (authUser?.profileImageUrl != null && authUser!.profileImageUrl!.isNotEmpty)
        ? authUser.profileImageUrl!
        : (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
            ? user.avatarUrl
            : const AvatarService().defaultFor(authUser?.email ?? 'zennyt'));

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

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return "Il y a ${diff.inMinutes} min";
    if (diff.inDays < 1) return "Il y a ${diff.inHours} h";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final user = ref.watch(currentUserProvider).value;
    final authUser = ref.watch(authControllerProvider).value;

    final effectiveAvatarUrl = (authUser?.profileImageUrl != null && authUser!.profileImageUrl!.isNotEmpty)
        ? authUser.profileImageUrl!
        : (user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
            ? user.avatarUrl
            : const AvatarService().defaultFor(authUser?.email ?? 'zennyt'));

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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  l10n.commentsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: commentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(child: Text(l10n.errorText)),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return ListView(
                          controller: scrollController,
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(l10n.noCommentsYet),
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

                          final commentAvatarUrl = (c.authorAvatarUrl != null && c.authorAvatarUrl!.isNotEmpty)
                              ? c.authorAvatarUrl!
                              : const AvatarService().defaultFor(c.authorName);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(commentAvatarUrl),
                            ),
                            title: Text(
                              c.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(c.content),
                            trailing: Text(
                              _formatDate(c.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                    left: 10,
                    right: 10,
                    top: 5,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(effectiveAvatarUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: l10n.commentPlaceholder,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : TextButton(
                              onPressed: _submitComment,
                              child: Text(l10n.postLabel),
                            ),
                    ],
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
