import '../../domain/entities/feed_post.dart';

/// DTO de la couche data : sérialisation JSON + mapping vers l'entité domaine.
///
/// Séparé de l'entité [FeedPost] pour que le domaine ne dépende pas du format
/// de l'API. Le jour où le contexte Engagement expose un vrai fil, seul ce
/// modèle (et le remote datasource) changent.
class FeedPostModel {
  final String id;
  final String authorName;
  final String authorAvatarUrl;
  final String? coauthors;
  final String timeAgo;
  final String? text;
  final String? linkUrl;
  final String? imageUrl;
  final String comments;
  final String shares;
  final String likedBy;

  const FeedPostModel({
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

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    return FeedPostModel(
      id: json['id'] as String,
      authorName: json['authorName'] as String? ?? '',
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      coauthors: json['coauthors'] as String?,
      timeAgo: json['timeAgo'] as String? ?? '',
      text: json['text'] as String?,
      linkUrl: json['linkUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      comments: json['comments'] as String? ?? '0',
      shares: json['shares'] as String? ?? '0',
      likedBy: json['likedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'coauthors': coauthors,
        'timeAgo': timeAgo,
        'text': text,
        'linkUrl': linkUrl,
        'imageUrl': imageUrl,
        'comments': comments,
        'shares': shares,
        'likedBy': likedBy,
      };

  FeedPost toEntity() => FeedPost(
        id: id,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        coauthors: coauthors,
        timeAgo: timeAgo,
        text: text,
        linkUrl: linkUrl,
        imageUrl: imageUrl,
        comments: comments,
        shares: shares,
        likedBy: likedBy,
      );
}
