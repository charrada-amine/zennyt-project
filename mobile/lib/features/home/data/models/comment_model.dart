import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.authorId,
    required super.authorName,
    super.authorAvatarUrl,
    required super.content,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    
    final dynamic raw = json['createdAt'];
    DateTime createdAt;
    if (raw is num) {
      
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (raw.toDouble() * 1000).toInt(),
      );
    } else if (raw is String) {
      createdAt = DateTime.parse(raw);
    } else {
      createdAt = DateTime.now();
    }

    return CommentModel(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromEntity(Comment entity) {
    return CommentModel(
      id: entity.id,
      postId: entity.postId,
      authorId: entity.authorId,
      authorName: entity.authorName,
      authorAvatarUrl: entity.authorAvatarUrl,
      content: entity.content,
      createdAt: entity.createdAt,
    );
  }
}
