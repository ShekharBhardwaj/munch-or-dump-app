import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT in the platform keystore (iOS Keychain / Android Keystore).
///
/// Mobile uses Bearer-token auth: the API reads the `Authorization` header
/// before the browser-only `mod_token` cookie (see API `shared/auth.py`), so
/// the cookie path is irrelevant here.
class TokenStore {
  const TokenStore([
    this._storage = const FlutterSecureStorage(
      // Keep the token device-local (out of iCloud Keychain / backups) and
      // readable only after first unlock — it's a re-authable session token.
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ]);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'munchordump_token';

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
