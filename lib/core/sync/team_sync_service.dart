import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:orchestra/core/sync/change_tracker.dart';
import 'package:orchestra/core/sync/sync_api_client.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_repository.dart';

/// Orchestrator service for team sharing operations.
///
/// Ties together [TeamSyncRepository] (local persistence),
/// [SyncApiClient] (REST transport), and [ChangeTracker] (sync queue) to
/// provide high-level share, check-for-updates, and pull workflows.
class TeamSyncService {
  TeamSyncService({
    required this.repository,
    required this.apiClient,
    required this.changeTracker,
  });

  final TeamSyncRepository repository;
  final SyncApiClient apiClient;
  final ChangeTracker changeTracker;

  // ── Share an entity with a team ────────────────────────────────────────

  /// Serializes [entityData], computes its content hash, calls the server
  /// share endpoint, and updates local metadata + share records on success.
  Future<ShareResponse> shareEntity({
    required String entityType,
    required String entityId,
    required String teamId,
    required bool shareWithAll,
    required List<String> memberIds,
    required SharePermission permission,
    required Map<String, dynamic> entityData,
  }) async {
    final hash = computeContentHash(entityData);

    // Build the share request for the API.
    final request = ShareRequest(
      entityType: entityType,
      entityId: entityId,
      teamId: teamId,
      shareWithAll: shareWithAll,
      memberIds: memberIds,
      permission: permission,
      entityData: entityData,
      contentHash: hash,
    );

    // Push to the server.
    final response = await apiClient.pushDeltas(
      SyncPushRequest(
        deltas: [
          SyncDelta(
            id: '${entityType}_${entityId}_share_${DateTime.now().microsecondsSinceEpoch}',
            entityType: entityType,
            entityId: entityId,
            operation: SyncOperation.update,
            data: request.toJson(),
            timestamp: DateTime.now().toUtc(),
            version: 0,
          ),
        ],
        clientId: changeTracker.nodeId,
        lastSyncTimestamp: DateTime.now().toUtc(),
      ),
    );

    final shareResponse = ShareResponse(
      shareId: '${entityType}_${entityId}_$teamId',
      success: response.conflicts.isEmpty,
      version: response.accepted.isNotEmpty ? 1 : 0,
      serverTimestamp: response.serverTimestamp,
      errorMessage: response.conflicts.isNotEmpty
          ? 'Conflict during share operation'
          : null,
    );

    if (shareResponse.success) {
      // Save the share locally.
      final share = TeamShare(
        id: shareResponse.shareId,
        entityType: entityType,
        entityId: entityId,
        teamId: teamId,
        shareWithAll: shareWithAll,
        memberIds: memberIds,
        permission: permission,
        sharedBy: changeTracker.nodeId,
        sharedAt: shareResponse.serverTimestamp,
        lastSyncedAt: shareResponse.serverTimestamp,
        version: shareResponse.version,
        contentHash: hash,
      );
      await repository.saveShare(share);

      // Update local sync metadata.
      final existing = await repository.getMetadata(entityType, entityId);
      final teamIds = existing?.sharedWithTeamIds.toList() ?? [];
      if (!teamIds.contains(teamId)) {
        teamIds.add(teamId);
      }
      await repository.upsertMetadata(
        EntitySyncMetadata(
          entityType: entityType,
          entityId: entityId,
          status: EntitySyncStatus.synced,
          lastSyncedAt: shareResponse.serverTimestamp,
          localVersion: shareResponse.version,
          remoteVersion: shareResponse.version,
          contentHash: hash,
          lastSyncedBy: changeTracker.nodeId,
          sharedWithTeamIds: teamIds,
        ),
      );

      // Record a version history entry.
      await repository.addVersionEntry(
        SyncVersionEntry(
          id: '${entityType}_${entityId}_v${shareResponse.version}',
          entityType: entityType,
          entityId: entityId,
          version: shareResponse.version,
          authorId: changeTracker.nodeId,
          authorName: changeTracker.nodeId,
          changeSummary: 'Shared with team $teamId',
          timestamp: shareResponse.serverTimestamp,
          contentHash: hash,
        ),
      );
    }

    return shareResponse;
  }

  // ── Check for team updates ─────────────────────────────────────────────

  /// Checks the server for pending updates from team members.
  /// Returns a [TeamUpdateStatus] suitable for displaying an "updates
  /// available" banner in the UI.
  Future<TeamUpdateStatus> checkForUpdates({String? deviceId}) async {
    try {
      final status = await apiClient.getStatus(deviceId: deviceId);
      return TeamUpdateStatus(
        availableUpdates: status.pendingCount,
        checkedAt: DateTime.now(),
      );
    } catch (_) {
      return TeamUpdateStatus(availableUpdates: 0, checkedAt: DateTime.now());
    }
  }

  // ── Pull team updates ──────────────────────────────────────────────────

  /// Downloads and applies updates from team members. Returns the number
  /// of entities that were updated.
  Future<int> pullUpdates({String? deviceId}) async {
    // Fetch all outdated entities that need refreshing.
    final outdated = await repository.getOutdatedEntities();
    if (outdated.isEmpty) {
      // Also check for any server-side updates since our last sync.
      final pullResponse = await apiClient.pullDeltas(
        SyncPullRequest(since: DateTime.utc(2000), limit: 100),
        deviceId: deviceId,
      );
      return pullResponse.deltas.length;
    }

    var updatedCount = 0;
    for (final meta in outdated) {
      try {
        // Pull changes for this specific entity type.
        final response = await apiClient.pullDeltas(
          SyncPullRequest(
            since: meta.lastSyncedAt ?? DateTime.utc(2000),
            entityTypes: [meta.entityType],
            limit: 50,
          ),
          deviceId: deviceId,
        );

        // Find deltas for this specific entity.
        final entityDeltas = response.deltas
            .where(
              (d) =>
                  d.entityType == meta.entityType &&
                  d.entityId == meta.entityId,
            )
            .toList();

        if (entityDeltas.isNotEmpty) {
          final latest = entityDeltas.last;
          final hash = latest.data != null
              ? computeContentHash(latest.data!)
              : meta.contentHash;

          // Update local metadata to reflect synced state.
          await repository.markSynced(
            meta.entityType,
            meta.entityId,
            version: latest.version,
            contentHash: hash ?? '',
            syncedBy: changeTracker.nodeId,
          );

          // Add version history entry.
          await repository.addVersionEntry(
            SyncVersionEntry(
              id: '${meta.entityType}_${meta.entityId}_v${latest.version}',
              entityType: meta.entityType,
              entityId: meta.entityId,
              version: latest.version,
              authorId: latest.clientId ?? 'server',
              authorName: latest.clientId ?? 'server',
              changeSummary: 'Pulled from server',
              timestamp: latest.timestamp,
              contentHash: hash,
            ),
          );

          updatedCount++;
        }
      } catch (_) {
        // Skip entities that fail to pull — they remain outdated and
        // will be retried on the next pull cycle.
      }
    }

    return updatedCount;
  }

  // ── Content hashing ────────────────────────────────────────────────────

  /// Computes a SHA-256 hash of JSON-encoded entity data for integrity
  /// checking and quick diff detection.
  String computeContentHash(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ── Batch share ────────────────────────────────────────────────────────

  /// Shares multiple entities at once. Each request is processed
  /// independently so partial failures don't block others.
  Future<List<ShareResponse>> batchShare({
    required List<ShareRequest> requests,
  }) async {
    final responses = <ShareResponse>[];
    for (final request in requests) {
      try {
        final response = await shareEntity(
          entityType: request.entityType,
          entityId: request.entityId,
          teamId: request.teamId,
          shareWithAll: request.shareWithAll,
          memberIds: request.memberIds,
          permission: request.permission,
          entityData: request.entityData,
        );
        responses.add(response);
      } catch (e) {
        responses.add(
          ShareResponse(
            shareId:
                '${request.entityType}_${request.entityId}_${request.teamId}',
            success: false,
            version: 0,
            serverTimestamp: DateTime.now(),
            errorMessage: e.toString(),
          ),
        );
      }
    }
    return responses;
  }

  // ── Entity sync status ─────────────────────────────────────────────────

  /// Returns the current sync status for a specific entity.
  Future<EntitySyncStatus> getEntitySyncStatus(
    String entityType,
    String entityId,
  ) async {
    final meta = await repository.getMetadata(entityType, entityId);
    return meta?.status ?? EntitySyncStatus.neverSynced;
  }

  // ── Mark entity changed ────────────────────────────────────────────────

  /// Updates local metadata after a local change to an entity, marking it
  /// as [EntitySyncStatus.pending] so the sync engine knows to push it.
  Future<void> markEntityChanged(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    final hash = computeContentHash(data);
    final existing = await repository.getMetadata(entityType, entityId);
    final newVersion = (existing?.localVersion ?? 0) + 1;

    await repository.upsertMetadata(
      EntitySyncMetadata(
        entityType: entityType,
        entityId: entityId,
        status: EntitySyncStatus.pending,
        lastSyncedAt: existing?.lastSyncedAt,
        localVersion: newVersion,
        remoteVersion: existing?.remoteVersion,
        contentHash: hash,
        lastSyncedBy: existing?.lastSyncedBy,
        sharedWithTeamIds: existing?.sharedWithTeamIds ?? [],
      ),
    );

    // Record the change in the change tracker so the sync engine will
    // pick it up during the next push cycle.
    await changeTracker.recordChange(
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      data: data,
    );
  }
}
