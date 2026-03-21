import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_notification_service.dart';
import 'package:orchestra/core/sync/team_management_provider.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';
import 'package:orchestra/widgets/team_updates_banner.dart';

// ── Sync event handler ───────────────────────────────────────────────────────

/// Listens to the WebSocket [WsManager.eventStream] for sync-related events
/// and invalidates the appropriate Riverpod providers so the UI stays fresh.
///
/// Managed as a Riverpod provider so it auto-disposes with the ProviderScope.
class SyncEventHandler {
  SyncEventHandler({required this.ref, required this.wsManager}) {
    _sub = wsManager.eventStream.listen(_onEvent);
  }

  final Ref ref;
  final WsManager wsManager;
  StreamSubscription<WsEvent>? _sub;

  void _onEvent(WsEvent event) {
    // Show a desktop/mobile push notification for sync events.
    ref.read(syncNotificationServiceProvider).showForEvent(event);

    switch (event) {
      case SyncEntityUpdatedEvent(:final entityType, :final entityId):
        // Refresh the specific entity's sync status.
        ref.invalidate(entitySyncStatusProvider((entityType, entityId)));
        // Refresh the team updates banner (new update available).
        ref.invalidate(teamUpdatesProvider);
        // Reset banner dismissed so it reappears.
        ref.read(bannerDismissedProvider.notifier).reset();

      case SyncEntitySharedEvent(:final entityType, :final entityId):
        // Refresh entity sync status and team updates.
        ref.invalidate(entitySyncStatusProvider((entityType, entityId)));
        ref.invalidate(teamUpdatesProvider);
        ref.read(bannerDismissedProvider.notifier).reset();
        // Also refresh the shares list for this entity.
        ref.invalidate(entitySharesProvider((entityType, entityId)));
        // Refresh team data in case membership changed.
        ref.invalidate(teamsProvider);

      case SyncEntityDeletedEvent(:final entityType, :final entityId):
        // Refresh the specific entity's status.
        ref.invalidate(entitySyncStatusProvider((entityType, entityId)));
        ref.invalidate(entitySharesProvider((entityType, entityId)));
        ref.invalidate(teamUpdatesProvider);

      default:
        break;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Initializes the [SyncEventHandler] as a side-effect provider.
///
/// Watch this provider from the app root (e.g. in a startup widget or the
/// summary screen) to activate real-time sync event handling.
final syncEventHandlerProvider = Provider<SyncEventHandler>((ref) {
  final handler = SyncEventHandler(
    ref: ref,
    wsManager: ref.watch(wsManagerProvider),
  );
  ref.onDispose(handler.dispose);
  return handler;
});

/// Convenience provider that connects the WebSocket and activates the
/// sync event handler. Watch this once at the app root.
final syncRealtimeProvider = Provider<void>((ref) {
  // Ensure WS is connected.
  final ws = ref.watch(wsManagerProvider);
  ws.connect();

  // Activate the event handler.
  ref.watch(syncEventHandlerProvider);
});
