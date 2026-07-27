import 'package:equatable/equatable.dart';

enum PostVisibility {
  public,
  friends,
}

enum MediaType {
  image,
  video,
  document,
}

class PostMedia extends Equatable {
  final String id;
  final MediaType type;
  final String url;
  final String? publicId;

  const PostMedia({
    required this.id,
    required this.type,
    required this.url,
    this.publicId,
  });

  @override
  List<Object?> get props => [id, type, url, publicId];
}

class PollOption extends Equatable {
  final String id;
  final String text;
  final int voteCount;
  final bool isSelected;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.isSelected = false,
  });

  PollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
    bool? isSelected,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [id, text, voteCount, isSelected];
}

class Poll extends Equatable {
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final String duration;

  const Poll({
    required this.question,
    required this.options,
    this.totalVotes = 0,
    this.duration = '3 days',
  });

  Poll copyWith({
    String? question,
    List<PollOption>? options,
    int? totalVotes,
    String? duration,
  }) {
    return Poll(
      question: question ?? this.question,
      options: options ?? this.options,
      totalVotes: totalVotes ?? this.totalVotes,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [question, options, totalVotes, duration];
}

class Post extends Equatable {
  final String id;
  final String authorId;
  final PostVisibility visibility;
  final String authorName;
  final String authorAvatarUrl;
  final String timeAgo;
  final bool isMultipleAuthors;
  final String? content;
  final List<PostMedia> media;
  final Poll? poll;
  final String commentsCount;
  final String sharesCount;
  final String likesCount;
  final bool isLikedByMe;
  final DateTime? createdAt;

  const Post({
    required this.id,
    required this.authorId,
    this.visibility = PostVisibility.public,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.timeAgo,
    this.isMultipleAuthors = false,
    this.content,
    this.media = const [],
    this.poll,
    required this.commentsCount,
    required this.sharesCount,
    required this.likesCount,
    required this.isLikedByMe,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        visibility,
        authorName,
        authorAvatarUrl,
        timeAgo,
        isMultipleAuthors,
        content,
        media,
        poll,
        commentsCount,
        sharesCount,
        likesCount,
        isLikedByMe,
        createdAt,
      ];
}
