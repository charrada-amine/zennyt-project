import '../../../core/constants/app_assets.dart';
import '../domain/entities/feed_post.dart';

/// Static data backing the home feed preview.
class HomeRepository {
  const HomeRepository();

  /// Posts shown in the Home social feed.
  List<FeedPost> getFeedPosts() => const [
    FeedPost(
      author: 'Anna Mary',
      avatar: AppAssets.avatar2,
      others: 'and 2 others',
      timeAgo: '3 Hours ago',
      text:
          "\u{1F44B} Hey guys..\ncheck out this beautiful landing page for JW "
          "company I just finished for a client. \u{1F604}",
      link: "https://www.landingpage'slink.com",
      comments: '3.4k',
      shares: '46',
      likedBy: 'Liked by Anna & 361k others',
    ),
    FeedPost(
      author: 'Millie Brown',
      avatar: AppAssets.avatar3,
      timeAgo: '2 Hours ago',
      image: AppAssets.feedLanding,
      comments: '3.4k',
      shares: '46',
      likedBy: 'Liked by Anna & 361k others',
    ),
  ];
}
