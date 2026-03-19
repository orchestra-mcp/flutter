import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/sync/change_tracker.dart';
import 'package:orchestra/core/sync/sync_status_provider.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_repository.dart';
import 'package:orchestra/core/sync/team_sync_service.dart';

// ── Repository ──────────────────────────────────────────────────────────────

/// Provides the [TeamSyncRepository] backed by the workspace-scoped
/// [LocalDatabase] from [localDatabaseProvider].
final teamSyncRepositoryProvider = Provider<TeamSyncRepository>((ref) {
  return TeamSyncRepository(db: ref.watch(localDatabaseProvider));
});

// ── Service ─────────────────────────────────────────────────────────────────

/// Provides the [TeamSyncService] that orchestrates team sharing operations
/// using the repository, API client, and change tracker.
final teamSyncServiceProvider = Provider<TeamSyncService>((ref) {
  return TeamSyncService(
    repository: ref.watch(teamSyncRepositoryProvider),
    apiClient: ref.watch(syncApiClientProvider),
    changeTracker: ref.watch(changeTrackerProvider),
  );
});

// ── Per-entity sync status ──────────────────────────────────────────────────

/// Fetches the [EntitySyncMetadata] for a specific entity identified by
/// a `(entityType, entityId)` tuple. Returns `null` if the entity has
/// never been tracked.
final entitySyncStatusProvider =
    FutureProvider.family<EntitySyncMetadata?, (String, String)>((
      ref,
      params,
    ) async {
      final repo = ref.watch(teamSyncRepositoryProvider);
      return repo.getMetadata(params.$1, params.$2);
    });

// ── Team update status (for banner) ─────────────────────────────────────────

/// Checks the server for pending team updates. Consumers can use this to
/// show an "X updates available" banner.
final teamUpdatesProvider = FutureProvider<TeamUpdateStatus>((ref) async {
  final service = ref.watch(teamSyncServiceProvider);
  // Ensure ChangeTracker is initialized so nodeId is populated.
  // Without a valid device_id the server counts all sync_logs as pending.
  final nodeId = service.changeTracker.nodeId;
  if (nodeId.isEmpty) {
    return TeamUpdateStatus(availableUpdates: 0, checkedAt: DateTime.now());
  }
  return service.checkForUpdates(deviceId: nodeId);
});

// ── Shares for entity (reactive stream) ─────────────────────────────────────

/// Watches all [TeamShare] records for a specific entity as a reactive
/// stream. The entity is identified by a `(entityType, entityId)` tuple.
final entitySharesProvider =
    StreamProvider.family<List<TeamShare>, (String, String)>((ref, params) {
      final repo = ref.watch(teamSyncRepositoryProvider);
      return repo.watchSharesForEntity(params.$1, params.$2);
    });

// ── Pending entities ────────────────────────────────────────────────────────

/// Returns all entities with `pending` sync status — local changes that
/// have not yet been pushed to the server.
final pendingEntitiesProvider = FutureProvider<List<EntitySyncMetadata>>((
  ref,
) async {
  final repo = ref.watch(teamSyncRepositoryProvider);
  return repo.getPendingEntities();
});

// ── Outdated entities ───────────────────────────────────────────────────────

/// Returns all entities with `outdated` sync status — the server has
/// newer versions that haven't been pulled yet.
final outdatedEntitiesProvider = FutureProvider<List<EntitySyncMetadata>>((
  ref,
) async {
  final repo = ref.watch(teamSyncRepositoryProvider);
  return repo.getOutdatedEntities();
});

// ── All sync metadata (reactive stream) ─────────────────────────────────────

/// Watches all entity sync metadata entries as a reactive stream.
/// Useful for a sync status dashboard or debug view.
final allSyncMetadataProvider = StreamProvider<List<EntitySyncMetadata>>((ref) {
  final repo = ref.watch(teamSyncRepositoryProvider);
  return repo.watchAll();
});
