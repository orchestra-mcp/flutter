import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:orchestra/features/installer/install_progress_model.dart';

/// Detects whether the Orchestra binary is installed and whether an update is
/// available by querying the GitHub releases API.
class OrchestraDetector {
  static const _releasesUrl =
      'https://api.github.com/repos/orchestra-mcp/framework/releases/latest';

  /// Ordered list of candidate binary paths per platform.
  static List<String> get _candidates {
    if (kIsWeb) return [];
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? '';
      return [
        '$home\\.orchestra\\bin\\orchestra.exe',
        r'C:\Program Files\Orchestra\orchestra.exe',
      ];
    }
    final home = Platform.environment['HOME'] ?? '';
    return [
      '$home/.orchestra/bin/orchestra',
      '/usr/local/bin/orchestra',
      '/opt/homebrew/bin/orchestra',
      '/usr/bin/orchestra',
    ];
  }

  /// Returns the path of the installed binary, or null if not found.
  Future<String?> _findBinary() async {
    for (final path in _candidates) {
      if (File(path).existsSync()) return path;
    }
    // Fallback: use `which` / `where`.
    if (!kIsWeb) {
      final cmd = Platform.isWindows ? 'where' : 'which';
      try {
        final result = await Process.run(cmd, ['orchestra']);
        if (result.exitCode == 0) {
          final out = (result.stdout as String).trim();
          if (out.isNotEmpty) return out.split('\n').first.trim();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Returns the installed version string by running `orchestra --version`.
  Future<String?> _installedVersion(String binaryPath) async {
    try {
      final result = await Process.run(binaryPath, ['--version']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim().replaceAll('orchestra ', '');
      }
    } catch (_) {}
    return null;
  }

  /// Checks whether Orchestra is installed.
  Future<DetectResult> check() async {
    if (kIsWeb) return DetectResult.notFound;
    final path = await _findBinary();
    if (path == null) return DetectResult.notFound;
    final versions = await getVersions();
    if (versions != null && versions.hasUpdate) return DetectResult.updateAvailable;
    return DetectResult.found;
  }

  /// Fetches installed + latest version information.
  /// Returns null if it cannot be determined.
  Future<VersionInfo?> getVersions() async {
    if (kIsWeb) return null;
    final path = await _findBinary();
    final installed = path != null ? await _installedVersion(path) : null;
    if (installed == null) return null;

    // Fetch latest from GitHub (best-effort; network may not be available).
    try {
      final result = await Process.run(
          'curl', ['-sf', _releasesUrl, '-H', 'Accept: application/json']);
      if (result.exitCode == 0) {
        final body = result.stdout as String;
        final tagMatch = RegExp(r'"tag_name"\s*:\s*"v?([^"]+)"').firstMatch(body);
        if (tagMatch != null) {
          final latest = tagMatch.group(1)!;
          final hasUpdate = installed != latest;
          return VersionInfo(installed: installed, latest: latest, hasUpdate: hasUpdate);
        }
      }
    } catch (_) {}

    return VersionInfo(installed: installed, latest: installed, hasUpdate: false);
  }
}
