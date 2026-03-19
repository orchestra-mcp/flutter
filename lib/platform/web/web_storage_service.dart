// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-specific token and preference storage using the browser Storage APIs.
///
/// On non-web builds this file is never imported — conditional imports in
/// `token_storage.dart` select the native implementation instead.
class WebStorageService {
  static const _tokenKey = 'orchestra_access_token';

  // ── Session token (sessionStorage) ───────────────────────────────────────

  /// Persists [token] in `sessionStorage` under [_tokenKey].
  void saveSessionToken(String token) =>
      html.window.sessionStorage[_tokenKey] = token;

  /// Returns the stored session token, or `null` if absent.
  String? getSessionToken() => html.window.sessionStorage[_tokenKey];

  /// Removes the session token from `sessionStorage`.
  void clearSessionToken() => html.window.sessionStorage.remove(_tokenKey);

  // ── Local preferences (localStorage) ─────────────────────────────────────

  /// Persists [value] under [key] in `localStorage`.
  void saveLocalPref(String key, String value) =>
      html.window.localStorage[key] = value;

  /// Returns the stored preference value for [key], or `null` if absent.
  String? getLocalPref(String key) => html.window.localStorage[key];
}
