import 'package:orchestra/core/config/env.dart';

/// Resolves an avatar URL that may be null, empty, or a relative server path.
///
/// Returns `null` for null/empty input.
/// Prepends [Env.apiBaseUrl] to relative paths (starting with `/`).
/// Returns absolute URLs as-is.
///
/// For `/uploads/` paths, appends a cache-busting query parameter derived
/// from the filename (which contains the upload timestamp) to ensure
/// stale cached 404s are evicted when the avatar URL changes.
String? resolveAvatarUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('/')) {
    final url = '${Env.apiBaseUrl}$raw';
    // Avatar filenames contain the upload timestamp (e.g. 17-1773854690.jpg).
    // Use it as cache-buster so changed avatars aren't blocked by cached 404s.
    if (raw.contains('/uploads/')) {
      final filename = raw.split('/').last.split('.').first;
      return '$url?v=$filename';
    }
    return url;
  }
  return raw;
}
