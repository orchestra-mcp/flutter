import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/ws/ws_event.dart';

void main() {
  group('SyncEntityUpdatedEvent', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'type': 'sync.entity_updated',
        'entity_type': 'note',
        'entity_id': 'n1',
        'entity_title': 'Meeting Notes',
        'author_id': 'u42',
        'author_name': 'Alice',
        'team_id': 'team-1',
        'version': 3,
      };
      final event = SyncEntityUpdatedEvent.fromJson(json);
      expect(event.entityType, 'note');
      expect(event.entityId, 'n1');
      expect(event.entityTitle, 'Meeting Notes');
      expect(event.authorId, 'u42');
      expect(event.authorName, 'Alice');
      expect(event.teamId, 'team-1');
      expect(event.version, 3);
    });

    test('fromJson defaults missing fields', () {
      final event =
          SyncEntityUpdatedEvent.fromJson(<String, dynamic>{'type': 'sync.entity_updated'});
      expect(event.entityType, '');
      expect(event.entityId, '');
      expect(event.entityTitle, '');
      expect(event.authorId, '');
      expect(event.authorName, '');
      expect(event.teamId, '');
      expect(event.version, 0);
    });

    test('WsEvent.fromJson dispatches correctly', () {
      final json = <String, dynamic>{
        'type': 'sync.entity_updated',
        'entity_type': 'skill',
        'entity_id': 's1',
        'entity_title': 'Deploy',
        'author_id': 'u1',
        'author_name': 'Bob',
        'team_id': 'team-2',
        'version': 5,
      };
      final event = WsEvent.fromJson(json);
      expect(event, isA<SyncEntityUpdatedEvent>());
      final updated = event as SyncEntityUpdatedEvent;
      expect(updated.entityType, 'skill');
      expect(updated.version, 5);
    });
  });

  group('SyncEntitySharedEvent', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'type': 'sync.entity_shared',
        'entity_type': 'project',
        'entity_id': 'p1',
        'entity_title': 'Orchestra',
        'author_id': 'u10',
        'author_name': 'Carol',
        'team_id': 'team-3',
        'permission': 'write',
      };
      final event = SyncEntitySharedEvent.fromJson(json);
      expect(event.entityType, 'project');
      expect(event.entityId, 'p1');
      expect(event.entityTitle, 'Orchestra');
      expect(event.authorId, 'u10');
      expect(event.authorName, 'Carol');
      expect(event.teamId, 'team-3');
      expect(event.permission, 'write');
    });

    test('fromJson defaults missing fields', () {
      final event =
          SyncEntitySharedEvent.fromJson(<String, dynamic>{'type': 'sync.entity_shared'});
      expect(event.entityType, '');
      expect(event.entityId, '');
      expect(event.permission, 'read');
    });

    test('WsEvent.fromJson dispatches correctly', () {
      final json = <String, dynamic>{
        'type': 'sync.entity_shared',
        'entity_type': 'doc',
        'entity_id': 'd1',
        'entity_title': 'API Ref',
        'author_id': 'u5',
        'author_name': 'Dave',
        'team_id': 'team-1',
        'permission': 'admin',
      };
      final event = WsEvent.fromJson(json);
      expect(event, isA<SyncEntitySharedEvent>());
      final shared = event as SyncEntitySharedEvent;
      expect(shared.permission, 'admin');
    });
  });

  group('SyncEntityDeletedEvent', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'type': 'sync.entity_deleted',
        'entity_type': 'workflow',
        'entity_id': 'w1',
        'author_id': 'u7',
        'author_name': 'Eve',
        'team_id': 'team-2',
      };
      final event = SyncEntityDeletedEvent.fromJson(json);
      expect(event.entityType, 'workflow');
      expect(event.entityId, 'w1');
      expect(event.authorId, 'u7');
      expect(event.authorName, 'Eve');
      expect(event.teamId, 'team-2');
    });

    test('fromJson defaults missing fields', () {
      final event =
          SyncEntityDeletedEvent.fromJson(<String, dynamic>{'type': 'sync.entity_deleted'});
      expect(event.entityType, '');
      expect(event.entityId, '');
      expect(event.authorId, '');
      expect(event.authorName, '');
      expect(event.teamId, '');
    });

    test('WsEvent.fromJson dispatches correctly', () {
      final json = <String, dynamic>{
        'type': 'sync.entity_deleted',
        'entity_type': 'agent',
        'entity_id': 'a1',
        'author_id': 'u3',
        'author_name': 'Frank',
        'team_id': 'team-4',
      };
      final event = WsEvent.fromJson(json);
      expect(event, isA<SyncEntityDeletedEvent>());
      final deleted = event as SyncEntityDeletedEvent;
      expect(deleted.entityType, 'agent');
    });
  });

  group('WsEvent dispatch for all sync types', () {
    test('unknown type falls through', () {
      final event = WsEvent.fromJson(<String, dynamic>{'type': 'sync.unknown'});
      expect(event, isA<UnknownWsEvent>());
    });

    test('existing events still work', () {
      final ping = WsEvent.fromJson(<String, dynamic>{'type': 'ping'});
      expect(ping, isA<PingEvent>());

      final ack = WsEvent.fromJson(<String, dynamic>{
        'type': 'sync.ack',
        'queue_id': 42,
      });
      expect(ack, isA<SyncAckEvent>());
      expect((ack as SyncAckEvent).queueId, 42);
    });

    test('pattern matching covers all sync events', () {
      final events = [
        WsEvent.fromJson(<String, dynamic>{
          'type': 'sync.entity_updated',
          'entity_type': 'note',
          'entity_id': 'n1',
          'entity_title': 'X',
          'author_id': 'u1',
          'author_name': 'A',
          'team_id': 't1',
          'version': 1,
        }),
        WsEvent.fromJson(<String, dynamic>{
          'type': 'sync.entity_shared',
          'entity_type': 'skill',
          'entity_id': 's1',
          'entity_title': 'Y',
          'author_id': 'u2',
          'author_name': 'B',
          'team_id': 't2',
          'permission': 'read',
        }),
        WsEvent.fromJson(<String, dynamic>{
          'type': 'sync.entity_deleted',
          'entity_type': 'doc',
          'entity_id': 'd1',
          'author_id': 'u3',
          'author_name': 'C',
          'team_id': 't3',
        }),
      ];
      expect(events[0], isA<SyncEntityUpdatedEvent>());
      expect(events[1], isA<SyncEntitySharedEvent>());
      expect(events[2], isA<SyncEntityDeletedEvent>());
    });
  });

  group('SyncEntityUpdatedEvent fields', () {
    test('stores constructor values', () {
      const event = SyncEntityUpdatedEvent(
        entityType: 'note',
        entityId: 'n99',
        entityTitle: 'Test',
        authorId: 'u1',
        authorName: 'Tester',
        teamId: 'team-x',
        version: 10,
      );
      expect(event.entityType, 'note');
      expect(event.entityId, 'n99');
      expect(event.entityTitle, 'Test');
      expect(event.authorId, 'u1');
      expect(event.authorName, 'Tester');
      expect(event.teamId, 'team-x');
      expect(event.version, 10);
    });
  });

  group('SyncEntitySharedEvent fields', () {
    test('stores constructor values', () {
      const event = SyncEntitySharedEvent(
        entityType: 'project',
        entityId: 'p5',
        entityTitle: 'Big Project',
        authorId: 'u2',
        authorName: 'Owner',
        teamId: 'team-y',
        permission: 'admin',
      );
      expect(event.entityType, 'project');
      expect(event.entityId, 'p5');
      expect(event.permission, 'admin');
    });
  });

  group('SyncEntityDeletedEvent fields', () {
    test('stores constructor values', () {
      const event = SyncEntityDeletedEvent(
        entityType: 'agent',
        entityId: 'a3',
        authorId: 'u9',
        authorName: 'Remover',
        teamId: 'team-z',
      );
      expect(event.entityType, 'agent');
      expect(event.entityId, 'a3');
      expect(event.authorId, 'u9');
      expect(event.teamId, 'team-z');
    });
  });
}
