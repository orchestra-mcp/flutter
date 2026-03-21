import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/web/activity/activity_feed_provider.dart';
import 'package:orchestra/screens/web/activity/activity_models.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

ActivityItem _item({
  required String id,
  required ActivityType actionType,
  required String userName,
  DateTime? timestamp,
}) => ActivityItem(
  id: id,
  userId: 'u1',
  userName: userName,
  userAvatar: 'XX',
  actionType: actionType,
  entityType: 'feature',
  entityId: 'FEAT-001',
  entityTitle: 'Test feature',
  description: 'desc',
  timestamp: timestamp ?? DateTime.now(),
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ActivityFeedState', () {
    test('default newCount is 0', () {
      const state = ActivityFeedState(items: []);
      expect(state.newCount, 0);
    });

    test('default isConnected is false', () {
      const state = ActivityFeedState(items: []);
      expect(state.isConnected, false);
    });

    test('copyWith updates newCount', () {
      const state = ActivityFeedState(items: [], newCount: 2);
      final updated = state.copyWith(newCount: 5);
      expect(updated.newCount, 5);
    });

    test('copyWith updates isConnected', () {
      const state = ActivityFeedState(items: []);
      final updated = state.copyWith(isConnected: true);
      expect(updated.isConnected, true);
    });

    test('copyWith preserves unchanged fields', () {
      final item = _item(id: 'a1', actionType: ActivityType.featureCreated, userName: 'Alice');
      final state = ActivityFeedState(items: [item], newCount: 3, isConnected: true);
      final updated = state.copyWith(newCount: 0);
      expect(updated.items, [item]);
      expect(updated.isConnected, true);
    });
  });

  group('groupForItem', () {
    test('item from today → ActivityTimeGroup.today', () {
      final item = _item(
        id: 'a1',
        actionType: ActivityType.featureCreated,
        userName: 'Alice',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(groupForItem(item), ActivityTimeGroup.today);
    });

    test('item from yesterday → ActivityTimeGroup.yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10);
      final item = _item(
        id: 'a2',
        actionType: ActivityType.noteCreated,
        userName: 'Bob',
        timestamp: yesterday,
      );
      expect(groupForItem(item), ActivityTimeGroup.yesterday);
    });

    test('item from 3 days ago → ActivityTimeGroup.earlier', () {
      final item = _item(
        id: 'a3',
        actionType: ActivityType.delegationCreated,
        userName: 'Carol',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(groupForItem(item), ActivityTimeGroup.earlier);
    });
  });

  group('groupActivities', () {
    test('empty list → empty result', () {
      expect(groupActivities([]), isEmpty);
    });

    test('all today → single group', () {
      final items = [
        _item(id: 'a1', actionType: ActivityType.featureCreated, userName: 'A'),
        _item(id: 'a2', actionType: ActivityType.noteCreated, userName: 'B'),
      ];
      final groups = groupActivities(items);
      expect(groups.length, 1);
      expect(groups.first.$1, ActivityTimeGroup.today);
      expect(groups.first.$2.length, 2);
    });

    test('mixed dates → groups in order: today, yesterday, earlier', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10);
      final old = DateTime.now().subtract(const Duration(days: 5));

      final items = [
        _item(id: 't1', actionType: ActivityType.featureCreated, userName: 'A', timestamp: now),
        _item(id: 'y1', actionType: ActivityType.noteCreated, userName: 'B', timestamp: yesterday),
        _item(id: 'e1', actionType: ActivityType.delegationCreated, userName: 'C', timestamp: old),
      ];
      final groups = groupActivities(items);
      expect(groups.length, 3);
      expect(groups[0].$1, ActivityTimeGroup.today);
      expect(groups[1].$1, ActivityTimeGroup.yesterday);
      expect(groups[2].$1, ActivityTimeGroup.earlier);
    });

    test('items placed in correct group', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10);

      final todayItem = _item(id: 't1', actionType: ActivityType.featureCreated, userName: 'A', timestamp: now);
      final yestItem = _item(id: 'y1', actionType: ActivityType.noteCreated, userName: 'B', timestamp: yesterday);

      final groups = groupActivities([todayItem, yestItem]);
      final todayGroup = groups.firstWhere((g) => g.$1 == ActivityTimeGroup.today);
      final yestGroup = groups.firstWhere((g) => g.$1 == ActivityTimeGroup.yesterday);

      expect(todayGroup.$2, contains(todayItem));
      expect(yestGroup.$2, contains(yestItem));
    });

    test('only earlier items → single earlier group', () {
      final old = DateTime.now().subtract(const Duration(days: 7));
      final items = [
        _item(id: 'e1', actionType: ActivityType.reviewSubmitted, userName: 'A', timestamp: old),
      ];
      final groups = groupActivities(items);
      expect(groups.length, 1);
      expect(groups.first.$1, ActivityTimeGroup.earlier);
    });
  });

  group('ActivityFeedScreen instantiation', () {
    test('ActivityFeedState can be constructed', () {
      expect(
        () => const ActivityFeedState(items: [], newCount: 0, isConnected: false),
        returnsNormally,
      );
    });
  });
}
