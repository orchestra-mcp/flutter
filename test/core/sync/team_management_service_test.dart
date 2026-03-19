import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_management_service.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

void main() {
  // =========================================================================
  // TeamSelectorData
  // =========================================================================
  group('TeamSelectorData', () {
    test('membersOf returns empty list for unknown team', () {
      const data = TeamSelectorData(teams: [], membersByTeamId: {});
      expect(data.membersOf('unknown'), isEmpty);
    });

    test('hasTeams is false when empty', () {
      const data = TeamSelectorData(teams: [], membersByTeamId: {});
      expect(data.hasTeams, false);
    });

    test('hasTeams is true when teams exist', () {
      final data = TeamSelectorData(
        teams: [
          Team(
            id: 't1',
            name: 'Engineering',
            createdAt: DateTime.utc(2026),
          ),
        ],
        membersByTeamId: const {},
      );
      expect(data.hasTeams, true);
    });

    test('membersOf returns correct members for known team', () {
      const members = [
        TeamMember(id: 'u1', name: 'Alice'),
        TeamMember(id: 'u2', name: 'Bob'),
      ];
      const data = TeamSelectorData(
        teams: [],
        membersByTeamId: {'team-1': members},
      );
      expect(data.membersOf('team-1'), hasLength(2));
      expect(data.membersOf('team-1')[0].name, 'Alice');
    });
  });

  // =========================================================================
  // Team model
  // =========================================================================
  group('Team', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'team-1',
        'name': 'Engineering',
        'description': 'The eng team',
        'avatar_url': 'https://img.test/team.png',
        'members': [
          {
            'id': 'u1',
            'name': 'Alice',
            'email': 'alice@test.com',
            'role': 'admin',
            'is_online': true,
          },
        ],
        'created_at': '2026-03-01T00:00:00Z',
      };
      final team = Team.fromJson(json);
      expect(team.id, 'team-1');
      expect(team.name, 'Engineering');
      expect(team.description, 'The eng team');
      expect(team.avatarUrl, 'https://img.test/team.png');
      expect(team.members.length, 1);
      expect(team.members[0].name, 'Alice');
    });

    test('toJson round-trip preserves data', () {
      final team = Team(
        id: 't1',
        name: 'Test Team',
        description: 'A test',
        avatarUrl: 'https://img.test/t.png',
        createdAt: DateTime.utc(2026, 3, 1),
        members: const [TeamMember(id: 'm1', name: 'Member 1')],
      );
      final json = team.toJson();
      final restored = Team.fromJson(json);
      expect(restored.id, team.id);
      expect(restored.name, team.name);
      expect(restored.description, team.description);
      expect(restored.avatarUrl, team.avatarUrl);
      expect(restored.members.length, 1);
      expect(restored.members[0].id, 'm1');
    });

    test('copyWith preserves unmodified fields', () {
      final team = Team(
        id: 't1',
        name: 'Original',
        description: 'Desc',
        createdAt: DateTime.utc(2026),
      );
      final updated = team.copyWith(name: 'Updated');
      expect(updated.id, 't1');
      expect(updated.name, 'Updated');
      expect(updated.description, 'Desc');
    });

    test('toString is human-readable', () {
      final team = Team(
        id: 't1',
        name: 'Eng',
        createdAt: DateTime.utc(2026),
        members: const [TeamMember(id: 'u1', name: 'A')],
      );
      expect(team.toString(), contains('t1'));
      expect(team.toString(), contains('Eng'));
      expect(team.toString(), contains('1 members'));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 't2',
        'name': 'Minimal',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final team = Team.fromJson(json);
      expect(team.description, isNull);
      expect(team.avatarUrl, isNull);
      expect(team.members, isEmpty);
    });
  });

  // =========================================================================
  // TeamMember model
  // =========================================================================
  group('TeamMember', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'u1',
        'name': 'Alice',
        'email': 'alice@test.com',
        'avatar_url': 'https://img.test/a.png',
        'role': 'admin',
        'is_online': true,
      };
      final member = TeamMember.fromJson(json);
      expect(member.id, 'u1');
      expect(member.name, 'Alice');
      expect(member.email, 'alice@test.com');
      expect(member.avatarUrl, 'https://img.test/a.png');
      expect(member.role, 'admin');
      expect(member.isOnline, true);
    });

    test('toJson round-trip preserves data', () {
      const member = TeamMember(
        id: 'u1',
        name: 'Alice',
        email: 'alice@test.com',
        avatarUrl: 'https://img.test/a.png',
        role: 'admin',
        isOnline: true,
      );
      final json = member.toJson();
      final restored = TeamMember.fromJson(json);
      expect(restored.id, member.id);
      expect(restored.name, member.name);
      expect(restored.email, member.email);
      expect(restored.avatarUrl, member.avatarUrl);
      expect(restored.role, member.role);
      expect(restored.isOnline, member.isOnline);
    });

    test('defaults role to member and isOnline to false', () {
      final json = {'id': 'u2', 'name': 'Bob'};
      final member = TeamMember.fromJson(json);
      expect(member.role, 'member');
      expect(member.isOnline, false);
      expect(member.email, isNull);
      expect(member.avatarUrl, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const member = TeamMember(id: 'u1', name: 'Alice', role: 'member');
      final updated = member.copyWith(role: 'admin', isOnline: true);
      expect(updated.id, 'u1');
      expect(updated.name, 'Alice');
      expect(updated.role, 'admin');
      expect(updated.isOnline, true);
    });

    test('toString is human-readable', () {
      const member = TeamMember(id: 'u1', name: 'Alice', role: 'admin');
      expect(member.toString(), contains('u1'));
      expect(member.toString(), contains('Alice'));
      expect(member.toString(), contains('admin'));
    });

    test('toJson omits null email and avatarUrl', () {
      const member = TeamMember(id: 'u1', name: 'Bob');
      final json = member.toJson();
      expect(json.containsKey('email'), false);
      expect(json.containsKey('avatar_url'), false);
    });
  });

  // =========================================================================
  // TeamShare model
  // =========================================================================
  group('TeamShare', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 's1',
        'entity_type': 'note',
        'entity_id': 'n1',
        'team_id': 't1',
        'share_with_all': false,
        'member_ids': ['u1', 'u2'],
        'permission': 'write',
        'shared_by': 'u1',
        'shared_at': '2026-03-10T12:00:00Z',
        'last_synced_at': '2026-03-11T12:00:00Z',
        'version': 2,
        'content_hash': 'abc123',
      };
      final share = TeamShare.fromJson(json);
      expect(share.id, 's1');
      expect(share.entityType, 'note');
      expect(share.shareWithAll, false);
      expect(share.memberIds, ['u1', 'u2']);
      expect(share.permission, SharePermission.write);
      expect(share.version, 2);
      expect(share.contentHash, 'abc123');
      expect(share.lastSyncedAt, isNotNull);
    });

    test('toJson round-trip preserves data', () {
      final share = TeamShare(
        id: 's1',
        entityType: 'note',
        entityId: 'n1',
        teamId: 't1',
        shareWithAll: false,
        memberIds: const ['u1', 'u2'],
        permission: SharePermission.write,
        sharedBy: 'u1',
        sharedAt: DateTime.utc(2026, 3, 10),
        lastSyncedAt: DateTime.utc(2026, 3, 11),
        version: 2,
        contentHash: 'abc123',
      );
      final json = share.toJson();
      final restored = TeamShare.fromJson(json);
      expect(restored.id, share.id);
      expect(restored.entityType, share.entityType);
      expect(restored.shareWithAll, false);
      expect(restored.memberIds, ['u1', 'u2']);
      expect(restored.permission, SharePermission.write);
      expect(restored.version, 2);
      expect(restored.contentHash, 'abc123');
    });

    test('copyWith preserves unmodified fields', () {
      final share = TeamShare(
        id: 's1',
        entityType: 'note',
        entityId: 'n1',
        teamId: 't1',
        sharedBy: 'u1',
        sharedAt: DateTime.utc(2026, 3, 10),
      );
      final updated = share.copyWith(version: 5);
      expect(updated.id, 's1');
      expect(updated.entityType, 'note');
      expect(updated.version, 5);
      expect(updated.shareWithAll, true); // default
    });

    test('toString is human-readable', () {
      final share = TeamShare(
        id: 's1',
        entityType: 'note',
        entityId: 'n1',
        teamId: 't1',
        sharedBy: 'u1',
        sharedAt: DateTime.utc(2026, 3, 10),
        version: 3,
      );
      expect(share.toString(), contains('note/n1'));
      expect(share.toString(), contains('team:t1'));
      expect(share.toString(), contains('v3'));
    });

    test('defaults: shareWithAll=true, permission=read, version=1', () {
      final json = {
        'id': 's2',
        'entity_type': 'project',
        'entity_id': 'p1',
        'team_id': 't1',
        'shared_by': 'u1',
        'shared_at': '2026-03-10T00:00:00Z',
      };
      final share = TeamShare.fromJson(json);
      expect(share.shareWithAll, true);
      expect(share.permission, SharePermission.read);
      expect(share.version, 1);
      expect(share.lastSyncedAt, isNull);
      expect(share.contentHash, isNull);
    });
  });

  // =========================================================================
  // SharePermission enum
  // =========================================================================
  group('SharePermission', () {
    test('fromString covers all values', () {
      expect(SharePermission.fromString('read'), SharePermission.read);
      expect(SharePermission.fromString('write'), SharePermission.write);
      expect(SharePermission.fromString('admin'), SharePermission.admin);
    });

    test('fromString throws on unknown value', () {
      expect(
        () => SharePermission.fromString('superadmin'),
        throwsArgumentError,
      );
    });
  });

  // =========================================================================
  // SyncEntityType enum
  // =========================================================================
  group('SyncEntityType', () {
    test('fromString covers all values', () {
      expect(SyncEntityType.fromString('project'), SyncEntityType.project);
      expect(SyncEntityType.fromString('note'), SyncEntityType.note);
      expect(SyncEntityType.fromString('skill'), SyncEntityType.skill);
      expect(SyncEntityType.fromString('agent'), SyncEntityType.agent);
      expect(SyncEntityType.fromString('workflow'), SyncEntityType.workflow);
      expect(SyncEntityType.fromString('doc'), SyncEntityType.doc);
    });

    test('fromString throws on unknown value', () {
      expect(
        () => SyncEntityType.fromString('unknown'),
        throwsArgumentError,
      );
    });
  });

  // =========================================================================
  // EntitySyncStatus enum
  // =========================================================================
  group('EntitySyncStatus', () {
    test('toJson / fromString round-trip for all values', () {
      for (final status in EntitySyncStatus.values) {
        final json = status.toJson();
        final parsed = EntitySyncStatus.fromString(json);
        expect(parsed, status);
      }
    });

    test('fromString throws on unknown value', () {
      expect(
        () => EntitySyncStatus.fromString('invalid'),
        throwsArgumentError,
      );
    });
  });

  // =========================================================================
  // EntitySyncMetadata model
  // =========================================================================
  group('EntitySyncMetadata', () {
    test('fromJson parses all fields', () {
      final json = {
        'entity_type': 'note',
        'entity_id': 'n1',
        'status': 'pending',
        'last_synced_at': '2026-03-10T00:00:00Z',
        'local_version': 3,
        'remote_version': 2,
        'content_hash': 'hash123',
        'last_synced_by': 'u1',
        'shared_with_team_ids': ['t1', 't2'],
      };
      final meta = EntitySyncMetadata.fromJson(json);
      expect(meta.entityType, 'note');
      expect(meta.entityId, 'n1');
      expect(meta.status, EntitySyncStatus.pending);
      expect(meta.localVersion, 3);
      expect(meta.remoteVersion, 2);
      expect(meta.contentHash, 'hash123');
      expect(meta.lastSyncedBy, 'u1');
      expect(meta.sharedWithTeamIds, ['t1', 't2']);
    });

    test('toJson round-trip preserves data', () {
      final meta = EntitySyncMetadata(
        entityType: 'project',
        entityId: 'p1',
        status: EntitySyncStatus.synced,
        lastSyncedAt: DateTime.utc(2026, 3, 15),
        localVersion: 5,
        remoteVersion: 5,
        contentHash: 'sha256abc',
        lastSyncedBy: 'u2',
        sharedWithTeamIds: const ['t1'],
      );
      final json = meta.toJson();
      final restored = EntitySyncMetadata.fromJson(json);
      expect(restored.entityType, meta.entityType);
      expect(restored.status, EntitySyncStatus.synced);
      expect(restored.localVersion, 5);
      expect(restored.remoteVersion, 5);
      expect(restored.sharedWithTeamIds, ['t1']);
    });

    test('defaults: neverSynced, version 0, empty team list', () {
      final json = {
        'entity_type': 'skill',
        'entity_id': 's1',
      };
      final meta = EntitySyncMetadata.fromJson(json);
      expect(meta.status, EntitySyncStatus.neverSynced);
      expect(meta.localVersion, 0);
      expect(meta.remoteVersion, isNull);
      expect(meta.sharedWithTeamIds, isEmpty);
    });

    test('copyWith preserves unmodified fields', () {
      const meta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n1',
        localVersion: 3,
      );
      final updated = meta.copyWith(status: EntitySyncStatus.synced);
      expect(updated.entityType, 'note');
      expect(updated.entityId, 'n1');
      expect(updated.localVersion, 3);
      expect(updated.status, EntitySyncStatus.synced);
    });

    test('toString is human-readable', () {
      const meta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n1',
        status: EntitySyncStatus.pending,
        localVersion: 3,
      );
      expect(meta.toString(), contains('note/n1'));
      expect(meta.toString(), contains('pending'));
      expect(meta.toString(), contains('v3'));
    });
  });

  // =========================================================================
  // SyncVersionEntry model
  // =========================================================================
  group('SyncVersionEntry', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'v1',
        'entity_type': 'note',
        'entity_id': 'n1',
        'version': 2,
        'author_id': 'u1',
        'author_name': 'Alice',
        'change_summary': 'Updated title',
        'timestamp': '2026-03-10T12:00:00Z',
        'content_hash': 'hash456',
      };
      final entry = SyncVersionEntry.fromJson(json);
      expect(entry.id, 'v1');
      expect(entry.version, 2);
      expect(entry.authorName, 'Alice');
      expect(entry.changeSummary, 'Updated title');
      expect(entry.contentHash, 'hash456');
    });

    test('toJson round-trip preserves data', () {
      final entry = SyncVersionEntry(
        id: 'v1',
        entityType: 'project',
        entityId: 'p1',
        version: 5,
        authorId: 'u2',
        authorName: 'Bob',
        changeSummary: 'Added feature',
        timestamp: DateTime.utc(2026, 3, 12),
        contentHash: 'sha',
      );
      final json = entry.toJson();
      final restored = SyncVersionEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.version, 5);
      expect(restored.authorName, 'Bob');
      expect(restored.changeSummary, 'Added feature');
    });

    test('copyWith preserves unmodified fields', () {
      final entry = SyncVersionEntry(
        id: 'v1',
        entityType: 'note',
        entityId: 'n1',
        version: 1,
        authorId: 'u1',
        authorName: 'Alice',
        timestamp: DateTime.utc(2026),
      );
      final updated = entry.copyWith(version: 2);
      expect(updated.id, 'v1');
      expect(updated.authorName, 'Alice');
      expect(updated.version, 2);
    });

    test('toString is human-readable', () {
      final entry = SyncVersionEntry(
        id: 'v1',
        entityType: 'note',
        entityId: 'n1',
        version: 3,
        authorId: 'u1',
        authorName: 'Alice',
        timestamp: DateTime.utc(2026),
      );
      expect(entry.toString(), contains('note/n1'));
      expect(entry.toString(), contains('v3'));
      expect(entry.toString(), contains('Alice'));
    });
  });

  // =========================================================================
  // ShareRequest model
  // =========================================================================
  group('ShareRequest', () {
    test('toJson produces correct payload', () {
      const request = ShareRequest(
        entityType: 'note',
        entityId: 'n1',
        teamId: 't1',
        shareWithAll: false,
        memberIds: ['u1', 'u2'],
        permission: SharePermission.write,
        entityData: {'title': 'Test'},
        contentHash: 'hash',
      );
      final json = request.toJson();
      expect(json['entity_type'], 'note');
      expect(json['share_with_all'], false);
      expect(json['member_ids'], ['u1', 'u2']);
      expect(json['permission'], 'write');
    });

    test('fromJson round-trip', () {
      const request = ShareRequest(
        entityType: 'project',
        entityId: 'p1',
        teamId: 't1',
        entityData: {'name': 'Proj'},
        contentHash: 'abc',
      );
      final restored = ShareRequest.fromJson(request.toJson());
      expect(restored.entityType, 'project');
      expect(restored.teamId, 't1');
      expect(restored.shareWithAll, true);
      expect(restored.permission, SharePermission.read);
    });
  });

  // =========================================================================
  // ShareResponse model
  // =========================================================================
  group('ShareResponse', () {
    test('fromJson parses success response', () {
      final json = {
        'share_id': 's1',
        'success': true,
        'version': 1,
        'server_timestamp': '2026-03-10T12:00:00Z',
      };
      final resp = ShareResponse.fromJson(json);
      expect(resp.shareId, 's1');
      expect(resp.success, true);
      expect(resp.version, 1);
      expect(resp.errorMessage, isNull);
    });

    test('fromJson parses error response', () {
      final json = {
        'share_id': 's2',
        'success': false,
        'version': 0,
        'server_timestamp': '2026-03-10T12:00:00Z',
        'error_message': 'Permission denied',
      };
      final resp = ShareResponse.fromJson(json);
      expect(resp.success, false);
      expect(resp.errorMessage, 'Permission denied');
    });

    test('toJson round-trip', () {
      final resp = ShareResponse(
        shareId: 's1',
        success: true,
        version: 3,
        serverTimestamp: DateTime.utc(2026, 3, 10),
      );
      final restored = ShareResponse.fromJson(resp.toJson());
      expect(restored.shareId, 's1');
      expect(restored.version, 3);
    });
  });

  // =========================================================================
  // TeamUpdateStatus / TeamUpdateEntry
  // =========================================================================
  group('TeamUpdateStatus', () {
    test('fromJson parses with updates', () {
      final json = {
        'available_updates': 2,
        'updates': [
          {
            'entity_type': 'note',
            'entity_id': 'n1',
            'entity_title': 'My Note',
            'team_id': 't1',
            'team_name': 'Eng',
            'author_name': 'Alice',
            'from_version': 1,
            'to_version': 3,
            'updated_at': '2026-03-15T10:00:00Z',
          },
        ],
        'checked_at': '2026-03-15T10:05:00Z',
      };
      final status = TeamUpdateStatus.fromJson(json);
      expect(status.availableUpdates, 2);
      expect(status.updates.length, 1);
      expect(status.updates[0].entityTitle, 'My Note');
      expect(status.updates[0].authorName, 'Alice');
    });

    test('copyWith preserves unmodified fields', () {
      final status = TeamUpdateStatus(
        availableUpdates: 5,
        checkedAt: DateTime.utc(2026, 3, 15),
      );
      final updated = status.copyWith(availableUpdates: 3);
      expect(updated.availableUpdates, 3);
      expect(updated.updates, isEmpty);
    });

    test('toString is human-readable', () {
      final status = TeamUpdateStatus(
        availableUpdates: 3,
        checkedAt: DateTime.utc(2026, 3, 15),
      );
      expect(status.toString(), contains('3 updates'));
    });
  });

  group('TeamUpdateEntry', () {
    test('fromJson round-trip', () {
      final json = {
        'entity_type': 'project',
        'entity_id': 'p1',
        'entity_title': 'My Project',
        'team_id': 't1',
        'team_name': 'Eng',
        'author_name': 'Bob',
        'from_version': 2,
        'to_version': 5,
        'updated_at': '2026-03-15T10:00:00Z',
      };
      final entry = TeamUpdateEntry.fromJson(json);
      final restored = TeamUpdateEntry.fromJson(entry.toJson());
      expect(restored.entityType, 'project');
      expect(restored.entityTitle, 'My Project');
      expect(restored.fromVersion, 2);
      expect(restored.toVersion, 5);
    });

    test('toString is human-readable', () {
      final entry = TeamUpdateEntry(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Note',
        teamId: 't1',
        teamName: 'Eng',
        authorName: 'Alice',
        fromVersion: 1,
        toVersion: 4,
        updatedAt: DateTime.utc(2026, 3, 15),
      );
      expect(entry.toString(), contains('note/n1'));
      expect(entry.toString(), contains('v1->v4'));
      expect(entry.toString(), contains('Alice'));
    });
  });
}
