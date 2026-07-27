import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/current_user.dart';
import '../entities/post.dart';
import '../entities/user_post_preferences.dart';
import '../entities/comment.dart';

abstract class PostRepository {
  Future<Either<Failure, List<Post>>> getPosts({int page = 0, int size = 100});
  Future<Either<Failure, Post>> createPost(Post post);
  Future<Either<Failure, CurrentUser>> getCurrentUser();
  Future<Either<Failure, UserPostPreferences>> getUserPostPreferences(
    String userId,
  );
  Future<Either<Failure, UserPostPreferences>> updateUserPostPreferences(
    UserPostPreferences preferences,
  );
  Future<Either<Failure, void>> likePost(String postId, String userId);
  Future<Either<Failure, void>> unlikePost(String postId, String userId);
  Future<Either<Failure, Comment>> addComment(Comment comment);
  Future<Either<Failure, List<Comment>>> getCommentsByPost(
    String postId,
    String userId,
  );
  Future<Either<Failure, Post>> votePoll(
    String postId,
    String optionId,
    String userId,
  );
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
    Uint8List bytes,
    String fileName,
  );
}
