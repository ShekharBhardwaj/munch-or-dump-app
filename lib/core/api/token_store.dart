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

  /// In-memory memo of the stored token, so the Keychain is hit once per app
  /// launch instead of on every request. Static (there is a single Keychain
  /// entry to mirror) so the constructor can stay `const`. [write] and [clear]
  /// write through and keep it in sync.
  static String? _memo;

  Future<String?> read() async => _memo ??= await _storage.read(key: _tokenKey);

  Future<void> write(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _memo = token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    _memo = null;
  }
}
