import 'package:equatable/equatable.dart';

/// Entité métier Commentaire.
class Comment extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorName,
        authorAvatarUrl,
        content,
        createdAt,
      ];
}
