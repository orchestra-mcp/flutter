import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/local_mcp_client.dart';
import 'package:orchestra/core/api/mcp_tcp_client.dart';
import 'package:orchestra/core/api/rest_client.dart';
import 'package:orchestra/core/mcp/mcp_action_logger.dart';
import 'package:orchestra/core/powersync/sync_providers.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/tray/tray_action_handler.dart';
import 'package:orchestra/core/tray/tray_service.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/screens/projects/projects_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Workspace path ──────────────────────────────────────────────────────────

/// Reactive workspace path. Changing this invalidates [apiClientProvider] and
/// all downstream data providers (projects, features, notes, library items).
class _WorkspacePath extends Notifier<String> {
  @override
  String build() => _cachedWorkspacePath ?? Directory.current.path;

  void update(String path) => state = path;
}

final workspacePathProvider = NotifierProvider<_WorkspacePath, String>(
  _WorkspacePath.new,
);

/// Cached workspace path — set once at startup before providers are read.
String? _cachedWorkspacePath;

/// Call this once at app startup (before ProviderScope is read) to prime the
/// workspace path from SharedPreferences. On non-desktop platforms this is a
/// no-op.
Future<void> initWorkspacePath() async {
  if (!isDesktop) return;
  final prefs = await SharedPreferences.getInstance();
  _cachedWorkspacePath =
      prefs.getString('workspace_path') ?? Directory.current.path;
}

/// Switches the active workspace. This:
/// 1. Persists the new path to SharedPreferences
/// 2. Adds it to the recent workspaces list
/// 3. Updates the reactive provider (which invalidates all data providers)
/// 4. Invalidates all library/data providers to force refetch
/// 5. Restarts the MCP orchestrator subprocess
/// 6. Refreshes the tray menu
Future<void> switchWorkspace(WidgetRef ref, String path) async {
  debugPrint('[Workspace] Switching to: $path');
  final prefs = await SharedPreferences.getInstance();

  // Save as current workspace
  await prefs.setString('workspace_path', path);
  _cachedWorkspacePath = path;

  // Add to recent workspaces list
  await _addRecentWorkspace(prefs, path);

  // Update the reactive provider. This cascades through the dependency graph:
  //   workspacePathProvider → localDatabaseProvider → DAOs → repositories
  //   workspacePathProvider → apiClientProvider → library FutureProviders
  // All screens using ref.watch() on these providers will automatically rebuild.
  ref.read(workspacePathProvider.notifier).update(path);

  // Restart the orchestrator subprocess with the new workspace
  final mcp = ref.read(mcpClientProvider);
  if (mcp != null) {
    await mcp.switchWorkspace(path);
    await TrayService.instance.updateIcon(mcp.processState.value);
  }

  // Refresh tray menu to show updated workspace name
  await TrayService.instance.refreshMenu();
}

/// Closes the current workspace, clearing the path and returning to the
/// welcome screen via the startup gate.
Future<void> closeWorkspace(WidgetRef ref) async {
  debugPrint('[Workspace] Closing workspace');
  final prefs = await SharedPreferences.getInstance();

  // Clear the stored workspace path
  await prefs.remove('workspace_path');
  _cachedWorkspacePath = null;

  // Stop the MCP subprocess
  final mcp = ref.read(mcpClientProvider);
  if (mcp != null) {
    mcp.disconnect();
  }

  // Update reactive provider to empty string (triggers downstream rebuild)
  ref.read(workspacePathProvider.notifier).update('');

  // Re-evaluate startup gate — this will detect needsWorkspace and redirect
  // to the welcome screen via the router redirect.
  await ref.read(startupGateProvider.notifier).recheck();
}

// ── Recent workspaces ───────────────────────────────────────────────────────

const _recentWorkspacesKey = 'recent_workspaces';
const _maxRecentWorkspaces = 10;

/// Provider for the list of recent workspaces.
final recentWorkspacesProvider = FutureProvider<List<RecentWorkspace>>((
  ref,
) async {
  // Watch workspace path so this refreshes after a switch
  ref.watch(workspacePathProvider);
  final prefs = await SharedPreferences.getInstance();
  return _loadRecentWorkspaces(prefs);
});

/// A recently-used workspace entry.
class RecentWorkspace {
  const RecentWorkspace({
    required this.path,
    required this.name,
    required this.lastUsed,
  });
  final String path;
  final String name;
  final String lastUsed; // ISO 8601
}

List<RecentWorkspace> _loadRecentWorkspaces(SharedPreferences prefs) {
  final raw = prefs.getString(_recentWorkspacesKey);
  if (raw == null || raw.isEmpty) return [];
  try {
    final list = jsonDecode(raw) as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return RecentWorkspace(
        path: m['path'] as String,
        name: m['name'] as String,
        lastUsed: m['lastUsed'] as String,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

Future<void> _addRecentWorkspace(SharedPreferences prefs, String path) async {
  final existing = _loadRecentWorkspaces(prefs);
  // Remove if already present
  existing.removeWhere((w) => w.path == path);
  // Add at the front
  existing.insert(
    0,
    RecentWorkspace(
      path: path,
      name: path.split('/').last,
      lastUsed: DateTime.now().toIso8601String(),
    ),
  );
  // Cap the list
  if (existing.length > _maxRecentWorkspaces) {
    existing.removeRange(_maxRecentWorkspaces, existing.length);
  }
  final encoded = jsonEncode(
    existing
        .map((w) => {'path': w.path, 'name': w.name, 'lastUsed': w.lastUsed})
        .toList(),
  );
  await prefs.setString(_recentWorkspacesKey, encoded);
}

// ── API client ──────────────────────────────────────────────────────────────

/// Platform-aware API client provider.
///
/// - **Desktop**: [LocalMcpClient] reads from the workspace filesystem.
/// - **Mobile / Web**: [RestClient] backed by Dio hitting the web-gate REST API.
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final rest = RestClient(dio: dio);

  if (isDesktop) {
    final workspace = ref.watch(workspacePathProvider);
    final client = LocalMcpClient(workspacePath: workspace, restClient: rest);
    ref.onDispose(client.close);
    return client;
  }

  return rest;
});

// ── MCP client ──────────────────────────────────────────────────────────────

/// Desktop-only MCP subprocess client. Used for direct `tools/call` passthrough
/// to `orchestra serve` (e.g. AI tool invocations). Not used for data fetching.
final mcpClientProvider = Provider<McpTcpClient?>((ref) {
  if (!isDesktop) return null;
  final mcp = McpTcpClient();

  // Attach action logger for MCP activity monitoring.
  final logger = ref.watch(mcpActionLoggerProvider);
  mcp.actionLogger = logger;

  // Wire tray menu actions to orchestrator process.
  final handler = DefaultTrayActionHandler(
    mcp,
    onWorkspaceChanged: (path) async {
      // Update reactive provider so UI rebuilds with new workspace data.
      await _addRecentWorkspace(await SharedPreferences.getInstance(), path);
      ref.read(workspacePathProvider.notifier).update(path);
    },
    onWorkspaceClosed: () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('workspace_path');
      _cachedWorkspacePath = null;
      ref.read(workspacePathProvider.notifier).update('');
      await ref.read(startupGateProvider.notifier).recheck();
    },
  );
  TrayService.instance.setHandler(handler);

  // Keep tray icon in sync with process state.
  void onStateChange() {
    TrayService.instance.updateIcon(mcp.processState.value);
  }

  mcp.processState.addListener(onStateChange);

  // Listen for server-pushed events and invalidate relevant providers.
  final notifSub = mcp.notifications.listen((json) {
    final method = json['method'] as String?;
    if (method != 'notifications/event' && method != 'notifications/data') {
      return;
    }
    final params = json['params'] as Map<String, dynamic>?;
    if (params == null) return;

    final topic = params['topic'] as String?;
    switch (topic) {
      case 'projects':
        ref.invalidate(syncedProjectsProvider);
      case 'features':
        ref.invalidate(syncedFeaturesProvider);
        ref.invalidate(projectsProvider);
      case 'plans':
        ref.invalidate(syncedPlansProvider);
      case 'notes':
        ref.invalidate(syncedNotesProvider);
        ref.read(notesRefreshProvider.notifier).refresh();
      case 'agents':
        ref.invalidate(syncedAgentsProvider);
      case 'skills':
        ref.invalidate(syncedSkillsProvider);
      case 'workflows':
        ref.invalidate(syncedWorkflowsProvider);
      case 'docs':
        ref.invalidate(syncedDocsProvider);
      case 'delegations':
        ref.invalidate(syncedDelegationsProvider);
      case 'requests':
        ref.invalidate(syncedRequestsProvider);
      case 'persons':
        ref.invalidate(syncedPersonsProvider);
      case 'sessions':
        ref.invalidate(syncedSessionsProvider);
    }
  });

  mcp.connect();
  ref.onDispose(() {
    notifSub.cancel();
    mcp.processState.removeListener(onStateChange);
    mcp.disconnect();
  });
  return mcp;
});

// ── MCP Action Logger ────────────────────────────────────────────────────────

/// Singleton MCP action logger — tracks all tool calls for the activity screen.
final mcpActionLoggerProvider = Provider<McpActionLogger>((ref) {
  final logger = McpActionLogger();
  ref.onDispose(logger.dispose);
  return logger;
});
