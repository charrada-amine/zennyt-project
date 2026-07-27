import 'package:equatable/equatable.dart';

class CurrentUser extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final List<String> friendIds;

  const CurrentUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.friendIds = const [],
  });

  factory CurrentUser.empty() => const CurrentUser(
        id: '',
        name: '',
        avatarUrl: '',
      );

  bool isFriendWith(String authorId) => friendIds.contains(authorId);

  @override
  List<Object?> get props => [id, name, avatarUrl, friendIds];
}
