import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAccessToken = 'orchestra_access_token';
const _kRefreshToken = 'orchestra_refresh_token';

/// Stores auth tokens in **both** [FlutterSecureStorage] (Keychain/KeyStore)
/// and [SharedPreferences] so the token survives across app restarts even when
/// Keychain access is flaky (sandboxed macOS debug builds, access-group
/// mismatches, etc.).
///
/// On read the secure storage is tried first; if it returns null or throws,
/// [SharedPreferences] acts as a durable fallback.
class TokenStorage {
  const TokenStorage();

  static const _secure = FlutterSecureStorage();

  // ── Write ─────────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Always persist to SharedPreferences (reliable across restarts).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);

    // Also try secure storage (best-effort).
    try {
      await Future.wait([
        _secure.write(key: _kAccessToken, value: accessToken),
        _secure.write(key: _kRefreshToken, value: refreshToken),
      ]);
    } on PlatformException catch (e) {
      debugPrint('[TokenStorage] Secure write failed: $e');
    }
  }

  // ── Read ──────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() => _read(_kAccessToken);
  Future<String?> getRefreshToken() => _read(_kRefreshToken);

  Future<String?> _read(String key) async {
    // Try secure storage first.
    try {
      final value = await _secure.read(key: key);
      if (value != null && value.isNotEmpty) return value;
    } on PlatformException catch (e) {
      debugPrint('[TokenStorage] Secure read failed: $e');
    }
    // Fall back to SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // ── Clear ─────────────────────────────────────────────────────────────

  Future<void> clearTokens() async {
    // Clear both stores.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);

    try {
      await Future.wait([
        _secure.delete(key: _kAccessToken),
        _secure.delete(key: _kRefreshToken),
      ]);
    } on PlatformException catch (e) {
      debugPrint('[TokenStorage] Secure delete failed: $e');
    }
  }
}
