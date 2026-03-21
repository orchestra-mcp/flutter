import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/notifications/notification_store.dart';

void main() {
  // ---------------------------------------------------------------------------
  // AppNotification model
  // ---------------------------------------------------------------------------

  group('AppNotification', () {
    test('default isRead is false', () {
      final n = AppNotification(
        id: '1',
        type: 'feature_update',
        title: 'title',
        body: 'body',
        timestamp: DateTime(2026, 3, 21),
      );
      expect(n.isRead, isFalse);
    });

    test('copyWith updates isRead', () {
      final n = AppNotification(
        id: '1',
        type: 'feature_update',
        title: 'title',
        body: 'body',
        timestamp: DateTime(2026, 3, 21),
      );
      final updated = n.copyWith(isRead: true);
      expect(updated.isRead, isTrue);
      expect(updated.id, equals('1'));
    });

    test('copyWith without args preserves isRead', () {
      final n = AppNotification(
        id: '2',
        type: 'sync',
        title: 'Sync',
        body: '5',
        timestamp: DateTime(2026, 3, 21),
        isRead: true,
      );
      expect(n.copyWith().isRead, isTrue);
    });

    test('toJson serializes correctly', () {
      final ts = DateTime(2026, 3, 21, 10, 0, 0);
      final n = AppNotification(
        id: 'abc',
        type: 'health_alert',
        title: 'Alert',
        body: 'Low water',
        timestamp: ts,
        isRead: true,
      );
      final json = n.toJson();
      expect(json['id'], equals('abc'));
      expect(json['type'], equals('health_alert'));
      expect(json['title'], equals('Alert'));
      expect(json['body'], equals('Low water'));
      expect(json['isRead'], isTrue);
      expect(json['timestamp'], equals(ts.toIso8601String()));
    });

    test('fromJson deserializes correctly', () {
      final ts = DateTime(2026, 3, 21, 10, 0, 0);
      final json = {
        'id': 'xyz',
        'type': 'smart_action',
        'title': 'Done',
        'body': 'Note created',
        'timestamp': ts.toIso8601String(),
        'isRead': false,
      };
      final n = AppNotification.fromJson(json);
      expect(n.id, equals('xyz'));
      expect(n.type, equals('smart_action'));
      expect(n.isRead, isFalse);
      expect(n.timestamp.year, equals(2026));
    });

    test('fromJson uses fallback defaults for missing fields', () {
      final n = AppNotification.fromJson({'id': 'fallback'});
      expect(n.type, equals('general'));
      expect(n.title, equals(''));
      expect(n.body, equals(''));
      expect(n.isRead, isFalse);
    });

    test('fromJson handles invalid timestamp gracefully', () {
      final n = AppNotification.fromJson({
        'id': 'bad-ts',
        'timestamp': 'not-a-date',
      });
      // Should not throw; timestamp falls back to DateTime.now()
      expect(n.timestamp, isA<DateTime>());
    });
  });

  // ---------------------------------------------------------------------------
  // _titleKey data pattern
  // ---------------------------------------------------------------------------

  group('_titleKey resolution pattern', () {
    test('notification with _titleKey stored in data map', () {
      final n = AppNotification(
        id: '10',
        type: 'feature_update',
        title: 'notifFeatureComplete',
        body: 'My Feature → done',
        timestamp: DateTime(2026, 3, 21),
        data: const {'_titleKey': 'notifFeatureComplete', 'title': 'My Feature'},
      );
      expect(n.data['_titleKey'], equals('notifFeatureComplete'));
    });

    test('sync notification stores _bodyCount in data', () {
      final n = AppNotification(
        id: '11',
        type: 'sync',
        title: 'notifSyncComplete',
        body: '3',
        timestamp: DateTime(2026, 3, 21),
        data: const {
          '_titleKey': 'notifSyncComplete',
          '_bodyCount': 3,
        },
      );
      expect(n.data['_bodyCount'], equals(3));
    });

    test('note notification stores _bodyNoteTitle in data', () {
      final n = AppNotification(
        id: '12',
        type: 'smart_action',
        title: 'notifNoteGenerated',
        body: 'Meeting notes',
        timestamp: DateTime(2026, 3, 21),
        data: const {
          '_titleKey': 'notifNoteGenerated',
          '_bodyNoteTitle': 'Meeting notes',
        },
      );
      expect(n.data['_bodyNoteTitle'], equals('Meeting notes'));
    });

    test('entity deleted notification stores entity_type and entity_id', () {
      final n = AppNotification(
        id: '13',
        type: 'sync',
        title: 'notifEntityDeleted',
        body: 'feature FEAT-ABC',
        timestamp: DateTime(2026, 3, 21),
        data: const {
          '_titleKey': 'notifEntityDeleted',
          'entity_type': 'feature',
          'entity_id': 'FEAT-ABC',
          'action': 'delete',
        },
      );
      expect(n.data['entity_type'], equals('feature'));
      expect(n.data['entity_id'], equals('FEAT-ABC'));
    });

    test('agent finished notification has empty body fallback path', () {
      final n = AppNotification(
        id: '14',
        type: 'agent_event',
        title: 'notifAgentFinished',
        body: '',
        timestamp: DateTime(2026, 3, 21),
        data: const {'_titleKey': 'notifAgentFinished'},
      );
      // body is empty → display code uses notifAgentSessionCompleted fallback
      expect(n.body.isEmpty, isTrue);
    });

    test('unknown _titleKey falls back to item.title', () {
      final n = AppNotification(
        id: '15',
        type: 'general',
        title: 'Raw title from server',
        body: 'Some body',
        timestamp: DateTime(2026, 3, 21),
      );
      // No _titleKey in data → title is used as-is
      expect(n.data['_titleKey'], isNull);
      expect(n.title, equals('Raw title from server'));
    });
  });
}
