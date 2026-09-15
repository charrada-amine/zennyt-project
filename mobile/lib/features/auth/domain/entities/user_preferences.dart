import 'package:equatable/equatable.dart';

/// Server-synced app preferences (`GET/PUT /users/me/preferences`).
///
/// Accessibility (contrast, text size) and the notifications toggle live here so
/// they survive a reinstall or a new device. The local providers stay the source
/// for instant UI feedback; this model is the persisted mirror.
class UserPreferences extends Equatable {
  final bool notificationsEnabled;
  final bool highContrast;
  final int textSizePx;

  const UserPreferences({
    required this.notificationsEnabled,
    required this.highContrast,
    required this.textSizePx,
  });

  static const UserPreferences defaults = UserPreferences(
    notificationsEnabled: true,
    highContrast: true,
    textSizePx: 18,
  );

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        highContrast: json['highContrast'] as bool? ?? true,
        textSizePx: (json['textSizePx'] as num?)?.toInt() ?? 18,
      );

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'highContrast': highContrast,
        'textSizePx': textSizePx,
      };

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? highContrast,
    int? textSizePx,
  }) =>
      UserPreferences(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        highContrast: highContrast ?? this.highContrast,
        textSizePx: textSizePx ?? this.textSizePx,
      );

  @override
  List<Object?> get props => [notificationsEnabled, highContrast, textSizePx];
}
