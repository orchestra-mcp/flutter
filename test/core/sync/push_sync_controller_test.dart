import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/push_sync_controller.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/widgets/team_selector_dialog.dart';

void main() {
  group('PushSyncResult', () {
    test('stores successful result fields', () {
      final response = ShareResponse(
        shareId: 'note_n1_team-1',
        success: true,
        version: 1,
        serverTimestamp: DateTime.utc(2026, 3, 17),
      );
      final result = PushSyncResult(success: true, shareResponse: response);
      expect(result.success, true);
      expect(result.shareResponse, isNotNull);
      expect(result.shareResponse!.shareId, 'note_n1_team-1');
      expect(result.shareResponse!.version, 1);
      expect(result.errorMessage, isNull);
    });

    test('stores failed result with error message', () {
      const result = PushSyncResult(
        success: false,
        errorMessage: 'Network timeout',
      );
      expect(result.success, false);
      expect(result.shareResponse, isNull);
      expect(result.errorMessage, 'Network timeout');
    });

    test('stores result with both response and error', () {
      final response = ShareResponse(
        shareId: 'note_n1_team-1',
        success: false,
        version: 0,
        serverTimestamp: DateTime.utc(2026, 3, 17),
        errorMessage: 'Conflict during share operation',
      );
      final result = PushSyncResult(
        success: false,
        shareResponse: response,
        errorMessage: 'Conflict during share operation',
      );
      expect(result.success, false);
      expect(result.shareResponse, isNotNull);
      expect(result.errorMessage, 'Conflict during share operation');
    });
  });

  group('TeamShareSelection integration', () {
    test('selection maps to push controller params', () {
      const selection = TeamShareSelection(
        teamId: 'team-1',
        shareWithAll: true,
        memberIds: [],
        permission: SharePermission.write,
      );
      // Verify the selection fields used by PushSyncController.pushEntity
      expect(selection.teamId, 'team-1');
      expect(selection.shareWithAll, true);
      expect(selection.memberIds, isEmpty);
      expect(selection.permission, SharePermission.write);
    });

    test('selection with specific members', () {
      const selection = TeamShareSelection(
        teamId: 'team-2',
        shareWithAll: false,
        memberIds: ['u1', 'u2', 'u3'],
        permission: SharePermission.read,
      );
      expect(selection.shareWithAll, false);
      expect(selection.memberIds, hasLength(3));
      expect(selection.permission, SharePermission.read);
    });

    test('selection with admin permission', () {
      const selection = TeamShareSelection(
        teamId: 'team-1',
        shareWithAll: false,
        memberIds: ['u1'],
        permission: SharePermission.admin,
      );
      expect(selection.permission, SharePermission.admin);
    });
  });

  group('ShareResponse', () {
    test('successful response', () {
      final response = ShareResponse(
        shareId: 'skill_s1_team-3',
        success: true,
        version: 5,
        serverTimestamp: DateTime.utc(2026, 3, 17, 12, 30),
      );
      expect(response.shareId, 'skill_s1_team-3');
      expect(response.success, true);
      expect(response.version, 5);
      expect(response.serverTimestamp, DateTime.utc(2026, 3, 17, 12, 30));
      expect(response.errorMessage, isNull);
    });

    test('failed response with error', () {
      final response = ShareResponse(
        shareId: 'note_n2_team-1',
        success: false,
        version: 0,
        serverTimestamp: DateTime.utc(2026, 3, 17),
        errorMessage: 'Permission denied',
      );
      expect(response.success, false);
      expect(response.errorMessage, 'Permission denied');
    });

    test('response shareId format', () {
      final response = ShareResponse(
        shareId: 'workflow_wf1_team-5',
        success: true,
        version: 1,
        serverTimestamp: DateTime.utc(2026),
      );
      expect(response.shareId, contains('workflow'));
      expect(response.shareId, contains('team-5'));
    });
  });

  group('ShareRequest', () {
    test('constructs with all fields', () {
      const request = ShareRequest(
        entityType: 'note',
        entityId: 'n1',
        teamId: 'team-1',
        shareWithAll: true,
        memberIds: [],
        permission: SharePermission.write,
        entityData: {'title': 'Test', 'content': 'Body'},
        contentHash: 'abc123',
      );
      expect(request.entityType, 'note');
      expect(request.entityId, 'n1');
      expect(request.teamId, 'team-1');
      expect(request.shareWithAll, true);
      expect(request.memberIds, isEmpty);
      expect(request.permission, SharePermission.write);
      expect(request.entityData['title'], 'Test');
      expect(request.contentHash, 'abc123');
    });

    test('serializes to JSON', () {
      const request = ShareRequest(
        entityType: 'skill',
        entityId: 's1',
        teamId: 'team-2',
        shareWithAll: false,
        memberIds: ['u1', 'u2'],
        permission: SharePermission.read,
        entityData: {'name': 'test-skill'},
        contentHash: 'def456',
      );
      final json = request.toJson();
      expect(json['entity_type'], 'skill');
      expect(json['entity_id'], 's1');
      expect(json['team_id'], 'team-2');
      expect(json['share_with_all'], false);
      expect(json['member_ids'], ['u1', 'u2']);
      expect(json['permission'], 'read');
      expect(json['content_hash'], 'def456');
    });
  });

  group('Entity data construction', () {
    test('note entity data', () {
      final entityData = <String, dynamic>{
        'title': 'Meeting Notes',
        'content': '## Agenda\n- Review sync feature',
      };
      expect(entityData, isA<Map<String, dynamic>>());
      expect(entityData['title'], isNotEmpty);
      expect(entityData['content'], contains('Agenda'));
    });

    test('skill entity data', () {
      final entityData = <String, dynamic>{
        'name': 'deploy',
        'command': '/deploy',
        'source': '.claude/skills/deploy/',
      };
      expect(entityData['name'], 'deploy');
      expect(entityData['command'], startsWith('/'));
      expect(entityData['source'], contains('skills'));
    });

    test('project entity data', () {
      final entityData = <String, dynamic>{
        'id': 'proj-1',
        'name': 'Orchestra',
        'description': 'AI project management',
        'mode': 'active',
      };
      expect(entityData['id'], isNotEmpty);
      expect(entityData['mode'], 'active');
    });

    test('workflow entity data from Map.from', () {
      final raw = <String, dynamic>{
        'name': 'default',
        'states': <String, dynamic>{
          'todo': <String, dynamic>{},
          'done': <String, dynamic>{},
        },
        'transitions': <Map<String, dynamic>>[
          <String, dynamic>{'from': 'todo', 'to': 'done'},
        ],
        'gates': <String, dynamic>{'gate1': <String, dynamic>{}},
        'initial_state': 'todo',
        'is_default': true,
      };
      final entityData = Map<String, dynamic>.from(raw);
      expect(entityData['name'], 'default');
      expect(entityData['states'], isA<Map<String, dynamic>>());
      expect((entityData['transitions'] as List).length, 1);
      expect(entityData['is_default'], true);
    });

    test('doc entity data from Map.from', () {
      final raw = <String, dynamic>{
        'title': 'API Reference',
        'path': 'docs/api-reference.md',
        'content': '# API Reference\n...',
        'updated_at': '2026-03-17',
      };
      final entityData = Map<String, dynamic>.from(raw);
      expect(entityData['title'], 'API Reference');
      expect(entityData['path'], contains('.md'));
    });

    test('agent entity data from Map.from', () {
      final raw = <String, dynamic>{
        'name': 'devops',
        'description': 'DevOps engineer agent',
      };
      final entityData = Map<String, dynamic>.from(raw);
      expect(entityData['name'], 'devops');
      expect(entityData['description'], isNotEmpty);
    });
  });

  group('PushSyncResult edge cases', () {
    test('success with null shareResponse', () {
      const result = PushSyncResult(success: true);
      expect(result.success, true);
      expect(result.shareResponse, isNull);
      expect(result.errorMessage, isNull);
    });

    test('failure with empty error message', () {
      const result = PushSyncResult(success: false, errorMessage: '');
      expect(result.success, false);
      expect(result.errorMessage, isEmpty);
    });
  });

  group('Permission mapping', () {
    test('all permission values are accessible', () {
      expect(SharePermission.values, hasLength(3));
      expect(SharePermission.read.name, 'read');
      expect(SharePermission.write.name, 'write');
      expect(SharePermission.admin.name, 'admin');
    });

    test('permission equality', () {
      const p1 = SharePermission.write;
      const p2 = SharePermission.write;
      expect(p1, equals(p2));
      expect(p1, isNot(equals(SharePermission.read)));
    });
  });
}
