// ignore_for_file: deprecated_member_use

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/shared/providers/internet_provider.dart';
import 'package:zennyt/core/avatar/avatar_service.dart';
import 'package:zennyt/core/utils/responsive.dart';
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
import 'package:zennyt/shared/widgets/initials_avatar.dart';

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
  bool _showDesktopOptions = false;

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

  void _showVisibilityMenu(BuildContext context) {
    final colors = context.colors;
    showMenu<PostVisibility>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 200, 100, 100),
      items: [
        PopupMenuItem(
          value: PostVisibility.public,
          child: Row(
            children: [
              Icon(Icons.public, color: colors.textPrimary, size: 18),
              const SizedBox(width: 8),
              const Text('Public'),
            ],
          ),
        ),
        PopupMenuItem(
          value: PostVisibility.friends,
          child: Row(
            children: [
              Icon(Icons.people_outline, color: colors.textPrimary, size: 18),
              const SizedBox(width: 8),
              const Text('Friends'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        ref.read(postVisibilityProvider.notifier).state = value;
      }
    });
  }

  Widget _buildDesktopOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColorScheme colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              icon,
              color: colors.accent,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMedia = ref.watch(selectedPostMediaProvider);
    final selectedDocuments = ref.watch(selectedPostDocumentsProvider);
    final visibility = ref.watch(postVisibilityProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final authUser = ref.watch(authControllerProvider).value;
    final colors = context.colors;
    final isDesktop = Responsive.isDesktop(context);

    final effectiveAvatarUrl = authUser?.effectiveAvatarUrl ??
        const AvatarService().defaultFor('zennyt');

    if (isDesktop) {
      return Material(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 550,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.inputFill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: 16),

              // Content Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InitialsAvatar(
                            url: effectiveAvatarUrl,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Visibility Pill
                                InkWell(
                                  onTap: () => _showVisibilityMenu(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.inputFill,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          visibility == PostVisibility.public
                                              ? Icons.public
                                              : Icons.people_outline,
                                          size: 14,
                                          color: colors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          visibility == PostVisibility.public
                                              ? 'Public'
                                              : 'Friends',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          size: 14,
                                          color: colors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Text Input
                                TextField(
                                  controller: _textController,
                                  maxLines: null,
                                  minLines: 3,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'New Project',
                                    hintStyle: TextStyle(
                                      color: colors.textSecondary,
                                    ),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Attached items previews
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

                      // Add to your post panel
                      if (_showDesktopOptions) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add to your post',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDesktopOptionButton(
                                    icon: Icons.image_outlined,
                                    label: 'Media',
                                    onTap: _openMediaPicker,
                                    colors: colors,
                                  ),
                                  _buildDesktopOptionButton(
                                    icon: Icons.emoji_events_outlined,
                                    label: 'Score',
                                    onTap: _openPollCreator,
                                    colors: colors,
                                  ),
                                  _buildDesktopOptionButton(
                                    icon: Icons.psychology_outlined,
                                    label: 'Resume AI',
                                    onTap: () {},
                                    colors: colors,
                                  ),
                                  _buildDesktopOptionButton(
                                    icon: Icons.description_outlined,
                                    label: 'Document',
                                    onTap: _pickDocuments,
                                    colors: colors,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: 12),

              // Bottom Actions Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Media icon
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: colors.accent),
                      onPressed: _openMediaPicker,
                    ),
                    // Trophy icon (score)
                    IconButton(
                      icon: Icon(Icons.emoji_events_outlined, color: colors.accent),
                      onPressed: _openPollCreator,
                    ),
                    // Plus icon (more options)
                    IconButton(
                      icon: Icon(
                        _showDesktopOptions ? Icons.remove : Icons.add,
                        color: colors.accent,
                      ),
                      onPressed: () {
                        setState(() {
                          _showDesktopOptions = !_showDesktopOptions;
                        });
                      },
                    ),
                    const Spacer(),
                    // Cancel Button
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Post Button
                    ElevatedButton(
                      onPressed: _canPost && !_isSubmitting ? _submitPost : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 40),
                        backgroundColor: colors.brandNavy,
                        disabledBackgroundColor: colors.iconDisabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Post',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
