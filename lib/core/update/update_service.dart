import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Information about an available update.
class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    this.downloadUrl,
    this.releaseNotes,
    this.storeUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;

  /// Direct download URL for the platform artifact (desktop only).
  final String? downloadUrl;

  /// Release notes markdown body.
  final String? releaseNotes;

  /// App Store / Play Store URL (mobile only).
  final String? storeUrl;
}

/// Checks GitHub Releases for app updates and downloads artifacts.
///
/// Mirrors the Go CLI pattern in `selfupdate.go` but targets the
/// `app-v*` tag namespace used by the Flutter release workflow.
class UpdateService {
  static const _repo = 'orchestra-mcp/framework';
  static const _releasesUrl =
      'https://api.github.com/repos/$_repo/releases';

  static const _iosStoreUrl =
      'https://apps.apple.com/app/orchestra/id0000000000';
  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.orchestramcp.orchestra';

  /// Queries GitHub releases API for the latest `app-v*` release and compares
  /// against the current app version from `package_info_plus`.
  Future<UpdateInfo> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final current = packageInfo.version; // e.g. "1.0.0"

    try {
      final response = await http
          .get(
            Uri.parse(_releasesUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return UpdateInfo(
          currentVersion: current,
          latestVersion: current,
          hasUpdate: false,
        );
      }

      final releases = jsonDecode(response.body) as List<dynamic>;

      // Find the latest app-v* release (not draft, not prerelease).
      Map<String, dynamic>? latestRelease;
      for (final r in releases) {
        final release = r as Map<String, dynamic>;
        final tag = release['tag_name'] as String? ?? '';
        if (!tag.startsWith('app-v')) continue;
        if (release['draft'] == true) continue;
        // Include prereleases — they indicate beta/RC availability.
        latestRelease = release;
        break; // Releases are sorted newest-first by GitHub.
      }

      if (latestRelease == null) {
        return UpdateInfo(
          currentVersion: current,
          latestVersion: current,
          hasUpdate: false,
        );
      }

      final tag = latestRelease['tag_name'] as String;
      final latest = tag.replaceFirst('app-v', ''); // "1.2.0"

      final hasUpdate = isNewer(current, latest);
      final releaseNotes = latestRelease['body'] as String?;

      String? downloadUrl;
      String? storeUrl;

      if (isDesktop) {
        downloadUrl = _resolveDesktopAsset(latestRelease);
      } else if (isMobile) {
        storeUrl = Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;
      }

      return UpdateInfo(
        currentVersion: current,
        latestVersion: latest,
        hasUpdate: hasUpdate,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
      );
    } catch (e) {
      debugPrint('[UpdateService] check failed: $e');
      return UpdateInfo(
        currentVersion: current,
        latestVersion: current,
        hasUpdate: false,
      );
    }
  }

  /// Downloads the platform artifact to a temp directory.
  /// Calls [onProgress] with 0.0–1.0 as bytes arrive.
  /// Returns the local file path of the downloaded artifact.
  Future<String> downloadUpdate(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final fileName = Uri.parse(url).pathSegments.last;
      final file = File('${tempDir.path}/$fileName');
      final sink = file.openWrite();

      var received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress(received / contentLength);
        }
      }

      await sink.close();
      return file.path;
    } finally {
      client.close();
    }
  }

  /// Opens the downloaded artifact for installation.
  ///
  /// - macOS: opens the DMG (user drags to /Applications)
  /// - Linux: extracts tarball (future: deb/snap)
  /// - Windows: extracts zip (future: MSIX)
  Future<void> installUpdate(String filePath) async {
    if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      // Open file manager at download location.
      final dir = File(filePath).parent.path;
      await Process.run('xdg-open', [dir]);
    } else if (Platform.isWindows) {
      // Open explorer at download location.
      final dir = File(filePath).parent.path;
      await Process.run('explorer', [dir]);
    }
  }

  /// Returns `true` if [latest] is strictly newer than [current].
  /// Ports the Go CLI `isNewerVersion` from `selfupdate.go`.
  static bool isNewer(String current, String latest) {
    final (curBase, curPre) = _splitVersion(current);
    final (latBase, latPre) = _splitVersion(latest);

    final curParts = _parseSemver(curBase);
    final latParts = _parseSemver(latBase);

    for (var i = 0; i < 3; i++) {
      if (latParts[i] > curParts[i]) return true;
      if (latParts[i] < curParts[i]) return false;
    }

    // Same base: release > prerelease.
    if (curPre.isNotEmpty && latPre.isEmpty) return true;
    if (curPre.isEmpty && latPre.isNotEmpty) return false;

    // Both have prerelease: compare lexicographically.
    return latPre.compareTo(curPre) > 0;
  }

  // ── Private helpers ─────────────────────────────────────────────────

  /// Strips `v` prefix, splits "1.0.0-beta" → ("1.0.0", "beta").
  static (String base, String pre) _splitVersion(String v) {
    v = v.replaceFirst(RegExp(r'^v'), '');
    final idx = v.indexOf('-');
    if (idx != -1) return (v.substring(0, idx), v.substring(idx + 1));
    return (v, '');
  }

  /// Parses "1.2.3" → [1, 2, 3].
  static List<int> _parseSemver(String base) {
    final parts = base.split('.');
    return List.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }

  /// Resolves the platform-specific asset URL from release assets.
  String? _resolveDesktopAsset(Map<String, dynamic> release) {
    final assets = release['assets'] as List<dynamic>? ?? [];
    final suffix = _platformAssetSuffix();
    if (suffix == null) return null;

    for (final a in assets) {
      final asset = a as Map<String, dynamic>;
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name.contains(suffix)) {
        return asset['browser_download_url'] as String?;
      }
    }
    return null;
  }

  /// Returns the expected asset name fragment for this platform.
  String? _platformAssetSuffix() {
    if (kIsWeb) return null;
    if (Platform.isMacOS) return 'macos.dmg';
    if (Platform.isLinux) return 'linux-x64.tar.gz';
    if (Platform.isWindows) return 'windows-x64.zip';
    return null;
  }
}
