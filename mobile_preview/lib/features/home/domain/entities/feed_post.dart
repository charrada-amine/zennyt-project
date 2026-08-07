import 'package:equatable/equatable.dart';

/// Entité métier d'une publication du fil d'actualité — pure, sans framework.
///
/// La couche data possède un [FeedPostModel] séparé (avec fromJson) qui se
/// mappe vers cette entité.
class FeedPost extends Equatable {
  final String id;
  final String authorName;
  final String authorAvatarUrl;
  final String? coauthors; // ex. "and 2 others"
  final String timeAgo; // ex. "3 Hours ago"
  final String? text;
  final String? linkUrl;
  final String? imageUrl;
  final String comments; // libellé prêt à afficher, ex. "3.4k"
  final String shares; // ex. "46"
  final String likedBy; // ex. "Liked by Anna & 361k others"

  const FeedPost({
    required this.id,
    required this.authorName,
    required this.authorAvatarUrl,
    this.coauthors,
    required this.timeAgo,
    this.text,
    this.linkUrl,
    this.imageUrl,
    this.comments = '0',
    this.shares = '0',
    this.likedBy = '',
  });

  @override
  List<Object?> get props => [
        id, authorName, authorAvatarUrl, coauthors, timeAgo,
        text, linkUrl, imageUrl, comments, shares, likedBy,
      ];
}
