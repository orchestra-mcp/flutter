import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/change_tracker.dart';
import 'package:orchestra/core/sync/conflict_resolver.dart';
import 'package:orchestra/core/sync/sync_engine.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/sync_scheduler.dart';
import 'package:orchestra/core/sync/sync_status_provider.dart';

/// Re-export all sync providers from a single barrel file so consumers
/// can do: `import 'package:orchestra/core/sync/sync_provider.dart';`

// ── Engine ────────────────────────────────────────────────────────────────
/// The primary sync engine notifier — observe [SyncEngineState], trigger
/// [initialSync], [incrementalSync], [pushLocalChanges], [fullSync].
final syncEngineProvider = syncEngineNotifierProvider;

// ── API client ────────────────────────────────────────────────────────────
/// Typed REST client for `/api/sync/push`, `/api/sync/pull`, `/api/sync/status`.
final syncClientProvider = syncApiClientProvider;

// ── Status ────────────────────────────────────────────────────────────────
/// Reactive [SyncStatusInfo] with periodic polling + WS refresh.
final syncStatusProv = syncStatusProvider;

// ── Change tracker ────────────────────────────────────────────────────────
/// Records local mutations and exposes pending changes for push.
final changeTrackerProv = changeTrackerProvider;

// ── Conflict resolver ─────────────────────────────────────────────────────
/// Stateless resolver for sync conflicts.
final conflictResolverProv = conflictResolverProvider;

// ── Scheduler ─────────────────────────────────────────────────────────────
/// Auto-sync on timer, app foreground, connectivity change, and debounced nudge.
final syncSchedulerProv = syncSchedulerProvider;

// ── Convenience ───────────────────────────────────────────────────────────

/// Whether the current sync phase is actively syncing.
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncEngineNotifierProvider).phase == SyncPhase.syncing;
});

/// The most recent sync error message, or null if none.
final syncErrorProvider = Provider<String?>((ref) {
  return ref.watch(syncEngineNotifierProvider).errorMessage;
});

/// Last successful sync timestamp.
final lastSyncTimestampProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncEngineNotifierProvider).lastSyncTimestamp;
});
