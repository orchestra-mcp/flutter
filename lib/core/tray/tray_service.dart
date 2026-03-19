import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';

/// Visual state of the tray icon — reflects the orchestrator subprocess status.
enum TrayIconState { running, starting, stopped, error }

/// Callback interface for tray menu actions that need app-level coordination.
abstract class TrayActionHandler {
  Future<void> onStart();
  Future<void> onRestart();
  Future<void> onStop();
  Future<void> onOpenWorkspace();
  Future<void> onCloseWorkspace();
  Future<void> onSwitchWorkspace(String path);
  Future<void> onConnectCloud();
  Future<void> onQuit();
}

/// Manages the system-tray / menu-bar icon on desktop platforms.
///
/// On web and mobile all methods are no-ops.
/// On desktop, delegates to the `tray_manager` package.
class TrayService with TrayListener {
  TrayService._();

  static final TrayService instance = TrayService._();

  TrayIconState _iconState = TrayIconState.stopped;
  TrayIconState get iconState => _iconState;

  TrayActionHandler? _handler;

  /// Sets the action handler that responds to menu item clicks.
  void setHandler(TrayActionHandler handler) => _handler = handler;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Initialises the tray icon and registers mouse-event listeners.
  ///
  /// Must be called once during app startup, after `WidgetsFlutterBinding`
  /// is initialised.
  Future<void> init() async {
    if (!isDesktop) {
      debugPrint('[TrayService] init() skipped — not a desktop platform');
      return;
    }
    debugPrint('[TrayService] init()');

    await trayManager.setIcon('assets/tray/tray_icon.png', isTemplate: true);
    await trayManager.setToolTip('Orchestra MCP — Stopped');
    trayManager.addListener(this);
    await _buildAndSetMenu();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Updates the tray icon state and tooltip.
  Future<void> updateIcon(TrayIconState state) async {
    if (!isDesktop) return;
    _iconState = state;

    final tooltip = switch (state) {
      TrayIconState.running => 'Orchestra MCP — Running',
      TrayIconState.starting => 'Orchestra MCP — Starting...',
      TrayIconState.stopped => 'Orchestra MCP — Stopped',
      TrayIconState.error => 'Orchestra MCP — Error',
    };
    await trayManager.setToolTip(tooltip);
    await _buildAndSetMenu();
  }

  /// Rebuilds and re-applies the context menu.
  Future<void> refreshMenu() async {
    if (!isDesktop) return;
    await _buildAndSetMenu();
  }

  /// Hides / removes the tray icon.
  Future<void> hide() async {
    if (!isDesktop) return;
    trayManager.removeListener(this);
    await trayManager.destroy();
    debugPrint('[TrayService] destroyed');
  }

  // ── Menu builder ───────────────────────────────────────────────────────────

  Future<void> _buildAndSetMenu() async {
    final isRunning = _iconState == TrayIconState.running;
    final statusLabel = switch (_iconState) {
      TrayIconState.running => 'Orchestra MCP — Running',
      TrayIconState.starting => 'Orchestra MCP — Starting...',
      TrayIconState.stopped => 'Orchestra MCP — Stopped',
      TrayIconState.error => 'Orchestra MCP — Error',
    };

    // Read workspace path and recent workspaces for display
    final prefs = await SharedPreferences.getInstance();
    final currentPath = prefs.getString('workspace_path') ?? '';
    final workspaceLabel = currentPath.isNotEmpty
        ? currentPath.split('/').last
        : 'No workspace';
    final recentItems = _buildRecentWorkspaceItems(prefs, currentPath);

    final menu = Menu(
      items: [
        // Status header (disabled — just a label)
        MenuItem(key: 'status', label: statusLabel, disabled: true),
        MenuItem.separator(),

        // Process controls
        MenuItem(key: 'start', label: 'Start', disabled: isRunning),
        MenuItem(key: 'restart', label: 'Restart', disabled: !isRunning),
        MenuItem(key: 'stop', label: 'Stop', disabled: !isRunning),
        MenuItem.separator(),

        // Workspaces submenu
        MenuItem.submenu(
          key: 'workspaces',
          label: 'Workspaces',
          submenu: Menu(
            items: [
              if (workspaceLabel != 'No workspace')
                MenuItem(
                  key: 'workspace_current',
                  label: workspaceLabel,
                  disabled: true,
                ),
              if (workspaceLabel != 'No workspace') MenuItem.separator(),
              ...recentItems,
              if (recentItems.isNotEmpty) MenuItem.separator(),
              MenuItem(key: 'open_workspace', label: 'Open Workspace...'),
              MenuItem(
                key: 'close_workspace',
                label: 'Close Workspace',
                disabled: workspaceLabel == 'No workspace',
              ),
            ],
          ),
        ),
        MenuItem.separator(),

        // Cloud
        MenuItem(key: 'connect_cloud', label: 'Connect to Cloud...'),
        MenuItem.separator(),

        // Quit
        MenuItem(key: 'quit', label: 'Quit Orchestra MCP'),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  // ── Recent workspaces helper ─────────────────────────────────────────────

  List<MenuItem> _buildRecentWorkspaceItems(
    SharedPreferences prefs,
    String currentPath,
  ) {
    final raw = prefs.getString('recent_workspaces');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final items = <MenuItem>[];
      for (final entry in list) {
        final m = entry as Map<String, dynamic>;
        final path = m['path'] as String;
        if (path == currentPath) continue; // skip the active workspace
        final name = m['name'] as String;
        items.add(MenuItem(key: 'recent_workspace:$path', label: name));
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  // ── TrayListener ───────────────────────────────────────────────────────────

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final handler = _handler;
    if (handler == null) {
      debugPrint('[TrayService] No handler set for menu item: ${menuItem.key}');
      return;
    }

    final key = menuItem.key ?? '';
    if (key.startsWith('recent_workspace:')) {
      handler.onSwitchWorkspace(key.substring('recent_workspace:'.length));
      return;
    }
    switch (key) {
      case 'start':
        handler.onStart();
      case 'restart':
        handler.onRestart();
      case 'stop':
        handler.onStop();
      case 'open_workspace':
        handler.onOpenWorkspace();
      case 'close_workspace':
        handler.onCloseWorkspace();
      case 'connect_cloud':
        handler.onConnectCloud();
      case 'quit':
        handler.onQuit();
    }
  }
}
