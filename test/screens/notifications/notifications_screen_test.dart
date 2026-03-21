import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/notifications/notification_store.dart';

void main() {
  group('AppNotification', () {
    test('isRead defaults to false', () {
      final item = AppNotification(
        id: '1',
        type: 'mention',
        title: 'Test',
        body: 'Body',
        timestamp: DateTime(2026, 3, 16),
      );
      expect(item.isRead, isFalse);
    });

    test('fields are stored correctly', () {
      final ts = DateTime(2026, 3, 16, 9, 0);
      final item = AppNotification(
        id: 'abc',
        type: 'featureUpdate',
        title: 'Hello',
        body: 'World',
        timestamp: ts,
        isRead: true,
      );
      expect(item.id, 'abc');
      expect(item.title, 'Hello');
      expect(item.isRead, isTrue);
      expect(item.timestamp, ts);
    });
  });
}
