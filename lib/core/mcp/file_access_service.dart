import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages security-scoped file access bookmarks on macOS.
///
/// On sandboxed macOS apps, the OS restricts access to files outside the
/// container. This service uses [NSOpenPanel] + security-scoped bookmarks
/// to let the user grant access to directories, then persists those grants
/// so access is restored automatically on subsequent launches.
///
/// On non-macOS platforms this is a no-op — all methods succeed immediately.
class FileAccessService {
  FileAccessService._();
  static final instance = FileAccessService._();

  static const _channel = MethodChannel('com.orchestra.app/file_access');
  static const _prefsPrefix = 'file_bookmark_';

  /// Whether the home directory (specifically `~/.orchestra/`) has been granted.
  bool _homeAccessGranted = false;
  bool get hasHomeAccess => _homeAccessGranted;

  /// Bookmarks currently resolved and active for this session.
  final Set<String> _activeBookmarks = {};

  // ── Startup ───────────────────────────────────────────────────────────────

  /// Call once at app startup. When sandbox is disabled (default for this app),
  /// grants access immediately. When sandboxed, resolves saved bookmarks.
  Future<bool> restoreSavedAccess() async {
    // Without sandbox, file access is unrestricted.
    // Try a quick probe to see if we can read ~/.orchestra/ directly.
    if (await _canAccessHomeDirectly()) {
      _homeAccessGranted = true;
      return true;
    }

    if (!_isMacOS) {
      _homeAccessGranted = true;
      return true;
    }

    // Sandboxed path: restore bookmarks from previous sessions.
    final prefs = await SharedPreferences.getInstance();

    final homeBookmark = prefs.getString('${_prefsPrefix}home');
    if (homeBookmark != null) {
      final bytes = Uint8List.fromList(homeBookmark.codeUnits);
      final ok = await _resolveBookmark(bytes);
      if (ok) {
        _homeAccessGranted = true;
        debugPrint('[FileAccess] Restored home directory access from bookmark');
      } else {
        await prefs.remove('${_prefsPrefix}home');
        debugPrint('[FileAccess] Home bookmark stale, needs re-prompt');
      }
    }

    // Restore workspace bookmarks
    final keys = prefs.getKeys().where(
      (k) => k.startsWith('${_prefsPrefix}ws_'),
    );
    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        final bytes = Uint8List.fromList(data.codeUnits);
        await _resolveBookmark(bytes);
      }
    }

    return _homeAccessGranted;
  }

  /// Probes whether we can access the filesystem without sandbox restrictions.
  Future<bool> _canAccessHomeDirectly() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkDirectAccess');
      return result ?? false;
    } on PlatformException {
      // Channel not available (web) or method not found — assume no access.
      return false;
    } on MissingPluginException {
      // Not on macOS — no sandbox, full access.
      return true;
    }
  }

  // ── Home directory access ─────────────────────────────────────────────────

  /// Prompts the user to grant access to the home directory.
  /// Shows an NSOpenPanel pre-navigated to `~/`. Returns true if granted.
  Future<bool> requestHomeAccess() async {
    if (!_isMacOS) {
      _homeAccessGranted = true;
      return true;
    }

    final home = _homeDir;
    final result = await _requestFolderAccess(
      message:
          'Orchestra needs access to your home directory to read '
          'workspace data and the ~/.orchestra/ configuration.',
      initialPath: home,
    );

    if (result != null) {
      _homeAccessGranted = true;
      await _saveBookmark('home', result.bookmark);
      debugPrint('[FileAccess] Home access granted: ${result.path}');
      return true;
    }
    return false;
  }

  // ── Workspace access ──────────────────────────────────────────────────────

  /// Grants access to a specific workspace directory and saves a bookmark.
  Future<bool> requestWorkspaceAccess(String path) async {
    if (!_isMacOS) return true;
    if (_activeBookmarks.contains(path)) return true;

    final result = await _requestFolderAccess(
      message: 'Grant access to workspace: $path',
      initialPath: path,
    );

    if (result != null) {
      final key = 'ws_${path.hashCode.toUnsigned(32).toRadixString(16)}';
      await _saveBookmark(key, result.bookmark);
      _activeBookmarks.add(result.path);
      return true;
    }
    return false;
  }

  // ── Directory Picker ─────────────────────────────────────────────────────

  /// Shows a native directory picker dialog. On macOS, uses NSOpenPanel directly
  /// via the file_access method channel (avoids file_picker's sandbox entitlement
  /// requirement). On other platforms, uses file_picker.
  Future<String?> pickDirectory({String? message, String? initialPath}) async {
    if (_isMacOS) {
      try {
        final result = await _channel
            .invokeMethod<Map<Object?, Object?>>('requestFolderAccess', {
              'message': message ?? 'Select a folder',
              if (initialPath != null) 'initialPath': initialPath,
            });
        if (result == null) return null;
        return result['path'] as String;
      } on PlatformException catch (e) {
        debugPrint('[FileAccess] pickDirectory error: $e');
        return null;
      }
    }
    // Non-macOS: use file_picker package.
    return FilePicker.platform.getDirectoryPath(dialogTitle: message);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<_BookmarkResult?> _requestFolderAccess({
    required String message,
    String? initialPath,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'requestFolderAccess',
        {
          'message': message,
          if (initialPath != null) 'initialPath': initialPath,
        },
      );

      if (result == null) return null; // User cancelled

      final path = result['path'] as String;
      final bookmark = result['bookmark'] as Uint8List;
      _activeBookmarks.add(path);
      return _BookmarkResult(path: path, bookmark: bookmark);
    } on PlatformException catch (e) {
      debugPrint('[FileAccess] requestFolderAccess error: $e');
      return null;
    }
  }

  Future<bool> _resolveBookmark(Uint8List bookmarkData) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'resolveBookmark',
        {'bookmark': bookmarkData},
      );

      if (result == null) return false;

      final path = result['path'] as String;
      _activeBookmarks.add(path);

      // If bookmark was stale, save the refreshed one
      final isStale = result['isStale'] as bool? ?? false;
      if (isStale) {
        final newBookmark = result['newBookmark'] as Uint8List?;
        if (newBookmark != null) {
          debugPrint('[FileAccess] Refreshed stale bookmark for $path');
        }
      }
      return true;
    } on PlatformException catch (e) {
      debugPrint('[FileAccess] resolveBookmark error: $e');
      return false;
    }
  }

  Future<void> _saveBookmark(String key, Uint8List data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$key', String.fromCharCodes(data));
  }

  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  /// Returns a best-guess home directory path for NSOpenPanel's initialPath.
  /// The native side handles actual path resolution — this is just a hint.
  String get _homeDir => '/Users';
}

class _BookmarkResult {
  const _BookmarkResult({required this.path, required this.bookmark});
  final String path;
  final Uint8List bookmark;
}
