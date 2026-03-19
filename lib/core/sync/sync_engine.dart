import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/db/app_database.dart';
import 'package:orchestra/core/db/database_provider.dart';
import 'package:orchestra/core/sync/change_tracker.dart';
import 'package:orchestra/core/sync/conflict_resolver.dart';
import 'package:orchestra/core/sync/sync_api_client.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/sync_status_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Sync state
// ---------------------------------------------------------------------------

/// High-level state of the sync engine lifecycle.
enum SyncPhase { idle, syncing, error }

/// Immutable snapshot of the sync engine state.
class SyncEngineState {
  const SyncEngineState({
    this.phase = SyncPhase.idle,
    this.lastSyncTimestamp,
    this.errorMessage,
    this.syncedDeltaCount = 0,
  });

  final SyncPhase phase;
  final DateTime? lastSyncTimestamp;
  final String? errorMessage;
  final int syncedDeltaCount;

  SyncEngineState copyWith({
    SyncPhase? phase,
    DateTime? lastSyncTimestamp,
    String? errorMessage,
    int? syncedDeltaCount,
  }) =>
      SyncEngineState(
        phase: phase ?? this.phase,
        lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
        errorMessage: errorMessage,
        syncedDeltaCount: syncedDeltaCount ?? this.syncedDeltaCount,
      );
}

// ---------------------------------------------------------------------------
// Sync engine notifier
// ---------------------------------------------------------------------------

/// Persists the ISO-8601 timestamp of the last successful sync.
const _kLastSyncKey = 'sync_engine_last_sync';

/// Unique client ID stored locally to identify this device.
const _kClientIdKey = 'sync_engine_client_id';

/// Core sync engine that orchestrates push/pull/initial/incremental sync.
///
/// Follows the existing [Notifier] pattern used by [ThemeNotifier] etc.
class SyncEngineNotifier extends Notifier<SyncEngineState> {
  @override
  SyncEngineState build() {
    _loadLastSync();
    return const SyncEngineState();
  }

  // ── Accessors ──────────────────────────────────────────────────────────

  AppDatabase get _db => ref.read(databaseProvider);
  ApiClient get _legacyClient => ref.read(apiClientProvider);
  SyncApiClient get _syncClient => ref.read(syncApiClientProvider);
  ChangeTracker get _changeTracker => ref.read(changeTrackerProvider);
  ConflictResolver get _conflictResolver => ConflictResolver();

  // ── Persisted state ────────────────────────────────────────────────────

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastSyncKey);
    if (raw != null) {
      state = state.copyWith(lastSyncTimestamp: DateTime.parse(raw));
    }
  }

  Future<void> _saveLastSync(DateTime ts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSyncKey, ts.toUtc().toIso8601String());
  }

  Future<String> _getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kClientIdKey);
    if (id == null) {
      id = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      await prefs.setString(_kClientIdKey, id);
    }
    return id;
  }

  // ── Initial sync ──────────────────────────────────────────────────────

  /// Pull ALL data from the server and bulk-insert into local SQLite.
  /// Intended for first launch or after a logout/re-login.
  Future<void> initialSync() async {
    if (state.phase == SyncPhase.syncing) return;
    state = state.copyWith(phase: SyncPhase.syncing, errorMessage: null);
    try {
      // Pull everything from epoch zero.
      final clientId = await _getClientId();
      final allDeltas = await _syncClient.pullAllDeltas(
        since: DateTime.utc(2000),
        deviceId: clientId,
      );
      await _applyDeltas(allDeltas);

      final serverTs =
          allDeltas.isNotEmpty ? allDeltas.last.timestamp : DateTime.now();
      await _saveLastSync(serverTs);
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncTimestamp: serverTs,
        syncedDeltaCount: allDeltas.length,
      );

      // Notify the status provider.
      ref.read(syncStatusProvider.notifier).markSynced(serverTs);
    } catch (e) {
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Incremental sync ──────────────────────────────────────────────────

  /// Pull only changes since the last sync timestamp.
  Future<void> incrementalSync() async {
    if (state.phase == SyncPhase.syncing) return;
    state = state.copyWith(phase: SyncPhase.syncing, errorMessage: null);
    try {
      final since =
          state.lastSyncTimestamp ?? DateTime.utc(2000);
      final clientId = await _getClientId();
      final response = await _syncClient.pullDeltas(
        SyncPullRequest(since: since),
        deviceId: clientId,
      );
      await _applyDeltas(response.deltas);
      await _saveLastSync(response.serverTimestamp);
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncTimestamp: response.serverTimestamp,
        syncedDeltaCount: response.deltas.length,
      );
      ref
          .read(syncStatusProvider.notifier)
          .markSynced(response.serverTimestamp);
    } catch (e) {
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Push local changes ────────────────────────────────────────────────

  /// Collect all un-pushed local changes from the [ChangeTracker] and
  /// send them to the server via the typed push endpoint.
  Future<void> pushLocalChanges() async {
    if (state.phase == SyncPhase.syncing) return;
    state = state.copyWith(phase: SyncPhase.syncing, errorMessage: null);
    try {
      final pending = await _changeTracker.getPendingChanges();
      if (pending.isEmpty) {
        state = state.copyWith(phase: SyncPhase.idle);
        return;
      }

      final clientId = await _getClientId();
      final request = SyncPushRequest(
        deltas: pending,
        clientId: clientId,
        lastSyncTimestamp:
            state.lastSyncTimestamp ?? DateTime.utc(2000),
      );
      final response = await _syncClient.pushDeltas(request);

      // Mark accepted deltas as synced.
      if (response.accepted.isNotEmpty) {
        await _changeTracker.markSynced(response.accepted);
      }

      // Handle conflicts using the configured strategy.
      for (final conflict in response.conflicts) {
        final resolved = _conflictResolver.resolveConflict(
          local: conflict.clientDelta,
          remote: conflict.serverDelta,
          strategy: ConflictStrategy.lastWriteWins,
        );
        if (resolved.resolution == ResolutionKind.useLocal) {
          // Re-push the local version with force.
          await _legacyClient.pushSync({
            'entity_type': conflict.clientDelta.entityType,
            'entity_id': conflict.clientDelta.entityId,
            'operation': conflict.clientDelta.operation.name,
            'payload': conflict.clientDelta.data ?? {},
            'force': true,
          });
        }
        // For useRemote or manual, the remote version already won.
        // Manual conflicts are stored for UI resolution.
        if (resolved.resolution == ResolutionKind.manual) {
          await _changeTracker.storeConflict(ConflictRecord(
            id: '${conflict.clientDelta.entityType}-${conflict.clientDelta.entityId}',
            entityType: conflict.clientDelta.entityType,
            entityId: conflict.clientDelta.entityId,
            localDelta: conflict.clientDelta,
            remoteDelta: conflict.serverDelta,
            detectedAt: DateTime.now(),
          ));
        }
        // For accepted conflicts, clear them from the queue.
        await _changeTracker.markSynced([conflict.clientDelta.id]);
      }

      await _saveLastSync(response.serverTimestamp);
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncTimestamp: response.serverTimestamp,
      );
      ref
          .read(syncStatusProvider.notifier)
          .markSynced(response.serverTimestamp);
    } catch (e) {
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Full sync ─────────────────────────────────────────────────────────

  /// Push local changes first, then pull remote changes.
  Future<void> fullSync() async {
    await pushLocalChanges();
    await incrementalSync();
  }

  // ── Legacy push (backward compat with existing SyncEngine) ────────────

  /// Drain the raw `sync_queue` table entries via the old untyped endpoint.
  /// Kept for backward compatibility with code that uses [enqueue].
  Future<void> pushLegacy() async {
    final queue = await _db.select(_db.syncQueueTable).get();
    if (queue.isEmpty) return;
    for (final entry in queue) {
      final nextRetry = entry.nextRetryAt;
      if (nextRetry != null && DateTime.now().isBefore(nextRetry)) continue;
      try {
        final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
        await _legacyClient.pushSync({
          'entity_type': entry.entityType,
          'entity_id': entry.entityId,
          'operation': entry.operation,
          'payload': payload,
        });
        await (_db.delete(_db.syncQueueTable)
              ..where((t) => t.id.equals(entry.id)))
            .go();
      } catch (_) {
        await (_db.update(_db.syncQueueTable)
              ..where((t) => t.id.equals(entry.id)))
            .write(SyncQueueTableCompanion(
          attempts: Value(entry.attempts + 1),
          nextRetryAt: Value(
            DateTime.now()
                .add(Duration(seconds: 30 * (entry.attempts + 1))),
          ),
        ));
      }
    }
  }

  // ── Enqueue (legacy) ──────────────────────────────────────────────────

  /// Enqueue a local mutation to the raw sync_queue table.
  /// New code should prefer [ChangeTracker.recordChange] instead.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payload: jsonEncode(payload),
            createdAt: DateTime.now(),
          ),
        );
    ref.read(syncStatusProvider.notifier).incrementPending();
  }

  // ── Apply deltas to local DB ──────────────────────────────────────────

  Future<void> _applyDeltas(List<SyncDelta> deltas) async {
    for (final delta in deltas) {
      switch (delta.entityType) {
        case 'feature':
          await _applyFeatureDelta(delta);
        case 'project':
          await _applyProjectDelta(delta);
        case 'note':
          await _applyNoteDelta(delta);
        default:
          // Unknown entity type — skip gracefully.
          break;
      }
    }
  }

  Future<void> _applyFeatureDelta(SyncDelta delta) async {
    if (delta.operation == SyncOperation.delete) {
      await (_db.delete(_db.featuresTable)
            ..where((t) => t.id.equals(delta.entityId)))
          .go();
      return;
    }
    final f = delta.data ?? {};
    final projectId = (f['project_id'] as String?) ?? '';
    await _db.into(_db.featuresTable).insertOnConflictUpdate(
          FeaturesTableCompanion.insert(
            id: delta.entityId,
            projectId: projectId,
            title: f['title'] as String? ?? '',
            status: Value(f['status'] as String? ?? 'todo'),
            kind: Value(f['kind'] as String? ?? 'feature'),
            priority: Value(f['priority'] as String? ?? 'P2'),
            labels: Value(f['labels'] as String? ?? '[]'),
            synced: const Value(true),
            createdAt:
                DateTime.tryParse(f['created_at'] as String? ?? '') ??
                    DateTime.now(),
            updatedAt:
                DateTime.tryParse(f['updated_at'] as String? ?? '') ??
                    DateTime.now(),
          ),
        );
  }

  Future<void> _applyProjectDelta(SyncDelta delta) async {
    if (delta.operation == SyncOperation.delete) {
      await (_db.delete(_db.projectsTable)
            ..where((t) => t.id.equals(delta.entityId)))
          .go();
      return;
    }
    final p = delta.data ?? {};
    final id = delta.entityId;
    final slug = (p['slug'] as String?) ?? id;
    await _db.into(_db.projectsTable).insertOnConflictUpdate(
          ProjectsTableCompanion.insert(
            id: id,
            slug: slug,
            name: p['name'] as String? ?? '',
            stacks: Value(p['stacks'] as String? ?? '[]'),
            synced: const Value(true),
            createdAt:
                DateTime.tryParse(p['created_at'] as String? ?? '') ??
                    DateTime.now(),
            updatedAt:
                DateTime.tryParse(p['updated_at'] as String? ?? '') ??
                    DateTime.now(),
          ),
        );
  }

  Future<void> _applyNoteDelta(SyncDelta delta) async {
    if (delta.operation == SyncOperation.delete) {
      await (_db.delete(_db.notesTable)
            ..where((t) => t.id.equals(delta.entityId)))
          .go();
      return;
    }
    final n = delta.data ?? {};
    await _db.into(_db.notesTable).insertOnConflictUpdate(
          NotesTableCompanion.insert(
            id: delta.entityId,
            projectId: Value(n['project_id'] as String?),
            title: n['title'] as String? ?? '',
            content: Value(n['content'] as String? ?? ''),
            pinned: Value(n['is_pinned'] as bool? ?? false),
            tags: Value(n['tags'] as String? ?? '[]'),
            synced: const Value(true),
            createdAt:
                DateTime.tryParse(n['created_at'] as String? ?? '') ??
                    DateTime.now(),
            updatedAt:
                DateTime.tryParse(n['updated_at'] as String? ?? '') ??
                    DateTime.now(),
          ),
        );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the sync engine as a [Notifier] so widgets can observe
/// [SyncEngineState] and trigger sync operations.
final syncEngineNotifierProvider =
    NotifierProvider<SyncEngineNotifier, SyncEngineState>(
  SyncEngineNotifier.new,
);
