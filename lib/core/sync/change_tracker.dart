import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/db/app_database.dart';
import 'package:orchestra/core/db/database_provider.dart';
import 'package:orchestra/core/sync/conflict_resolver.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/version_vector.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the monotonic Lamport counter across app restarts.
const _kLamportKey = 'change_tracker_lamport';

/// Persists the serialized version vector for this client node.
const _kVersionVectorKey = 'change_tracker_version_vector';

/// Persists the node ID that identifies this client in version vectors.
const _kNodeIdKey = 'change_tracker_node_id';

// ---------------------------------------------------------------------------
// ChangeTracker
// ---------------------------------------------------------------------------

/// Tracks local modifications by writing them to the `sync_queue` SQLite
/// table and maintaining a Lamport counter + version vector for ordering.
///
/// The [SyncEngine] reads pending changes from here, pushes them to the
/// server, and calls [markSynced] on success.
class ChangeTracker {
  ChangeTracker({required this.db});

  final AppDatabase db;

  int _lamport = 0;
  late String _nodeId;
  VersionVector _versionVector = VersionVector.empty();
  bool _initialized = false;

  // ── Initialization ─────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Lamport counter.
    _lamport = prefs.getInt(_kLamportKey) ?? 0;

    // Node ID.
    _nodeId = prefs.getString(_kNodeIdKey) ?? _generateNodeId();
    await prefs.setString(_kNodeIdKey, _nodeId);

    // Version vector.
    final vvJson = prefs.getString(_kVersionVectorKey);
    if (vvJson != null) {
      _versionVector = VersionVector.fromJson(
        jsonDecode(vvJson) as Map<String, dynamic>,
      );
    }

    _initialized = true;
  }

  String _generateNodeId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> _persistCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLamportKey, _lamport);
    await prefs.setString(
      _kVersionVectorKey,
      jsonEncode(_versionVector.toJson()),
    );
  }

  // ── Record a local change ──────────────────────────────────────────────

  /// Log a pending change to the `sync_queue` table.
  ///
  /// The returned [SyncDelta] can be used immediately for optimistic UI
  /// updates. The actual push happens when [SyncEngine.pushLocalChanges] runs.
  Future<SyncDelta> recordChange({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    Map<String, dynamic>? data,
  }) async {
    await _ensureInitialized();

    // Increment Lamport clock and version vector.
    _lamport++;
    _versionVector = _versionVector.increment(_nodeId);
    await _persistCounters();

    final deltaId =
        '${entityType}_${entityId}_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toUtc();

    final delta = SyncDelta(
      id: deltaId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      timestamp: now,
      version: _lamport,
      clientId: _nodeId,
      versionVector: _versionVector.toJson(),
    );

    // Persist to SQLite sync_queue.
    await db
        .into(db.syncQueueTable)
        .insert(
          SyncQueueTableCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation.name,
            payload: jsonEncode({
              'delta_id': deltaId,
              'data': data,
              'version': _lamport,
              'version_vector': _versionVector.toJson(),
            }),
            createdAt: now,
          ),
        );

    return delta;
  }

  // ── Query pending changes ──────────────────────────────────────────────

  /// Returns all un-synced local changes as typed [SyncDelta] objects.
  Future<List<SyncDelta>> getPendingChanges() async {
    await _ensureInitialized();
    final rows = await db.select(db.syncQueueTable).get();
    return rows.map((row) {
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      return SyncDelta(
        id:
            payload['delta_id'] as String? ??
            '${row.entityType}_${row.entityId}_${row.id}',
        entityType: row.entityType,
        entityId: row.entityId,
        operation: SyncOperation.fromString(row.operation),
        data: payload['data'] as Map<String, dynamic>?,
        timestamp: row.createdAt,
        version: payload['version'] as int? ?? 0,
        clientId: _nodeId,
        versionVector: payload['version_vector'] as Map<String, dynamic>?,
      );
    }).toList();
  }

  // ── Mark changes as synced ─────────────────────────────────────────────

  /// Remove synced entries from the queue by their delta IDs.
  ///
  /// The delta ID is stored inside the payload JSON, so we iterate and
  /// match rather than using a simple SQL `IN` clause.
  Future<void> markSynced(List<String> deltaIds) async {
    if (deltaIds.isEmpty) return;
    final deltaIdSet = deltaIds.toSet();
    final rows = await db.select(db.syncQueueTable).get();
    for (final row in rows) {
      final payload = jsonDecode(row.payload) as Map<String, dynamic>;
      final id = payload['delta_id'] as String?;
      if (id != null && deltaIdSet.contains(id)) {
        await (db.delete(
          db.syncQueueTable,
        )..where((t) => t.id.equals(row.id))).go();
      }
    }
  }

  // ── Conflict storage ───────────────────────────────────────────────────

  /// Store an unresolved conflict for later manual resolution in the UI.
  ///
  /// Conflicts are persisted to the sync_queue table with a special
  /// `_conflict` operation so they survive app restarts.
  Future<void> storeConflict(ConflictRecord conflict) async {
    await db
        .into(db.syncQueueTable)
        .insert(
          SyncQueueTableCompanion.insert(
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            operation: '_conflict',
            payload: jsonEncode(conflict.toJson()),
            createdAt: conflict.detectedAt,
          ),
        );
  }

  /// Retrieve all unresolved conflicts.
  Future<List<ConflictRecord>> getUnresolvedConflicts() async {
    final rows = await (db.select(
      db.syncQueueTable,
    )..where((t) => t.operation.equals('_conflict'))).get();
    return rows.map((row) {
      final json = jsonDecode(row.payload) as Map<String, dynamic>;
      return ConflictRecord.fromJson(json);
    }).toList();
  }

  /// Remove a resolved conflict from storage.
  Future<void> removeConflict(String conflictId) async {
    final rows = await (db.select(
      db.syncQueueTable,
    )..where((t) => t.operation.equals('_conflict'))).get();
    for (final row in rows) {
      final json = jsonDecode(row.payload) as Map<String, dynamic>;
      if (json['id'] == conflictId) {
        await (db.delete(
          db.syncQueueTable,
        )..where((t) => t.id.equals(row.id))).go();
        break;
      }
    }
  }

  // ── Counters (exposed for testing / debug) ─────────────────────────────

  /// The current Lamport counter value.
  int get lamportClock => _lamport;

  /// The current version vector for this node.
  VersionVector get versionVector => _versionVector;

  /// The node ID for this client.
  String get nodeId => _initialized ? _nodeId : '';
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the [ChangeTracker] backed by the app's Drift database.
final changeTrackerProvider = Provider<ChangeTracker>((ref) {
  return ChangeTracker(db: ref.watch(databaseProvider));
});
