/// Immutable non-scoring controls captured by the backend when a session starts.
class GameRuntimeSnapshot {
  const GameRuntimeSnapshot({
    this.bankId,
    this.bankCode,
    this.bankVersion,
    this.bankContentType,
    this.settingsVersion,
    this.modifiersVersion,
    this.settings = const {},
    this.modifiers = const {},
  });

  final String? bankId;
  final String? bankCode;
  final int? bankVersion;
  final String? bankContentType;
  final int? settingsVersion;
  final int? modifiersVersion;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> modifiers;

  factory GameRuntimeSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GameRuntimeSnapshot();
    return GameRuntimeSnapshot(
      bankId: json['bankId'] as String?,
      bankCode: json['bankCode'] as String?,
      bankVersion: (json['bankVersion'] as num?)?.toInt(),
      bankContentType: json['bankContentType'] as String?,
      settingsVersion: (json['settingsVersion'] as num?)?.toInt(),
      modifiersVersion: (json['modifiersVersion'] as num?)?.toInt(),
      settings: _freezeMap(json['settings'] as Map<String, dynamic>?),
      modifiers: _freezeMap(json['modifiers'] as Map<String, dynamic>?),
    );
  }

  bool settingBool(String key, {required bool fallback}) =>
      settings[key] is bool ? settings[key] as bool : fallback;

  bool modifierBool(String key, {required bool fallback}) =>
      modifiers[key] is bool ? modifiers[key] as bool : fallback;

  int modifierInt(
    String key, {
    required int fallback,
    required int minimum,
    required int maximum,
  }) {
    final value = modifiers[key];
    if (value is! num) return fallback;
    return value.toInt().clamp(minimum, maximum);
  }
}

Map<String, dynamic> _freezeMap(Map<String, dynamic>? source) =>
    Map<String, dynamic>.unmodifiable(
      (source ?? const {}).map(
        (key, value) => MapEntry(key, _freezeValue(value)),
      ),
    );

dynamic _freezeValue(dynamic value) {
  if (value is Map<String, dynamic>) return _freezeMap(value);
  if (value is List<dynamic>) {
    return List<dynamic>.unmodifiable(value.map(_freezeValue));
  }
  return value;
}
