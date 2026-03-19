import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/health/managers/caffeine_manager.dart';
import 'package:orchestra/features/health/managers/hydration_manager.dart';

void main() {
  // ─── HydrationManager ──────────────────────────────────────────────────────

  group('HydrationManager', () {
    late HydrationManager manager;

    setUp(() => manager = HydrationManager(dailyGoalMl: 2000));

    test('initial totalMl is 0', () {
      expect(manager.totalMl, 0);
    });

    test('logWater accumulates ml within one call', () {
      manager.logWater(750);
      expect(manager.totalMl, 750);
    });

    test('logWater does not exceed 5000 ml cap in a single large call', () {
      manager.logWater(9999);
      expect(manager.totalMl, lessThanOrEqualTo(5000));
    });

    test('status is goalReached when totalMl >= dailyGoalMl', () {
      manager.logWater(2000);
      expect(manager.status, HydrationStatus.goalReached);
    });
  });

  // ─── CaffeineManager ───────────────────────────────────────────────────────

  group('CaffeineManager', () {
    // Use a wake time well outside the cortisol window (3 h ago).
    late CaffeineManager manager;

    setUp(() {
      manager = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
    });

    test('initial status is noIntake', () {
      expect(manager.status, CaffeineStatus.noIntake);
    });

    test('logCaffeine adds entry outside cortisol window', () {
      manager.logCaffeine(CaffeineType.espresso);
      expect(manager.logs.length, 1);
    });

    test('status is clean when only clean drinks logged', () {
      manager.logCaffeine(CaffeineType.blackCoffee);
      manager.logCaffeine(CaffeineType.matcha);
      expect(manager.status, CaffeineStatus.clean);
    });

    test('isSugarBased returns true for redBull', () {
      expect(manager.isSugarBased(CaffeineType.redBull), isTrue);
    });

    test('isSugarBased returns false for espresso', () {
      expect(manager.isSugarBased(CaffeineType.espresso), isFalse);
    });

    test('isCortisolWindow returns false when wake time is 3 h ago', () {
      expect(manager.isCortisolWindow(), isFalse);
    });

    test('isCortisolWindow returns true when wake time is 95 min ago', () {
      final inWindow = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(minutes: 95)),
      );
      expect(inWindow.isCortisolWindow(), isTrue);
    });

    test(
      'logCaffeine throws CortisolWindowException during cortisol window',
      () {
        final inWindow = CaffeineManager(
          wakeTime: DateTime.now().subtract(const Duration(minutes: 95)),
        );
        expect(
          () => inWindow.logCaffeine(CaffeineType.espresso),
          throwsA(isA<CortisolWindowException>()),
        );
      },
    );
  });
}
