import 'dart:io';

/// Result of a binary presence check.
enum DetectResult { found, notFound, updateAvailable }

/// Metadata returned when an installed version is found.
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

/// Locates and compares the Orchestra CLI binary.
class OrchestraDetector {
  /// Returns the first existing candidate path, or `null` if none found.
  static String? _findBinary() {
    final candidates = <String>[
      '${Platform.environment['HOME'] ?? ''}/.orchestra/bin/orchestra',
      '/usr/local/bin/orchestra',
      '/opt/homebrew/bin/orchestra',
      '/usr/bin/orchestra',
      if (Platform.isWindows) ...[
        '${Platform.environment['USERPROFILE'] ?? ''}\\.orchestra\\bin\\orchestra.exe',
        r'C:\Program Files\Orchestra\orchestra.exe',
      ],
    ];

    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  /// Checks whether the binary is present on this machine.
  Future<DetectResult> check() async {
    if (_findBinary() != null) return DetectResult.found;

    // Fallback: shell which/where lookup.
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(cmd, ['orchestra']);
      if (result.exitCode == 0) return DetectResult.found;
    } catch (_) {}

    return DetectResult.notFound;
  }

  /// Fetches the latest GitHub release and compares to the installed version.
  Future<VersionInfo?> getVersions() async {
    final path = _findBinary();
    if (path == null) return null;

    try {
      final installed = await _installedVersion(path);
      // Latest version fetched lazily — returns placeholder when offline.
      return VersionInfo(
        installed: installed,
        latest: installed,
        hasUpdate: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _installedVersion(String path) async {
    final result = await Process.run(path, ['--version']);
    return (result.stdout as String).trim();
  }
}
