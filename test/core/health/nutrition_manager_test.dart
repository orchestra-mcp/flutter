import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';

void main() {
  group('FoodRegistry', () {
    test('allFoods is non-empty', () {
      expect(FoodRegistry.allFoods, isNotEmpty);
    });

    test('safeFoods are all isSafe', () {
      for (final f in FoodRegistry.safeFoods) {
        expect(f.isSafe, isTrue, reason: '${f.name} should be safe');
      }
    });

    test('findByName returns correct food', () {
      final rice = FoodRegistry.findByName('Rice');
      expect(rice, isNotNull);
      expect(rice!.name, 'Rice');
      expect(rice.isSafe, isTrue);
    });

    test('findByName returns null for unknown food', () {
      expect(FoodRegistry.findByName('Pizza'), isNull);
    });

    test('trigger foods have at least one condition', () {
      final triggers = FoodRegistry.allFoods.where((f) => !f.isSafe);
      for (final f in triggers) {
        expect(
          f.triggerConditions,
          isNotEmpty,
          reason: '${f.name} should have triggers',
        );
      }
    });
  });

  group('NutritionState', () {
    test('safetyScore is 100 with no entries', () {
      const state = NutritionState();
      expect(state.safetyScore, 100.0);
    });

    test('status is allSafe when score >= 75', () {
      const state = NutritionState();
      expect(state.status, NutritionStatus.allSafe);
    });

    test('maxRiceRule not triggered by default', () {
      const state = NutritionState();
      expect(state.maxRiceRuleTriggered, isFalse);
    });
  });

  group('ShutdownState', () {
    test('default phase is inactive', () {
      const s = ShutdownState();
      expect(s.phase, ShutdownPhase.inactive);
      expect(s.isInShutdownMode, isFalse);
    });

    test('allowedDuringShutdown contains water', () {
      expect(ShutdownState.allowedDuringShutdown, contains('Water'));
    });

    test('shutdownTime is null without targetSleepTime', () {
      const s = ShutdownState();
      expect(s.shutdownTime, isNull);
    });

    test('shutdownTime is sleepTime minus window', () {
      final sleep = DateTime(2026, 3, 17, 23, 0);
      final s = ShutdownState(targetSleepTime: sleep, shutdownWindowHours: 4);
      expect(s.shutdownTime, DateTime(2026, 3, 17, 19, 0));
    });
  });
}
