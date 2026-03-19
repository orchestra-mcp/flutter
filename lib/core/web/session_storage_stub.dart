/// No-op stubs used on non-web (dart:io) targets.
///
/// These are never called at runtime — every call site in [WebAuthStorage]
/// is guarded by `if (kIsWeb)` — but they must exist so the conditional
/// import in web_auth_storage.dart compiles on all platforms.

// ignore_for_file: avoid_unused_parameters

/// No-op: native platforms use flutter_secure_storage instead.
void sessionStorageSet(String key, String value) {}

/// No-op: returns null on native platforms.
String? sessionStorageGet(String key) => null;

/// No-op: nothing to remove on native platforms.
void sessionStorageRemove(String key) {}
