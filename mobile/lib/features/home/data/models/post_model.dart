import '../../domain/entities/post.dart';

class PostMediaModel extends PostMedia {
  const PostMediaModel({
    required super.id,
    required super.type,
    required super.url,
  });

  factory PostMediaModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.toUpperCase() ?? 'IMAGE';
    final rawUrl = (json['url'] ?? json['imageUrl'] ?? json['mediaUrl'] ?? json['photoUrl']) as String? ?? '';
    final rawId = (json['id'] ?? json['publicId'] ?? DateTime.now().millisecondsSinceEpoch).toString();

    return PostMediaModel(
      id: rawId,
      type: MediaType.values.firstWhere(
        (e) => e.name.toUpperCase() == rawType,
        orElse: () => MediaType.image,
      ),
      url: rawUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name.toUpperCase(),
      'url': url,
    };
  }
}

class PollOptionModel extends PollOption {
  const PollOptionModel({
    required super.id,
    required super.text,
    super.voteCount = 0,
    super.isSelected = false,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'voteCount': voteCount,
      'isSelected': isSelected,
    };
  }
}

class PollModel extends Poll {
  const PollModel({
    required super.question,
    required super.options,
    super.totalVotes = 0,
    super.duration = '3 days',
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>;
    return PollModel(
      question: json['question'] as String,
      options: optionsJson
          .map((e) => PollOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalVotes: (json['totalVotes'] as num?)?.toInt() ?? 0,
      duration: json['duration'] as String? ?? '3 days',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options
          .map(
            (o) => o is PollOptionModel
                ? o.toJson()
                : PollOptionModel(
                    id: o.id,
                    text: o.text,
                    voteCount: o.voteCount,
                    isSelected: o.isSelected,
                  ).toJson(),
          )
          .toList(),
      'totalVotes': totalVotes,
      'duration': duration,
    };
  }
}

class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.authorId,
    super.visibility = PostVisibility.public,
    required super.authorName,
    required super.authorAvatarUrl,
    required super.timeAgo,
    super.isMultipleAuthors = false,
    super.content,
    super.media = const [],
    super.poll,
    required super.commentsCount,
    required super.sharesCount,
    required super.likesCount,
    required super.isLikedByMe,
    super.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'] as List<dynamic>?;
    final fallbackImageUrl = (json['imageUrl'] ?? json['photoUrl'] ?? json['mediaUrl']) as String?;

    final List<PostMedia> mediaList = [];
    if (mediaJson != null && mediaJson.isNotEmpty) {
      for (final item in mediaJson) {
        try {
          if (item is Map<String, dynamic>) {
            final pm = PostMediaModel.fromJson(item);
            if (pm.url.isNotEmpty) mediaList.add(pm);
          } else if (item is String && item.isNotEmpty) {
            mediaList.add(PostMediaModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: MediaType.image,
              url: item,
            ));
          }
        } catch (_) {}
      }
    }

    if (mediaList.isEmpty && fallbackImageUrl != null && fallbackImageUrl.isNotEmpty) {
      mediaList.add(PostMediaModel(
        id: 'legacy-image',
        type: MediaType.image,
        url: fallbackImageUrl,
      ));
    }

    final pollJson = json['poll'] as Map<String, dynamic>?;
    final Poll? poll = pollJson != null ? PollModel.fromJson(pollJson) : null;

    DateTime? createdAt;
    final createdAtRaw = json['createdAt'];
    if (createdAtRaw != null) {
      if (createdAtRaw is String) {
        createdAt = DateTime.tryParse(createdAtRaw);
      } else if (createdAtRaw is num) {
        createdAt =
            DateTime.fromMillisecondsSinceEpoch((createdAtRaw * 1000).toInt());
      }
    }

    return PostModel(
      id: (json['id'] ?? '').toString(),
      authorId: (json['authorId'] ?? json['authorName'] ?? '').toString(),
      visibility: _parseVisibility(json['visibility'] as String?),
      authorName: (json['authorName'] ?? json['author'] ?? 'User').toString(),
      authorAvatarUrl: (json['authorPhotoUrl'] ?? json['authorAvatarUrl'] ?? json['profileImageUrl'] ?? '').toString(),
      timeAgo: (json['timeAgo'] ?? '').toString(),
      isMultipleAuthors: json['isMultipleAuthors'] as bool? ?? false,
      content: json['content'] as String?,
      media: mediaList,
      poll: poll,
      commentsCount: json['commentsCount']?.toString() ?? '0',
      sharesCount: json['sharesCount']?.toString() ?? '0',
      likesCount: json['likesCount']?.toString() ?? '0',
      isLikedByMe: json['isLikedByMe'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    final firstImageUrl = media.isNotEmpty ? media.first.url : null;
    return {
      'id': id,
      'authorId': authorId,
      'visibility': visibility.name.toUpperCase(),
      'authorName': authorName,
      'authorPhotoUrl': authorAvatarUrl,
      'imageUrl': firstImageUrl,
      'timeAgo': timeAgo,
      'isMultipleAuthors': isMultipleAuthors,
      'content': content,
      'media': media
          .map(
            (m) => m is PostMediaModel
                ? m.toJson()
                : PostMediaModel(
                    id: m.id,
                    type: m.type,
                    url: m.url,
                  ).toJson(),
          )
          .toList(),
      'poll': poll != null
          ? (poll is PollModel
              ? (poll as PollModel).toJson()
              : PollModel(
                  question: poll!.question,
                  options: poll!.options
                      .map(
                        (o) => PollOptionModel(
                          id: o.id,
                          text: o.text,
                          voteCount: o.voteCount,
                          isSelected: o.isSelected,
                        ),
                      )
                      .toList(),
                  totalVotes: poll!.totalVotes,
                  duration: poll!.duration,
                ).toJson())
          : null,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likesCount': likesCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static PostVisibility _parseVisibility(String? value) {
    return PostVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PostVisibility.public,
    );
  }
}
