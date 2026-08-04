import '../models/feed_post_model.dart';

/// Source de données du fil.
abstract class FeedLocalDataSource {
  Future<List<FeedPostModel>> getFeed();
}

/// Implémentation **mock** — données factices en dur.
///
/// Le contexte Engagement (fil social) n'est pas encore exposé par le backend ;
/// en attendant, l'écran consomme ces données. Quand l'API existera, il suffira
/// d'ajouter un `FeedRemoteDataSource` (Dio) et de basculer dans le repository,
/// sans toucher à la présentation.
class FeedMockDataSource implements FeedLocalDataSource {
  @override
  Future<List<FeedPostModel>> getFeed() async {
    // Petite latence pour rendre l'état de chargement visible.
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      FeedPostModel(
        id: '1',
        authorName: 'Anna Mary',
        coauthors: 'and 2 others',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=45',
        timeAgo: '3 Hours ago',
        text: "👋 Hey guys.. check out this beautiful landing page for JW "
            "company I just finished for a client. 😊",
        linkUrl: "https://www.landingpageslink.com",
        comments: '3.4k',
        shares: '46',
        likedBy: 'Liked by Anna & 361k others',
      ),
      FeedPostModel(
        id: '2',
        authorName: 'Millie Brown',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=32',
        timeAgo: '2 Hours ago',
        imageUrl: 'https://picsum.photos/seed/landingpage/900/560',
        comments: '3.4k',
        shares: '46',
        likedBy: 'Liked by Anna & 361k others',
      ),
      FeedPostModel(
        id: '3',
        authorName: 'Michael Johnson',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=12',
        timeAgo: '2m',
        text: 'Great work! Well done girl. 👏',
        comments: '128',
        shares: '4',
        likedBy: 'Liked by 24 others',
      ),
      FeedPostModel(
        id: '4',
        authorName: 'Sophia Martin',
        coauthors: 'and 5 others',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=20',
        timeAgo: '5 Hours ago',
        text: 'Just shipped a new design system for our mobile app. '
            'Feedback welcome! 🚀',
        imageUrl: 'https://picsum.photos/seed/designsystem/900/560',
        comments: '892',
        shares: '73',
        likedBy: 'Liked by Millie & 120k others',
      ),
    ];
  }
}
