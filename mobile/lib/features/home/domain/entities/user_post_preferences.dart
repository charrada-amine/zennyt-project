import 'package:equatable/equatable.dart';

class UserPostPreferences extends Equatable {
  final String id;
  final List<String> hiddenPostIds;
  final List<String> blockedAuthorIds;

  const UserPostPreferences({
    required this.id,
    this.hiddenPostIds = const [],
    this.blockedAuthorIds = const [],
  });
  const UserPostPreferences.empty()
      : id = '',
        hiddenPostIds = const [],
        blockedAuthorIds = const [];

  UserPostPreferences copyWith({
    String? id,
    List<String>? hiddenPostIds,
    List<String>? blockedAuthorIds,
  }) {
    return UserPostPreferences(
      id: id ?? this.id,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      blockedAuthorIds: blockedAuthorIds ?? this.blockedAuthorIds,
    );
  }

  bool isPostHidden(String postId) => hiddenPostIds.contains(postId);

  bool isAuthorBlocked(String authorId) => blockedAuthorIds.contains(authorId);

  @override
  List<Object?> get props => [id, hiddenPostIds, blockedAuthorIds];
}
