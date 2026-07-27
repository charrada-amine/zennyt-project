import '../../domain/entities/current_user.dart';

class CurrentUserModel extends CurrentUser {
  const CurrentUserModel({
    required super.id,
    required super.name,
    required super.avatarUrl,
    super.friendIds = const [],
  });

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    final friendIdsJson = json['friendIds'] as List<dynamic>?;
    return CurrentUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      friendIds: friendIdsJson?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'friendIds': friendIds,
    };
  }
}
