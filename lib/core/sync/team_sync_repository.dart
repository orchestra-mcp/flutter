import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:orchestra/core/storage/local_database.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

/// Repository for team sharing and per-entity sync metadata tables.
///
/// Wraps Drift queries against [TeamSharesTable], [EntitySyncMetadataTable],
/// and [SyncVersionHistoryTable]. Follows the same pattern as
/// [ProjectRepository] — direct DB operations, no API calls.
class TeamSyncRepository {
  TeamSyncRepository({required this.db});

  final LocalDatabase db;

  // ── EntitySyncMetadata CRUD ──────────────────────────────────────────────

  /// Returns the sync metadata for a specific entity, or `null` if none
  /// has been recorded yet.
  Future<EntitySyncMetadata?> getMetadata(
    String entityType,
    String entityId,
  ) async {
    final row =
        await (db.select(db.entitySyncMetadataTable)..where(
              (t) =>
                  t.entityType.equals(entityType) & t.entityId.equals(entityId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return _rowToMetadata(row);
  }

  /// Returns all sync metadata entries for a given entity type.
  Future<List<EntitySyncMetadata>> getMetadataByType(String entityType) async {
    final rows = await (db.select(
      db.entitySyncMetadataTable,
    )..where((t) => t.entityType.equals(entityType))).get();
    return rows.map(_rowToMetadata).toList();
  }

  /// Returns all entities with `pending` sync status.
  Future<List<EntitySyncMetadata>> getPendingEntities() async {
    final rows = await (db.select(
      db.entitySyncMetadataTable,
    )..where((t) => t.status.equals('pending'))).get();
    return rows.map(_rowToMetadata).toList();
  }

  /// Returns all entities with `outdated` sync status.
  Future<List<EntitySyncMetadata>> getOutdatedEntities() async {
    final rows = await (db.select(
      db.entitySyncMetadataTable,
    )..where((t) => t.status.equals('outdated'))).get();
    return rows.map(_rowToMetadata).toList();
  }

  /// Inserts or updates sync metadata for an entity. Uses the composite
  /// primary key (entityType, entityId) for conflict resolution.
  Future<void> upsertMetadata(EntitySyncMetadata metadata) async {
    await db
        .into(db.entitySyncMetadataTable)
        .insertOnConflictUpdate(
          EntitySyncMetadataTableCompanion.insert(
            entityType: metadata.entityType,
            entityId: metadata.entityId,
            status: Value(metadata.status.toJson()),
            lastSyncedAt: Value(metadata.lastSyncedAt),
            localVersion: Value(metadata.localVersion),
            remoteVersion: Value(metadata.remoteVersion),
            contentHash: Value(metadata.contentHash),
            lastSyncedBy: Value(metadata.lastSyncedBy),
            sharedWithTeamIds: Value(jsonEncode(metadata.sharedWithTeamIds)),
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Updates only the sync status for an entity.
  Future<void> updateStatus(
    String entityType,
    String entityId,
    EntitySyncStatus status,
  ) async {
    await (db.update(db.entitySyncMetadataTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .write(
          EntitySyncMetadataTableCompanion(
            status: Value(status.toJson()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Marks an entity as fully synced with the server.
  Future<void> markSynced(
    String entityType,
    String entityId, {
    required int version,
    required String contentHash,
    String? syncedBy,
  }) async {
    final now = DateTime.now();
    await (db.update(db.entitySyncMetadataTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .write(
          EntitySyncMetadataTableCompanion(
            status: const Value('synced'),
            lastSyncedAt: Value(now),
            remoteVersion: Value(version),
            localVersion: Value(version),
            contentHash: Value(contentHash),
            lastSyncedBy: Value(syncedBy),
            updatedAt: Value(now),
          ),
        );
  }

  /// Deletes the sync metadata for a specific entity.
  Future<void> deleteMetadata(String entityType, String entityId) async {
    await (db.delete(db.entitySyncMetadataTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .go();
  }

  /// Watches all entity sync metadata as a reactive stream.
  Stream<List<EntitySyncMetadata>> watchAll() {
    return db
        .select(db.entitySyncMetadataTable)
        .watch()
        .map((rows) => rows.map(_rowToMetadata).toList());
  }

  /// Watches the sync metadata for a specific entity.
  Stream<EntitySyncMetadata?> watchEntity(String entityType, String entityId) {
    return (db.select(db.entitySyncMetadataTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _rowToMetadata(row));
  }

  // ── TeamShare CRUD ───────────────────────────────────────────────────────

  /// Saves a team share record (insert or update on conflict).
  Future<void> saveShare(TeamShare share) async {
    await db
        .into(db.teamSharesTable)
        .insertOnConflictUpdate(
          TeamSharesTableCompanion.insert(
            id: share.id,
            entityType: share.entityType,
            entityId: share.entityId,
            teamId: share.teamId,
            shareWithAll: Value(share.shareWithAll),
            memberIds: Value(jsonEncode(share.memberIds)),
            permission: Value(share.permission.name),
            sharedBy: share.sharedBy,
            sharedAt: share.sharedAt,
            lastSyncedAt: Value(share.lastSyncedAt),
            version: Value(share.version),
            contentHash: Value(share.contentHash),
          ),
        );
  }

  /// Returns all shares for a specific entity.
  Future<List<TeamShare>> getSharesForEntity(
    String entityType,
    String entityId,
  ) async {
    final rows =
        await (db.select(db.teamSharesTable)..where(
              (t) =>
                  t.entityType.equals(entityType) & t.entityId.equals(entityId),
            ))
            .get();
    return rows.map(_rowToShare).toList();
  }

  /// Returns all shares belonging to a specific team.
  Future<List<TeamShare>> getSharesByTeam(String teamId) async {
    final rows = await (db.select(
      db.teamSharesTable,
    )..where((t) => t.teamId.equals(teamId))).get();
    return rows.map(_rowToShare).toList();
  }

  /// Deletes a single share by its ID.
  Future<void> deleteShare(String shareId) async {
    await (db.delete(
      db.teamSharesTable,
    )..where((t) => t.id.equals(shareId))).go();
  }

  /// Deletes all shares for a specific entity.
  Future<void> deleteSharesForEntity(String entityType, String entityId) async {
    await (db.delete(db.teamSharesTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .go();
  }

  /// Watches all shares for a specific entity as a reactive stream.
  Stream<List<TeamShare>> watchSharesForEntity(
    String entityType,
    String entityId,
  ) {
    return (db.select(db.teamSharesTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .watch()
        .map((rows) => rows.map(_rowToShare).toList());
  }

  // ── SyncVersionHistory CRUD ──────────────────────────────────────────────

  /// Adds a new version history entry.
  Future<void> addVersionEntry(SyncVersionEntry entry) async {
    await db
        .into(db.syncVersionHistoryTable)
        .insertOnConflictUpdate(
          SyncVersionHistoryTableCompanion.insert(
            id: entry.id,
            entityType: entry.entityType,
            entityId: entry.entityId,
            version: entry.version,
            authorId: entry.authorId,
            authorName: entry.authorName,
            changeSummary: Value(entry.changeSummary),
            timestamp: entry.timestamp,
            contentHash: Value(entry.contentHash),
          ),
        );
  }

  /// Returns the full version history for an entity, ordered newest first.
  Future<List<SyncVersionEntry>> getVersionHistory(
    String entityType,
    String entityId,
  ) async {
    final rows =
        await (db.select(db.syncVersionHistoryTable)
              ..where(
                (t) =>
                    t.entityType.equals(entityType) &
                    t.entityId.equals(entityId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.version)]))
            .get();
    return rows.map(_rowToVersionEntry).toList();
  }

  /// Returns the latest (highest version) entry for an entity.
  Future<SyncVersionEntry?> getLatestVersion(
    String entityType,
    String entityId,
  ) async {
    final row =
        await (db.select(db.syncVersionHistoryTable)
              ..where(
                (t) =>
                    t.entityType.equals(entityType) &
                    t.entityId.equals(entityId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.version)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return _rowToVersionEntry(row);
  }

  /// Deletes all version history entries for an entity.
  Future<void> deleteVersionHistory(String entityType, String entityId) async {
    await (db.delete(db.syncVersionHistoryTable)..where(
          (t) => t.entityType.equals(entityType) & t.entityId.equals(entityId),
        ))
        .go();
  }

  // ── Row → Model converters ──────────────────────────────────────────────

  EntitySyncMetadata _rowToMetadata(EntitySyncMetadataTableData row) {
    List<String> teamIds;
    try {
      teamIds = (jsonDecode(row.sharedWithTeamIds) as List).cast<String>();
    } catch (_) {
      teamIds = [];
    }
    return EntitySyncMetadata(
      entityType: row.entityType,
      entityId: row.entityId,
      status: EntitySyncStatus.fromString(row.status),
      lastSyncedAt: row.lastSyncedAt,
      localVersion: row.localVersion,
      remoteVersion: row.remoteVersion,
      contentHash: row.contentHash,
      lastSyncedBy: row.lastSyncedBy,
      sharedWithTeamIds: teamIds,
    );
  }

  TeamShare _rowToShare(TeamSharesTableData row) {
    List<String> memberIds;
    try {
      memberIds = (jsonDecode(row.memberIds) as List).cast<String>();
    } catch (_) {
      memberIds = [];
    }
    return TeamShare(
      id: row.id,
      entityType: row.entityType,
      entityId: row.entityId,
      teamId: row.teamId,
      shareWithAll: row.shareWithAll,
      memberIds: memberIds,
      permission: SharePermission.fromString(row.permission),
      sharedBy: row.sharedBy,
      sharedAt: row.sharedAt,
      lastSyncedAt: row.lastSyncedAt,
      version: row.version,
      contentHash: row.contentHash,
    );
  }

  SyncVersionEntry _rowToVersionEntry(SyncVersionHistoryTableData row) {
    return SyncVersionEntry(
      id: row.id,
      entityType: row.entityType,
      entityId: row.entityId,
      version: row.version,
      authorId: row.authorId,
      authorName: row.authorName,
      changeSummary: row.changeSummary,
      timestamp: row.timestamp,
      contentHash: row.contentHash,
    );
  }
}
