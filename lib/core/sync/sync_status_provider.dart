import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/sync/sync_api_client.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';

// ---------------------------------------------------------------------------
// SyncApiClient provider
// ---------------------------------------------------------------------------

/// Provides the typed [SyncApiClient] backed by the shared Dio instance.
final syncApiClientProvider = Provider<SyncApiClient>((ref) {
  return SyncApiClient(dio: ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// SyncStatusNotifier
// ---------------------------------------------------------------------------

/// Reactive sync status that combines:
///   1. Periodic polling of `GET /api/sync/status`
///   2. Real-time WebSocket events that nudge a refresh
///
/// Consumers see a [SyncStatusInfo] that always reflects the latest state.
class SyncStatusNotifier extends Notifier<SyncStatusInfo> {
  Timer? _pollTimer;
  StreamSubscription<WsState>? _wsSub;

  static const Duration _pollInterval = Duration(seconds: 30);

  @override
  SyncStatusInfo build() {
    // Fetch from server immediately on creation.
    refresh();

    // Poll on a fixed interval as a fallback.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refresh());

    // When WS reconnects, refresh status immediately.
    final wsManager = ref.watch(wsManagerProvider);
    _wsSub?.cancel();
    _wsSub = wsManager.stateStream.listen((wsState) {
      if (wsState == WsState.connected) {
        refresh();
      }
      // Mirror WS connectivity into the status model.
      state = state.copyWith(connected: wsState == WsState.connected);
    });

    // Clean up timers and subscriptions on dispose.
    ref.onDispose(() {
      _pollTimer?.cancel();
      _wsSub?.cancel();
    });

    return const SyncStatusInfo(
      lastSync: null,
      pendingCount: 0,
      connected: false,
    );
  }

  SyncApiClient get _apiClient => ref.read(syncApiClientProvider);

  /// Force-refresh the status from the server.
  Future<void> refresh() async {
    try {
      final info = await _apiClient.getStatus();
      state = info;
    } catch (_) {
      // On network failure, mark disconnected but keep last-known values.
      state = state.copyWith(connected: false);
    }
  }

  /// Locally adjust the pending count (e.g. after enqueuing a change).
  void incrementPending([int amount = 1]) {
    state = state.copyWith(pendingCount: state.pendingCount + amount);
  }

  /// Mark sync as just completed with [serverTimestamp].
  void markSynced(DateTime serverTimestamp) {
    state = state.copyWith(
      lastSync: serverTimestamp,
      pendingCount: 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Exposes the reactive [SyncStatusInfo] to the widget tree.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatusInfo>(
  SyncStatusNotifier.new,
);

/// Quick read-only accessor for the sync connection state.
final isSyncConnectedProvider = Provider<bool>((ref) {
  return ref.watch(syncStatusProvider).connected;
});

/// Quick read-only accessor for the pending delta count.
final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(syncStatusProvider).pendingCount;
});
