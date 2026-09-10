// ignore_for_file: deprecated_member_use

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/shared/providers/internet_provider.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/features/auth/presentation/auth_controller.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../data/models/post_model.dart';
import '../../domain/entities/post.dart';
import '../providers/home_providers.dart';
import '../providers/media_picker_provider.dart';
import '../widgets/add_options_bottom_sheet.dart';
import '../widgets/create_post_bottom_actions.dart';
import '../widgets/create_post_header.dart';
import '../widgets/create_post_text_field.dart';
import '../widgets/selected_post_documents_preview.dart';
import '../widgets/selected_post_media_preview.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final TextEditingController _textController = TextEditingController();
  bool _canPost = false;
  Poll? _attachedPoll;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    final canPost = _evaluateCanPost();
    if (canPost != _canPost) {
      setState(() => _canPost = canPost);
    }
  }

  bool _evaluateCanPost() {
    final selectedMedia = ref.read(selectedPostMediaProvider);
    final selectedDocuments = ref.read(selectedPostDocumentsProvider);
    final hasMedia = selectedMedia.isNotEmpty;
    final hasDocuments = selectedDocuments.isNotEmpty;
    final hasPoll = _attachedPoll != null;
    return _textController.text.isNotEmpty ||
        hasMedia ||
        hasDocuments ||
        hasPoll;
  }

  void _openAddOptions() {
    AddOptionsBottomSheet.show(
      context,
      onMediaTap: _openMediaPicker,
      onDocumentTap: _pickDocuments,
      onPollTap: _openPollCreator,
    );
  }

  Future<void> _openPollCreator() async {
    final result = await context.push<Poll>('/create-post/poll');
    if (result != null) {
      setState(() {
        _attachedPoll = result;
      });
      _onContentChanged();
    }
  }

  void _openMediaPicker() {
    context.push('/create-post/media');
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        ref
            .read(selectedPostDocumentsProvider.notifier)
            .addDocuments(result.files);
      }
    } catch (e) {
      debugPrint('Error picking documents: $e');
    }
  }

  Future<void> _submitPost() async {
    if (!_canPost || _isSubmitting) return;

    final isConnected = await checkInternetWithLoader(context, ref);
    if (!isConnected) return;

    final l10n = AppLocalizations.of(context);
    final currentUser = await ref.read(currentUserProvider.future);
    final authUser = ref.read(authControllerProvider).value;
    final visibility = ref.read(postVisibilityProvider);

    final authorName = (authUser?.fullName.trim().isNotEmpty ?? false)
        ? authUser!.fullName.trim()
        : currentUser.name;

    final authorAvatarUrl = authUser?.effectiveAvatarUrl ??
        (currentUser.avatarUrl.isNotEmpty
            ? currentUser.avatarUrl
            : const AvatarService().defaultFor(authorName));

    setState(() => _isSubmitting = true);

    try {
      final post = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: currentUser.id,
        visibility: visibility,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        timeAgo: l10n.justNow,
        content: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        media: [],
        poll: _attachedPoll,
        commentsCount: '0',
        sharesCount: '0',
        likesCount: '0',
        isLikedByMe: false,
        createdAt: DateTime.now(),
      );

      await ref.read(createPostControllerProvider.notifier).submit(post);

      if (!mounted) return;
      context.pop();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onContentChanged);
    _textController.dispose();
    try {
      ref.read(selectedPostMediaProvider.notifier).clear();
      ref.read(selectedPostDocumentsProvider.notifier).clear();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMedia = ref.watch(selectedPostMediaProvider);
    final selectedDocuments = ref.watch(selectedPostDocumentsProvider);
    final visibility = ref.watch(postVisibilityProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final authUser = ref.watch(authControllerProvider).value;

    final effectiveAvatarUrl = authUser?.effectiveAvatarUrl ??
        const AvatarService().defaultFor('zennyt');

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            currentUserAsync.when(
              data: (currentUser) => CreatePostHeader(
                onPostTap: _submitPost,
                isPostEnabled: _canPost && !_isSubmitting,
                visibility: visibility,
                avatarUrl: effectiveAvatarUrl,
                onVisibilityChanged: (value) {
                  ref.read(postVisibilityProvider.notifier).state = value;
                },
              ),
              loading: () => CreatePostHeader(
                onPostTap: null,
                isPostEnabled: false,
                visibility: visibility,
                avatarUrl: effectiveAvatarUrl,
                onVisibilityChanged: (_) {},
              ),
              error: (_, __) => CreatePostHeader(
                onPostTap: null,
                isPostEnabled: false,
                visibility: visibility,
                avatarUrl: effectiveAvatarUrl,
                onVisibilityChanged: (_) {},
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CreatePostTextField(
                      controller: _textController,
                      onChanged: (_) {},
                    ),
                    SelectedPostMediaPreview(
                      media: selectedMedia,
                      onRemove: (id) => ref
                          .read(selectedPostMediaProvider.notifier)
                          .removeMedia(id),
                    ),
                    SelectedPostDocumentsPreview(
                      documents: selectedDocuments,
                      onRemove: (path) => ref
                          .read(selectedPostDocumentsProvider.notifier)
                          .removeDocument(path),
                    ),
                    if (_attachedPoll != null) _buildPollPreview(),
                  ],
                ),
              ),
            ),
            AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: CreatePostBottomActions(
                onAddTap: _openAddOptions,
                onMediaTap: _openMediaPicker,
                bottomInset: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollPreview() {
    final l10n = AppLocalizations.of(context);
    final poll = _attachedPoll!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.poll_outlined,
                  color: context.colors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.pollAttached,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _attachedPoll = null;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              poll.question,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.optionsCount(poll.options.length)} · ${poll.duration}',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
