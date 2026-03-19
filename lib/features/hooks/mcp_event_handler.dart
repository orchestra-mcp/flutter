import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';
import 'package:orchestra/screens/projects/projects_screen.dart';

// ── MCP event handler ───────────────────────────────────────────────────────

/// Listens to the WebSocket [WsManager.eventStream] for MCP hook events
/// (tool calls, agent spawns, notifications) and invalidates relevant
/// Riverpod providers so screens auto-refresh.
class McpEventHandler {
  McpEventHandler({required this.ref, required this.wsManager}) {
    _sub = wsManager.eventStream.listen(_onEvent);
  }

  final Ref ref;
  final WsManager wsManager;
  StreamSubscription<WsEvent>? _sub;

  void _onEvent(WsEvent event) {
    switch (event) {
      case McpToolCalledEvent(:final toolName):
        _handleToolCalled(toolName);

      case McpAgentSpawnedEvent():
        // Agent spawned — could refresh agent sessions list.
        break;

      case McpNotificationEvent(:final entityType):
        _handleNotification(entityType);

      case McpGenericEvent():
        // Unknown MCP action — ignore.
        break;

      default:
        // Not an MCP event — handled by other listeners.
        break;
    }
  }

  /// When a tool is called that modifies data, invalidate the relevant
  /// providers so the UI stays fresh.
  void _handleToolCalled(String toolName) {
    // Feature lifecycle tools → refresh projects/features.
    if (toolName.startsWith('create_feature') ||
        toolName.startsWith('advance_feature') ||
        toolName.startsWith('submit_review') ||
        toolName.startsWith('set_current_feature')) {
      ref.invalidate(projectsProvider);
      return;
    }

    // Note tools → refresh notes list.
    if (toolName.startsWith('create_note') ||
        toolName.startsWith('update_note') ||
        toolName.startsWith('delete_note')) {
      // Notes providers are screen-local (_notesListProvider), so we
      // invalidate projects which triggers a cascade.
      ref.invalidate(projectsProvider);
      return;
    }

    // Project tools → refresh projects.
    if (toolName.startsWith('create_project') ||
        toolName.startsWith('update_project') ||
        toolName.startsWith('delete_project')) {
      ref.invalidate(projectsProvider);
      return;
    }
  }

  /// When an MCP notification arrives (delegation, permission, review),
  /// trigger a provider refresh so the notification badge updates.
  void _handleNotification(String entityType) {
    // Refresh projects as a catch-all — covers features, plans, etc.
    ref.invalidate(projectsProvider);
  }

  void dispose() {
    _sub?.cancel();
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

/// Initializes the [McpEventHandler] as a side-effect provider.
final mcpEventHandlerProvider = Provider<McpEventHandler>((ref) {
  final handler = McpEventHandler(
    ref: ref,
    wsManager: ref.watch(wsManagerProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});

/// Convenience provider that connects WS and activates the MCP event handler.
/// Watch this once at the app root alongside [syncRealtimeProvider].
final mcpRealtimeProvider = Provider<void>((ref) {
  final ws = ref.watch(wsManagerProvider);
  ws.connect();
  ref.watch(mcpEventHandlerProvider);
});
