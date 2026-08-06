import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for the JWT access token, the rotating refresh token and a
/// cached copy of the current user (for instant startup).
///
/// Backed by the OS keychain (iOS) / keystore (Android) via
/// [FlutterSecureStorage]; never use plain SharedPreferences for secrets.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'auth.accessToken';
  static const _kRefreshToken = 'auth.refreshToken';
  static const _kUser = 'auth.user';

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<String?> readUser() => _storage.read(key: _kUser);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) =>
      _storage.write(key: _kAccessToken, value: accessToken);

  Future<void> saveUser(String userJson) =>
      _storage.write(key: _kUser, value: userJson);

  Future<void> clear() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUser);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

/// Instance par défaut pour les call sites hors Riverpod (ex. le singleton
/// [WebSocketService]) : même stockage sécurisé que [secureStorageProvider]
/// (le paramètre déprécié est ignoré par la lib, données migrées à l'accès).
final defaultTokenStorage = TokenStorage(const FlutterSecureStorage());
