import '../../domain/entities/current_user.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_post_preferences.dart';

class PostFeedFilter {
  static List<Post> apply({
    required List<Post> posts,
    CurrentUser? currentUser,
    UserPostPreferences? preferences,
  }) {
    if (currentUser == null || preferences == null) return posts;

    return posts.where((post) {
      if (preferences.isPostHidden(post.id)) return false;
      if (preferences.isAuthorBlocked(post.authorId)) return false;

      if (post.authorId == currentUser.id) return true;

      if (post.visibility == PostVisibility.friends &&
          !currentUser.isFriendWith(post.authorId)) {
        return false;
      }

      return true;
    }).toList();
  }
}
