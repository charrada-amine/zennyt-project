import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:photo_manager/photo_manager.dart';
import 'package:file_picker/file_picker.dart';

import 'package:zennyt/core/error/failures.dart';
import 'package:zennyt/features/home/domain/entities/comment.dart';
import 'package:zennyt/features/home/domain/usecases/get_comments_by_post.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../domain/entities/current_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_post_preferences.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_posts.dart';
import '../../domain/usecases/get_user_post_preferences.dart';
import '../../domain/usecases/update_user_post_preferences.dart';
import '../../domain/usecases/like_post.dart';
import '../../domain/usecases/unlike_post.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/upload_file.dart';
import '../../domain/usecases/vote_poll.dart';
import '../../domain/repositories/post_repository.dart';
import '../../data/services/posts_cache_service.dart';
import '../../data/services/posts_sync_service.dart';
import '../../../../shared/providers/internet_provider.dart';
import '../utils/post_feed_filter.dart';
import 'media_picker_provider.dart';

final postsRepositoryProvider = Provider<PostRepository>((ref) => sl());
final postsCacheProvider = Provider<PostsCacheService>((ref) => sl());
final postsSyncServiceProvider = Provider<PostsSyncService>((ref) => sl());
final getPostsProvider = Provider<GetPosts>((ref) => sl());
final createPostProvider = Provider<CreatePost>((ref) => sl());
final getCurrentUserProvider = Provider<GetCurrentUser>((ref) => sl());
final getUserPostPreferencesProvider =
    Provider<GetUserPostPreferences>((ref) => sl());
final updateUserPostPreferencesProvider =
    Provider<UpdateUserPostPreferences>((ref) => sl());
final likePostProvider = Provider<LikePost>((ref) => sl());
final unlikePostProvider = Provider<UnlikePost>((ref) => sl());
final addCommentProvider = Provider<AddComment>((ref) => sl());
final getCommentsByPostProvider = Provider<GetCommentsByPost>((ref) => sl());
final uploadFileProvider = Provider<UploadFile>((ref) => sl());
final votePollProvider = Provider<VotePoll>((ref) => sl());

// ── Sync service ─────────────────────────────────────────────────────

final keepAliveSyncProvider = Provider<void>((ref) {
  final syncService = ref.read(postsSyncServiceProvider);

  ref.listen<bool>(internetProvider, (previous, next) {
    if (next) {
      syncService.syncPosts().then((_) {
        ref.invalidate(postsProvider);
      });
      syncService.startPeriodicSync();
    } else {
      syncService.stopPeriodicSync();
    }
  });

  ref.onDispose(() => syncService.dispose());
});

// ── Current user ────────────────────────────────────────────────────

// Dépend de l'état d'auth pour que les providers scopés utilisateur
// (conversations, notifications, fil) soient reconstruits au login/logout
// et ne gardent pas le cache du compte précédent.
final currentUserProvider = FutureProvider<CurrentUser>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth.value == null) return CurrentUser.empty();

  final result = await ref.watch(getCurrentUserProvider)();
  return result.fold(
    (failure) => CurrentUser.empty(),
    (user) => user,
  );
});

// ── Preferences ─────────────────────────────────────────────────────

final userPostPreferencesProvider =
    AsyncNotifierProvider<UserPostPreferencesNotifier, UserPostPreferences>(
  UserPostPreferencesNotifier.new,
);

class UserPostPreferencesNotifier extends AsyncNotifier<UserPostPreferences> {
  @override
  Future<UserPostPreferences> build() async {
    final result = await ref.read(getUserPostPreferencesProvider)('me');
    return result.fold(
      (failure) => const UserPostPreferences.empty(),
      (preferences) => preferences,
    );
  }

  Future<void> hidePost(String postId) async {
    final current = state.value;
    if (current == null || current.hiddenPostIds.contains(postId)) return;
    final updated = current.copyWith(
      hiddenPostIds: [...current.hiddenPostIds, postId],
    );
    state = AsyncData(updated);
    final result = await ref.read(updateUserPostPreferencesProvider)(updated);
    result.fold(
      (failure) => state = AsyncData(current),
      (preferences) => state = AsyncData(preferences),
    );
  }

  Future<void> blockAuthor(String authorId) async {
    final current = state.value;
    if (current == null || current.blockedAuthorIds.contains(authorId)) return;
    final updated = current.copyWith(
      blockedAuthorIds: [...current.blockedAuthorIds, authorId],
    );
    state = AsyncData(updated);
    final result = await ref.read(updateUserPostPreferencesProvider)(updated);
    result.fold(
      (failure) => state = AsyncData(current),
      (preferences) => state = AsyncData(preferences),
    );
  }
}

// ── Feed ────────────────────────────────────────────────────────────

final postsFeedHasMoreProvider = StateProvider<bool>((ref) => true);
final postsFeedLoadingMoreProvider = StateProvider<bool>((ref) => false);

class PostsFeedNotifier extends AsyncNotifier<List<Post>> {
  int _currentPage = 0;

  @override
  Future<List<Post>> build() async {
    _currentPage = 0;
    Future.microtask(() {
      ref.read(postsFeedHasMoreProvider.notifier).state = true;
      ref.read(postsFeedLoadingMoreProvider.notifier).state = false;
    });
    return _fetchPosts(page: 0);
  }

  Future<List<Post>> _fetchPosts({required int page}) async {
    final result = await ref.read(getPostsProvider)(page: page, size: 100);
    return result.fold(
      (failure) => throw failure,
      (posts) {
        if (posts.length < 100) {
          Future.microtask(() {
            ref.read(postsFeedHasMoreProvider.notifier).state = false;
          });
        }
        return posts;
      },
    );
  }

  Future<void> loadMore() async {
    final hasMore = ref.read(postsFeedHasMoreProvider);
    final isLoadingMore = ref.read(postsFeedLoadingMoreProvider);
    if (isLoadingMore || !hasMore) return;
    ref.read(postsFeedLoadingMoreProvider.notifier).state = true;
    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _fetchPosts(page: nextPage);
      _currentPage = nextPage;
      final currentPosts = state.value ?? [];
      final existingIds = currentPosts.map((p) => p.id).toSet();
      final filteredNewPosts =
          newPosts.where((p) => !existingIds.contains(p.id)).toList();
      state = AsyncData([...currentPosts, ...filteredNewPosts]);
    } catch (e) {
      print('Error loading more posts: $e');
    } finally {
      ref.read(postsFeedLoadingMoreProvider.notifier).state = false;
    }
  }
}

final postsProvider = AsyncNotifierProvider<PostsFeedNotifier, List<Post>>(
  PostsFeedNotifier.new,
);

// ── Feed display ────────────────────────────────────────────────────

final feedPostsProvider = Provider<AsyncValue<List<Post>>>((ref) {
  final posts = ref.watch(postsProvider);
  final currentUser = ref.watch(currentUserProvider);
  final preferences = ref.watch(userPostPreferencesProvider);

  if (posts.isLoading || currentUser.isLoading || preferences.isLoading) {
    return const AsyncValue.loading();
  }

  if (posts.hasError) {
    return AsyncValue.error(posts.error!, posts.stackTrace!);
  }

  final postsData = posts.requireValue;
  final currentUserData =
      currentUser.hasError ? null : currentUser.requireValue;
  final preferencesData =
      preferences.hasError ? null : preferences.requireValue;

  return AsyncValue.data(
    PostFeedFilter.apply(
      posts: postsData,
      currentUser: currentUserData,
      preferences: preferencesData,
    ),
  );
});

// ── Create post ─────────────────────────────────────────────────────

final postVisibilityProvider =
    StateProvider<PostVisibility>((ref) => PostVisibility.public);

final createPostControllerProvider =
    AsyncNotifierProvider<CreatePostController, void>(
  CreatePostController.new,
);

class CreatePostController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(Post post) async {
    debugPrint('🚀 submit() called');
    state = const AsyncLoading();

    try {
      final List<PostMedia> uploadedMedia = [];
      final uploadUseCase = ref.read(uploadFileProvider);
      final visualAssets = ref.read(selectedPostMediaProvider);

      for (int i = 0; i < visualAssets.length; i++) {
        final asset = visualAssets[i];
        try {
          Uint8List? bytes = await asset.originBytes;
          if (bytes == null || bytes.isEmpty) {
            final file = await asset.file;
            if (file != null) {
              bytes = await file.readAsBytes();
            }
          }
          if (bytes == null || bytes.isEmpty) {
            bytes = await asset.thumbnailDataWithSize(const ThumbnailSize(1920, 1080));
          }
          if (bytes == null || bytes.isEmpty) continue;

          final rawTitle = await asset.titleAsync;
          final fileName = rawTitle.isNotEmpty ? rawTitle : 'media_$i.jpg';
          final mediaType =
              asset.type == AssetType.video ? MediaType.video : MediaType.image;
          final result = await uploadUseCase(bytes, fileName);
          result.fold(
            (failure) => throw failure,
            (cloudData) {
              final url = cloudData['url'] as String;
              uploadedMedia.add(PostMedia(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: mediaType,
                publicId: cloudData['public_id'] as String?,
                url: url,
              ));
            },
          );
        } catch (e) {
          debugPrint('Error processing asset $i: $e');
          rethrow;
        }
      }

      final docFiles = ref.read(selectedPostDocumentsProvider);
      for (int i = 0; i < docFiles.length; i++) {
        final pf = docFiles[i];
        try {
          final Uint8List? bytes = pf.bytes ?? (pf.path != null ? await File(pf.path!).readAsBytes() : null);
          if (bytes == null || bytes.isEmpty) continue;
          final result = await uploadUseCase(bytes, pf.name);
          result.fold(
            (failure) => throw failure,
            (cloudData) {
              final String url = cloudData['url'] as String;
              uploadedMedia.add(PostMedia(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: MediaType.document,
                url: url,
                publicId: cloudData['public_id'] as String?,
              ));
            },
          );
        } catch (e) {
          debugPrint('Error processing document $i: $e');
          rethrow;
        }
      }

      final existingMedia =
          post.media.where((m) => m.url.startsWith('http')).toList();
      final allMedia = [...existingMedia, ...uploadedMedia];

      final updatedPost = Post(
        id: post.id,
        authorId: post.authorId,
        visibility: post.visibility,
        authorName: post.authorName,
        authorAvatarUrl: post.authorAvatarUrl,
        timeAgo: post.timeAgo,
        isMultipleAuthors: post.isMultipleAuthors,
        content: post.content,
        media: allMedia,
        poll: post.poll,
        commentsCount: post.commentsCount,
        sharesCount: post.sharesCount,
        likesCount: post.likesCount,
        isLikedByMe: post.isLikedByMe,
        createdAt: post.createdAt,
      );

      final createResult = await ref.read(createPostProvider)(updatedPost);
      createResult.fold(
        (failure) => throw failure,
        (_) {
          state = const AsyncData(null);
          ref.invalidate(postsProvider);
          ref.read(selectedPostMediaProvider.notifier).clear();
          ref.read(selectedPostDocumentsProvider.notifier).clear();
        },
      );
    } catch (e, stack) {
      debugPrint('Error submitting post: $stack');
      state = AsyncError(
        e is Failure ? e : ServerFailure(e.toString()),
        stack,
      );
    }
  }
}

// ── Comments ────────────────────────────────────────────────────────

final commentsProvider =
    FutureProvider.family.autoDispose<List<Comment>, String>(
  (ref, postId) async {
    final currentUserAsync = ref.watch(currentUserProvider);
    final userId = currentUserAsync.requireValue.id;
    final result = await ref.watch(getCommentsByPostProvider)(
      GetCommentsByPostParams(postId: postId, userId: userId),
    );
    return result.fold(
      (failure) => throw failure,
      (comments) => comments,
    );
  },
);
