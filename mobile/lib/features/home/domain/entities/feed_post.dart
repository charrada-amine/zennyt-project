import 'package:flutter/foundation.dart';

/// A single post in the Home social feed (static maquette data).
@immutable
class FeedPost {
  const FeedPost({
    required this.author,
    required this.avatar,
    required this.timeAgo,
    required this.comments,
    required this.shares,
    required this.likedBy,
    this.others,
    this.text,
    this.link,
    this.image,
  });

  final String author;
  final String avatar;

  /// e.g. "and 2 others" shown next to the author name.
  final String? others;
  final String timeAgo;

  /// Optional body text of the post.
  final String? text;

  /// Optional URL rendered as a highlighted link beneath [text].
  final String? link;

  /// Optional attached image URL.
  final String? image;

  final String comments;
  final String shares;
  final String likedBy;
}
