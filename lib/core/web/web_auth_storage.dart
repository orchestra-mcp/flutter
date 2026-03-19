import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orchestra/core/web/session_storage_interop.dart'
    if (dart.library.io) 'package:orchestra/core/web/session_storage_stub.dart';

const _kAccessToken = 'orchestra_access_token';
const _kRefreshToken = 'orchestra_refresh_token';

/// Platform-aware auth token storage.
///
/// On web: delegates to window.sessionStorage (cleared when the tab closes,
/// which is the recommended approach for access tokens on web).
/// On native (iOS, Android, macOS, Windows, Linux): falls back to an
/// in-memory map — the real native implementation uses [TokenStorage] backed
/// by flutter_secure_storage instead.
class WebAuthStorage {
  WebAuthStorage._();
  static final WebAuthStorage _instance = WebAuthStorage._();
  factory WebAuthStorage() => _instance;

  // In-memory fallback used on native platforms.
  final Map<String, String> _memory = {};

  /// Persists [accessToken] and [refreshToken].
  void saveTokens({required String accessToken, required String refreshToken}) {
    _write(_kAccessToken, accessToken);
    _write(_kRefreshToken, refreshToken);
  }

  /// Returns the stored access token, or null if absent.
  String? getAccessToken() => _read(_kAccessToken);

  /// Returns the stored refresh token, or null if absent.
  String? getRefreshToken() => _read(_kRefreshToken);

  /// Removes all stored tokens from the active storage backend.
  void clearTokens() {
    _delete(_kAccessToken);
    _delete(_kRefreshToken);
  }

  void _write(String key, String value) {
    if (kIsWeb) {
      sessionStorageSet(key, value);
    } else {
      _memory[key] = value;
    }
  }

  String? _read(String key) {
    if (kIsWeb) return sessionStorageGet(key);
    return _memory[key];
  }

  void _delete(String key) {
    if (kIsWeb) {
      sessionStorageRemove(key);
    } else {
      _memory.remove(key);
    }
  }
}
