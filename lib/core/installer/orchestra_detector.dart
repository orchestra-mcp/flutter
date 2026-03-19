import 'dart:io';

import 'package:flutter/foundation.dart';

/// Result of the Orchestra binary detection.
enum DetectResult { found, notFound, updateAvailable }

/// Version information for installed vs latest Orchestra binary.
class VersionInfo {
  const VersionInfo({
    required this.installed,
    required this.latest,
    required this.hasUpdate,
  });

  final String installed;
  final String latest;
  final bool hasUpdate;
}

/// Detects whether the Orchestra CLI binary is installed on the host machine.
///
/// Checks common installation paths before falling back to `which`/`where`.
class OrchestraDetector {
  /// Ordered list of candidate paths to check for the binary.
  static List<String> get _candidates {
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? '';
      return [
        '$home\\.orchestra\\bin\\orchestra.exe',
        'C:\\Program Files\\Orchestra\\orchestra.exe',
      ];
    }
    final home = Platform.environment['HOME'] ?? '';
    return [
      '$home/.orchestra/bin/orchestra',
      '/usr/local/bin/orchestra',
      '/opt/homebrew/bin/orchestra',
      '/usr/bin/orchestra',
      '$home/go/bin/orchestra',
    ];
  }

  /// Returns [DetectResult.found] if the Orchestra binary exists at any
  /// known path, otherwise [DetectResult.notFound].
  ///
  /// On non-desktop platforms (web/mobile) always returns [DetectResult.notFound].
  static Future<bool> check() async {
    if (kIsWeb) return false;
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return false;
    }

    // Check well-known paths first.
    for (final path in _candidates) {
      if (await File(path).exists()) return true;
    }

    // Fallback: use `which` / `where`.
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, ['orchestra']);
      return result.exitCode == 0 &&
          (result.stdout as String).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the first found binary path, or `null` if none found.
  static Future<String?> binaryPath() async {
    if (kIsWeb) return null;
    for (final path in _candidates) {
      if (await File(path).exists()) return path;
    }
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, ['orchestra']);
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim();
        if (out.isNotEmpty) return out.split('\n').first;
      }
    } catch (_) {}
    return null;
  }

  /// Runs `orchestra --version` and returns the version string, or `null`.
  static Future<String?> installedVersion() async {
    final path = await binaryPath();
    if (path == null) return null;
    try {
      final result = await Process.run(path, ['--version']);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return null;
  }
}
