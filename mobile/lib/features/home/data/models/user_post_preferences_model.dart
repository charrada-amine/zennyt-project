import '../../domain/entities/user_post_preferences.dart';

class UserPostPreferencesModel extends UserPostPreferences {
  const UserPostPreferencesModel({
    required super.id,
    super.hiddenPostIds = const [],
    super.blockedAuthorIds = const [],
  });

  factory UserPostPreferencesModel.fromJson(Map<String, dynamic> json) {
    final hiddenJson = json['hiddenPostIds'] as List<dynamic>?;
    final blockedJson = json['blockedAuthorIds'] as List<dynamic>?;
    return UserPostPreferencesModel(
      id: json['id'] as String,
      hiddenPostIds: hiddenJson?.map((e) => e as String).toList() ?? const [],
      blockedAuthorIds:
          blockedJson?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hiddenPostIds': hiddenPostIds,
      'blockedAuthorIds': blockedAuthorIds,
    };
  }

  @override
  UserPostPreferencesModel copyWith({
    String? id,
    List<String>? hiddenPostIds,
    List<String>? blockedAuthorIds,
  }) {
    return UserPostPreferencesModel(
      id: id ?? this.id,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      blockedAuthorIds: blockedAuthorIds ?? this.blockedAuthorIds,
    );
  }
}
