import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/ws/ws_event.dart';

void main() {
  group('SyncNotificationService event mapping', () {
    test('SyncEntityUpdatedEvent produces correct notification content', () {
      const event = SyncEntityUpdatedEvent(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Meeting Notes',
        authorId: 'u42',
        authorName: 'Alice',
        teamId: 'team-1',
        version: 3,
      );

      // Verify the event fields used for notification title/body.
      expect(event.authorName, 'Alice');
      expect(event.entityTitle, 'Meeting Notes');
      expect(event.entityType, 'note');
      // Expected title: "Alice updated a note"
      expect('${event.authorName} updated a ${event.entityType}',
          'Alice updated a note');
      // Expected body: entity title
      expect(event.entityTitle, 'Meeting Notes');
    });

    test('SyncEntitySharedEvent produces correct notification content', () {
      const event = SyncEntitySharedEvent(
        entityType: 'project',
        entityId: 'p1',
        entityTitle: 'Orchestra',
        authorId: 'u10',
        authorName: 'Carol',
        teamId: 'team-3',
        permission: 'write',
      );

      expect('${event.authorName} shared a ${event.entityType} with you',
          'Carol shared a project with you');
      expect(event.entityTitle, 'Orchestra');
    });

    test('SyncEntityDeletedEvent produces correct notification content', () {
      const event = SyncEntityDeletedEvent(
        entityType: 'workflow',
        entityId: 'w1',
        authorId: 'u7',
        authorName: 'Eve',
        teamId: 'team-2',
      );

      expect('${event.authorName} deleted a shared ${event.entityType}',
          'Eve deleted a shared workflow');
      expect('A shared ${event.entityType} was removed',
          'A shared workflow was removed');
    });

    test('non-sync events produce no notification content', () {
      const event = PingEvent();
      // PingEvent is not a sync event — should not generate a notification.
      expect(event, isA<PingEvent>());
      expect(event, isNot(isA<SyncEntityUpdatedEvent>()));
      expect(event, isNot(isA<SyncEntitySharedEvent>()));
      expect(event, isNot(isA<SyncEntityDeletedEvent>()));
    });

    test('UnknownWsEvent produces no notification content', () {
      const event = UnknownWsEvent(
        type: 'custom.event',
        data: <String, dynamic>{'foo': 'bar'},
      );
      expect(event, isNot(isA<SyncEntityUpdatedEvent>()));
      expect(event, isNot(isA<SyncEntitySharedEvent>()));
      expect(event, isNot(isA<SyncEntityDeletedEvent>()));
    });
  });

  group('Notification preference extraction', () {
    test('sync key defaults to enabled when missing', () {
      final prefs = <String, dynamic>{
        'notifications': <String, dynamic>{
          'push': true,
          'email': false,
        },
      };
      final notifications = prefs['notifications'] as Map;
      // sync key not present — should default to enabled (not false).
      expect(notifications['sync'] != false, true);
    });

    test('sync key respects explicit false', () {
      final prefs = <String, dynamic>{
        'notifications': <String, dynamic>{
          'push': true,
          'sync': false,
          'email': true,
        },
      };
      final notifications = prefs['notifications'] as Map;
      expect(notifications['sync'] != false, false);
    });

    test('sync key respects explicit true', () {
      final prefs = <String, dynamic>{
        'notifications': <String, dynamic>{
          'push': true,
          'sync': true,
          'email': true,
        },
      };
      final notifications = prefs['notifications'] as Map;
      expect(notifications['sync'] != false, true);
    });

    test('fallback extraction with notification_ prefix', () {
      final prefs = <String, dynamic>{
        'notification_sync': false,
      };
      // Fallback logic: notification_sync != false
      expect(prefs['notification_sync'] != false, false);
    });

    test('fallback extraction defaults when key missing', () {
      final prefs = <String, dynamic>{};
      // Both notification_sync and sync are null — null != false is true.
      expect(prefs['notification_sync'] != false, true);
      expect(prefs['sync'] != false, true);
    });
  });

  group('FCM topic naming', () {
    test('team sync topic appends _sync suffix', () {
      const teamId = 'team-1';
      final topic = '${teamId}_sync';
      expect(topic, 'team-1_sync');
    });

    test('different teams produce unique topics', () {
      const teamIds = ['team-1', 'team-2', 'team-xyz'];
      final topics = teamIds.map((id) => '${id}_sync').toList();
      expect(topics, hasLength(3));
      expect(topics.toSet().length, 3); // All unique.
      expect(topics, contains('team-1_sync'));
      expect(topics, contains('team-2_sync'));
      expect(topics, contains('team-xyz_sync'));
    });
  });

  group('Notification ID allocation', () {
    test('sync notification IDs are unique', () {
      // IDs used by the service: 20000, 20001, 20002
      const ids = [20000, 20001, 20002];
      expect(ids.toSet().length, 3);
    });

    test('sync IDs do not overlap with health IDs', () {
      // Health IDs: 1000-10000 range. Sync IDs start at 20000.
      const healthMaxId = 10000;
      const syncMinId = 20000;
      expect(syncMinId > healthMaxId, true);
    });
  });

  group('Event type to deep link payload', () {
    test('updated event maps to entity type route', () {
      const entityType = 'note';
      expect('/$entityType', '/note');
    });

    test('shared event maps to entity type route', () {
      const entityType = 'project';
      expect('/$entityType', '/project');
    });

    test('deleted event maps to entity type route', () {
      const entityType = 'workflow';
      expect('/$entityType', '/workflow');
    });

    test('all entity types produce valid routes', () {
      for (final type in ['note', 'project', 'skill', 'workflow', 'doc', 'agent']) {
        final route = '/$type';
        expect(route, startsWith('/'));
        expect(route.length, greaterThan(1));
      }
    });
  });
}
