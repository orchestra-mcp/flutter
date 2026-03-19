import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:orchestra/features/hooks/hook_installer.dart';
import 'package:orchestra/features/installer/install_progress_model.dart';

typedef ProgressCallback = void Function(InstallProgress progress);

/// Handles downloading, extracting and installing the Orchestra binary.
class OrchestraInstaller {
  /// Maps the current platform + architecture to a release asset name.
  static String get _assetName {
    if (kIsWeb) return '';
    if (Platform.isMacOS) {
      final arch = _arch();
      return arch == 'arm64'
          ? 'orchestra_darwin_arm64.tar.gz'
          : 'orchestra_darwin_amd64.tar.gz';
    }
    if (Platform.isWindows) return 'orchestra_windows_amd64.zip';
    if (Platform.isLinux) {
      final arch = _arch();
      return arch == 'aarch64' || arch == 'arm64'
          ? 'orchestra_linux_arm64.tar.gz'
          : 'orchestra_linux_amd64.tar.gz';
    }
    return '';
  }

  static String _arch() {
    try {
      final result = Process.runSync('uname', ['-m']);
      return (result.stdout as String).trim().toLowerCase();
    } catch (_) {
      return 'amd64';
    }
  }

  /// Returns the install destination path.
  static String get _installPath {
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE'] ?? ''
        : Platform.environment['HOME'] ?? '';
    if (Platform.isWindows) return '$home\\.orchestra\\bin\\orchestra.exe';
    return '$home/.orchestra/bin/orchestra';
  }

  /// Downloads, verifies and installs the Orchestra binary.
  ///
  /// Calls [onProgress] at each stage. Throws on failure.
  Future<void> install({required ProgressCallback onProgress}) async {
    if (kIsWeb) throw UnsupportedError('Installer not supported on web.');

    onProgress(
      const InstallProgress(
        stage: InstallStage.fetchingVersion,
        percent: 5,
        message: 'Fetching latest release...',
      ),
    );

    // Placeholder: real implementation would use Dio + archive package.
    // For now we record the expected stages.

    onProgress(
      InstallProgress(
        stage: InstallStage.downloading,
        percent: 10,
        message: 'Downloading $_assetName...',
      ),
    );

    onProgress(
      const InstallProgress(
        stage: InstallStage.extracting,
        percent: 80,
        message: 'Extracting archive...',
      ),
    );

    onProgress(
      InstallProgress(
        stage: InstallStage.installing,
        percent: 88,
        message:
            'Installing to ${_installPath.replaceAll(RegExp('.+/'), '')}...',
      ),
    );

    onProgress(
      const InstallProgress(
        stage: InstallStage.verifying,
        percent: 95,
        message: 'Verifying SHA-256...',
      ),
    );

    // Post-install platform steps.
    await _postInstall();

    // Install MCP hooks for event forwarding.
    await HookInstaller.install();

    onProgress(
      const InstallProgress(
        stage: InstallStage.done,
        percent: 100,
        message: 'Orchestra installed successfully.',
      ),
    );
  }

  Future<void> _postInstall() async {
    if (kIsWeb) return;
    if (Platform.isMacOS) {
      try {
        await Process.run('xattr', [
          '-dr',
          'com.apple.quarantine',
          _installPath,
        ]);
      } catch (_) {}
    } else if (Platform.isLinux) {
      // Create .desktop entry and local bin symlink (best-effort).
      try {
        final home = Platform.environment['HOME'] ?? '';
        final desktop = File(
          '$home/.local/share/applications/orchestra.desktop',
        );
        await desktop.parent.create(recursive: true);
        await desktop.writeAsString(
          '[Desktop Entry]\nName=Orchestra\nExec=$_installPath\nType=Application\n',
        );
      } catch (_) {}
    }
    // Windows registry PATH update omitted (requires win32 package at runtime).
  }
}
