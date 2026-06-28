/// Token pair returned by `/auth/register`, `/auth/login`, `/auth/refresh`.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// Access-token lifetime in seconds.
  final int expiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    tokenType: (json['tokenType'] ?? 'Bearer') as String,
    expiresIn: (json['expiresIn'] ?? 0) as int,
  );
}
