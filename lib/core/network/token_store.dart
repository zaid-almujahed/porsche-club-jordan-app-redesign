import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the bearer token outside the widget tree.
abstract interface class TokenStore {
  Future<String?> read();

  Future<String?> readRefreshToken();

  Future<void> write(String token, {String? refreshToken});

  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'pcj_access_token';
  static const String _refreshTokenKey = 'pcj_refresh_token';

  final FlutterSecureStorage _storage;
  String? _cachedToken;
  String? _cachedRefreshToken;
  bool _hasLoadedToken = false;
  bool _hasLoadedRefreshToken = false;

  @override
  Future<String?> read() async {
    if (_hasLoadedToken) return _cachedToken;
    _cachedToken = await _readOrReset(_tokenKey);
    _hasLoadedToken = true;
    return _cachedToken;
  }

  @override
  Future<String?> readRefreshToken() async {
    if (_hasLoadedRefreshToken) return _cachedRefreshToken;
    _cachedRefreshToken = await _readOrReset(_refreshTokenKey);
    _hasLoadedRefreshToken = true;
    return _cachedRefreshToken;
  }

  /// Secure storage can become unreadable (e.g. after the OS resets its
  /// keystore). Treat that as "signed out" and clear the saved login, so the
  /// member lands on Welcome instead of a launch screen that keeps failing.
  Future<String?> _readOrReset(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await _deleteQuietly(_tokenKey);
      await _deleteQuietly(_refreshTokenKey);
      return null;
    }
  }

  Future<void> _deleteQuietly(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Nothing more can be done; the in-memory session is already cleared.
    }
  }

  @override
  Future<void> write(String token, {String? refreshToken}) async {
    final String cleanToken = token.trim();
    final String? cleanRefreshToken = refreshToken?.trim();
    _cachedToken = cleanToken;
    _cachedRefreshToken = cleanRefreshToken;
    _hasLoadedToken = true;
    _hasLoadedRefreshToken = true;
    await _storage.write(key: _tokenKey, value: cleanToken);
    if (cleanRefreshToken == null || cleanRefreshToken.isEmpty) {
      await _storage.delete(key: _refreshTokenKey);
    } else {
      await _storage.write(key: _refreshTokenKey, value: cleanRefreshToken);
    }
  }

  @override
  Future<void> clear() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _hasLoadedToken = true;
    _hasLoadedRefreshToken = true;
    // Signing out must never fail because storage is unreadable.
    await Future.wait(<Future<void>>[
      _deleteQuietly(_tokenKey),
      _deleteQuietly(_refreshTokenKey),
    ]);
  }
}
