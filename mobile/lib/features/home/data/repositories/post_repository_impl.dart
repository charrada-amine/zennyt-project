import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/current_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_post_preferences.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';
import '../models/post_model.dart';
import '../models/user_post_preferences_model.dart';
import '../models/comment_model.dart';
import '../services/posts_cache_service.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final PostsCacheService cacheService;

  static const int _maxPagesForCache = 10;

  PostRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.cacheService,
  });

  @override
  Future<Either<Failure, List<Post>>> getPosts({int page = 0, int size = 100}) async {
    final online = await networkInfo.isConnected;

    if (online) {
      try {
        if (page == 0) return await _fetchAndCacheFeed(size: size);
        final result = await remoteDataSource.getPosts(page: page, size: size);
        return Right(result.posts);
      } catch (_) {
        if (page == 0) return _loadCachedPosts();
        return const Right([]);
      }
    }

    if (page > 0) return const Right([]);
    return _loadCachedPosts();
  }

  Future<Either<Failure, T>> _tryApi<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(mapStatusCodeToFailure(e.statusCode, e.message));
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Post>> createPost(Post post) async {
    return _tryApi(() => remoteDataSource.createPost(
          PostModel(
            id: post.id,
            authorId: post.authorId,
            visibility: post.visibility,
            authorName: post.authorName,
            authorAvatarUrl: post.authorAvatarUrl,
            timeAgo: post.timeAgo,
            isMultipleAuthors: post.isMultipleAuthors,
            content: post.content,
            media: post.media,
            poll: post.poll,
            commentsCount: post.commentsCount,
            sharesCount: post.sharesCount,
            likesCount: post.likesCount,
            isLikedByMe: post.isLikedByMe,
            createdAt: post.createdAt,
          ),
        ));
  }

  @override
  Future<Either<Failure, CurrentUser>> getCurrentUser() async {
    return _tryApi(() => remoteDataSource.getCurrentUser());
  }

  @override
  Future<Either<Failure, UserPostPreferences>> getUserPostPreferences(
    String userId,
  ) async {
    return _tryApi(() => remoteDataSource.getUserPostPreferences(userId));
  }

  @override
  Future<Either<Failure, UserPostPreferences>> updateUserPostPreferences(
    UserPostPreferences preferences,
  ) async {
    return _tryApi(() => remoteDataSource.updateUserPostPreferences(
          UserPostPreferencesModel(
            id: preferences.id,
            hiddenPostIds: preferences.hiddenPostIds,
            blockedAuthorIds: preferences.blockedAuthorIds,
          ),
        ));
  }

  @override
  Future<Either<Failure, void>> likePost(String postId, String userId) async {
    return _tryApi(() async {
      await remoteDataSource.likePost(postId, userId);
    });
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId, String userId) async {
    return _tryApi(() async {
      await remoteDataSource.unlikePost(postId, userId);
    });
  }

  @override
  Future<Either<Failure, Comment>> addComment(Comment comment) async {
    return _tryApi(() async {
      final model = CommentModel.fromEntity(comment);
      return await remoteDataSource.addComment(model);
    });
  }

  @override
  Future<Either<Failure, List<Comment>>> getCommentsByPost(
      String postId, String userId) async {
    return _tryApi(() => remoteDataSource.getCommentsByPost(postId, userId));
  }

  @override
  Future<Either<Failure, Post>> votePoll(
    String postId,
    String optionId,
    String userId,
  ) async {
    return _tryApi(() => remoteDataSource.votePoll(postId, optionId, userId));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
      Uint8List bytes, String fileName) async {
    return _tryApi(() => remoteDataSource.uploadFile(bytes, fileName));
  }

  Future<Either<Failure, List<Post>>> _fetchAndCacheFeed({required int size}) async {
    final allPosts = <PostModel>[];
    var currentPage = 0;

    while (currentPage < _maxPagesForCache) {
      final result = await remoteDataSource.getPosts(page: currentPage, size: size);
      allPosts.addAll(result.posts);
      if (!result.hasMore) break;
      if (_hasCoveredCacheWindow(allPosts)) break;
      currentPage++;
    }

    await cacheService.savePosts(allPosts);
    await cacheService.saveLastSync(DateTime.now());
    
    return Right(allPosts);
  }

  bool _hasCoveredCacheWindow(List<PostModel> posts) {
    if (posts.isEmpty) return false;
    final latestDate = posts.first.createdAt;
    if (latestDate == null) return false;
    final cutoffDate = DateTime(
      latestDate.year,
      latestDate.month,
      latestDate.day,
    ).subtract(const Duration(days: 2));
    final oldestDate = posts.last.createdAt;
    if (oldestDate == null) return false;
    final oldestDay = DateTime(oldestDate.year, oldestDate.month, oldestDate.day);
    return !oldestDay.isAfter(cutoffDate);
  }

  Future<Either<Failure, List<Post>>> _loadCachedPosts() async {
    try {
      final cached = await cacheService.loadPosts();
      if (cached.isEmpty) return const Left(CacheFailure('Aucune publication en cache'));
      return Right(cached);
    } catch (_) {
      return const Left(CacheFailure('Aucune publication en cache'));
    }
  }
}
