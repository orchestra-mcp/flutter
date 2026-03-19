import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

// ---------------------------------------------------------------------------
// Helper: replicates the same SHA-256 hash logic used by
// TeamSyncService.computeContentHash so we can verify correctness
// without constructing the full service (which requires DB + API deps).
//
// See: lib/core/sync/team_sync_service.dart lines 229-233
// ---------------------------------------------------------------------------
String computeContentHash(Map<String, dynamic> data) {
  final jsonString = jsonEncode(data);
  final bytes = utf8.encode(jsonString);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

void main() {
  // =========================================================================
  // 1. Content hash computation
  //
  // Tests the pure-logic hash function that TeamSyncService uses for
  // integrity checking and quick diff detection.
  // =========================================================================
  group('computeContentHash', () {
    test('produces a 64-character hex SHA-256 digest', () {
      final hash = computeContentHash({'key': 'value'});
      expect(hash.length, 64);
      // SHA-256 hex contains only [0-9a-f].
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });

    test('is deterministic — same data yields same hash', () {
      final data = {'title': 'Project Alpha', 'version': 42};
      final hash1 = computeContentHash(data);
      final hash2 = computeContentHash(data);
      expect(hash1, hash2);
    });

    test('different data yields different hashes', () {
      final hashA = computeContentHash({'title': 'A'});
      final hashB = computeContentHash({'title': 'B'});
      expect(hashA, isNot(hashB));
    });

    test('handles empty map', () {
      final hash = computeContentHash({});
      expect(hash.length, 64);
      // The SHA-256 of the JSON string "{}" is well-known.
      final expected = sha256.convert(utf8.encode('{}')).toString();
      expect(hash, expected);
    });

    test('handles nested data', () {
      final data = {
        'project': {
          'name': 'Orchestra',
          'tags': ['dart', 'flutter'],
          'meta': {'priority': 1, 'active': true},
        },
      };
      final hash = computeContentHash(data);
      expect(hash.length, 64);
      // Verify it matches the canonical JSON representation.
      final expected =
          sha256.convert(utf8.encode(jsonEncode(data))).toString();
      expect(hash, expected);
    });

    test('key order matters — different insertion order gives different hash', () {
      // jsonEncode preserves insertion order of LinkedHashMap literals.
      final dataA = {'a': 1, 'b': 2};
      final dataB = {'b': 2, 'a': 1};
      final hashA = computeContentHash(dataA);
      final hashB = computeContentHash(dataB);
      // In Dart, map literals are LinkedHashMap, so insertion order differs
      // the JSON output and thus the hash.
      expect(hashA, isNot(hashB));
    });

    test('handles data with null values', () {
      final hash = computeContentHash({'key': null});
      expect(hash.length, 64);
      final expected =
          sha256.convert(utf8.encode(jsonEncode({'key': null}))).toString();
      expect(hash, expected);
    });

    test('handles data with list values', () {
      final data = {
        'items': [1, 2, 3],
        'names': ['Alice', 'Bob'],
      };
      final hash = computeContentHash(data);
      final expected =
          sha256.convert(utf8.encode(jsonEncode(data))).toString();
      expect(hash, expected);
    });

    test('handles data with special unicode characters', () {
      final data = {'greeting': 'Hello, world!'};
      final hash = computeContentHash(data);
      expect(hash.length, 64);
    });

    test('handles large nested structures', () {
      final data = <String, dynamic>{};
      for (var i = 0; i < 100; i++) {
        data['field_$i'] = {
          'value': i,
          'nested': {'deep': i * 2},
          'list': List.generate(5, (j) => j + i),
        };
      }
      final hash = computeContentHash(data);
      expect(hash.length, 64);
      // Verify determinism on large data.
      expect(computeContentHash(data), hash);
    });

    test('numeric type differences produce different hashes', () {
      final hashInt = computeContentHash({'value': 1});
      final hashDouble = computeContentHash({'value': 1.0});
      // In Dart JSON encoding, 1 and 1.0 may produce different strings
      // depending on the runtime (1 vs 1.0). This test documents the behavior.
      final jsonInt = jsonEncode({'value': 1});
      final jsonDouble = jsonEncode({'value': 1.0});
      if (jsonInt == jsonDouble) {
        expect(hashInt, hashDouble);
      } else {
        expect(hashInt, isNot(hashDouble));
      }
    });

    test('boolean values hash correctly', () {
      final hashTrue = computeContentHash({'flag': true});
      final hashFalse = computeContentHash({'flag': false});
      expect(hashTrue, isNot(hashFalse));
    });
  });

  // =========================================================================
  // 2. EntitySyncStatus transitions
  //
  // Validates the logical state machine: neverSynced -> pending -> synced,
  // synced -> outdated -> synced, pending -> conflict -> synced, etc.
  // Uses copyWith to simulate what TeamSyncService does at each step.
  // =========================================================================
  group('EntitySyncStatus transitions', () {
    test('new entity starts at neverSynced', () {
      const meta = EntitySyncMetadata(
        entityType: 'project',
        entityId: 'proj-001',
      );
      expect(meta.status, EntitySyncStatus.neverSynced);
      expect(meta.localVersion, 0);
      expect(meta.remoteVersion, isNull);
      expect(meta.lastSyncedAt, isNull);
    });

    test('neverSynced -> pending after local change', () {
      // Simulates what markEntityChanged does: compute hash, bump version,
      // set status to pending.
      const original = EntitySyncMetadata(
        entityType: 'project',
        entityId: 'proj-001',
      );
      final data = {'title': 'New Project'};
      final hash = computeContentHash(data);
      final updated = original.copyWith(
        status: EntitySyncStatus.pending,
        localVersion: original.localVersion + 1,
        contentHash: hash,
      );
      expect(updated.status, EntitySyncStatus.pending);
      expect(updated.localVersion, 1);
      expect(updated.contentHash, hash);
      // Remote version and lastSyncedAt should remain null (never synced).
      expect(updated.remoteVersion, isNull);
      expect(updated.lastSyncedAt, isNull);
    });

    test('pending -> synced after successful share', () {
      final pendingMeta = EntitySyncMetadata(
        entityType: 'project',
        entityId: 'proj-001',
        status: EntitySyncStatus.pending,
        localVersion: 1,
        contentHash: computeContentHash({'title': 'New Project'}),
      );
      final serverTimestamp = DateTime.utc(2026, 3, 15, 12, 0, 0);
      final synced = pendingMeta.copyWith(
        status: EntitySyncStatus.synced,
        lastSyncedAt: serverTimestamp,
        remoteVersion: 1,
        localVersion: 1,
        lastSyncedBy: 'node-abc',
        sharedWithTeamIds: ['team-xyz'],
      );
      expect(synced.status, EntitySyncStatus.synced);
      expect(synced.lastSyncedAt, serverTimestamp);
      expect(synced.remoteVersion, 1);
      expect(synced.localVersion, 1);
      expect(synced.lastSyncedBy, 'node-abc');
      expect(synced.sharedWithTeamIds, ['team-xyz']);
    });

    test('synced -> pending after subsequent local change', () {
      final syncedMeta = EntitySyncMetadata(
        entityType: 'project',
        entityId: 'proj-001',
        status: EntitySyncStatus.synced,
        lastSyncedAt: DateTime.utc(2026, 3, 15, 12, 0, 0),
        localVersion: 1,
        remoteVersion: 1,
        contentHash: 'oldhash',
        lastSyncedBy: 'node-abc',
        sharedWithTeamIds: ['team-xyz'],
      );
      final newHash = computeContentHash({'title': 'Updated Title'});
      final updated = syncedMeta.copyWith(
        status: EntitySyncStatus.pending,
        localVersion: syncedMeta.localVersion + 1,
        contentHash: newHash,
      );
      expect(updated.status, EntitySyncStatus.pending);
      expect(updated.localVersion, 2);
      expect(updated.contentHash, newHash);
      // Remote version stays at 1 until pushed.
      expect(updated.remoteVersion, 1);
      // Team IDs preserved from previous state.
      expect(updated.sharedWithTeamIds, ['team-xyz']);
    });

    test('synced -> outdated when server has newer version', () {
      final syncedMeta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'note-001',
        status: EntitySyncStatus.synced,
        localVersion: 3,
        remoteVersion: 3,
        lastSyncedAt: DateTime.utc(2026, 3, 14),
      );
      // Server reports version 5 while we're at 3.
      final outdated = syncedMeta.copyWith(
        status: EntitySyncStatus.outdated,
        remoteVersion: 5,
      );
      expect(outdated.status, EntitySyncStatus.outdated);
      expect(outdated.localVersion, 3);
      expect(outdated.remoteVersion, 5);
    });

    test('outdated -> synced after pull completes', () {
      final outdatedMeta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'note-001',
        status: EntitySyncStatus.outdated,
        localVersion: 3,
        remoteVersion: 5,
        lastSyncedAt: DateTime.utc(2026, 3, 14),
      );
      final pullTimestamp = DateTime.utc(2026, 3, 15, 10, 0, 0);
      final synced = outdatedMeta.copyWith(
        status: EntitySyncStatus.synced,
        localVersion: 5,
        remoteVersion: 5,
        lastSyncedAt: pullTimestamp,
        contentHash: computeContentHash({'body': 'updated content'}),
      );
      expect(synced.status, EntitySyncStatus.synced);
      expect(synced.localVersion, 5);
      expect(synced.remoteVersion, 5);
      expect(synced.lastSyncedAt, pullTimestamp);
    });

    test('pending + remote change = conflict', () {
      const pendingMeta = EntitySyncMetadata(
        entityType: 'doc',
        entityId: 'doc-001',
        status: EntitySyncStatus.pending,
        localVersion: 4,
        remoteVersion: 3,
      );
      // Both client and server modified. Move to conflict.
      final conflicted = pendingMeta.copyWith(
        status: EntitySyncStatus.conflict,
        remoteVersion: 5,
      );
      expect(conflicted.status, EntitySyncStatus.conflict);
      expect(conflicted.localVersion, 4);
      expect(conflicted.remoteVersion, 5);
    });

    test('conflict -> synced after resolution', () {
      const conflicted = EntitySyncMetadata(
        entityType: 'doc',
        entityId: 'doc-001',
        status: EntitySyncStatus.conflict,
        localVersion: 4,
        remoteVersion: 5,
      );
      final resolved = conflicted.copyWith(
        status: EntitySyncStatus.synced,
        localVersion: 6,
        remoteVersion: 6,
        lastSyncedAt: DateTime.utc(2026, 3, 16),
        contentHash: computeContentHash({'body': 'merged content'}),
      );
      expect(resolved.status, EntitySyncStatus.synced);
      expect(resolved.localVersion, 6);
      expect(resolved.remoteVersion, 6);
    });

    test('team IDs accumulate across shares', () {
      const initial = EntitySyncMetadata(
        entityType: 'project',
        entityId: 'proj-001',
        status: EntitySyncStatus.synced,
        sharedWithTeamIds: ['team-a'],
      );
      final withSecondTeam = initial.copyWith(
        sharedWithTeamIds: [...initial.sharedWithTeamIds, 'team-b'],
      );
      expect(withSecondTeam.sharedWithTeamIds, ['team-a', 'team-b']);
      final withThirdTeam = withSecondTeam.copyWith(
        sharedWithTeamIds: [...withSecondTeam.sharedWithTeamIds, 'team-c'],
      );
      expect(
        withThirdTeam.sharedWithTeamIds,
        ['team-a', 'team-b', 'team-c'],
      );
    });

    test('version increments correctly through multiple changes', () {
      const meta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'note-001',
      );
      // Simulate 3 sequential local changes.
      var current = meta;
      for (var i = 1; i <= 3; i++) {
        current = current.copyWith(
          status: EntitySyncStatus.pending,
          localVersion: current.localVersion + 1,
        );
      }
      expect(current.localVersion, 3);
      expect(current.status, EntitySyncStatus.pending);
    });
  });

  // =========================================================================
  // 3. ShareRequest construction
  //
  // Verifies that ShareRequest payloads are built correctly with all fields,
  // defaults, and nested entity data intact.
  // =========================================================================
  group('ShareRequest construction', () {
    test('builds correct payload for full-team share', () {
      final entityData = {'title': 'My Project', 'description': 'A project'};
      final hash = computeContentHash(entityData);

      final request = ShareRequest(
        entityType: 'project',
        entityId: 'proj-abc',
        teamId: 'team-xyz',
        shareWithAll: true,
        memberIds: const [],
        permission: SharePermission.write,
        entityData: entityData,
        contentHash: hash,
      );

      expect(request.entityType, 'project');
      expect(request.entityId, 'proj-abc');
      expect(request.teamId, 'team-xyz');
      expect(request.shareWithAll, true);
      expect(request.memberIds, isEmpty);
      expect(request.permission, SharePermission.write);
      expect(request.contentHash, hash);
      expect(request.entityData, entityData);
    });

    test('builds correct payload for selective member share', () {
      final entityData = {'body': 'Note content'};
      final hash = computeContentHash(entityData);

      final request = ShareRequest(
        entityType: 'note',
        entityId: 'note-001',
        teamId: 'team-abc',
        shareWithAll: false,
        memberIds: ['mem-a', 'mem-b', 'mem-c'],
        permission: SharePermission.read,
        entityData: entityData,
        contentHash: hash,
      );

      expect(request.shareWithAll, false);
      expect(request.memberIds, ['mem-a', 'mem-b', 'mem-c']);
      expect(request.permission, SharePermission.read);
    });

    test('toJson includes all required fields', () {
      final entityData = {'key': 'value'};
      final hash = computeContentHash(entityData);

      final request = ShareRequest(
        entityType: 'skill',
        entityId: 'skill-001',
        teamId: 'team-123',
        shareWithAll: true,
        memberIds: const [],
        permission: SharePermission.admin,
        entityData: entityData,
        contentHash: hash,
      );

      final json = request.toJson();
      expect(json['entity_type'], 'skill');
      expect(json['entity_id'], 'skill-001');
      expect(json['team_id'], 'team-123');
      expect(json['share_with_all'], true);
      expect(json['member_ids'], <String>[]);
      expect(json['permission'], 'admin');
      expect(json['entity_data'], entityData);
      expect(json['content_hash'], hash);
    });

    test('content hash in request matches independently computed hash', () {
      final entityData = {
        'title': 'Workflow Config',
        'steps': [
          {'name': 'build', 'timeout': 300},
          {'name': 'test', 'timeout': 600},
        ],
      };
      final hash = computeContentHash(entityData);
      // Verify the hash we would put in the request matches the expected
      // SHA-256 of the JSON.
      final expected =
          sha256.convert(utf8.encode(jsonEncode(entityData))).toString();
      expect(hash, expected);
    });

    test('request with complex nested entity data serializes correctly', () {
      final entityData = {
        'name': 'Agent Config',
        'tools': [
          {'name': 'search', 'enabled': true},
          {'name': 'execute', 'enabled': false},
        ],
        'metadata': {
          'version': 2,
          'tags': ['ai', 'agent'],
          'nested': {'deep': {'value': 42}},
        },
      };
      final hash = computeContentHash(entityData);
      final request = ShareRequest(
        entityType: 'agent',
        entityId: 'agt-001',
        teamId: 'team-ai',
        shareWithAll: true,
        memberIds: const [],
        permission: SharePermission.write,
        entityData: entityData,
        contentHash: hash,
      );
      final json = request.toJson();
      // Verify nested data survives serialization.
      final ed = json['entity_data'] as Map<String, dynamic>;
      expect(ed['tools'], isList);
      expect((ed['tools'] as List).length, 2);
      expect(
        (ed['metadata'] as Map)['nested'],
        {'deep': {'value': 42}},
      );
    });

    test('default values for shareWithAll and permission', () {
      const request = ShareRequest(
        entityType: 'doc',
        entityId: 'doc-1',
        teamId: 'team-1',
        entityData: {'x': 1},
        contentHash: 'ch',
      );
      expect(request.shareWithAll, true);
      expect(request.memberIds, isEmpty);
      expect(request.permission, SharePermission.read);
    });
  });

  // =========================================================================
  // 4. ShareResponse construction and interpretation
  //
  // Verifies the response model the service constructs after API push.
  // =========================================================================
  group('ShareResponse construction', () {
    test('successful response has expected fields', () {
      final serverTimestamp = DateTime.utc(2026, 3, 15, 12, 0, 0);
      final response = ShareResponse(
        shareId: 'project_proj-abc_team-xyz',
        success: true,
        version: 1,
        serverTimestamp: serverTimestamp,
        errorMessage: null,
      );
      expect(response.success, true);
      expect(response.errorMessage, isNull);
      expect(response.version, 1);
      expect(response.serverTimestamp, serverTimestamp);
    });

    test('failed response includes error message', () {
      final response = ShareResponse(
        shareId: 'project_proj-abc_team-xyz',
        success: false,
        version: 0,
        serverTimestamp: DateTime.utc(2026, 3, 15),
        errorMessage: 'Conflict during share operation',
      );
      expect(response.success, false);
      expect(response.errorMessage, 'Conflict during share operation');
      expect(response.version, 0);
    });

    test('shareId follows entityType_entityId_teamId convention', () {
      // The service constructs shareId as '${entityType}_${entityId}_$teamId'.
      const entityType = 'note';
      const entityId = 'note-123';
      const teamId = 'team-abc';
      final expectedId = '${entityType}_${entityId}_$teamId';

      final response = ShareResponse(
        shareId: expectedId,
        success: true,
        version: 1,
        serverTimestamp: DateTime.utc(2026, 3, 15),
      );
      expect(response.shareId, 'note_note-123_team-abc');
    });

    test('toJson round-trip preserves success response', () {
      final response = ShareResponse(
        shareId: 'skill_skill-001_team-dev',
        success: true,
        version: 3,
        serverTimestamp: DateTime.utc(2026, 3, 15, 14, 30, 0),
      );
      final json = response.toJson();
      final restored = ShareResponse.fromJson(json);
      expect(restored.shareId, response.shareId);
      expect(restored.success, response.success);
      expect(restored.version, response.version);
      expect(restored.serverTimestamp, response.serverTimestamp);
      expect(restored.errorMessage, isNull);
    });

    test('toJson round-trip preserves error response', () {
      final response = ShareResponse(
        shareId: 'doc_doc-001_team-eng',
        success: false,
        version: 0,
        serverTimestamp: DateTime.utc(2026, 3, 15, 14, 30, 0),
        errorMessage: 'Rate limit exceeded',
      );
      final json = response.toJson();
      final restored = ShareResponse.fromJson(json);
      expect(restored.success, false);
      expect(restored.errorMessage, 'Rate limit exceeded');
    });

    test('success is determined by empty conflicts list', () {
      // The service sets success = response.conflicts.isEmpty.
      // Here we verify the logic: no conflicts = success.
      final noConflicts = <String>[];
      final hasConflicts = ['conflict-1'];
      expect(noConflicts.isEmpty, true); // => success = true
      expect(hasConflicts.isEmpty, false); // => success = false
    });

    test('version is 1 when accepted list is non-empty', () {
      // The service sets version = response.accepted.isNotEmpty ? 1 : 0.
      final accepted = ['delta-1'];
      final empty = <String>[];
      expect(accepted.isNotEmpty ? 1 : 0, 1);
      expect(empty.isNotEmpty ? 1 : 0, 0);
    });
  });

  // =========================================================================
  // 5. TeamShare construction from service context
  //
  // Validates the TeamShare object the service builds after a successful
  // share operation.
  // =========================================================================
  group('TeamShare construction', () {
    test('service creates TeamShare with correct fields after successful share', () {
      final entityData = {'title': 'Shared Note'};
      final hash = computeContentHash(entityData);
      final serverTimestamp = DateTime.utc(2026, 3, 15, 12, 0, 0);
      const nodeId = 'node-abc';
      const entityType = 'note';
      const entityId = 'note-001';
      const teamId = 'team-xyz';

      final share = TeamShare(
        id: '${entityType}_${entityId}_$teamId',
        entityType: entityType,
        entityId: entityId,
        teamId: teamId,
        shareWithAll: true,
        memberIds: const [],
        permission: SharePermission.write,
        sharedBy: nodeId,
        sharedAt: serverTimestamp,
        lastSyncedAt: serverTimestamp,
        version: 1,
        contentHash: hash,
      );

      expect(share.id, 'note_note-001_team-xyz');
      expect(share.entityType, entityType);
      expect(share.entityId, entityId);
      expect(share.teamId, teamId);
      expect(share.shareWithAll, true);
      expect(share.memberIds, isEmpty);
      expect(share.permission, SharePermission.write);
      expect(share.sharedBy, nodeId);
      expect(share.sharedAt, serverTimestamp);
      expect(share.lastSyncedAt, serverTimestamp);
      expect(share.version, 1);
      expect(share.contentHash, hash);
    });

    test('TeamShare for selective member share has correct memberIds', () {
      final serverTimestamp = DateTime.utc(2026, 3, 15);
      final share = TeamShare(
        id: 'project_proj-001_team-abc',
        entityType: 'project',
        entityId: 'proj-001',
        teamId: 'team-abc',
        shareWithAll: false,
        memberIds: ['user-1', 'user-2'],
        permission: SharePermission.admin,
        sharedBy: 'node-owner',
        sharedAt: serverTimestamp,
        lastSyncedAt: serverTimestamp,
        version: 1,
        contentHash: 'somehash',
      );
      expect(share.shareWithAll, false);
      expect(share.memberIds, ['user-1', 'user-2']);
      expect(share.permission, SharePermission.admin);
    });

    test('TeamShare toJson round-trip preserves content hash', () {
      final entityData = {'body': 'Test content'};
      final hash = computeContentHash(entityData);
      final serverTimestamp = DateTime.utc(2026, 3, 15, 12, 0, 0);
      final share = TeamShare(
        id: 'note_note-001_team-abc',
        entityType: 'note',
        entityId: 'note-001',
        teamId: 'team-abc',
        sharedBy: 'node-1',
        sharedAt: serverTimestamp,
        contentHash: hash,
      );
      final json = share.toJson();
      final restored = TeamShare.fromJson(json);
      expect(restored.contentHash, hash);
    });
  });

  // =========================================================================
  // 6. SyncVersionEntry construction from service context
  //
  // Validates the version history entries the service creates for share
  // and pull operations.
  // =========================================================================
  group('SyncVersionEntry construction', () {
    test('version entry for a share operation has correct fields', () {
      final hash = computeContentHash({'title': 'Test'});
      final serverTimestamp = DateTime.utc(2026, 3, 15, 12, 0, 0);

      final entry = SyncVersionEntry(
        id: 'note_note-001_v1',
        entityType: 'note',
        entityId: 'note-001',
        version: 1,
        authorId: 'node-abc',
        authorName: 'node-abc',
        changeSummary: 'Shared with team team-xyz',
        timestamp: serverTimestamp,
        contentHash: hash,
      );

      expect(entry.id, 'note_note-001_v1');
      expect(entry.entityType, 'note');
      expect(entry.entityId, 'note-001');
      expect(entry.version, 1);
      expect(entry.authorId, 'node-abc');
      expect(entry.authorName, 'node-abc');
      expect(entry.changeSummary, 'Shared with team team-xyz');
      expect(entry.timestamp, serverTimestamp);
      expect(entry.contentHash, hash);
    });

    test('version entry for a pull operation uses server author', () {
      final entry = SyncVersionEntry(
        id: 'project_proj-001_v5',
        entityType: 'project',
        entityId: 'proj-001',
        version: 5,
        authorId: 'server',
        authorName: 'server',
        changeSummary: 'Pulled from server',
        timestamp: DateTime.utc(2026, 3, 15, 14, 0, 0),
        contentHash: computeContentHash({'updated': true}),
      );

      expect(entry.authorId, 'server');
      expect(entry.changeSummary, 'Pulled from server');
      expect(entry.version, 5);
    });

    test('version entry IDs follow entityType_entityId_vN convention', () {
      const entityType = 'workflow';
      const entityId = 'wfl-001';
      const version = 3;
      final expectedId = '${entityType}_${entityId}_v$version';

      final entry = SyncVersionEntry(
        id: expectedId,
        entityType: entityType,
        entityId: entityId,
        version: version,
        authorId: 'user-1',
        authorName: 'Alice',
        timestamp: DateTime.utc(2026, 3, 15),
      );

      expect(entry.id, 'workflow_wfl-001_v3');
    });

    test('changeSummary includes team ID for share operations', () {
      const teamId = 'team-eng';
      const changeSummary = 'Shared with team $teamId';
      final entry = SyncVersionEntry(
        id: 'note_note-001_v1',
        entityType: 'note',
        entityId: 'note-001',
        version: 1,
        authorId: 'node-1',
        authorName: 'node-1',
        changeSummary: changeSummary,
        timestamp: DateTime.utc(2026, 3, 15),
      );
      expect(entry.changeSummary, contains('team-eng'));
    });
  });

  // =========================================================================
  // 7. TeamUpdateStatus
  //
  // Validates the model used to show "updates available" banners.
  // =========================================================================
  group('TeamUpdateStatus', () {
    test('zero-update status represents no available updates', () {
      final status = TeamUpdateStatus(
        availableUpdates: 0,
        checkedAt: DateTime.utc(2026, 3, 15),
      );
      expect(status.availableUpdates, 0);
      expect(status.updates, isEmpty);
    });

    test('status with updates contains correct entry count', () {
      final entries = [
        TeamUpdateEntry(
          entityType: 'note',
          entityId: 'note-1',
          entityTitle: 'Design',
          teamId: 'team-1',
          teamName: 'Eng',
          authorName: 'Bob',
          fromVersion: 1,
          toVersion: 3,
          updatedAt: DateTime.utc(2026, 3, 15),
        ),
      ];
      final status = TeamUpdateStatus(
        availableUpdates: 1,
        updates: entries,
        checkedAt: DateTime.utc(2026, 3, 15),
      );
      expect(status.availableUpdates, 1);
      expect(status.updates.length, 1);
      expect(status.updates.first.entityTitle, 'Design');
    });

    test('checkedAt timestamp is preserved', () {
      final checkedAt = DateTime.utc(2026, 3, 15, 10, 30, 0);
      final status = TeamUpdateStatus(
        availableUpdates: 0,
        checkedAt: checkedAt,
      );
      expect(status.checkedAt, checkedAt);
    });

    test('error fallback produces zero-update status', () {
      // The service returns 0 updates on API error. Verify the model works.
      final status = TeamUpdateStatus(
        availableUpdates: 0,
        checkedAt: DateTime.now(),
      );
      expect(status.availableUpdates, 0);
      expect(status.updates, isEmpty);
    });
  });

  // =========================================================================
  // 8. EntitySyncStatus enum completeness
  // =========================================================================
  group('EntitySyncStatus enum', () {
    test('contains all five expected values', () {
      expect(EntitySyncStatus.values.length, 5);
      expect(
        EntitySyncStatus.values,
        containsAll([
          EntitySyncStatus.neverSynced,
          EntitySyncStatus.synced,
          EntitySyncStatus.pending,
          EntitySyncStatus.outdated,
          EntitySyncStatus.conflict,
        ]),
      );
    });

    test('fromString and toJson round-trip for all values', () {
      for (final status in EntitySyncStatus.values) {
        final json = status.toJson();
        final parsed = EntitySyncStatus.fromString(json);
        expect(parsed, status);
      }
    });

    test('fromString rejects camelCase variants', () {
      expect(
        () => EntitySyncStatus.fromString('neverSynced'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromString rejects empty string', () {
      expect(
        () => EntitySyncStatus.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromString rejects unknown values', () {
      expect(
        () => EntitySyncStatus.fromString('in_progress'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // =========================================================================
  // 9. SharePermission coverage for service usage
  // =========================================================================
  group('SharePermission in service context', () {
    test('read permission is the default for ShareRequest', () {
      const request = ShareRequest(
        entityType: 'doc',
        entityId: 'doc-1',
        teamId: 'team-1',
        entityData: {'x': 1},
        contentHash: 'hash',
      );
      expect(request.permission, SharePermission.read);
    });

    test('all permission levels can be used in ShareRequest', () {
      for (final perm in SharePermission.values) {
        final request = ShareRequest(
          entityType: 'doc',
          entityId: 'doc-1',
          teamId: 'team-1',
          permission: perm,
          entityData: const {'x': 1},
          contentHash: 'hash',
        );
        expect(request.permission, perm);
        // Verify toJson uses the enum name.
        expect(request.toJson()['permission'], perm.name);
      }
    });

    test('all permission levels can be used in TeamShare', () {
      for (final perm in SharePermission.values) {
        final share = TeamShare(
          id: 'share-1',
          entityType: 'note',
          entityId: 'note-1',
          teamId: 'team-1',
          permission: perm,
          sharedBy: 'user-1',
          sharedAt: DateTime.utc(2026, 3, 15),
        );
        expect(share.permission, perm);
      }
    });
  });

  // =========================================================================
  // 10. SyncEntityType coverage
  // =========================================================================
  group('SyncEntityType in service context', () {
    test('all entity types can be used as entityType string in metadata', () {
      for (final entityType in SyncEntityType.values) {
        final meta = EntitySyncMetadata(
          entityType: entityType.name,
          entityId: '${entityType.name}-001',
        );
        expect(meta.entityType, entityType.name);
      }
    });

    test('all entity types can be used in ShareRequest', () {
      for (final entityType in SyncEntityType.values) {
        final request = ShareRequest(
          entityType: entityType.name,
          entityId: '${entityType.name}-001',
          teamId: 'team-1',
          entityData: const {},
          contentHash: computeContentHash(const {}),
        );
        expect(request.entityType, entityType.name);
      }
    });
  });

  // =========================================================================
  // 11. Integration: hash-based change detection
  //
  // Simulates the full flow: create entity, change it, verify hash detects
  // the change, share it, verify hash matches.
  // =========================================================================
  group('Hash-based change detection', () {
    test('changing entity data produces a new hash', () {
      final original = {'title': 'Draft', 'body': 'Initial content'};
      final modified = {'title': 'Draft', 'body': 'Updated content'};
      final hashOriginal = computeContentHash(original);
      final hashModified = computeContentHash(modified);
      expect(hashOriginal, isNot(hashModified));
    });

    test('no change means same hash — no sync needed', () {
      final data = {'title': 'Stable', 'version': 1};
      final hash1 = computeContentHash(data);
      // Simulate "loading from DB" by creating a new map with same values.
      final hash2 = computeContentHash({'title': 'Stable', 'version': 1});
      expect(hash1, hash2);
    });

    test('metadata content hash tracks entity changes', () {
      final v1Data = {'title': 'My Note', 'body': 'Hello'};
      final v2Data = {'title': 'My Note', 'body': 'Hello World'};
      final hashV1 = computeContentHash(v1Data);
      final hashV2 = computeContentHash(v2Data);

      // Simulate: entity at v1 synced.
      var meta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'note-001',
        status: EntitySyncStatus.synced,
        localVersion: 1,
        remoteVersion: 1,
        contentHash: hashV1,
      );
      expect(meta.contentHash, hashV1);

      // Local change to v2 — hash changes, status -> pending.
      meta = meta.copyWith(
        status: EntitySyncStatus.pending,
        localVersion: 2,
        contentHash: hashV2,
      );
      expect(meta.contentHash, hashV2);
      expect(meta.contentHash, isNot(hashV1));
      expect(meta.status, EntitySyncStatus.pending);

      // After successful push — status -> synced, remote matches local.
      meta = meta.copyWith(
        status: EntitySyncStatus.synced,
        remoteVersion: 2,
      );
      expect(meta.status, EntitySyncStatus.synced);
      expect(meta.localVersion, 2);
      expect(meta.remoteVersion, 2);
      expect(meta.contentHash, hashV2);
    });
  });
}
