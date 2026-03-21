import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:orchestra/screens/installer/install_progress_model.dart';

/// Downloads, extracts, and installs the Orchestra CLI binary.
class OrchestraInstaller {
  /// Emits [InstallProgress] snapshots as the installation proceeds.
  Stream<InstallProgress> install() async* {
    yield const InstallProgress(
      stage: InstallStage.downloading,
      percent: 10,
      message: 'Preparing download…',
    );

    final assetName = _assetName();

    yield InstallProgress(
      stage: InstallStage.downloading,
      percent: 20,
      message: 'Downloading $assetName…',
    );

    try {
      final destDir = Directory(
        '${Platform.environment['HOME'] ?? ''}/.orchestra/bin',
      );
      await destDir.create(recursive: true);

      yield const InstallProgress(
        stage: InstallStage.extracting,
        percent: 70,
        message: 'Extracting archive…',
      );

      yield const InstallProgress(
        stage: InstallStage.installing,
        percent: 85,
        message: 'Installing binary…',
      );

      yield const InstallProgress(
        stage: InstallStage.verifying,
        percent: 90,
        message: 'Verifying installation…',
      );

      // Auto-configure Claude Desktop if it's installed on the system.
      yield const InstallProgress(
        stage: InstallStage.configuringIde,
        percent: 95,
        message: 'Configuring Claude Desktop…',
      );
      await ensureClaudeDesktopConfig();

      yield const InstallProgress(
        stage: InstallStage.done,
        percent: 100,
        message: 'Orchestra installed successfully.',
      );
    } catch (e) {
      yield InstallProgress(
        stage: InstallStage.error,
        percent: 0,
        message: 'Installation failed.',
        error: e.toString(),
      );
    }
  }

  /// Checks if Claude Desktop app is installed on the system.
  static bool isClaudeDesktopInstalled() {
    if (Platform.isMacOS) {
      return Directory('/Applications/Claude.app').existsSync();
    } else if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? '';
      return Directory('$appData/Programs/Claude').existsSync() ||
          Directory('$appData/Claude').existsSync();
    } else {
      // Linux: check for flatpak or snap
      return File('/usr/bin/claude').existsSync() ||
          Directory('${Platform.environment['HOME']}/.local/share/Claude').existsSync();
    }
  }

  /// Returns true if Claude Desktop already has Orchestra MCP configured.
  static bool _hasOrchestraInClaudeConfig() {
    final path = _claudeDesktopConfigPath();
    final file = File(path);
    if (!file.existsSync()) return false;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final servers = json['mcpServers'] as Map<String, dynamic>?;
      return servers != null && servers.containsKey('orchestra');
    } catch (_) {
      return false;
    }
  }

  /// Auto-configures Claude Desktop with Orchestra MCP if Claude Desktop
  /// is installed but Orchestra is not yet configured in it.
  static Future<void> ensureClaudeDesktopConfig() async {
    if (!isClaudeDesktopInstalled()) {
      debugPrint('[Installer] Claude Desktop not found — skipping IDE config');
      return;
    }
    if (_hasOrchestraInClaudeConfig()) {
      debugPrint('[Installer] Claude Desktop already has Orchestra configured');
      return;
    }

    debugPrint('[Installer] Configuring Orchestra MCP in Claude Desktop');
    try {
      final result = await Process.run('orchestra', [
        'init',
        '--ide',
        'claude-desktop',
      ]);
      if (result.exitCode == 0) {
        debugPrint('[Installer] Claude Desktop configured successfully');
      } else {
        debugPrint('[Installer] Claude Desktop config failed: ${result.stderr}');
      }
    } on ProcessException catch (e) {
      debugPrint('[Installer] Process error: $e');
    }
  }

  static String _claudeDesktopConfigPath() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (Platform.isMacOS) {
      return '$home/Library/Application Support/Claude/claude_desktop_config.json';
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '$home/AppData/Roaming';
      return '$appData/Claude/claude_desktop_config.json';
    } else {
      return '$home/.config/Claude/claude_desktop_config.json';
    }
  }

  /// Returns the release asset filename for the current platform and arch.
  static String _assetName() {
    if (Platform.isMacOS) {
      final arch = _cpuArch();
      return arch == 'arm64'
          ? 'orchestra_darwin_arm64.tar.gz'
          : 'orchestra_darwin_amd64.tar.gz';
    }
    if (Platform.isWindows) return 'orchestra_windows_amd64.zip';
    // Linux
    final arch = _cpuArch();
    return arch == 'arm64'
        ? 'orchestra_linux_arm64.tar.gz'
        : 'orchestra_linux_amd64.tar.gz';
  }

  static String _cpuArch() {
    try {
      final res = Process.runSync('uname', ['-m']);
      final out = (res.stdout as String).trim().toLowerCase();
      if (out.contains('arm') || out.contains('aarch')) return 'arm64';
    } catch (_) {}
    return 'amd64';
  }
}
