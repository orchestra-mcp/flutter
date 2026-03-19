import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/notifications/notifications_screen.dart';

void main() {
  group('NotificationItem', () {
    test('isRead defaults to false', () {
      final item = NotificationItem(
        id: '1',
        type: NotificationType.mention,
        title: 'Test',
        body: 'Body',
        timestamp: DateTime(2026, 3, 16),
      );
      expect(item.isRead, isFalse);
    });

    test('fields are stored correctly', () {
      final ts = DateTime(2026, 3, 16, 9, 0);
      final item = NotificationItem(
        id: 'abc',
        type: NotificationType.featureUpdate,
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
