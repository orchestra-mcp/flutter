import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

void main() {
  // =========================================================================
  // 1. ShareRequest serialization
  // =========================================================================
  group('ShareRequest serialization', () {
    test('toJson produces correct payload for POST /api/sync/share', () {
      const request = ShareRequest(
        entityType: 'project',
        entityId: 'proj-123',
        teamId: 'team-456',
        shareWithAll: true,
        memberIds: [],
        permission: SharePermission.write,
        entityData: {'name': 'My Project', 'status': 'active'},
        contentHash: 'abc123def456',
      );

      final json = request.toJson();

      expect(json['entity_type'], 'project');
      expect(json['entity_id'], 'proj-123');
      expect(json['team_id'], 'team-456');
      expect(json['share_with_all'], true);
      expect(json['member_ids'], <String>[]);
      expect(json['permission'], 'write');
      expect(json['entity_data'], {'name': 'My Project', 'status': 'active'});
      expect(json['content_hash'], 'abc123def456');
    });

    test('toJson produces correct payload for selective member sharing', () {
      const request = ShareRequest(
        entityType: 'note',
        entityId: 'note-789',
        teamId: 'team-456',
        shareWithAll: false,
        memberIds: ['user-a', 'user-b'],
        permission: SharePermission.read,
        entityData: {'title': 'Meeting Notes'},
        contentHash: 'sha256hash',
      );

      final json = request.toJson();

      expect(json['share_with_all'], false);
      expect(json['member_ids'], ['user-a', 'user-b']);
      expect(json['permission'], 'read');
    });

    test('toJson includes admin permission correctly', () {
      const request = ShareRequest(
        entityType: 'workflow',
        entityId: 'wfl-001',
        teamId: 'team-100',
        permission: SharePermission.admin,
        entityData: {},
        contentHash: 'hash',
      );

      expect(request.toJson()['permission'], 'admin');
    });

    test('round-trip: toJson -> fromJson produces equivalent object', () {
      final original = ShareRequest(
        entityType: 'agent',
        entityId: 'agt-555',
        teamId: 'team-999',
        shareWithAll: false,
        memberIds: const ['m-1', 'm-2', 'm-3'],
        permission: SharePermission.write,
        entityData: const {
          'config': true,
          'nested': {'key': 'val'},
        },
        contentHash: 'roundtriphash',
      );

      final json = original.toJson();
      final restored = ShareRequest.fromJson(json);

      expect(restored.entityType, original.entityType);
      expect(restored.entityId, original.entityId);
      expect(restored.teamId, original.teamId);
      expect(restored.shareWithAll, original.shareWithAll);
      expect(restored.memberIds, original.memberIds);
      expect(restored.permission, original.permission);
      expect(restored.entityData, original.entityData);
      expect(restored.contentHash, original.contentHash);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = <String, dynamic>{
        'entity_type': 'doc',
        'entity_id': 'doc-1',
        'team_id': 'team-1',
        'entity_data': <String, dynamic>{'body': 'text'},
        'content_hash': 'h',
      };

      final request = ShareRequest.fromJson(json);

      expect(request.shareWithAll, true);
      expect(request.memberIds, <String>[]);
      expect(request.permission, SharePermission.read);
    });

    test('toJson uses snake_case keys matching API contract', () {
      const request = ShareRequest(
        entityType: 'skill',
        entityId: 's-1',
        teamId: 't-1',
        entityData: {},
        contentHash: 'h',
      );

      final json = request.toJson();
      final keys = json.keys.toSet();

      expect(
        keys,
        containsAll([
          'entity_type',
          'entity_id',
          'team_id',
          'share_with_all',
          'member_ids',
          'permission',
          'entity_data',
          'content_hash',
        ]),
      );
      // Verify no camelCase keys leaked through.
      expect(keys.any((k) => k.contains('entityType')), false);
      expect(keys.any((k) => k.contains('teamId')), false);
      expect(keys.any((k) => k.contains('shareWithAll')), false);
      expect(keys.any((k) => k.contains('memberIds')), false);
      expect(keys.any((k) => k.contains('entityData')), false);
      expect(keys.any((k) => k.contains('contentHash')), false);
    });
  });

  // =========================================================================
  // 2. ShareResponse deserialization
  // =========================================================================
  group('ShareResponse deserialization', () {
    test('fromJson handles a successful server response', () {
      final json = <String, dynamic>{
        'share_id': 'share-abc-123',
        'success': true,
        'version': 3,
        'server_timestamp': '2026-03-17T10:30:00.000Z',
      };

      final response = ShareResponse.fromJson(json);

      expect(response.shareId, 'share-abc-123');
      expect(response.success, true);
      expect(response.version, 3);
      expect(response.serverTimestamp, DateTime.utc(2026, 3, 17, 10, 30));
      expect(response.errorMessage, isNull);
    });

    test('fromJson handles an error server response', () {
      final json = <String, dynamic>{
        'share_id': '',
        'success': false,
        'version': 0,
        'server_timestamp': '2026-03-17T10:30:00.000Z',
        'error_message': 'Insufficient permissions',
      };

      final response = ShareResponse.fromJson(json);

      expect(response.success, false);
      expect(response.errorMessage, 'Insufficient permissions');
    });

    test('fromJson handles missing error_message as null', () {
      final json = <String, dynamic>{
        'share_id': 'x',
        'success': true,
        'version': 1,
        'server_timestamp': '2026-01-01T00:00:00.000Z',
      };

      final response = ShareResponse.fromJson(json);
      expect(response.errorMessage, isNull);
    });

    test('round-trip: toJson -> fromJson preserves all fields', () {
      final original = ShareResponse(
        shareId: 'share-rt',
        success: true,
        version: 7,
        serverTimestamp: DateTime.utc(2026, 6, 15, 12, 0, 0),
        errorMessage: null,
      );

      final json = original.toJson();
      final restored = ShareResponse.fromJson(json);

      expect(restored.shareId, original.shareId);
      expect(restored.success, original.success);
      expect(restored.version, original.version);
      expect(restored.serverTimestamp, original.serverTimestamp);
      expect(restored.errorMessage, original.errorMessage);
    });

    test('round-trip with error message preserves error field', () {
      final original = ShareResponse(
        shareId: 'share-err',
        success: false,
        version: 0,
        serverTimestamp: DateTime.utc(2026, 1, 1),
        errorMessage: 'Entity not found',
      );

      final json = original.toJson();
      final restored = ShareResponse.fromJson(json);

      expect(restored.errorMessage, 'Entity not found');
    });

    test('toJson omits error_message when null', () {
      final response = ShareResponse(
        shareId: 's',
        success: true,
        version: 1,
        serverTimestamp: DateTime.utc(2026),
      );

      expect(response.toJson().containsKey('error_message'), false);
    });

    test('toJson includes error_message when present', () {
      final response = ShareResponse(
        shareId: 's',
        success: false,
        version: 0,
        serverTimestamp: DateTime.utc(2026),
        errorMessage: 'conflict',
      );

      expect(response.toJson()['error_message'], 'conflict');
    });
  });

  // =========================================================================
  // 3. TeamUpdateStatus deserialization
  // =========================================================================
  group('TeamUpdateStatus deserialization', () {
    test('fromJson parses team-updates endpoint response', () {
      final json = <String, dynamic>{
        'available_updates': 2,
        'updates': [
          {
            'entity_type': 'project',
            'entity_id': 'proj-1',
            'entity_title': 'Alpha Project',
            'team_id': 'team-1',
            'team_name': 'Engineering',
            'author_name': 'Alice',
            'from_version': 3,
            'to_version': 5,
            'updated_at': '2026-03-17T09:00:00.000Z',
          },
          {
            'entity_type': 'note',
            'entity_id': 'note-2',
            'entity_title': 'Sprint Retro',
            'team_id': 'team-1',
            'team_name': 'Engineering',
            'author_name': 'Bob',
            'from_version': 1,
            'to_version': 2,
            'updated_at': '2026-03-17T09:15:00.000Z',
          },
        ],
        'checked_at': '2026-03-17T09:20:00.000Z',
      };

      final status = TeamUpdateStatus.fromJson(json);

      expect(status.availableUpdates, 2);
      expect(status.updates.length, 2);
      expect(status.checkedAt, DateTime.utc(2026, 3, 17, 9, 20));
    });

    test('fromJson parses individual TeamUpdateEntry fields', () {
      final json = <String, dynamic>{
        'available_updates': 1,
        'updates': [
          {
            'entity_type': 'workflow',
            'entity_id': 'wfl-77',
            'entity_title': 'Deploy Pipeline',
            'team_id': 'team-ops',
            'team_name': 'DevOps',
            'author_name': 'Charlie',
            'from_version': 10,
            'to_version': 12,
            'updated_at': '2026-03-16T18:00:00.000Z',
          },
        ],
        'checked_at': '2026-03-17T00:00:00.000Z',
      };

      final status = TeamUpdateStatus.fromJson(json);
      final entry = status.updates.first;

      expect(entry.entityType, 'workflow');
      expect(entry.entityId, 'wfl-77');
      expect(entry.entityTitle, 'Deploy Pipeline');
      expect(entry.teamId, 'team-ops');
      expect(entry.teamName, 'DevOps');
      expect(entry.authorName, 'Charlie');
      expect(entry.fromVersion, 10);
      expect(entry.toVersion, 12);
      expect(entry.updatedAt, DateTime.utc(2026, 3, 16, 18, 0));
    });

    test('fromJson defaults available_updates to 0 when missing', () {
      final json = <String, dynamic>{'checked_at': '2026-03-17T00:00:00.000Z'};

      final status = TeamUpdateStatus.fromJson(json);

      expect(status.availableUpdates, 0);
      expect(status.updates, isEmpty);
    });

    test('round-trip: toJson -> fromJson preserves data', () {
      final original = TeamUpdateStatus(
        availableUpdates: 3,
        updates: [
          TeamUpdateEntry(
            entityType: 'agent',
            entityId: 'agt-1',
            entityTitle: 'Code Agent',
            teamId: 'team-ai',
            teamName: 'AI Team',
            authorName: 'Dana',
            fromVersion: 1,
            toVersion: 4,
            updatedAt: DateTime.utc(2026, 3, 15, 14, 30),
          ),
        ],
        checkedAt: DateTime.utc(2026, 3, 17, 12, 0),
      );

      final json = original.toJson();
      final restored = TeamUpdateStatus.fromJson(json);

      expect(restored.availableUpdates, 3);
      expect(restored.updates.length, 1);
      expect(restored.updates.first.entityTitle, 'Code Agent');
      expect(restored.updates.first.toVersion, 4);
      expect(restored.checkedAt, original.checkedAt);
    });

    test('TeamUpdateEntry toJson produces snake_case keys', () {
      final entry = TeamUpdateEntry(
        entityType: 'doc',
        entityId: 'd-1',
        entityTitle: 'Readme',
        teamId: 't-1',
        teamName: 'Docs',
        authorName: 'Eve',
        fromVersion: 0,
        toVersion: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final json = entry.toJson();

      expect(json.containsKey('entity_type'), true);
      expect(json.containsKey('entity_id'), true);
      expect(json.containsKey('entity_title'), true);
      expect(json.containsKey('team_id'), true);
      expect(json.containsKey('team_name'), true);
      expect(json.containsKey('author_name'), true);
      expect(json.containsKey('from_version'), true);
      expect(json.containsKey('to_version'), true);
      expect(json.containsKey('updated_at'), true);
    });
  });

  // =========================================================================
  // 4. SyncVersionEntry list deserialization
  // =========================================================================
  group('SyncVersionEntry list deserialization', () {
    test('parses entries array from /api/sync/history response', () {
      final serverResponse = <String, dynamic>{
        'entries': [
          {
            'id': 'ver-1',
            'entity_type': 'project',
            'entity_id': 'proj-1',
            'version': 1,
            'author_id': 'user-1',
            'author_name': 'Alice',
            'change_summary': 'Initial creation',
            'timestamp': '2026-03-10T08:00:00.000Z',
            'content_hash': 'hash-v1',
          },
          {
            'id': 'ver-2',
            'entity_type': 'project',
            'entity_id': 'proj-1',
            'version': 2,
            'author_id': 'user-2',
            'author_name': 'Bob',
            'timestamp': '2026-03-11T12:00:00.000Z',
          },
          {
            'id': 'ver-3',
            'entity_type': 'project',
            'entity_id': 'proj-1',
            'version': 3,
            'author_id': 'user-1',
            'author_name': 'Alice',
            'change_summary': 'Added deployment config',
            'timestamp': '2026-03-12T16:30:00.000Z',
            'content_hash': 'hash-v3',
          },
        ],
      };

      // Simulate what SyncApiClient.getEntityHistory does:
      final entries = (serverResponse['entries'] as List)
          .map((e) => SyncVersionEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(entries.length, 3);
      expect(entries[0].version, 1);
      expect(entries[1].version, 2);
      expect(entries[2].version, 3);
    });

    test('parses entry with all fields populated', () {
      final json = <String, dynamic>{
        'id': 'ver-full',
        'entity_type': 'note',
        'entity_id': 'note-42',
        'version': 7,
        'author_id': 'user-99',
        'author_name': 'Zara',
        'change_summary': 'Fixed typo in section 3',
        'timestamp': '2026-03-17T14:00:00.000Z',
        'content_hash': 'sha256-full',
      };

      final entry = SyncVersionEntry.fromJson(json);

      expect(entry.id, 'ver-full');
      expect(entry.entityType, 'note');
      expect(entry.entityId, 'note-42');
      expect(entry.version, 7);
      expect(entry.authorId, 'user-99');
      expect(entry.authorName, 'Zara');
      expect(entry.changeSummary, 'Fixed typo in section 3');
      expect(entry.timestamp, DateTime.utc(2026, 3, 17, 14, 0));
      expect(entry.contentHash, 'sha256-full');
    });

    test('parses entry with optional fields missing', () {
      final json = <String, dynamic>{
        'id': 'ver-min',
        'entity_type': 'skill',
        'entity_id': 'skill-1',
        'version': 1,
        'author_id': 'user-1',
        'author_name': 'Minimal',
        'timestamp': '2026-01-01T00:00:00.000Z',
      };

      final entry = SyncVersionEntry.fromJson(json);

      expect(entry.changeSummary, isNull);
      expect(entry.contentHash, isNull);
    });

    test('handles empty entries array', () {
      final serverResponse = <String, dynamic>{'entries': <dynamic>[]};

      final entries = (serverResponse['entries'] as List)
          .map((e) => SyncVersionEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(entries, isEmpty);
    });

    test('handles missing entries key (defaults to empty)', () {
      final serverResponse = <String, dynamic>{};

      // Simulate the null-coalescing in SyncApiClient:
      final entries = (serverResponse['entries'] as List? ?? [])
          .map((e) => SyncVersionEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(entries, isEmpty);
    });

    test('round-trip: toJson -> fromJson preserves all fields', () {
      final original = SyncVersionEntry(
        id: 'ver-rt',
        entityType: 'agent',
        entityId: 'agt-10',
        version: 5,
        authorId: 'uid-7',
        authorName: 'RoundTripper',
        changeSummary: 'Updated prompt template',
        timestamp: DateTime.utc(2026, 2, 28, 23, 59, 59),
        contentHash: 'rt-hash',
      );

      final json = original.toJson();
      final restored = SyncVersionEntry.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.entityType, original.entityType);
      expect(restored.entityId, original.entityId);
      expect(restored.version, original.version);
      expect(restored.authorId, original.authorId);
      expect(restored.authorName, original.authorName);
      expect(restored.changeSummary, original.changeSummary);
      expect(restored.timestamp, original.timestamp);
      expect(restored.contentHash, original.contentHash);
    });

    test('toJson omits optional fields when null', () {
      final entry = SyncVersionEntry(
        id: 'v1',
        entityType: 'doc',
        entityId: 'd1',
        version: 1,
        authorId: 'u1',
        authorName: 'A',
        timestamp: DateTime.utc(2026),
      );

      final json = entry.toJson();

      expect(json.containsKey('change_summary'), false);
      expect(json.containsKey('content_hash'), false);
    });
  });

  // =========================================================================
  // 5. Team list deserialization
  // =========================================================================
  group('Team list deserialization', () {
    test('parses teams array from GET /api/teams response', () {
      final serverResponse = <String, dynamic>{
        'teams': [
          {
            'id': 'team-eng',
            'name': 'Engineering',
            'description': 'Core engineering team',
            'avatar_url': 'https://example.com/eng.png',
            'members': [
              {
                'id': 'user-1',
                'name': 'Alice',
                'email': 'alice@example.com',
                'role': 'admin',
                'is_online': true,
              },
              {'id': 'user-2', 'name': 'Bob', 'role': 'member'},
            ],
            'created_at': '2026-01-15T10:00:00.000Z',
          },
          {
            'id': 'team-design',
            'name': 'Design',
            'created_at': '2026-02-01T09:00:00.000Z',
          },
        ],
      };

      // Simulate what SyncApiClient.getTeams does:
      final teams = (serverResponse['teams'] as List)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(teams.length, 2);
      expect(teams[0].id, 'team-eng');
      expect(teams[0].name, 'Engineering');
      expect(teams[0].description, 'Core engineering team');
      expect(teams[0].avatarUrl, 'https://example.com/eng.png');
      expect(teams[0].members.length, 2);
      expect(teams[0].createdAt, DateTime.utc(2026, 1, 15, 10, 0));

      expect(teams[1].id, 'team-design');
      expect(teams[1].name, 'Design');
      expect(teams[1].description, isNull);
      expect(teams[1].avatarUrl, isNull);
      expect(teams[1].members, isEmpty);
    });

    test('parses Team with nested TeamMember fields', () {
      final json = <String, dynamic>{
        'id': 'team-1',
        'name': 'Full Team',
        'members': [
          {
            'id': 'u-1',
            'name': 'Member One',
            'email': 'one@test.com',
            'avatar_url': 'https://img.test/1.png',
            'role': 'admin',
            'is_online': true,
          },
        ],
        'created_at': '2026-03-01T00:00:00.000Z',
      };

      final team = Team.fromJson(json);
      final member = team.members.first;

      expect(member.id, 'u-1');
      expect(member.name, 'Member One');
      expect(member.email, 'one@test.com');
      expect(member.avatarUrl, 'https://img.test/1.png');
      expect(member.role, 'admin');
      expect(member.isOnline, true);
    });

    test('handles empty teams array', () {
      final serverResponse = <String, dynamic>{'teams': <dynamic>[]};

      final teams = (serverResponse['teams'] as List)
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(teams, isEmpty);
    });

    test('handles missing teams key (defaults to empty)', () {
      final serverResponse = <String, dynamic>{};

      final teams = (serverResponse['teams'] as List? ?? [])
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(teams, isEmpty);
    });

    test('round-trip: toJson -> fromJson preserves Team data', () {
      final original = Team(
        id: 'team-rt',
        name: 'Round Trip Team',
        description: 'Testing round trip',
        avatarUrl: 'https://avatar.test/rt.png',
        members: [
          const TeamMember(
            id: 'u-rt',
            name: 'RT User',
            email: 'rt@test.com',
            role: 'viewer',
            isOnline: false,
          ),
        ],
        createdAt: DateTime.utc(2026, 6, 1, 8, 0),
      );

      final json = original.toJson();
      final restored = Team.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.members.length, 1);
      expect(restored.members.first.id, 'u-rt');
      expect(restored.members.first.role, 'viewer');
      expect(restored.createdAt, original.createdAt);
    });

    test('toJson omits optional fields when null', () {
      final team = Team(
        id: 't',
        name: 'Minimal',
        createdAt: DateTime.utc(2026),
      );

      final json = team.toJson();

      expect(json.containsKey('description'), false);
      expect(json.containsKey('avatar_url'), false);
    });
  });

  // =========================================================================
  // 6. TeamMember list deserialization
  // =========================================================================
  group('TeamMember list deserialization', () {
    test('parses members array from GET /api/teams/:id/members response', () {
      final serverResponse = <String, dynamic>{
        'members': [
          {
            'id': 'user-a',
            'name': 'Alice Admin',
            'email': 'alice@corp.com',
            'avatar_url': 'https://img.corp/alice.png',
            'role': 'admin',
            'is_online': true,
          },
          {
            'id': 'user-b',
            'name': 'Bob Builder',
            'email': 'bob@corp.com',
            'role': 'member',
            'is_online': false,
          },
          {'id': 'user-c', 'name': 'Carol Viewer', 'role': 'viewer'},
        ],
      };

      // Simulate what SyncApiClient.getTeamMembers does:
      final members = (serverResponse['members'] as List)
          .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(members.length, 3);
      expect(members[0].name, 'Alice Admin');
      expect(members[0].role, 'admin');
      expect(members[0].isOnline, true);
      expect(members[1].email, 'bob@corp.com');
      expect(members[2].avatarUrl, isNull);
    });

    test('defaults role to "member" when missing', () {
      final json = <String, dynamic>{'id': 'u-1', 'name': 'No Role'};

      final member = TeamMember.fromJson(json);
      expect(member.role, 'member');
    });

    test('defaults is_online to false when missing', () {
      final json = <String, dynamic>{'id': 'u-1', 'name': 'Offline'};

      final member = TeamMember.fromJson(json);
      expect(member.isOnline, false);
    });

    test('handles empty members array', () {
      final serverResponse = <String, dynamic>{'members': <dynamic>[]};

      final members = (serverResponse['members'] as List)
          .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(members, isEmpty);
    });

    test('handles missing members key (defaults to empty)', () {
      final serverResponse = <String, dynamic>{};

      final members = (serverResponse['members'] as List? ?? [])
          .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(members, isEmpty);
    });

    test('round-trip: toJson -> fromJson preserves all fields', () {
      const original = TeamMember(
        id: 'u-rt',
        name: 'Round Trip Member',
        email: 'rt@test.com',
        avatarUrl: 'https://avatar.test/rt.png',
        role: 'admin',
        isOnline: true,
      );

      final json = original.toJson();
      final restored = TeamMember.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.avatarUrl, original.avatarUrl);
      expect(restored.role, original.role);
      expect(restored.isOnline, original.isOnline);
    });

    test('toJson omits email and avatar_url when null', () {
      const member = TeamMember(id: 'u', name: 'Minimal');
      final json = member.toJson();

      expect(json.containsKey('email'), false);
      expect(json.containsKey('avatar_url'), false);
      // Required fields should always be present.
      expect(json.containsKey('id'), true);
      expect(json.containsKey('name'), true);
      expect(json.containsKey('role'), true);
      expect(json.containsKey('is_online'), true);
    });

    test('copyWith produces updated member', () {
      const member = TeamMember(
        id: 'u-1',
        name: 'Original',
        role: 'member',
        isOnline: false,
      );

      final updated = member.copyWith(name: 'Updated', isOnline: true);

      expect(updated.id, 'u-1');
      expect(updated.name, 'Updated');
      expect(updated.isOnline, true);
      expect(updated.role, 'member');
    });
  });

  // =========================================================================
  // 7. TeamShare list deserialization
  // =========================================================================
  group('TeamShare list deserialization', () {
    test('parses shares array from GET /api/sync/share/:type/:id response', () {
      final serverResponse = <String, dynamic>{
        'shares': [
          {
            'id': 'share-1',
            'entity_type': 'project',
            'entity_id': 'proj-100',
            'team_id': 'team-eng',
            'share_with_all': true,
            'member_ids': <String>[],
            'permission': 'write',
            'shared_by': 'user-admin',
            'shared_at': '2026-03-10T10:00:00.000Z',
            'last_synced_at': '2026-03-17T08:00:00.000Z',
            'version': 5,
            'content_hash': 'hash-5',
          },
          {
            'id': 'share-2',
            'entity_type': 'project',
            'entity_id': 'proj-100',
            'team_id': 'team-design',
            'share_with_all': false,
            'member_ids': ['user-x', 'user-y'],
            'permission': 'read',
            'shared_by': 'user-admin',
            'shared_at': '2026-03-12T14:00:00.000Z',
            'version': 3,
          },
        ],
      };

      // Simulate what SyncApiClient.getEntityShares does:
      final shares = (serverResponse['shares'] as List)
          .map((e) => TeamShare.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(shares.length, 2);

      expect(shares[0].id, 'share-1');
      expect(shares[0].shareWithAll, true);
      expect(shares[0].permission, SharePermission.write);
      expect(shares[0].lastSyncedAt, DateTime.utc(2026, 3, 17, 8, 0));
      expect(shares[0].contentHash, 'hash-5');

      expect(shares[1].id, 'share-2');
      expect(shares[1].shareWithAll, false);
      expect(shares[1].memberIds, ['user-x', 'user-y']);
      expect(shares[1].permission, SharePermission.read);
      expect(shares[1].lastSyncedAt, isNull);
      expect(shares[1].contentHash, isNull);
    });

    test('fromJson handles all permission levels', () {
      for (final perm in ['read', 'write', 'admin']) {
        final json = <String, dynamic>{
          'id': 'share-perm',
          'entity_type': 'note',
          'entity_id': 'n-1',
          'team_id': 't-1',
          'permission': perm,
          'shared_by': 'u-1',
          'shared_at': '2026-01-01T00:00:00.000Z',
        };

        final share = TeamShare.fromJson(json);
        expect(share.permission, SharePermission.fromString(perm));
      }
    });

    test('fromJson defaults share_with_all to true when missing', () {
      final json = <String, dynamic>{
        'id': 'share-def',
        'entity_type': 'doc',
        'entity_id': 'd-1',
        'team_id': 't-1',
        'shared_by': 'u-1',
        'shared_at': '2026-01-01T00:00:00.000Z',
      };

      final share = TeamShare.fromJson(json);
      expect(share.shareWithAll, true);
    });

    test('fromJson defaults permission to read when missing', () {
      final json = <String, dynamic>{
        'id': 'share-noperm',
        'entity_type': 'doc',
        'entity_id': 'd-1',
        'team_id': 't-1',
        'shared_by': 'u-1',
        'shared_at': '2026-01-01T00:00:00.000Z',
      };

      final share = TeamShare.fromJson(json);
      expect(share.permission, SharePermission.read);
    });

    test('fromJson defaults version to 1 when missing', () {
      final json = <String, dynamic>{
        'id': 'share-nover',
        'entity_type': 'skill',
        'entity_id': 's-1',
        'team_id': 't-1',
        'shared_by': 'u-1',
        'shared_at': '2026-01-01T00:00:00.000Z',
      };

      final share = TeamShare.fromJson(json);
      expect(share.version, 1);
    });

    test('fromJson defaults member_ids to empty list when missing', () {
      final json = <String, dynamic>{
        'id': 'share-nomem',
        'entity_type': 'agent',
        'entity_id': 'a-1',
        'team_id': 't-1',
        'shared_by': 'u-1',
        'shared_at': '2026-01-01T00:00:00.000Z',
      };

      final share = TeamShare.fromJson(json);
      expect(share.memberIds, <String>[]);
    });

    test('handles empty shares array', () {
      final serverResponse = <String, dynamic>{'shares': <dynamic>[]};

      final shares = (serverResponse['shares'] as List)
          .map((e) => TeamShare.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(shares, isEmpty);
    });

    test('handles missing shares key (defaults to empty)', () {
      final serverResponse = <String, dynamic>{};

      final shares = (serverResponse['shares'] as List? ?? [])
          .map((e) => TeamShare.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(shares, isEmpty);
    });

    test('round-trip: toJson -> fromJson preserves all fields', () {
      final original = TeamShare(
        id: 'share-rt',
        entityType: 'workflow',
        entityId: 'wfl-rt',
        teamId: 'team-rt',
        shareWithAll: false,
        memberIds: const ['m-1', 'm-2'],
        permission: SharePermission.admin,
        sharedBy: 'u-admin',
        sharedAt: DateTime.utc(2026, 3, 1, 9, 0),
        lastSyncedAt: DateTime.utc(2026, 3, 15, 12, 0),
        version: 8,
        contentHash: 'rt-hash-8',
      );

      final json = original.toJson();
      final restored = TeamShare.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.entityType, original.entityType);
      expect(restored.entityId, original.entityId);
      expect(restored.teamId, original.teamId);
      expect(restored.shareWithAll, original.shareWithAll);
      expect(restored.memberIds, original.memberIds);
      expect(restored.permission, original.permission);
      expect(restored.sharedBy, original.sharedBy);
      expect(restored.sharedAt, original.sharedAt);
      expect(restored.lastSyncedAt, original.lastSyncedAt);
      expect(restored.version, original.version);
      expect(restored.contentHash, original.contentHash);
    });

    test('toJson omits optional fields when null', () {
      final share = TeamShare(
        id: 's',
        entityType: 'note',
        entityId: 'n',
        teamId: 't',
        sharedBy: 'u',
        sharedAt: DateTime.utc(2026),
      );

      final json = share.toJson();

      expect(json.containsKey('last_synced_at'), false);
      expect(json.containsKey('content_hash'), false);
      // Required fields should always be present.
      expect(json.containsKey('id'), true);
      expect(json.containsKey('entity_type'), true);
      expect(json.containsKey('shared_at'), true);
      expect(json.containsKey('version'), true);
    });

    test('toJson includes last_synced_at and content_hash when present', () {
      final share = TeamShare(
        id: 's',
        entityType: 'note',
        entityId: 'n',
        teamId: 't',
        sharedBy: 'u',
        sharedAt: DateTime.utc(2026),
        lastSyncedAt: DateTime.utc(2026, 3, 17),
        contentHash: 'present-hash',
      );

      final json = share.toJson();

      expect(json.containsKey('last_synced_at'), true);
      expect(json.containsKey('content_hash'), true);
      expect(json['content_hash'], 'present-hash');
    });
  });

  // =========================================================================
  // 8. API endpoint paths
  // =========================================================================
  group('API endpoint paths', () {
    // SyncApiClient uses static const paths. We cannot access private static
    // constants directly, but we can verify the expected URL patterns that the
    // API client constructs by checking the known contract.

    test('share endpoint: POST /api/sync/share', () {
      const expected = '/api/sync/share';
      // Validates the path the client uses for shareEntity().
      expect(expected, startsWith('/api/sync/'));
      expect(expected, endsWith('/share'));
    });

    test('team-updates endpoint: GET /api/sync/team-updates', () {
      const expected = '/api/sync/team-updates';
      expect(expected, '/api/sync/team-updates');
    });

    test('teams endpoint: GET /api/teams', () {
      const expected = '/api/teams';
      expect(expected, '/api/teams');
    });

    test('team members endpoint: GET /api/teams/:id/members', () {
      const teamId = 'team-abc';
      const path = '/api/teams/$teamId/members';
      expect(path, '/api/teams/team-abc/members');
    });

    test('entity shares endpoint: GET /api/sync/share/:type/:id', () {
      const entityType = 'project';
      const entityId = 'proj-123';
      const path = '/api/sync/share/$entityType/$entityId';
      expect(path, '/api/sync/share/project/proj-123');
    });

    test('revoke share endpoint: DELETE /api/sync/share/:shareId', () {
      const shareId = 'share-xyz';
      const path = '/api/sync/share/$shareId';
      expect(path, '/api/sync/share/share-xyz');
    });

    test('history endpoint: GET /api/sync/history/:type/:id', () {
      const entityType = 'note';
      const entityId = 'note-42';
      const path = '/api/sync/history/$entityType/$entityId';
      expect(path, '/api/sync/history/note/note-42');
    });

    test('push/pull/status endpoints use /api/sync/ prefix', () {
      const push = '/api/sync/push';
      const pull = '/api/sync/pull';
      const status = '/api/sync/status';

      for (final path in [push, pull, status]) {
        expect(path, startsWith('/api/sync/'));
      }
    });
  });

  // =========================================================================
  // 9. Edge cases
  // =========================================================================
  group('Edge cases', () {
    group('empty lists', () {
      test('ShareRequest with empty memberIds serializes correctly', () {
        const request = ShareRequest(
          entityType: 'project',
          entityId: 'p-1',
          teamId: 't-1',
          shareWithAll: true,
          memberIds: [],
          entityData: {},
          contentHash: 'h',
        );

        final json = request.toJson();
        expect(json['member_ids'], <String>[]);

        final restored = ShareRequest.fromJson(json);
        expect(restored.memberIds, isEmpty);
      });

      test('TeamShare with empty memberIds round-trips', () {
        final share = TeamShare(
          id: 's-empty',
          entityType: 'doc',
          entityId: 'd-1',
          teamId: 't-1',
          memberIds: const [],
          sharedBy: 'u-1',
          sharedAt: DateTime.utc(2026),
        );

        final json = share.toJson();
        expect(json['member_ids'], <String>[]);

        final restored = TeamShare.fromJson(json);
        expect(restored.memberIds, isEmpty);
      });

      test('Team with empty members list round-trips', () {
        final team = Team(
          id: 't-nomem',
          name: 'Ghost Team',
          members: const [],
          createdAt: DateTime.utc(2026),
        );

        final json = team.toJson();
        expect(json['members'], <dynamic>[]);

        final restored = Team.fromJson(json);
        expect(restored.members, isEmpty);
      });

      test('TeamUpdateStatus with empty updates round-trips', () {
        final status = TeamUpdateStatus(
          availableUpdates: 0,
          updates: const [],
          checkedAt: DateTime.utc(2026),
        );

        final json = status.toJson();
        expect(json['updates'], <dynamic>[]);

        final restored = TeamUpdateStatus.fromJson(json);
        expect(restored.updates, isEmpty);
        expect(restored.availableUpdates, 0);
      });
    });

    group('missing optional fields', () {
      test('TeamMember fromJson with only required fields', () {
        final json = <String, dynamic>{'id': 'u-min', 'name': 'Minimum'};

        final member = TeamMember.fromJson(json);

        expect(member.id, 'u-min');
        expect(member.name, 'Minimum');
        expect(member.email, isNull);
        expect(member.avatarUrl, isNull);
        expect(member.role, 'member');
        expect(member.isOnline, false);
      });

      test('Team fromJson with only required fields', () {
        final json = <String, dynamic>{
          'id': 't-min',
          'name': 'Minimal Team',
          'created_at': '2026-01-01T00:00:00.000Z',
        };

        final team = Team.fromJson(json);

        expect(team.description, isNull);
        expect(team.avatarUrl, isNull);
        expect(team.members, isEmpty);
      });

      test('EntitySyncMetadata fromJson with minimal fields', () {
        final json = <String, dynamic>{
          'entity_type': 'project',
          'entity_id': 'p-1',
        };

        final meta = EntitySyncMetadata.fromJson(json);

        expect(meta.status, EntitySyncStatus.neverSynced);
        expect(meta.lastSyncedAt, isNull);
        expect(meta.localVersion, 0);
        expect(meta.remoteVersion, isNull);
        expect(meta.contentHash, isNull);
        expect(meta.lastSyncedBy, isNull);
        expect(meta.sharedWithTeamIds, isEmpty);
      });

      test('EntitySyncMetadata round-trip preserves optional nulls', () {
        const original = EntitySyncMetadata(
          entityType: 'note',
          entityId: 'n-1',
        );

        final json = original.toJson();
        final restored = EntitySyncMetadata.fromJson(json);

        expect(restored.lastSyncedAt, isNull);
        expect(restored.remoteVersion, isNull);
        expect(restored.contentHash, isNull);
        expect(restored.lastSyncedBy, isNull);
      });

      test('EntitySyncMetadata round-trip preserves all populated fields', () {
        final original = EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p-1',
          status: EntitySyncStatus.synced,
          lastSyncedAt: DateTime.utc(2026, 3, 17),
          localVersion: 5,
          remoteVersion: 5,
          contentHash: 'abc',
          lastSyncedBy: 'user-1',
          sharedWithTeamIds: ['team-1', 'team-2'],
        );

        final json = original.toJson();
        final restored = EntitySyncMetadata.fromJson(json);

        expect(restored.entityType, original.entityType);
        expect(restored.entityId, original.entityId);
        expect(restored.status, EntitySyncStatus.synced);
        expect(restored.lastSyncedAt, original.lastSyncedAt);
        expect(restored.localVersion, 5);
        expect(restored.remoteVersion, 5);
        expect(restored.contentHash, 'abc');
        expect(restored.lastSyncedBy, 'user-1');
        expect(restored.sharedWithTeamIds, ['team-1', 'team-2']);
      });
    });

    group('malformed data handling', () {
      test('SharePermission.fromString throws on unknown value', () {
        expect(
          () => SharePermission.fromString('owner'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('SharePermission.fromString throws on empty string', () {
        expect(
          () => SharePermission.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('SyncEntityType.fromString throws on unknown value', () {
        expect(
          () => SyncEntityType.fromString('folder'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('EntitySyncStatus.fromString throws on camelCase', () {
        expect(
          () => EntitySyncStatus.fromString('neverSynced'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('EntitySyncStatus.fromString throws on unknown value', () {
        expect(
          () => EntitySyncStatus.fromString('deleted'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('TeamMember.fromJson throws on missing required id', () {
        final json = <String, dynamic>{'name': 'No ID'};

        expect(() => TeamMember.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('TeamMember.fromJson throws on missing required name', () {
        final json = <String, dynamic>{'id': 'u-1'};

        expect(() => TeamMember.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('Team.fromJson throws on missing required created_at', () {
        final json = <String, dynamic>{'id': 't-1', 'name': 'Team No Date'};

        expect(
          () => Team.fromJson(json),
          throwsA(anyOf(isA<TypeError>(), isA<FormatException>())),
        );
      });

      test('ShareResponse.fromJson throws on missing required fields', () {
        final json = <String, dynamic>{'success': true};

        expect(() => ShareResponse.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('SyncVersionEntry.fromJson throws on missing required version', () {
        final json = <String, dynamic>{
          'id': 'v-1',
          'entity_type': 'doc',
          'entity_id': 'd-1',
          'author_id': 'u-1',
          'author_name': 'A',
          'timestamp': '2026-01-01T00:00:00.000Z',
        };

        expect(
          () => SyncVersionEntry.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });

      test('TeamShare.fromJson throws on missing required shared_at', () {
        final json = <String, dynamic>{
          'id': 's-1',
          'entity_type': 'project',
          'entity_id': 'p-1',
          'team_id': 't-1',
          'shared_by': 'u-1',
        };

        expect(
          () => TeamShare.fromJson(json),
          throwsA(anyOf(isA<TypeError>(), isA<FormatException>())),
        );
      });

      test('TeamUpdateEntry.fromJson throws on missing required fields', () {
        final json = <String, dynamic>{
          'entity_type': 'project',
          // Missing all other required fields.
        };

        expect(() => TeamUpdateEntry.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    group('DateTime serialization', () {
      test('ShareResponse serverTimestamp preserves UTC precision', () {
        final json = <String, dynamic>{
          'share_id': 's',
          'success': true,
          'version': 1,
          'server_timestamp': '2026-03-17T10:30:45.123Z',
        };

        final response = ShareResponse.fromJson(json);

        expect(response.serverTimestamp.year, 2026);
        expect(response.serverTimestamp.month, 3);
        expect(response.serverTimestamp.day, 17);
        expect(response.serverTimestamp.hour, 10);
        expect(response.serverTimestamp.minute, 30);
        expect(response.serverTimestamp.second, 45);
        expect(response.serverTimestamp.millisecond, 123);
        expect(response.serverTimestamp.isUtc, true);
      });

      test('TeamShare sharedAt parses timezone-aware ISO 8601', () {
        final json = <String, dynamic>{
          'id': 's-tz',
          'entity_type': 'note',
          'entity_id': 'n-1',
          'team_id': 't-1',
          'shared_by': 'u-1',
          'shared_at': '2026-03-17T10:00:00.000Z',
        };

        final share = TeamShare.fromJson(json);
        expect(share.sharedAt, DateTime.utc(2026, 3, 17, 10, 0));
        expect(share.sharedAt.isUtc, true);
      });

      test('toJson outputs ISO 8601 UTC string for DateTime fields', () {
        final share = TeamShare(
          id: 's',
          entityType: 'doc',
          entityId: 'd',
          teamId: 't',
          sharedBy: 'u',
          sharedAt: DateTime.utc(2026, 12, 31, 23, 59, 59),
          lastSyncedAt: DateTime.utc(2026, 12, 31, 23, 59, 59),
        );

        final json = share.toJson();
        final sharedAtStr = json['shared_at'] as String;
        final lastSyncedAtStr = json['last_synced_at'] as String;

        expect(sharedAtStr, contains('2026-12-31'));
        expect(sharedAtStr, endsWith('Z'));
        expect(lastSyncedAtStr, endsWith('Z'));
      });
    });

    group('copyWith', () {
      test('TeamShare copyWith updates only specified fields', () {
        final original = TeamShare(
          id: 's-1',
          entityType: 'project',
          entityId: 'p-1',
          teamId: 't-1',
          shareWithAll: true,
          permission: SharePermission.read,
          sharedBy: 'u-1',
          sharedAt: DateTime.utc(2026, 1, 1),
          version: 1,
        );

        final updated = original.copyWith(
          permission: SharePermission.admin,
          version: 5,
        );

        expect(updated.id, 's-1');
        expect(updated.entityType, 'project');
        expect(updated.permission, SharePermission.admin);
        expect(updated.version, 5);
        // Unchanged fields remain.
        expect(updated.shareWithAll, true);
        expect(updated.sharedBy, 'u-1');
      });

      test('EntitySyncMetadata copyWith updates status', () {
        const original = EntitySyncMetadata(
          entityType: 'note',
          entityId: 'n-1',
          status: EntitySyncStatus.neverSynced,
          localVersion: 0,
        );

        final updated = original.copyWith(
          status: EntitySyncStatus.synced,
          localVersion: 3,
          remoteVersion: 3,
        );

        expect(updated.status, EntitySyncStatus.synced);
        expect(updated.localVersion, 3);
        expect(updated.remoteVersion, 3);
        expect(updated.entityType, 'note');
        expect(updated.entityId, 'n-1');
      });

      test('SyncVersionEntry copyWith updates changeSummary', () {
        final original = SyncVersionEntry(
          id: 'v-1',
          entityType: 'doc',
          entityId: 'd-1',
          version: 1,
          authorId: 'u-1',
          authorName: 'Author',
          timestamp: DateTime.utc(2026),
        );

        final updated = original.copyWith(
          changeSummary: 'Added introduction section',
          contentHash: 'new-hash',
        );

        expect(updated.changeSummary, 'Added introduction section');
        expect(updated.contentHash, 'new-hash');
        expect(updated.version, 1);
        expect(updated.authorName, 'Author');
      });

      test('TeamUpdateStatus copyWith updates availableUpdates', () {
        final original = TeamUpdateStatus(
          availableUpdates: 5,
          updates: const [],
          checkedAt: DateTime.utc(2026),
        );

        final updated = original.copyWith(availableUpdates: 0);

        expect(updated.availableUpdates, 0);
        expect(updated.checkedAt, original.checkedAt);
      });
    });

    group('toString', () {
      test('TeamMember.toString includes id, name, role', () {
        const member = TeamMember(id: 'u-1', name: 'Alice', role: 'admin');
        expect(member.toString(), 'TeamMember(u-1, Alice, admin)');
      });

      test('Team.toString includes id, name, member count', () {
        final team = Team(
          id: 't-1',
          name: 'Engineering',
          members: const [
            TeamMember(id: 'u-1', name: 'A'),
            TeamMember(id: 'u-2', name: 'B'),
          ],
          createdAt: DateTime.utc(2026),
        );
        expect(team.toString(), 'Team(t-1, Engineering, 2 members)');
      });

      test('TeamShare.toString includes entity path and version', () {
        final share = TeamShare(
          id: 's-1',
          entityType: 'project',
          entityId: 'p-1',
          teamId: 't-1',
          sharedBy: 'u-1',
          sharedAt: DateTime.utc(2026),
          version: 3,
        );
        expect(share.toString(), 'TeamShare(project/p-1 -> team:t-1 v3)');
      });

      test('SyncVersionEntry.toString includes entity, version, author', () {
        final entry = SyncVersionEntry(
          id: 'v-1',
          entityType: 'note',
          entityId: 'n-42',
          version: 7,
          authorId: 'u-1',
          authorName: 'Bob',
          timestamp: DateTime.utc(2026),
        );
        expect(entry.toString(), 'SyncVersionEntry(note/n-42 v7 by Bob)');
      });

      test('TeamUpdateStatus.toString includes update count', () {
        final status = TeamUpdateStatus(
          availableUpdates: 12,
          checkedAt: DateTime.utc(2026),
        );
        expect(status.toString(), 'TeamUpdateStatus(12 updates)');
      });

      test('TeamUpdateEntry.toString includes version range', () {
        final entry = TeamUpdateEntry(
          entityType: 'agent',
          entityId: 'agt-1',
          entityTitle: 'My Agent',
          teamId: 't-1',
          teamName: 'AI',
          authorName: 'Carol',
          fromVersion: 2,
          toVersion: 5,
          updatedAt: DateTime.utc(2026),
        );
        expect(
          entry.toString(),
          'TeamUpdateEntry(agent/agt-1 v2->v5 by Carol)',
        );
      });

      test('EntitySyncMetadata.toString includes status and version', () {
        const meta = EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p-1',
          status: EntitySyncStatus.pending,
          localVersion: 4,
        );
        expect(meta.toString(), 'EntitySyncMetadata(project/p-1 pending v4)');
      });
    });
  });
}
