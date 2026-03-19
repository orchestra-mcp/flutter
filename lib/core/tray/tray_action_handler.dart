import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/api/mcp_tcp_client.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/tray/tray_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridges tray menu actions to the [McpTcpClient] orchestrator process.
///
/// Workspace switching goes through [McpTcpClient.switchWorkspace] to properly
/// handle the `_stopped` flag. The optional [onWorkspaceChanged] callback
/// lets the Riverpod layer update providers after the MCP client switches.
class DefaultTrayActionHandler implements TrayActionHandler {
  DefaultTrayActionHandler(this._mcp, {this.onWorkspaceChanged, this.onWorkspaceClosed});

  final McpTcpClient _mcp;

  /// Called after MCP switches workspace — update Riverpod providers here.
  final Future<void> Function(String path)? onWorkspaceChanged;

  /// Called after workspace is closed — trigger startup gate recheck here.
  final Future<void> Function()? onWorkspaceClosed;

  @override
  Future<void> onStart() async {
    debugPrint('[Tray] Start');
    // Use switchWorkspace to clear _stopped flag and start fresh.
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('workspace_path') ?? '';
    if (path.isNotEmpty) {
      await _mcp.switchWorkspace(path);
      await onWorkspaceChanged?.call(path);
    }
    await TrayService.instance.updateIcon(_mcp.processState.value);
  }

  @override
  Future<void> onRestart() async {
    debugPrint('[Tray] Restart');
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('workspace_path') ?? '';
    if (path.isNotEmpty) {
      await _mcp.switchWorkspace(path);
    } else {
      _mcp.disconnect();
    }
    await TrayService.instance.updateIcon(_mcp.processState.value);
  }

  @override
  Future<void> onStop() async {
    debugPrint('[Tray] Stop');
    _mcp.disconnect();
    await TrayService.instance.updateIcon(TrayIconState.stopped);
  }

  /// Bring the app to foreground so macOS allows presenting dialogs
  /// from a tray-only (accessory) process.
  static const _appChannel = MethodChannel('com.orchestra.app/lifecycle');

  Future<void> _activateApp() async {
    if (!Platform.isMacOS) return;
    try {
      await _appChannel.invokeMethod('activateApp');
    } catch (_) {
      // Channel not registered — app may already be foreground.
    }
  }

  @override
  Future<void> onOpenWorkspace() async {
    debugPrint('[Tray] Open workspace');
    // macOS tray-only apps must be activated before showing native dialogs.
    await _activateApp();
    final result = await FileAccessService.instance.pickDirectory(
      message: 'Select workspace folder',
    );
    if (result != null) {
      await _mcp.switchWorkspace(result);
      await onWorkspaceChanged?.call(result);
      await TrayService.instance.updateIcon(_mcp.processState.value);
      await TrayService.instance.refreshMenu();
    }
  }

  @override
  Future<void> onSwitchWorkspace(String path) async {
    debugPrint('[Tray] Switch workspace to: $path');
    await _mcp.switchWorkspace(path);
    await onWorkspaceChanged?.call(path);
    await TrayService.instance.updateIcon(_mcp.processState.value);
    await TrayService.instance.refreshMenu();
  }

  @override
  Future<void> onCloseWorkspace() async {
    debugPrint('[Tray] Close workspace');
    _mcp.disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('workspace_path');
    await onWorkspaceClosed?.call();
    await TrayService.instance.updateIcon(TrayIconState.stopped);
    await TrayService.instance.refreshMenu();
  }

  @override
  Future<void> onConnectCloud() async {
    debugPrint('[Tray] Connect to cloud (TODO)');
    // Future: open cloud connection dialog or URL
  }

  @override
  Future<void> onQuit() async {
    debugPrint('[Tray] Quit');
    _mcp.disconnect();
    await TrayService.instance.hide();
    exit(0);
  }
}
