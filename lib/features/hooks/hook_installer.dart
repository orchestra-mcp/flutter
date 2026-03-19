import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Installs Orchestra MCP hooks into .claude/settings.json so that
/// Claude Code events (tool calls, agent spawns, notifications) are
/// forwarded to the Orchestra backend via the hook script.
class HookInstaller {
  /// The hook events we want to register for.
  static const _hookEvents = [
    'tool_use_start',
    'tool_use_end',
    'notification',
    'subagent_start',
    'subagent_end',
  ];

  /// Path to the hook script relative to the Orchestra install directory.
  static String get _hookScriptPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.claude/hooks/orchestra-mcp-hook.sh';
  }

  /// Path to the Claude Code settings file.
  static String get _settingsPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.claude/settings.json';
  }

  /// Installs hooks into .claude/settings.json.
  /// Creates the settings file if it doesn't exist.
  /// Preserves existing settings and merges hook configuration.
  static Future<bool> install() async {
    if (kIsWeb) return false;

    try {
      final settingsFile = File(_settingsPath);
      Map<String, dynamic> settings = {};

      // Read existing settings if present.
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        if (content.trim().isNotEmpty) {
          settings = jsonDecode(content) as Map<String, dynamic>;
        }
      } else {
        await settingsFile.parent.create(recursive: true);
      }

      // Get or create the hooks map.
      final hooks = (settings['hooks'] as Map<String, dynamic>?) ?? {};

      // Register hook script for each event.
      for (final event in _hookEvents) {
        final eventHooks = (hooks[event] as List<dynamic>?) ?? [];

        // Check if our hook is already registered.
        final alreadyRegistered = eventHooks.any((h) {
          if (h is Map<String, dynamic>) {
            final cmd = h['command'] as String? ?? '';
            return cmd.contains('orchestra-mcp-hook');
          }
          return false;
        });

        if (!alreadyRegistered) {
          eventHooks.add({
            'command': _hookScriptPath,
            'timeout': 5000,
          });
        }

        hooks[event] = eventHooks;
      }

      settings['hooks'] = hooks;

      // Write back.
      final encoder = const JsonEncoder.withIndent('  ');
      await settingsFile.writeAsString(encoder.convert(settings));

      return true;
    } catch (e) {
      debugPrint('[HookInstaller] failed to install hooks: $e');
      return false;
    }
  }

  /// Checks if hooks are already installed.
  static Future<bool> isInstalled() async {
    if (kIsWeb) return false;

    try {
      final settingsFile = File(_settingsPath);
      if (!await settingsFile.exists()) return false;

      final content = await settingsFile.readAsString();
      if (content.trim().isEmpty) return false;

      final settings = jsonDecode(content) as Map<String, dynamic>;
      final hooks = settings['hooks'] as Map<String, dynamic>?;
      if (hooks == null) return false;

      // Check if at least the first event has our hook.
      final firstEvent = hooks[_hookEvents.first] as List<dynamic>?;
      if (firstEvent == null) return false;

      return firstEvent.any((h) {
        if (h is Map<String, dynamic>) {
          return (h['command'] as String? ?? '').contains('orchestra-mcp-hook');
        }
        return false;
      });
    } catch (_) {
      return false;
    }
  }

  /// Removes Orchestra hooks from .claude/settings.json.
  static Future<bool> uninstall() async {
    if (kIsWeb) return false;

    try {
      final settingsFile = File(_settingsPath);
      if (!await settingsFile.exists()) return true;

      final content = await settingsFile.readAsString();
      if (content.trim().isEmpty) return true;

      final settings = jsonDecode(content) as Map<String, dynamic>;
      final hooks = (settings['hooks'] as Map<String, dynamic>?) ?? {};

      for (final event in _hookEvents) {
        final eventHooks = (hooks[event] as List<dynamic>?) ?? [];
        eventHooks.removeWhere((h) {
          if (h is Map<String, dynamic>) {
            return (h['command'] as String? ?? '').contains('orchestra-mcp-hook');
          }
          return false;
        });
        if (eventHooks.isEmpty) {
          hooks.remove(event);
        } else {
          hooks[event] = eventHooks;
        }
      }

      settings['hooks'] = hooks;

      final encoder = const JsonEncoder.withIndent('  ');
      await settingsFile.writeAsString(encoder.convert(settings));

      return true;
    } catch (e) {
      debugPrint('[HookInstaller] failed to uninstall hooks: $e');
      return false;
    }
  }
}
