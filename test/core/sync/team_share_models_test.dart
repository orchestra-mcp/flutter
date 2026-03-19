import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

void main() {
  // -------------------------------------------------------------------------
  // SyncEntityType
  // -------------------------------------------------------------------------
  group('SyncEntityType', () {
    test('fromString parses "project"', () {
      expect(SyncEntityType.fromString('project'), SyncEntityType.project);
    });

    test('fromString parses "note"', () {
      expect(SyncEntityType.fromString('note'), SyncEntityType.note);
    });

    test('fromString parses "skill"', () {
      expect(SyncEntityType.fromString('skill'), SyncEntityType.skill);
    });

    test('fromString parses "agent"', () {
      expect(SyncEntityType.fromString('agent'), SyncEntityType.agent);
    });

    test('fromString parses "workflow"', () {
      expect(SyncEntityType.fromString('workflow'), SyncEntityType.workflow);
    });

    test('fromString parses "doc"', () {
      expect(SyncEntityType.fromString('doc'), SyncEntityType.doc);
    });

    test('fromString throws ArgumentError on invalid value', () {
      expect(
        () => SyncEntityType.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromString throws ArgumentError on empty string', () {
      expect(
        () => SyncEntityType.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // EntitySyncStatus
  // -------------------------------------------------------------------------
  group('EntitySyncStatus', () {
    test('fromString parses "never_synced"', () {
      expect(
        EntitySyncStatus.fromString('never_synced'),
        EntitySyncStatus.neverSynced,
      );
    });

    test('fromString parses "synced"', () {
      expect(EntitySyncStatus.fromString('synced'), EntitySyncStatus.synced);
    });

    test('fromString parses "pending"', () {
      expect(EntitySyncStatus.fromString('pending'), EntitySyncStatus.pending);
    });

    test('fromString parses "outdated"', () {
      expect(
        EntitySyncStatus.fromString('outdated'),
        EntitySyncStatus.outdated,
      );
    });

    test('fromString parses "conflict"', () {
      expect(
        EntitySyncStatus.fromString('conflict'),
        EntitySyncStatus.conflict,
      );
    });

    test('fromString throws ArgumentError on invalid value', () {
      expect(
        () => EntitySyncStatus.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromString throws on camelCase variant', () {
      expect(
        () => EntitySyncStatus.fromString('neverSynced'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson returns snake_case strings', () {
      expect(EntitySyncStatus.neverSynced.toJson(), 'never_synced');
      expect(EntitySyncStatus.synced.toJson(), 'synced');
      expect(EntitySyncStatus.pending.toJson(), 'pending');
      expect(EntitySyncStatus.outdated.toJson(), 'outdated');
      expect(EntitySyncStatus.conflict.toJson(), 'conflict');
    });

    test('toJson and fromString round-trip for all values', () {
      for (final status in EntitySyncStatus.values) {
        final json = status.toJson();
        final parsed = EntitySyncStatus.fromString(json);
        expect(parsed, status);
      }
    });
  });

  // -------------------------------------------------------------------------
  // SharePermission
  // -------------------------------------------------------------------------
  group('SharePermission', () {
    test('fromString parses "read"', () {
      expect(SharePermission.fromString('read'), SharePermission.read);
    });

    test('fromString parses "write"', () {
      expect(SharePermission.fromString('write'), SharePermission.write);
    });

    test('fromString parses "admin"', () {
      expect(SharePermission.fromString('admin'), SharePermission.admin);
    });

    test('fromString throws ArgumentError on invalid value', () {
      expect(
        () => SharePermission.fromString('owner'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromString throws ArgumentError on empty string', () {
      expect(
        () => SharePermission.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // TeamMember
  // -------------------------------------------------------------------------
  group('TeamMember', () {
    Map<String, dynamic> fullMemberJson() => {
      'id': 'mem-001',
      'name': 'Alice',
      'email': 'alice@example.com',
      'avatar_url': 'https://img.example.com/alice.png',
      'role': 'admin',
      'is_online': true,
    };

    test('fromJson parses all fields', () {
      final member = TeamMember.fromJson(fullMemberJson());
      expect(member.id, 'mem-001');
      expect(member.name, 'Alice');
      expect(member.email, 'alice@example.com');
      expect(member.avatarUrl, 'https://img.example.com/alice.png');
      expect(member.role, 'admin');
      expect(member.isOnline, true);
    });

    test('fromJson applies default role "member" when absent', () {
      final json = {'id': 'mem-002', 'name': 'Bob'};
      final member = TeamMember.fromJson(json);
      expect(member.role, 'member');
    });

    test('fromJson applies default isOnline false when absent', () {
      final json = {'id': 'mem-003', 'name': 'Carol'};
      final member = TeamMember.fromJson(json);
      expect(member.isOnline, false);
    });

    test('fromJson handles null email and avatarUrl', () {
      final json = {'id': 'mem-004', 'name': 'Dave'};
      final member = TeamMember.fromJson(json);
      expect(member.email, isNull);
      expect(member.avatarUrl, isNull);
    });

    test('toJson produces correct keys', () {
      final member = TeamMember.fromJson(fullMemberJson());
      final json = member.toJson();
      expect(json['id'], 'mem-001');
      expect(json['name'], 'Alice');
      expect(json['email'], 'alice@example.com');
      expect(json['avatar_url'], 'https://img.example.com/alice.png');
      expect(json['role'], 'admin');
      expect(json['is_online'], true);
    });

    test('toJson omits null email and avatarUrl', () {
      const member = TeamMember(id: 'mem-005', name: 'Eve');
      final json = member.toJson();
      expect(json.containsKey('email'), false);
      expect(json.containsKey('avatar_url'), false);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = fullMemberJson();
      final member = TeamMember.fromJson(original);
      final roundTripped = member.toJson();
      expect(roundTripped, original);
    });

    test('copyWith overrides selected fields', () {
      final member = TeamMember.fromJson(fullMemberJson());
      final updated = member.copyWith(name: 'Alicia', isOnline: false);
      expect(updated.id, member.id);
      expect(updated.name, 'Alicia');
      expect(updated.email, member.email);
      expect(updated.isOnline, false);
    });

    test('copyWith with no arguments returns identical values', () {
      final member = TeamMember.fromJson(fullMemberJson());
      final copy = member.copyWith();
      expect(copy.toJson(), member.toJson());
    });

    test('constructor default values', () {
      const member = TeamMember(id: 'x', name: 'Y');
      expect(member.role, 'member');
      expect(member.isOnline, false);
      expect(member.email, isNull);
      expect(member.avatarUrl, isNull);
    });

    test('toString includes id, name, and role', () {
      const member = TeamMember(id: 'mem-001', name: 'Alice', role: 'admin');
      expect(member.toString(), 'TeamMember(mem-001, Alice, admin)');
    });
  });

  // -------------------------------------------------------------------------
  // Team
  // -------------------------------------------------------------------------
  group('Team', () {
    final createdAt = DateTime.utc(2026, 3, 15, 10, 30, 0);

    Map<String, dynamic> fullTeamJson() => {
      'id': 'team-abc',
      'name': 'Engineering',
      'description': 'Core engineering team',
      'avatar_url': 'https://img.example.com/eng.png',
      'members': [
        {'id': 'mem-001', 'name': 'Alice', 'role': 'admin', 'is_online': true},
        {'id': 'mem-002', 'name': 'Bob', 'role': 'member', 'is_online': false},
      ],
      'created_at': createdAt.toIso8601String(),
    };

    test('fromJson parses all fields including nested members', () {
      final team = Team.fromJson(fullTeamJson());
      expect(team.id, 'team-abc');
      expect(team.name, 'Engineering');
      expect(team.description, 'Core engineering team');
      expect(team.avatarUrl, 'https://img.example.com/eng.png');
      expect(team.members, hasLength(2));
      expect(team.members[0].id, 'mem-001');
      expect(team.members[0].name, 'Alice');
      expect(team.members[1].id, 'mem-002');
      expect(team.createdAt, createdAt);
    });

    test('fromJson handles missing members list', () {
      final json = {
        'id': 'team-xyz',
        'name': 'Empty Team',
        'created_at': createdAt.toIso8601String(),
      };
      final team = Team.fromJson(json);
      expect(team.members, isEmpty);
    });

    test('fromJson handles null description and avatarUrl', () {
      final json = {
        'id': 'team-xyz',
        'name': 'Minimal Team',
        'created_at': createdAt.toIso8601String(),
      };
      final team = Team.fromJson(json);
      expect(team.description, isNull);
      expect(team.avatarUrl, isNull);
    });

    test('toJson produces correct keys and nested members', () {
      final team = Team.fromJson(fullTeamJson());
      final json = team.toJson();
      expect(json['id'], 'team-abc');
      expect(json['name'], 'Engineering');
      expect(json['description'], 'Core engineering team');
      expect(json['avatar_url'], 'https://img.example.com/eng.png');
      expect(json['members'], isList);
      expect((json['members'] as List), hasLength(2));
      expect(json['created_at'], createdAt.toIso8601String());
    });

    test('toJson omits null description and avatarUrl', () {
      final team = Team(id: 'team-xyz', name: 'Minimal', createdAt: createdAt);
      final json = team.toJson();
      expect(json.containsKey('description'), false);
      expect(json.containsKey('avatar_url'), false);
    });

    test('fromJson/toJson round-trip preserves structure', () {
      final original = fullTeamJson();
      final team = Team.fromJson(original);
      final roundTripped = team.toJson();
      expect(roundTripped, original);
    });

    test('copyWith overrides selected fields', () {
      final team = Team.fromJson(fullTeamJson());
      final updated = team.copyWith(name: 'Platform', members: []);
      expect(updated.id, team.id);
      expect(updated.name, 'Platform');
      expect(updated.members, isEmpty);
      expect(updated.description, team.description);
    });

    test('copyWith with no arguments returns identical values', () {
      final team = Team.fromJson(fullTeamJson());
      final copy = team.copyWith();
      expect(copy.toJson(), team.toJson());
    });

    test('toString includes id, name, and member count', () {
      final team = Team.fromJson(fullTeamJson());
      expect(team.toString(), 'Team(team-abc, Engineering, 2 members)');
    });

    test('empty members list serializes to empty array', () {
      final team = Team(id: 'team-empty', name: 'Ghost', createdAt: createdAt);
      final json = team.toJson();
      expect(json['members'], <Map<String, dynamic>>[]);
    });
  });

  // -------------------------------------------------------------------------
  // TeamShare
  // -------------------------------------------------------------------------
  group('TeamShare', () {
    final sharedAt = DateTime.utc(2026, 3, 15, 12, 0, 0);
    final lastSyncedAt = DateTime.utc(2026, 3, 15, 13, 0, 0);

    Map<String, dynamic> fullShareJson() => {
      'id': 'share-001',
      'entity_type': 'project',
      'entity_id': 'proj-abc',
      'team_id': 'team-xyz',
      'share_with_all': false,
      'member_ids': ['mem-001', 'mem-002'],
      'permission': 'write',
      'shared_by': 'user-100',
      'shared_at': sharedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt.toIso8601String(),
      'version': 5,
      'content_hash': 'abc123def456',
    };

    test('fromJson parses all fields', () {
      final share = TeamShare.fromJson(fullShareJson());
      expect(share.id, 'share-001');
      expect(share.entityType, 'project');
      expect(share.entityId, 'proj-abc');
      expect(share.teamId, 'team-xyz');
      expect(share.shareWithAll, false);
      expect(share.memberIds, ['mem-001', 'mem-002']);
      expect(share.permission, SharePermission.write);
      expect(share.sharedBy, 'user-100');
      expect(share.sharedAt, sharedAt);
      expect(share.lastSyncedAt, lastSyncedAt);
      expect(share.version, 5);
      expect(share.contentHash, 'abc123def456');
    });

    test('fromJson applies defaults when fields are absent', () {
      final json = {
        'id': 'share-002',
        'entity_type': 'note',
        'entity_id': 'note-abc',
        'team_id': 'team-xyz',
        'shared_by': 'user-200',
        'shared_at': sharedAt.toIso8601String(),
      };
      final share = TeamShare.fromJson(json);
      expect(share.shareWithAll, true);
      expect(share.memberIds, isEmpty);
      expect(share.permission, SharePermission.read);
      expect(share.lastSyncedAt, isNull);
      expect(share.version, 1);
      expect(share.contentHash, isNull);
    });

    test('toJson produces correct keys', () {
      final share = TeamShare.fromJson(fullShareJson());
      final json = share.toJson();
      expect(json['id'], 'share-001');
      expect(json['entity_type'], 'project');
      expect(json['entity_id'], 'proj-abc');
      expect(json['team_id'], 'team-xyz');
      expect(json['share_with_all'], false);
      expect(json['member_ids'], ['mem-001', 'mem-002']);
      expect(json['permission'], 'write');
      expect(json['shared_by'], 'user-100');
      expect(json['shared_at'], sharedAt.toIso8601String());
      expect(json['last_synced_at'], lastSyncedAt.toIso8601String());
      expect(json['version'], 5);
      expect(json['content_hash'], 'abc123def456');
    });

    test('toJson omits null lastSyncedAt and contentHash', () {
      final share = TeamShare(
        id: 'share-min',
        entityType: 'note',
        entityId: 'note-1',
        teamId: 'team-1',
        sharedBy: 'user-1',
        sharedAt: sharedAt,
      );
      final json = share.toJson();
      expect(json.containsKey('last_synced_at'), false);
      expect(json.containsKey('content_hash'), false);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = fullShareJson();
      final share = TeamShare.fromJson(original);
      final roundTripped = share.toJson();
      expect(roundTripped, original);
    });

    test('copyWith overrides selected fields', () {
      final share = TeamShare.fromJson(fullShareJson());
      final updated = share.copyWith(
        permission: SharePermission.admin,
        version: 10,
        shareWithAll: true,
      );
      expect(updated.id, share.id);
      expect(updated.permission, SharePermission.admin);
      expect(updated.version, 10);
      expect(updated.shareWithAll, true);
      expect(updated.entityType, share.entityType);
    });

    test('copyWith with no arguments returns identical values', () {
      final share = TeamShare.fromJson(fullShareJson());
      final copy = share.copyWith();
      expect(copy.toJson(), share.toJson());
    });

    test('constructor default values', () {
      final share = TeamShare(
        id: 'share-def',
        entityType: 'doc',
        entityId: 'doc-1',
        teamId: 'team-1',
        sharedBy: 'user-1',
        sharedAt: sharedAt,
      );
      expect(share.shareWithAll, true);
      expect(share.memberIds, isEmpty);
      expect(share.permission, SharePermission.read);
      expect(share.version, 1);
      expect(share.lastSyncedAt, isNull);
      expect(share.contentHash, isNull);
    });

    test('memberIds list preserves order', () {
      final json = fullShareJson();
      json['member_ids'] = ['z', 'a', 'm'];
      final share = TeamShare.fromJson(json);
      expect(share.memberIds, ['z', 'a', 'm']);
    });

    test('toString includes entity type, id, team, and version', () {
      final share = TeamShare.fromJson(fullShareJson());
      expect(
        share.toString(),
        'TeamShare(project/proj-abc -> team:team-xyz v5)',
      );
    });
  });

  // -------------------------------------------------------------------------
  // EntitySyncMetadata
  // -------------------------------------------------------------------------
  group('EntitySyncMetadata', () {
    final lastSyncedAt = DateTime.utc(2026, 3, 15, 14, 0, 0);

    Map<String, dynamic> fullMetadataJson() => {
      'entity_type': 'project',
      'entity_id': 'proj-abc',
      'status': 'synced',
      'last_synced_at': lastSyncedAt.toIso8601String(),
      'local_version': 7,
      'remote_version': 7,
      'content_hash': 'hash789',
      'last_synced_by': 'user-300',
      'shared_with_team_ids': ['team-a', 'team-b'],
    };

    test('fromJson parses all fields', () {
      final meta = EntitySyncMetadata.fromJson(fullMetadataJson());
      expect(meta.entityType, 'project');
      expect(meta.entityId, 'proj-abc');
      expect(meta.status, EntitySyncStatus.synced);
      expect(meta.lastSyncedAt, lastSyncedAt);
      expect(meta.localVersion, 7);
      expect(meta.remoteVersion, 7);
      expect(meta.contentHash, 'hash789');
      expect(meta.lastSyncedBy, 'user-300');
      expect(meta.sharedWithTeamIds, ['team-a', 'team-b']);
    });

    test('fromJson applies defaults when fields are absent', () {
      final json = {'entity_type': 'note', 'entity_id': 'note-1'};
      final meta = EntitySyncMetadata.fromJson(json);
      expect(meta.status, EntitySyncStatus.neverSynced);
      expect(meta.lastSyncedAt, isNull);
      expect(meta.localVersion, 0);
      expect(meta.remoteVersion, isNull);
      expect(meta.contentHash, isNull);
      expect(meta.lastSyncedBy, isNull);
      expect(meta.sharedWithTeamIds, isEmpty);
    });

    test('toJson produces correct keys with status as snake_case', () {
      final meta = EntitySyncMetadata.fromJson(fullMetadataJson());
      final json = meta.toJson();
      expect(json['entity_type'], 'project');
      expect(json['entity_id'], 'proj-abc');
      expect(json['status'], 'synced');
      expect(json['last_synced_at'], lastSyncedAt.toIso8601String());
      expect(json['local_version'], 7);
      expect(json['remote_version'], 7);
      expect(json['content_hash'], 'hash789');
      expect(json['last_synced_by'], 'user-300');
      expect(json['shared_with_team_ids'], ['team-a', 'team-b']);
    });

    test('toJson omits null optional fields', () {
      const meta = EntitySyncMetadata(entityType: 'note', entityId: 'note-1');
      final json = meta.toJson();
      expect(json.containsKey('last_synced_at'), false);
      expect(json.containsKey('remote_version'), false);
      expect(json.containsKey('content_hash'), false);
      expect(json.containsKey('last_synced_by'), false);
      // shared_with_team_ids is always present (empty list)
      expect(json['shared_with_team_ids'], <String>[]);
    });

    test('toJson serializes neverSynced status as "never_synced"', () {
      const meta = EntitySyncMetadata(entityType: 'doc', entityId: 'doc-1');
      expect(meta.toJson()['status'], 'never_synced');
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = fullMetadataJson();
      final meta = EntitySyncMetadata.fromJson(original);
      final roundTripped = meta.toJson();
      expect(roundTripped, original);
    });

    test('copyWith overrides selected fields', () {
      final meta = EntitySyncMetadata.fromJson(fullMetadataJson());
      final updated = meta.copyWith(
        status: EntitySyncStatus.pending,
        localVersion: 8,
      );
      expect(updated.entityType, meta.entityType);
      expect(updated.status, EntitySyncStatus.pending);
      expect(updated.localVersion, 8);
      expect(updated.remoteVersion, meta.remoteVersion);
    });

    test('copyWith with no arguments returns identical values', () {
      final meta = EntitySyncMetadata.fromJson(fullMetadataJson());
      final copy = meta.copyWith();
      expect(copy.toJson(), meta.toJson());
    });

    test('sharedWithTeamIds list preserves order', () {
      final json = fullMetadataJson();
      json['shared_with_team_ids'] = ['z-team', 'a-team', 'm-team'];
      final meta = EntitySyncMetadata.fromJson(json);
      expect(meta.sharedWithTeamIds, ['z-team', 'a-team', 'm-team']);
    });

    test('constructor default values', () {
      const meta = EntitySyncMetadata(entityType: 'skill', entityId: 'skill-1');
      expect(meta.status, EntitySyncStatus.neverSynced);
      expect(meta.localVersion, 0);
      expect(meta.lastSyncedAt, isNull);
      expect(meta.remoteVersion, isNull);
      expect(meta.contentHash, isNull);
      expect(meta.lastSyncedBy, isNull);
      expect(meta.sharedWithTeamIds, isEmpty);
    });

    test('toString includes entity type, id, status, and version', () {
      final meta = EntitySyncMetadata.fromJson(fullMetadataJson());
      expect(meta.toString(), 'EntitySyncMetadata(project/proj-abc synced v7)');
    });
  });

  // -------------------------------------------------------------------------
  // SyncVersionEntry
  // -------------------------------------------------------------------------
  group('SyncVersionEntry', () {
    final timestamp = DateTime.utc(2026, 3, 15, 15, 0, 0);

    Map<String, dynamic> fullVersionJson() => {
      'id': 'ver-001',
      'entity_type': 'note',
      'entity_id': 'note-abc',
      'version': 3,
      'author_id': 'user-400',
      'author_name': 'Diana',
      'change_summary': 'Added introduction section',
      'timestamp': timestamp.toIso8601String(),
      'content_hash': 'vhash456',
    };

    test('fromJson parses all fields', () {
      final entry = SyncVersionEntry.fromJson(fullVersionJson());
      expect(entry.id, 'ver-001');
      expect(entry.entityType, 'note');
      expect(entry.entityId, 'note-abc');
      expect(entry.version, 3);
      expect(entry.authorId, 'user-400');
      expect(entry.authorName, 'Diana');
      expect(entry.changeSummary, 'Added introduction section');
      expect(entry.timestamp, timestamp);
      expect(entry.contentHash, 'vhash456');
    });

    test('fromJson handles null changeSummary and contentHash', () {
      final json = {
        'id': 'ver-002',
        'entity_type': 'doc',
        'entity_id': 'doc-1',
        'version': 1,
        'author_id': 'user-500',
        'author_name': 'Eve',
        'timestamp': timestamp.toIso8601String(),
      };
      final entry = SyncVersionEntry.fromJson(json);
      expect(entry.changeSummary, isNull);
      expect(entry.contentHash, isNull);
    });

    test('toJson produces correct keys', () {
      final entry = SyncVersionEntry.fromJson(fullVersionJson());
      final json = entry.toJson();
      expect(json['id'], 'ver-001');
      expect(json['entity_type'], 'note');
      expect(json['entity_id'], 'note-abc');
      expect(json['version'], 3);
      expect(json['author_id'], 'user-400');
      expect(json['author_name'], 'Diana');
      expect(json['change_summary'], 'Added introduction section');
      expect(json['timestamp'], timestamp.toIso8601String());
      expect(json['content_hash'], 'vhash456');
    });

    test('toJson omits null changeSummary and contentHash', () {
      final entry = SyncVersionEntry(
        id: 'ver-min',
        entityType: 'agent',
        entityId: 'agt-1',
        version: 1,
        authorId: 'user-1',
        authorName: 'Frank',
        timestamp: timestamp,
      );
      final json = entry.toJson();
      expect(json.containsKey('change_summary'), false);
      expect(json.containsKey('content_hash'), false);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = fullVersionJson();
      final entry = SyncVersionEntry.fromJson(original);
      final roundTripped = entry.toJson();
      expect(roundTripped, original);
    });

    test('copyWith overrides selected fields', () {
      final entry = SyncVersionEntry.fromJson(fullVersionJson());
      final updated = entry.copyWith(
        version: 4,
        changeSummary: 'Updated conclusion',
      );
      expect(updated.id, entry.id);
      expect(updated.version, 4);
      expect(updated.changeSummary, 'Updated conclusion');
      expect(updated.authorName, entry.authorName);
    });

    test('copyWith with no arguments returns identical values', () {
      final entry = SyncVersionEntry.fromJson(fullVersionJson());
      final copy = entry.copyWith();
      expect(copy.toJson(), entry.toJson());
    });

    test('toString includes entity type, id, version, and author', () {
      final entry = SyncVersionEntry.fromJson(fullVersionJson());
      expect(entry.toString(), 'SyncVersionEntry(note/note-abc v3 by Diana)');
    });
  });

  // -------------------------------------------------------------------------
  // ShareRequest
  // -------------------------------------------------------------------------
  group('ShareRequest', () {
    Map<String, dynamic> fullRequestJson() => {
      'entity_type': 'project',
      'entity_id': 'proj-xyz',
      'team_id': 'team-abc',
      'share_with_all': false,
      'member_ids': ['mem-a', 'mem-b'],
      'permission': 'admin',
      'entity_data': {
        'title': 'My Project',
        'tags': ['go', 'grpc'],
        'nested': {'key': 42},
      },
      'content_hash': 'reqhash789',
    };

    test('fromJson parses all fields', () {
      final req = ShareRequest.fromJson(fullRequestJson());
      expect(req.entityType, 'project');
      expect(req.entityId, 'proj-xyz');
      expect(req.teamId, 'team-abc');
      expect(req.shareWithAll, false);
      expect(req.memberIds, ['mem-a', 'mem-b']);
      expect(req.permission, SharePermission.admin);
      expect(req.entityData['title'], 'My Project');
      expect(req.contentHash, 'reqhash789');
    });

    test('fromJson applies defaults when optional fields are absent', () {
      final json = {
        'entity_type': 'note',
        'entity_id': 'note-1',
        'team_id': 'team-1',
        'entity_data': {'body': 'Hello'},
        'content_hash': 'hash1',
      };
      final req = ShareRequest.fromJson(json);
      expect(req.shareWithAll, true);
      expect(req.memberIds, isEmpty);
      expect(req.permission, SharePermission.read);
    });

    test('toJson produces correct keys', () {
      final req = ShareRequest.fromJson(fullRequestJson());
      final json = req.toJson();
      expect(json['entity_type'], 'project');
      expect(json['entity_id'], 'proj-xyz');
      expect(json['team_id'], 'team-abc');
      expect(json['share_with_all'], false);
      expect(json['member_ids'], ['mem-a', 'mem-b']);
      expect(json['permission'], 'admin');
      expect(json['content_hash'], 'reqhash789');
    });

    test('entityData map is preserved through round-trip', () {
      final original = fullRequestJson();
      final req = ShareRequest.fromJson(original);
      final json = req.toJson();
      final entityData = json['entity_data'] as Map<String, dynamic>;
      expect(entityData['title'], 'My Project');
      expect(entityData['tags'], ['go', 'grpc']);
      expect((entityData['nested'] as Map)['key'], 42);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = fullRequestJson();
      final req = ShareRequest.fromJson(original);
      final roundTripped = req.toJson();
      expect(roundTripped, original);
    });

    test('entityData with empty map', () {
      final json = {
        'entity_type': 'skill',
        'entity_id': 'skill-1',
        'team_id': 'team-1',
        'entity_data': <String, dynamic>{},
        'content_hash': 'empty',
      };
      final req = ShareRequest.fromJson(json);
      expect(req.entityData, isEmpty);
      expect(req.toJson()['entity_data'], <String, dynamic>{});
    });

    test('constructor default values', () {
      const req = ShareRequest(
        entityType: 'doc',
        entityId: 'doc-1',
        teamId: 'team-1',
        entityData: {'x': 1},
        contentHash: 'ch',
      );
      expect(req.shareWithAll, true);
      expect(req.memberIds, isEmpty);
      expect(req.permission, SharePermission.read);
    });
  });

  // -------------------------------------------------------------------------
  // ShareResponse
  // -------------------------------------------------------------------------
  group('ShareResponse', () {
    final serverTimestamp = DateTime.utc(2026, 3, 15, 16, 0, 0);

    Map<String, dynamic> successResponseJson() => {
      'share_id': 'share-resp-001',
      'success': true,
      'version': 3,
      'server_timestamp': serverTimestamp.toIso8601String(),
    };

    Map<String, dynamic> errorResponseJson() => {
      'share_id': 'share-resp-002',
      'success': false,
      'version': 0,
      'server_timestamp': serverTimestamp.toIso8601String(),
      'error_message': 'Permission denied',
    };

    test('fromJson parses successful response', () {
      final resp = ShareResponse.fromJson(successResponseJson());
      expect(resp.shareId, 'share-resp-001');
      expect(resp.success, true);
      expect(resp.version, 3);
      expect(resp.serverTimestamp, serverTimestamp);
      expect(resp.errorMessage, isNull);
    });

    test('fromJson parses error response with message', () {
      final resp = ShareResponse.fromJson(errorResponseJson());
      expect(resp.shareId, 'share-resp-002');
      expect(resp.success, false);
      expect(resp.version, 0);
      expect(resp.errorMessage, 'Permission denied');
    });

    test('toJson produces correct keys for success response', () {
      final resp = ShareResponse.fromJson(successResponseJson());
      final json = resp.toJson();
      expect(json['share_id'], 'share-resp-001');
      expect(json['success'], true);
      expect(json['version'], 3);
      expect(json['server_timestamp'], serverTimestamp.toIso8601String());
      expect(json.containsKey('error_message'), false);
    });

    test('toJson includes errorMessage when present', () {
      final resp = ShareResponse.fromJson(errorResponseJson());
      final json = resp.toJson();
      expect(json['error_message'], 'Permission denied');
    });

    test('fromJson/toJson round-trip for success response', () {
      final original = successResponseJson();
      final resp = ShareResponse.fromJson(original);
      final roundTripped = resp.toJson();
      expect(roundTripped, original);
    });

    test('fromJson/toJson round-trip for error response', () {
      final original = errorResponseJson();
      final resp = ShareResponse.fromJson(original);
      final roundTripped = resp.toJson();
      expect(roundTripped, original);
    });

    test('nullable errorMessage is null when not in JSON', () {
      final resp = ShareResponse.fromJson(successResponseJson());
      expect(resp.errorMessage, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // TeamUpdateStatus
  // -------------------------------------------------------------------------
  group('TeamUpdateStatus', () {
    final checkedAt = DateTime.utc(2026, 3, 15, 17, 0, 0);
    final updatedAt = DateTime.utc(2026, 3, 15, 16, 30, 0);

    Map<String, dynamic> fullStatusJson() => {
      'available_updates': 2,
      'updates': [
        {
          'entity_type': 'note',
          'entity_id': 'note-abc',
          'entity_title': 'Design Doc',
          'team_id': 'team-1',
          'team_name': 'Engineering',
          'author_name': 'Grace',
          'from_version': 2,
          'to_version': 4,
          'updated_at': updatedAt.toIso8601String(),
        },
        {
          'entity_type': 'project',
          'entity_id': 'proj-xyz',
          'entity_title': 'Backend Refactor',
          'team_id': 'team-1',
          'team_name': 'Engineering',
          'author_name': 'Hank',
          'from_version': 1,
          'to_version': 2,
          'updated_at': updatedAt.toIso8601String(),
        },
      ],
      'checked_at': checkedAt.toIso8601String(),
    };

    test('fromJson parses all fields including nested updates', () {
      final status = TeamUpdateStatus.fromJson(fullStatusJson());
      expect(status.availableUpdates, 2);
      expect(status.updates, hasLength(2));
      expect(status.updates[0].entityTitle, 'Design Doc');
      expect(status.updates[1].authorName, 'Hank');
      expect(status.checkedAt, checkedAt);
    });

    test('fromJson handles missing updates list', () {
      final json = {
        'available_updates': 0,
        'checked_at': checkedAt.toIso8601String(),
      };
      final status = TeamUpdateStatus.fromJson(json);
      expect(status.updates, isEmpty);
    });

    test('fromJson defaults availableUpdates to 0 when absent', () {
      final json = {'checked_at': checkedAt.toIso8601String()};
      final status = TeamUpdateStatus.fromJson(json);
      expect(status.availableUpdates, 0);
    });

    test('toJson produces correct keys with nested updates', () {
      final status = TeamUpdateStatus.fromJson(fullStatusJson());
      final json = status.toJson();
      expect(json['available_updates'], 2);
      expect(json['updates'], isList);
      expect((json['updates'] as List), hasLength(2));
      expect(json['checked_at'], checkedAt.toIso8601String());
    });

    test('fromJson/toJson round-trip preserves structure', () {
      final original = fullStatusJson();
      final status = TeamUpdateStatus.fromJson(original);
      final roundTripped = status.toJson();
      expect(roundTripped, original);
    });

    test('copyWith overrides selected fields', () {
      final status = TeamUpdateStatus.fromJson(fullStatusJson());
      final updated = status.copyWith(availableUpdates: 0, updates: []);
      expect(updated.availableUpdates, 0);
      expect(updated.updates, isEmpty);
      expect(updated.checkedAt, status.checkedAt);
    });

    test('copyWith with no arguments returns identical values', () {
      final status = TeamUpdateStatus.fromJson(fullStatusJson());
      final copy = status.copyWith();
      expect(copy.toJson(), status.toJson());
    });

    test('toString includes update count', () {
      final status = TeamUpdateStatus.fromJson(fullStatusJson());
      expect(status.toString(), 'TeamUpdateStatus(2 updates)');
    });

    test('empty updates list serializes to empty array', () {
      final status = TeamUpdateStatus(
        availableUpdates: 0,
        checkedAt: checkedAt,
      );
      final json = status.toJson();
      expect(json['updates'], <Map<String, dynamic>>[]);
    });
  });

  // -------------------------------------------------------------------------
  // TeamUpdateEntry
  // -------------------------------------------------------------------------
  group('TeamUpdateEntry', () {
    final updatedAt = DateTime.utc(2026, 3, 15, 18, 0, 0);

    Map<String, dynamic> fullEntryJson() => {
      'entity_type': 'note',
      'entity_id': 'note-entry-1',
      'entity_title': 'API Reference',
      'team_id': 'team-docs',
      'team_name': 'Documentation',
      'author_name': 'Ivan',
      'from_version': 5,
      'to_version': 8,
      'updated_at': updatedAt.toIso8601String(),
    };

    test('fromJson parses all fields', () {
      final entry = TeamUpdateEntry.fromJson(fullEntryJson());
      expect(entry.entityType, 'note');
      expect(entry.entityId, 'note-entry-1');
      expect(entry.entityTitle, 'API Reference');
      expect(entry.teamId, 'team-docs');
      expect(entry.teamName, 'Documentation');
      expect(entry.authorName, 'Ivan');
      expect(entry.fromVersion, 5);
      expect(entry.toVersion, 8);
      expect(entry.updatedAt, updatedAt);
    });

    test('toJson produces correct keys', () {
      final entry = TeamUpdateEntry.fromJson(fullEntryJson());
      final json = entry.toJson();
      expect(json['entity_type'], 'note');
      expect(json['entity_id'], 'note-entry-1');
      expect(json['entity_title'], 'API Reference');
      expect(json['team_id'], 'team-docs');
      expect(json['team_name'], 'Documentation');
      expect(json['author_name'], 'Ivan');
      expect(json['from_version'], 5);
      expect(json['to_version'], 8);
      expect(json['updated_at'], updatedAt.toIso8601String());
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = fullEntryJson();
      final entry = TeamUpdateEntry.fromJson(original);
      final roundTripped = entry.toJson();
      expect(roundTripped, original);
    });

    test('toString includes entity type, id, version range, and author', () {
      final entry = TeamUpdateEntry.fromJson(fullEntryJson());
      expect(
        entry.toString(),
        'TeamUpdateEntry(note/note-entry-1 v5->v8 by Ivan)',
      );
    });

    test('version numbers can be zero', () {
      final json = fullEntryJson();
      json['from_version'] = 0;
      json['to_version'] = 1;
      final entry = TeamUpdateEntry.fromJson(json);
      expect(entry.fromVersion, 0);
      expect(entry.toVersion, 1);
    });
  });
}
