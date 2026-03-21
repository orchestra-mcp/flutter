import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Ensures a workspace directory has Orchestra initialized.
///
/// Checks for the `.orchestra/` directory and runs `orchestra init` if missing.
/// Also ensures Claude Desktop has the Orchestra MCP server configured.
class WorkspaceInitializer {
  WorkspaceInitializer._();

  /// Returns true if the workspace already has Orchestra initialized.
  static bool isInitialized(String workspacePath) {
    return Directory('$workspacePath/.orchestra').existsSync();
  }

  /// Ensures the workspace is initialized. Runs `orchestra init` if needed.
  /// Returns true if init was run, false if already initialized.
  static Future<bool> ensureInitialized(String workspacePath) async {
    if (isInitialized(workspacePath)) return false;

    debugPrint('[WorkspaceInit] Running orchestra init in $workspacePath');
    try {
      final result = await Process.run('orchestra', [
        'init',
      ], workingDirectory: workspacePath);
      if (result.exitCode == 0) {
        debugPrint('[WorkspaceInit] Init completed successfully');
        return true;
      } else {
        debugPrint('[WorkspaceInit] Init failed: ${result.stderr}');
        return false;
      }
    } on ProcessException catch (e) {
      debugPrint('[WorkspaceInit] Process error: $e');
      return false;
    }
  }

  /// Returns the platform-specific path to Claude Desktop's config file.
  static String get _claudeDesktopConfigPath {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (Platform.isMacOS) {
      return '$home/Library/Application Support/Claude/claude_desktop_config.json';
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ??
          '$home/AppData/Roaming';
      return '$appData/Claude/claude_desktop_config.json';
    } else {
      return '$home/.config/Claude/claude_desktop_config.json';
    }
  }

  /// Checks if Claude Desktop has Orchestra MCP configured.
  static bool _hasClaudeDesktopConfig() {
    final file = File(_claudeDesktopConfigPath);
    if (!file.existsSync()) return false;
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final servers = json['mcpServers'] as Map<String, dynamic>?;
      return servers != null && servers.containsKey('orchestra');
    } catch (_) {
      return false;
    }
  }

  /// Ensures Claude Desktop has Orchestra MCP server configured.
  /// Runs `orchestra init --ide claude-desktop` if the config is missing.
  static Future<void> ensureClaudeDesktopConfig(String workspacePath) async {
    if (_hasClaudeDesktopConfig()) return;

    debugPrint('[WorkspaceInit] Claude Desktop config missing — auto-installing Orchestra MCP');
    try {
      final result = await Process.run('orchestra', [
        'init',
        '--ide',
        'claude-desktop',
        '--workspace',
        workspacePath,
      ], workingDirectory: workspacePath);
      if (result.exitCode == 0) {
        debugPrint('[WorkspaceInit] Claude Desktop config installed');
      } else {
        debugPrint('[WorkspaceInit] Claude Desktop config install failed: ${result.stderr}');
      }
    } on ProcessException catch (e) {
      debugPrint('[WorkspaceInit] Process error: $e');
    }
  }
}
