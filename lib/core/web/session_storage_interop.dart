import 'package:web/web.dart' as web;

/// Sets [key] → [value] in window.sessionStorage.
void sessionStorageSet(String key, String value) =>
    web.window.sessionStorage.setItem(key, value);

/// Returns the value for [key] from window.sessionStorage, or null.
String? sessionStorageGet(String key) =>
    web.window.sessionStorage.getItem(key);

/// Removes [key] from window.sessionStorage.
void sessionStorageRemove(String key) =>
    web.window.sessionStorage.removeItem(key);
