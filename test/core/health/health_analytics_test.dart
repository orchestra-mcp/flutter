import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/analytics_engine.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';

void main() {
  // ─── HealthAnalyticsEngine ────────────────────────────────────────────────

  group('HealthAnalyticsEngine', () {
    const engine = HealthAnalyticsEngine();

    test('perfect scores produce healthScore of 100', () {
      final ctx = engine.compute(
        hydrationScore: 100,
        pomodoroScore: 100,
        nutritionScore: 100,
        sleepScore: 100,
        shutdownScore: 100,
      );
      expect(ctx.healthScore, closeTo(100.0, 0.01));
    });

    test('zero scores produce healthScore of 0', () {
      final ctx = engine.compute(
        hydrationScore: 0,
        pomodoroScore: 0,
        nutritionScore: 0,
        sleepScore: 0,
        shutdownScore: 0,
      );
      expect(ctx.healthScore, closeTo(0.0, 0.01));
    });

    test('weighted score uses correct component weights', () {
      // Only hydration = 100; all others = 0. Weight = 0.25.
      final ctx = engine.compute(
        hydrationScore: 100,
        pomodoroScore: 0,
        nutritionScore: 0,
        sleepScore: 0,
        shutdownScore: 0,
      );
      expect(ctx.healthScore, closeTo(25.0, 0.01));
    });

    test('summary contains overall score', () {
      final ctx = engine.compute(
        hydrationScore: 80,
        pomodoroScore: 70,
        nutritionScore: 90,
        sleepScore: 60,
        shutdownScore: 100,
      );
      expect(ctx.summary, contains('Overall health score'));
    });
  });

  // ─── FoodRegistry ─────────────────────────────────────────────────────────

  group('FoodRegistry', () {
    test('allFoods is non-empty', () {
      expect(FoodRegistry.allFoods, isNotEmpty);
    });

    test('safeFoods contains only items with no trigger conditions', () {
      for (final food in FoodRegistry.safeFoods) {
        expect(food.triggerConditions, isEmpty);
      }
    });

    test('findByName returns correct item', () {
      final rice = FoodRegistry.findByName('Rice');
      expect(rice, isNotNull);
      expect(rice!.category, FoodCategory.carb);
    });

    test('findByName is case-insensitive', () {
      expect(FoodRegistry.findByName('rice'), isNotNull);
      expect(FoodRegistry.findByName('RICE'), isNotNull);
    });

    test('findByName returns null for unknown food', () {
      expect(FoodRegistry.findByName('unknown-food-xyz'), isNull);
    });
  });

  // ─── NutritionState ───────────────────────────────────────────────────────

  group('NutritionState', () {
    test('initial safetyScore is 100', () {
      expect(const NutritionState().safetyScore, 100.0);
    });

    test('maxRiceRuleTriggered is false with no entries', () {
      expect(const NutritionState().maxRiceRuleTriggered, isFalse);
    });

    test('status is allSafe when safetyScore >= 75', () {
      expect(const NutritionState().status, NutritionStatus.allSafe);
    });
  });
}
