import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/current_user_model.dart';
import '../models/paginated_posts_result.dart';
import '../models/post_model.dart';
import '../models/user_post_preferences_model.dart';
import '../models/comment_model.dart';

abstract class PostRemoteDataSource {
  Future<PaginatedPostsResult> getPosts({int page = 0, int size = 100});
  Future<PostModel> createPost(PostModel post);
  Future<CurrentUserModel> getCurrentUser();
  Future<UserPostPreferencesModel> getUserPostPreferences(String userId);
  Future<UserPostPreferencesModel> updateUserPostPreferences(
    UserPostPreferencesModel preferences,
  );
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  Future<CommentModel> addComment(CommentModel comment);
  Future<List<CommentModel>> getCommentsByPost(String postId, String userId);
  Future<PostModel> votePoll(String postId, String optionId, String userId);
  Future<Map<String, dynamic>> uploadFile(Uint8List bytes, String fileName);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final Dio dio;

  PostRemoteDataSourceImpl(this.dio);

  @override
  Future<PaginatedPostsResult> getPosts({int page = 0, int size = 100}) async {
    try {
      final res = await dio.get(
        '/posts',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      final data = res.data;
      final List<dynamic> rawItems = data is Map<String, dynamic>
          ? (data['content'] as List<dynamic>? ?? [])
          : (data as List<dynamic>);

      final List<PostModel> posts = [];
      for (final item in rawItems) {
        try {
          if (item is Map<String, dynamic>) {
            posts.add(PostModel.fromJson(item));
          }
        } catch (e, stack) {
          debugPrint('Error parsing post item: $e\n$stack');
        }
      }

      // Parse pagination metadata
      int totalElements = 0;
      bool hasMore = false;
      if (data is Map<String, dynamic> && data['page'] != null) {
        final pageMeta = data['page'] as Map<String, dynamic>;
        totalElements = (pageMeta['totalElements'] as num?)?.toInt() ?? 0;
        final bool isLast = pageMeta['last'] as bool? ?? true;
        hasMore = !isLast;
      } else {
        totalElements = posts.length;
        hasMore = false;
      }

      return PaginatedPostsResult(
        posts: posts,
        totalElements: totalElements,
        hasMore: hasMore,
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    try {
      final res = await dio.post(
        '/posts',
        data: post.toJson(),
      );
      return PostModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<CurrentUserModel> getCurrentUser() async {
    try {
      final res = await dio.get('/profiles/me');
      final data = res.data as Map<String, dynamic>;
      final avatarUrl = data['profileImageUrl'] as String? ??
          data['avatarUrl'] as String? ??
          data['cvUrl'] as String? ??
          '';
      return CurrentUserModel(
        id: data['userId']?.toString() ?? data['id']?.toString() ?? '',
        name: data['currentPosition'] as String? ?? 'User',
        avatarUrl: avatarUrl,
        friendIds: const [],
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<UserPostPreferencesModel> getUserPostPreferences(String userId) async {
    try {
      final res = await dio.get(
        '/users/me/post-preferences',
      );
      return UserPostPreferencesModel.fromJson(
          res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<UserPostPreferencesModel> updateUserPostPreferences(
    UserPostPreferencesModel preferences,
  ) async {
    try {
      final res = await dio.put(
        '/users/me/post-preferences',
        data: preferences.toJson(),
      );
      return UserPostPreferencesModel.fromJson(
          res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    try {
      await dio.post(
        '/posts/$postId/likes',
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await dio.delete(
        '/posts/$postId/likes',
      );
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<CommentModel> addComment(CommentModel comment) async {
    try {
      final res = await dio.post(
        '/posts/${comment.postId}/comments',
        data: comment.toJson(),
      );
      return CommentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<List<CommentModel>> getCommentsByPost(
    String postId,
    String userId,
  ) async {
    try {
      final res = await dio.get(
        '/posts/$postId/comments',
      );
      final List<dynamic> items = res.data as List<dynamic>;

      return items
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<PostModel> votePoll(String postId, String optionId, String userId) async {
    try {
      final res = await dio.post(
        '/posts/$postId/polls/vote',
        data: {'optionId': optionId},
      );
      return PostModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
      Uint8List bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'filename': fileName,
      });
      final res = await dio.post('/media/upload', data: formData);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
