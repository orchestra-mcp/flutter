import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/utils/date_utils.dart';

void main() {
  group('formatRelative', () {
    test('just now for seconds ago', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatRelative(dt), 'just now');
    });

    test('minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatRelative(dt), '5m ago');
    });

    test('hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatRelative(dt), '3h ago');
    });

    test('yesterday', () {
      final dt = DateTime.now().subtract(const Duration(days: 1));
      expect(formatRelative(dt), 'yesterday');
    });

    test('days ago for 3 days', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(formatRelative(dt), '3d ago');
    });

    test('month day for same year older dates', () {
      final now = DateTime.now();
      final dt = DateTime(now.year, 1, 5);
      final result = formatRelative(dt);
      expect(result, contains('Jan'));
    });

    test('month day year for different year', () {
      final dt = DateTime(2023, 3, 15);
      final result = formatRelative(dt);
      expect(result, contains('2023'));
    });
  });

  group('formatISO', () {
    test('returns ISO 8601 UTC string', () {
      final dt = DateTime.utc(2025, 6, 15, 12, 0, 0);
      expect(formatISO(dt), '2025-06-15T12:00:00.000Z');
    });

    test('converts local time to UTC', () {
      final dt = DateTime(2025, 1, 1, 0, 0, 0);
      final iso = formatISO(dt);
      expect(iso, endsWith('Z'));
    });
  });

  group('parseISO', () {
    test('parses valid ISO string', () {
      final result = parseISO('2025-06-15T12:00:00.000Z');
      expect(result.year, 2025);
      expect(result.month, 6);
      expect(result.day, 15);
    });

    test('returns DateTime.now() on invalid string', () {
      final before = DateTime.now();
      final result = parseISO('not-a-date');
      final after = DateTime.now();
      expect(result.isAfter(before) || result.isAtSameMomentAs(before), isTrue);
      expect(result.isBefore(after) || result.isAtSameMomentAs(after), isTrue);
    });
  });
}
