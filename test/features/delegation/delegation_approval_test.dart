import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:orchestra/features/delegation/delegation_notification_service.dart';

void main() {
  group('DelegationEvent', () {
    test('fromJson parses all fields correctly', () {
      final event = DelegationEvent.fromJson({
        'id': 'DEL-ABC',
        'delegation_type': 'created',
        'feature_id': 'FEAT-123',
        'feature_title': 'Add login',
        'from_user': 'Alice',
        'to_user': 'Bob',
        'message': 'Please review',
        'timestamp': '2026-03-20T10:00:00Z',
      });

      expect(event.id, 'DEL-ABC');
      expect(event.type, DelegationEventType.created);
      expect(event.featureId, 'FEAT-123');
      expect(event.featureTitle, 'Add login');
      expect(event.fromUser, 'Alice');
      expect(event.toUser, 'Bob');
      expect(event.message, 'Please review');
      expect(event.timestamp, DateTime.utc(2026, 3, 20, 10));
    });

    test('fromJson defaults missing fields', () {
      final event = DelegationEvent.fromJson({});

      expect(event.id, '');
      expect(event.type, DelegationEventType.created);
      expect(event.featureId, '');
      expect(event.featureTitle, '');
      expect(event.fromUser, '');
      expect(event.toUser, '');
      expect(event.message, '');
    });

    test('fromJson parses all event types', () {
      for (final t in DelegationEventType.values) {
        final event = DelegationEvent.fromJson({'delegation_type': t.name});
        expect(event.type, t);
      }
    });

    test('fromJson defaults unknown type to created', () {
      final event = DelegationEvent.fromJson({
        'delegation_type': 'unknown_type',
      });
      expect(event.type, DelegationEventType.created);
    });

    test('actionText describes created delegation', () {
      final event = DelegationEvent.fromJson({
        'delegation_type': 'created',
        'from_user': 'Alice',
        'feature_title': 'Add login',
      });
      expect(event.actionText, contains('Alice'));
      expect(event.actionText, contains('Add login'));
    });

    test('actionText describes accepted delegation', () {
      final event = DelegationEvent.fromJson({
        'delegation_type': 'accepted',
        'to_user': 'Bob',
        'feature_title': 'Fix bug',
      });
      expect(event.actionText, contains('Bob'));
      expect(event.actionText, contains('accepted'));
    });

    test('actionText describes rejected delegation', () {
      final event = DelegationEvent.fromJson({
        'delegation_type': 'rejected',
        'to_user': 'Charlie',
        'feature_title': 'Refactor',
      });
      expect(event.actionText, contains('Charlie'));
      expect(event.actionText, contains('declined'));
    });

    test('each event type has a distinct icon', () {
      final icons = <dynamic>{};
      for (final t in DelegationEventType.values) {
        final event = DelegationEvent.fromJson({'delegation_type': t.name});
        icons.add(event.icon);
      }
      // All 5 types should have distinct icons
      expect(icons.length, DelegationEventType.values.length);
    });

    test('each event type has a color', () {
      for (final t in DelegationEventType.values) {
        final event = DelegationEvent.fromJson({'delegation_type': t.name});
        expect(event.color, isNotNull);
      }
    });
  });

  group('Endpoints', () {
    test('delegationRespond builds correct URL', () {
      expect(
        Endpoints.delegationRespond('DEL-ABC'),
        '/api/delegations/DEL-ABC/respond',
      );
    });

    test('delegation builds correct URL', () {
      expect(
        Endpoints.delegation('DEL-XYZ'),
        '/api/delegations/DEL-XYZ',
      );
    });
  });

  group('Routes', () {
    test('delegation route contains id', () {
      expect(Routes.delegation('DEL-ABC'), '/library/delegations/DEL-ABC');
    });

    test('delegations list route', () {
      expect(Routes.delegations, '/library/delegations');
    });
  });

  group('McpNotificationEvent delegation detection', () {
    test('delegation notification has entity_type delegation', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'delegation',
        'entity_id': 'DEL-123',
        'session_id': 'sess-abc',
        'timestamp': 1710000000,
      });
      expect(e, isA<McpNotificationEvent>());
      final n = e as McpNotificationEvent;
      expect(n.entityType, 'delegation');
      expect(n.entityId, 'DEL-123');
    });

    test('non-delegation notification has different entity_type', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'permission',
        'entity_id': 'perm-456',
        'session_id': 'sess-def',
        'timestamp': 1710000001,
      });
      expect(e, isA<McpNotificationEvent>());
      final n = e as McpNotificationEvent;
      expect(n.entityType, isNot('delegation'));
    });
  });
}
