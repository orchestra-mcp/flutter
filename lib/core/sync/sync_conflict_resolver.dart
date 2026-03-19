import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_conflict_models.dart';

// ── Text field detection ────────────────────────────────────────────────────

/// Fields considered long-form text content (merge-eligible).
const _textFields = {'content', 'description', 'body', 'notes', 'bio'};

bool _isTextField(String field) => _textFields.contains(field);

// ── Diff computation ────────────────────────────────────────────────────────

/// Computes field-level diffs between [local] and [remote] data maps.
///
/// Returns a [FieldDiff] for every key present in either map, marking
/// text-content fields for merge eligibility.
List<FieldDiff> computeFieldDiffs(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final allKeys = {...local.keys, ...remote.keys};
  final diffs = <FieldDiff>[];

  for (final key in allKeys) {
    final localVal = local[key];
    final remoteVal = remote[key];
    if (localVal?.toString() != remoteVal?.toString()) {
      diffs.add(
        FieldDiff(
          field: key,
          localValue: localVal,
          remoteValue: remoteVal,
          isTextContent: _isTextField(key),
        ),
      );
    }
  }
  return diffs;
}

// ── Conflict detection ──────────────────────────────────────────────────────

/// Detects a conflict between local and remote entity data.
///
/// Returns a [SyncConflict] if the versions diverge and the content hashes
/// differ, or `null` if there is no conflict.
SyncConflict? detectConflict({
  required String entityType,
  required String entityId,
  required String entityTitle,
  required int localVersion,
  required int remoteVersion,
  required Map<String, dynamic> localData,
  required Map<String, dynamic> remoteData,
  String? localHash,
  String? remoteHash,
}) {
  // Same version or remote is older — no conflict.
  if (remoteVersion <= localVersion) return null;

  // Hashes match — content is identical despite version bump.
  if (localHash != null && remoteHash != null && localHash == remoteHash) {
    return null;
  }

  final diffs = computeFieldDiffs(localData, remoteData);
  if (diffs.isEmpty) return null;

  return SyncConflict(
    entityType: entityType,
    entityId: entityId,
    entityTitle: entityTitle,
    localVersion: localVersion,
    remoteVersion: remoteVersion,
    localData: localData,
    remoteData: remoteData,
    diffs: diffs,
    detectedAt: DateTime.now().toUtc(),
  );
}

// ── Resolution strategies ───────────────────────────────────────────────────

/// Resolves a [SyncConflict] by keeping the local version.
SyncConflict resolveKeepLocal(SyncConflict conflict) {
  return conflict.copyWith(
    resolution: ConflictResolution.keepLocal,
    resolvedAt: DateTime.now().toUtc(),
    resolvedData: Map<String, dynamic>.from(conflict.localData),
  );
}

/// Resolves a [SyncConflict] by accepting the remote version.
SyncConflict resolveKeepRemote(SyncConflict conflict) {
  return conflict.copyWith(
    resolution: ConflictResolution.keepRemote,
    resolvedAt: DateTime.now().toUtc(),
    resolvedData: Map<String, dynamic>.from(conflict.remoteData),
  );
}

/// Resolves a [SyncConflict] by merging field-by-field.
///
/// [fieldChoices] maps each conflicting field name to `true` (keep local)
/// or `false` (keep remote). Fields not in the map default to remote.
SyncConflict resolveMerge(
  SyncConflict conflict,
  Map<String, bool> fieldChoices,
) {
  final merged = Map<String, dynamic>.from(conflict.remoteData);
  for (final diff in conflict.diffs) {
    if (diff.hasConflict) {
      final keepLocal = fieldChoices[diff.field] ?? false;
      if (keepLocal) {
        merged[diff.field] = diff.localValue;
      }
    }
  }
  return conflict.copyWith(
    resolution: ConflictResolution.merge,
    resolvedAt: DateTime.now().toUtc(),
    resolvedData: merged,
  );
}

/// Auto-resolves a conflict using last-write-wins for non-text fields
/// and marks text fields as needing manual merge.
///
/// Returns `null` if text fields have conflicts (needs manual resolution).
/// Returns a resolved conflict if all conflicts are non-text (auto-resolvable).
SyncConflict? autoResolve(SyncConflict conflict) {
  if (conflict.hasTextConflicts) return null;

  // All conflicts are non-text — use last-write-wins (remote wins).
  return resolveKeepRemote(conflict);
}

// ── Provider ────────────────────────────────────────────────────────────────

/// Tracks active (unresolved) sync conflicts per entity.
class SyncConflictNotifier extends Notifier<Map<String, SyncConflict>> {
  @override
  Map<String, SyncConflict> build() => {};

  /// Key for the conflict map.
  String _key(String entityType, String entityId) => '$entityType:$entityId';

  /// Adds or replaces a conflict for an entity.
  void addConflict(SyncConflict conflict) {
    final key = _key(conflict.entityType, conflict.entityId);
    state = {...state, key: conflict};
  }

  /// Resolves a conflict and removes it from the active map.
  void resolveConflict(
    String entityType,
    String entityId,
    SyncConflict resolved,
  ) {
    final key = _key(entityType, entityId);
    state = Map.from(state)..remove(key);
  }

  /// Returns the active conflict for an entity, or null.
  SyncConflict? getConflict(String entityType, String entityId) {
    return state[_key(entityType, entityId)];
  }

  /// Clears all active conflicts.
  void clear() {
    state = {};
  }
}

final syncConflictsProvider =
    NotifierProvider<SyncConflictNotifier, Map<String, SyncConflict>>(
      SyncConflictNotifier.new,
    );
