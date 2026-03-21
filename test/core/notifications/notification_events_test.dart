import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/notifications/notification_store.dart';
import 'package:orchestra/core/ws/ws_event.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SyncBroadcastEvent
  // ---------------------------------------------------------------------------

  group('SyncBroadcastEvent', () {
    test('parses from JSON correctly', () {
      final json = {
        'type': 'sync',
        'entity_type': 'note',
        'entity_id': 'abc-123',
        'action': 'upsert',
        'user_id': 42,
        'timestamp': 1710900000000,
      };

      final event = WsEvent.fromJson(json);
      expect(event, isA<SyncBroadcastEvent>());

      final sync = event as SyncBroadcastEvent;
      expect(sync.entityType, equals('note'));
      expect(sync.entityId, equals('abc-123'));
      expect(sync.action, equals('upsert'));
      expect(sync.userId, equals(42));
      expect(sync.timestamp, equals(1710900000000));
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{'type': 'sync'};
      final event = WsEvent.fromJson(json) as SyncBroadcastEvent;
      expect(event.entityType, equals(''));
      expect(event.entityId, equals(''));
      expect(event.action, equals(''));
      expect(event.userId, equals(0));
      expect(event.timestamp, equals(0));
    });

    test('parses delete action', () {
      final json = {
        'type': 'sync',
        'entity_type': 'feature',
        'entity_id': 'FEAT-123',
        'action': 'delete',
        'user_id': 1,
        'timestamp': 1710900000,
      };
      final event = WsEvent.fromJson(json) as SyncBroadcastEvent;
      expect(event.action, equals('delete'));
      expect(event.entityType, equals('feature'));
      expect(event.entityId, equals('FEAT-123'));
    });

    test('preserves all entity types', () {
      for (final entityType in [
        'note',
        'feature',
        'agent',
        'workflow',
        'doc',
        'plan',
      ]) {
        final json = {
          'type': 'sync',
          'entity_type': entityType,
          'entity_id': 'id-1',
          'action': 'upsert',
          'user_id': 1,
          'timestamp': 0,
        };
        final event = WsEvent.fromJson(json) as SyncBroadcastEvent;
        expect(event.entityType, equals(entityType));
      }
    });

    test('is a WsEvent subclass', () {
      final json = {
        'type': 'sync',
        'entity_type': 'note',
        'entity_id': 'x',
        'action': 'upsert',
        'user_id': 1,
        'timestamp': 0,
      };
      final event = WsEvent.fromJson(json);
      expect(event, isA<WsEvent>());
      expect(event, isA<SyncBroadcastEvent>());
    });
  });

  // ---------------------------------------------------------------------------
  // PresenceEvent
  // ---------------------------------------------------------------------------

  group('PresenceEvent', () {
    test('parses online event', () {
      final json = {
        'type': 'presence',
        'user_id': 5,
        'action': 'online',
        'timestamp': 1710900000,
      };
      final event = WsEvent.fromJson(json);
      expect(event, isA<PresenceEvent>());

      final presence = event as PresenceEvent;
      expect(presence.userId, equals(5));
      expect(presence.action, equals('online'));
      expect(presence.timestamp, equals(1710900000));
    });

    test('parses offline event', () {
      final json = {
        'type': 'presence',
        'user_id': 3,
        'action': 'offline',
        'timestamp': 1710900000,
      };
      final event = WsEvent.fromJson(json) as PresenceEvent;
      expect(event.action, equals('offline'));
      expect(event.userId, equals(3));
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{'type': 'presence'};
      final event = WsEvent.fromJson(json) as PresenceEvent;
      expect(event.userId, equals(0));
      expect(event.action, equals(''));
      expect(event.timestamp, equals(0));
    });

    test('is a WsEvent subclass', () {
      final json = {
        'type': 'presence',
        'user_id': 1,
        'action': 'online',
        'timestamp': 0,
      };
      final event = WsEvent.fromJson(json);
      expect(event, isA<WsEvent>());
      expect(event, isA<PresenceEvent>());
    });
  });

  // ---------------------------------------------------------------------------
  // WsEvent.fromJson routing
  // ---------------------------------------------------------------------------

  group('WsEvent.fromJson routing', () {
    test('routes sync type to SyncBroadcastEvent', () {
      expect(WsEvent.fromJson({'type': 'sync'}), isA<SyncBroadcastEvent>());
    });

    test('routes presence type to PresenceEvent', () {
      expect(WsEvent.fromJson({'type': 'presence'}), isA<PresenceEvent>());
    });

    test('routes mcp type with tool_called action to McpToolCalledEvent', () {
      expect(
        WsEvent.fromJson({'type': 'mcp', 'action': 'tool_called'}),
        isA<McpToolCalledEvent>(),
      );
    });

    test(
      'routes mcp type with agent_spawned action to McpAgentSpawnedEvent',
      () {
        expect(
          WsEvent.fromJson({'type': 'mcp', 'action': 'agent_spawned'}),
          isA<McpAgentSpawnedEvent>(),
        );
      },
    );

    test(
      'routes mcp type with notification action to McpNotificationEvent',
      () {
        expect(
          WsEvent.fromJson({'type': 'mcp', 'action': 'notification'}),
          isA<McpNotificationEvent>(),
        );
      },
    );

    test('routes ping type to PingEvent', () {
      expect(WsEvent.fromJson({'type': 'ping'}), isA<PingEvent>());
    });

    test('routes unknown type to UnknownWsEvent', () {
      final event = WsEvent.fromJson({'type': 'foobar'});
      expect(event, isA<UnknownWsEvent>());
      expect((event as UnknownWsEvent).type, equals('foobar'));
    });

    test('routes feature.updated type to FeatureUpdatedEvent', () {
      final json = {
        'type': 'feature.updated',
        'feature_id': 'F1',
        'payload': <String, dynamic>{},
      };
      expect(WsEvent.fromJson(json), isA<FeatureUpdatedEvent>());
    });

    test('routes health.updated type to HealthDataUpdatedEvent', () {
      final json = <String, dynamic>{'type': 'health.updated'};
      expect(WsEvent.fromJson(json), isA<HealthDataUpdatedEvent>());
    });

    test('routes note.created type to NoteCreatedEvent', () {
      final json = {
        'type': 'note.created',
        'note_id': 'n-1',
        'payload': <String, dynamic>{},
      };
      expect(WsEvent.fromJson(json), isA<NoteCreatedEvent>());
    });

    test('routes sync.ack type to SyncAckEvent', () {
      final json = {'type': 'sync.ack', 'queue_id': 1};
      expect(WsEvent.fromJson(json), isA<SyncAckEvent>());
    });

    test('routes sync.entity_updated type to SyncEntityUpdatedEvent', () {
      final json = <String, dynamic>{'type': 'sync.entity_updated'};
      expect(WsEvent.fromJson(json), isA<SyncEntityUpdatedEvent>());
    });

    test('routes sync.entity_shared type to SyncEntitySharedEvent', () {
      final json = <String, dynamic>{'type': 'sync.entity_shared'};
      expect(WsEvent.fromJson(json), isA<SyncEntitySharedEvent>());
    });

    test('routes sync.entity_deleted type to SyncEntityDeletedEvent', () {
      final json = <String, dynamic>{'type': 'sync.entity_deleted'};
      expect(WsEvent.fromJson(json), isA<SyncEntityDeletedEvent>());
    });

    test('missing type field routes to UnknownWsEvent with empty type', () {
      final event = WsEvent.fromJson(<String, dynamic>{'data': 'hello'});
      expect(event, isA<UnknownWsEvent>());
      expect((event as UnknownWsEvent).type, equals(''));
    });
  });

  // ---------------------------------------------------------------------------
  // AppNotification
  // ---------------------------------------------------------------------------

  group('AppNotification', () {
    test('serializes to JSON', () {
      final notif = AppNotification(
        id: '123',
        type: 'sync',
        title: 'Feature Deleted',
        body: 'feature FEAT-123 was removed',
        timestamp: DateTime(2024, 3, 20),
      );
      final json = notif.toJson();
      expect(json['id'], equals('123'));
      expect(json['type'], equals('sync'));
      expect(json['title'], equals('Feature Deleted'));
      expect(json['body'], equals('feature FEAT-123 was removed'));
      expect(json['isRead'], equals(false));
      expect(json['timestamp'], isA<String>());
    });

    test('deserializes from JSON', () {
      final json = {
        'id': '456',
        'type': 'sync',
        'title': 'Note Deleted',
        'body': 'note abc was removed',
        'timestamp': '2024-03-20T00:00:00.000',
        'isRead': true,
      };
      final notif = AppNotification.fromJson(json);
      expect(notif.id, equals('456'));
      expect(notif.type, equals('sync'));
      expect(notif.title, equals('Note Deleted'));
      expect(notif.body, equals('note abc was removed'));
      expect(notif.isRead, isTrue);
    });

    test('copyWith creates correct copy', () {
      final notif = AppNotification(
        id: '789',
        type: 'feature_update',
        title: 'Test',
        body: 'Body',
        timestamp: DateTime(2024, 1, 1),
      );
      expect(notif.isRead, isFalse);

      final read = notif.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, equals(notif.id));
      expect(read.title, equals(notif.title));
      expect(read.body, equals(notif.body));
      expect(read.type, equals(notif.type));
    });

    test('copyWith without arguments preserves all fields', () {
      final notif = AppNotification(
        id: 'x',
        type: 'health_alert',
        title: 'Alert',
        body: 'Drink water',
        timestamp: DateTime(2024, 6, 15),
        isRead: true,
      );
      final copy = notif.copyWith();
      expect(copy.id, equals(notif.id));
      expect(copy.type, equals(notif.type));
      expect(copy.title, equals(notif.title));
      expect(copy.body, equals(notif.body));
      expect(copy.isRead, equals(notif.isRead));
    });

    test('handles missing JSON fields with defaults', () {
      final json = <String, dynamic>{'id': '1'};
      final notif = AppNotification.fromJson(json);
      expect(notif.id, equals('1'));
      expect(notif.type, equals('general'));
      expect(notif.title, equals(''));
      expect(notif.body, equals(''));
      expect(notif.isRead, isFalse);
      // timestamp should be a DateTime (defaults to DateTime.now())
      expect(notif.timestamp, isA<DateTime>());
    });

    test('round-trip serialization preserves data', () {
      final original = AppNotification(
        id: 'rt-1',
        type: 'agent_event',
        title: 'Agent Finished',
        body: 'QA testing complete',
        timestamp: DateTime(2024, 3, 20, 14, 30),
      );
      final json = original.toJson();
      final restored = AppNotification.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.type, equals(original.type));
      expect(restored.title, equals(original.title));
      expect(restored.body, equals(original.body));
      expect(restored.isRead, equals(original.isRead));
    });

    test('invalid timestamp string defaults to DateTime.now()', () {
      final json = {'id': '2', 'timestamp': 'not-a-date'};
      final notif = AppNotification.fromJson(json);
      // DateTime.tryParse returns null for invalid strings, so it falls
      // back to DateTime.now(). We just verify it is a recent DateTime.
      expect(notif.timestamp, isA<DateTime>());
      final now = DateTime.now();
      expect(notif.timestamp.difference(now).inSeconds.abs(), lessThan(5));
    });

    test('toJson includes all required fields', () {
      final notif = AppNotification(
        id: 'check',
        type: 'smart_action',
        title: 'Note Generated',
        body: 'Your note is ready',
        timestamp: DateTime(2024, 1, 1),
        isRead: true,
      );
      final json = notif.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('body'), isTrue);
      expect(json.containsKey('timestamp'), isTrue);
      expect(json.containsKey('isRead'), isTrue);
    });

    test('default isRead is false', () {
      final notif = AppNotification(
        id: 'default',
        type: 'sync',
        title: 'T',
        body: 'B',
        timestamp: DateTime.now(),
      );
      expect(notif.isRead, isFalse);
    });

    test('data field defaults to empty map', () {
      final notif = AppNotification(
        id: 'd1',
        type: 'sync',
        title: 'T',
        body: 'B',
        timestamp: DateTime.now(),
      );
      expect(notif.data, equals(<String, dynamic>{}));
    });

    test('data field can be populated', () {
      final notif = AppNotification(
        id: 'd2',
        type: 'sync',
        title: 'T',
        body: 'B',
        timestamp: DateTime.now(),
        data: {'noteId': 'n-1', 'action': 'delete'},
      );
      expect(notif.data['noteId'], equals('n-1'));
      expect(notif.data['action'], equals('delete'));
    });
  });

  // ---------------------------------------------------------------------------
  // McpEvent subtypes
  // ---------------------------------------------------------------------------

  group('McpEvent subtypes', () {
    test('McpToolCalledEvent parses correctly', () {
      final json = {
        'type': 'mcp',
        'action': 'tool_called',
        'tool_name': 'Read',
        'entity_type': 'tool',
        'session_id': 'sess-1',
        'timestamp': 100,
      };
      final event = WsEvent.fromJson(json) as McpToolCalledEvent;
      expect(event.toolName, equals('Read'));
      expect(event.entityType, equals('tool'));
      expect(event.sessionId, equals('sess-1'));
      expect(event.timestamp, equals(100));
    });

    test('McpToolCalledEvent with missing optional fields', () {
      final json = {'type': 'mcp', 'action': 'tool_called'};
      final event = WsEvent.fromJson(json) as McpToolCalledEvent;
      expect(event.toolName, equals(''));
      expect(event.entityType, equals('tool')); // default value
      expect(event.sessionId, equals(''));
      expect(event.timestamp, equals(0));
    });

    test('McpAgentSpawnedEvent parses correctly', () {
      final json = {
        'type': 'mcp',
        'action': 'agent_spawned',
        'agent_type': 'qa-testing',
        'session_id': 'sess-2',
        'timestamp': 200,
      };
      final event = WsEvent.fromJson(json) as McpAgentSpawnedEvent;
      expect(event.agentType, equals('qa-testing'));
      expect(event.sessionId, equals('sess-2'));
      expect(event.timestamp, equals(200));
    });

    test('McpAgentSpawnedEvent with missing fields', () {
      final json = {'type': 'mcp', 'action': 'agent_spawned'};
      final event = WsEvent.fromJson(json) as McpAgentSpawnedEvent;
      expect(event.agentType, equals(''));
      expect(event.sessionId, equals(''));
      expect(event.timestamp, equals(0));
    });

    test('McpNotificationEvent parses correctly', () {
      final json = {
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'delegation',
        'entity_id': 'DEL-1',
        'session_id': 'sess-3',
        'timestamp': 300,
      };
      final event = WsEvent.fromJson(json) as McpNotificationEvent;
      expect(event.entityType, equals('delegation'));
      expect(event.entityId, equals('DEL-1'));
      expect(event.sessionId, equals('sess-3'));
      expect(event.timestamp, equals(300));
    });

    test('McpNotificationEvent with missing fields uses defaults', () {
      final json = {'type': 'mcp', 'action': 'notification'};
      final event = WsEvent.fromJson(json) as McpNotificationEvent;
      expect(event.entityType, equals('notification')); // default value
      expect(event.entityId, equals(''));
      expect(event.sessionId, equals(''));
      expect(event.timestamp, equals(0));
    });

    test('McpGenericEvent for unknown action', () {
      final json = {
        'type': 'mcp',
        'action': 'custom_action',
        'session_id': 'sess-4',
        'timestamp': 400,
      };
      final event = WsEvent.fromJson(json) as McpGenericEvent;
      expect(event.action, equals('custom_action'));
      expect(event.sessionId, equals('sess-4'));
      expect(event.timestamp, equals(400));
      expect(event.data, isA<Map<String, dynamic>>());
      expect(event.data['action'], equals('custom_action'));
    });

    test('McpGenericEvent for empty action string', () {
      final json = {'type': 'mcp', 'session_id': 'sess-5', 'timestamp': 500};
      final event = WsEvent.fromJson(json) as McpGenericEvent;
      expect(event.action, equals(''));
    });

    test('all McpEvent subtypes are WsEvent instances', () {
      final toolEvent = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'tool_called',
      });
      final agentEvent = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'agent_spawned',
      });
      final notifEvent = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
      });
      final genericEvent = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'unknown',
      });

      expect(toolEvent, isA<WsEvent>());
      expect(toolEvent, isA<McpEvent>());
      expect(agentEvent, isA<WsEvent>());
      expect(agentEvent, isA<McpEvent>());
      expect(notifEvent, isA<WsEvent>());
      expect(notifEvent, isA<McpEvent>());
      expect(genericEvent, isA<WsEvent>());
      expect(genericEvent, isA<McpEvent>());
    });
  });

  // ---------------------------------------------------------------------------
  // HealthDataUpdatedEvent
  // ---------------------------------------------------------------------------

  group('HealthDataUpdatedEvent', () {
    test('parses with all fields', () {
      final json = {
        'type': 'health.updated',
        'dimension': 'hydration',
        'user_id': 'usr-42',
      };
      final event = WsEvent.fromJson(json) as HealthDataUpdatedEvent;
      expect(event.dimension, equals('hydration'));
      expect(event.userId, equals('usr-42'));
    });

    test('defaults dimension to all when missing', () {
      final json = <String, dynamic>{'type': 'health.updated'};
      final event = WsEvent.fromJson(json) as HealthDataUpdatedEvent;
      expect(event.dimension, equals('all'));
      expect(event.userId, equals(''));
    });

    test('handles various dimension values', () {
      for (final dim in [
        'hydration',
        'caffeine',
        'nutrition',
        'pomodoro',
        'shutdown',
        'weight',
        'sleep',
        'all',
      ]) {
        final json = {
          'type': 'health.updated',
          'dimension': dim,
          'user_id': 'u1',
        };
        final event = WsEvent.fromJson(json) as HealthDataUpdatedEvent;
        expect(event.dimension, equals(dim));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // SyncEntityUpdatedEvent
  // ---------------------------------------------------------------------------

  group('SyncEntityUpdatedEvent', () {
    test('parses all fields', () {
      final json = {
        'type': 'sync.entity_updated',
        'entity_type': 'note',
        'entity_id': 'n-1',
        'entity_title': 'My Note',
        'author_id': 'a-1',
        'author_name': 'Alice',
        'team_id': 't-1',
        'version': 5,
      };
      final event = WsEvent.fromJson(json) as SyncEntityUpdatedEvent;
      expect(event.entityType, equals('note'));
      expect(event.entityId, equals('n-1'));
      expect(event.entityTitle, equals('My Note'));
      expect(event.authorId, equals('a-1'));
      expect(event.authorName, equals('Alice'));
      expect(event.teamId, equals('t-1'));
      expect(event.version, equals(5));
    });

    test('defaults missing fields', () {
      final json = <String, dynamic>{'type': 'sync.entity_updated'};
      final event = WsEvent.fromJson(json) as SyncEntityUpdatedEvent;
      expect(event.entityType, equals(''));
      expect(event.entityId, equals(''));
      expect(event.entityTitle, equals(''));
      expect(event.authorId, equals(''));
      expect(event.authorName, equals(''));
      expect(event.teamId, equals(''));
      expect(event.version, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // SyncEntitySharedEvent
  // ---------------------------------------------------------------------------

  group('SyncEntitySharedEvent', () {
    test('parses all fields', () {
      final json = {
        'type': 'sync.entity_shared',
        'entity_type': 'feature',
        'entity_id': 'FEAT-1',
        'entity_title': 'Dark Mode',
        'author_id': 'a-2',
        'author_name': 'Bob',
        'team_id': 't-2',
        'permission': 'write',
      };
      final event = WsEvent.fromJson(json) as SyncEntitySharedEvent;
      expect(event.entityType, equals('feature'));
      expect(event.entityId, equals('FEAT-1'));
      expect(event.entityTitle, equals('Dark Mode'));
      expect(event.authorId, equals('a-2'));
      expect(event.authorName, equals('Bob'));
      expect(event.teamId, equals('t-2'));
      expect(event.permission, equals('write'));
    });

    test('defaults permission to read when missing', () {
      final json = <String, dynamic>{'type': 'sync.entity_shared'};
      final event = WsEvent.fromJson(json) as SyncEntitySharedEvent;
      expect(event.permission, equals('read'));
    });
  });

  // ---------------------------------------------------------------------------
  // SyncEntityDeletedEvent
  // ---------------------------------------------------------------------------

  group('SyncEntityDeletedEvent', () {
    test('parses all fields', () {
      final json = {
        'type': 'sync.entity_deleted',
        'entity_type': 'workflow',
        'entity_id': 'WFL-1',
        'author_id': 'a-3',
        'author_name': 'Carol',
        'team_id': 't-3',
      };
      final event = WsEvent.fromJson(json) as SyncEntityDeletedEvent;
      expect(event.entityType, equals('workflow'));
      expect(event.entityId, equals('WFL-1'));
      expect(event.authorId, equals('a-3'));
      expect(event.authorName, equals('Carol'));
      expect(event.teamId, equals('t-3'));
    });

    test('defaults missing fields', () {
      final json = <String, dynamic>{'type': 'sync.entity_deleted'};
      final event = WsEvent.fromJson(json) as SyncEntityDeletedEvent;
      expect(event.entityType, equals(''));
      expect(event.entityId, equals(''));
      expect(event.authorId, equals(''));
      expect(event.authorName, equals(''));
      expect(event.teamId, equals(''));
    });
  });

  // ---------------------------------------------------------------------------
  // UnknownWsEvent
  // ---------------------------------------------------------------------------

  group('UnknownWsEvent', () {
    test('captures type and full data', () {
      final json = {'type': 'future.event', 'key': 'value', 'count': 42};
      final event = WsEvent.fromJson(json) as UnknownWsEvent;
      expect(event.type, equals('future.event'));
      expect(event.data['key'], equals('value'));
      expect(event.data['count'], equals(42));
    });

    test('captures empty type from missing field', () {
      final json = <String, dynamic>{'some_data': true};
      final event = WsEvent.fromJson(json) as UnknownWsEvent;
      expect(event.type, equals(''));
    });
  });
}
