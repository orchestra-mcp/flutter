import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/ai_insight_engine.dart';

void main() {
  group('HealthContext', () {
    test('defaults to zero values', () {
      const ctx = HealthContext();
      expect(ctx.hydrationMl, 0);
      expect(ctx.caffeineMg, 0);
      expect(ctx.nutritionSafetyScore, 100.0);
      expect(ctx.completedPomodoros, 0);
      expect(ctx.shutdownCompliant, isTrue);
      expect(ctx.recentTriggerFoods, isEmpty);
    });
  });

  group('AiInsights', () {
    test('constructor stores all fields', () {
      final now = DateTime.now();
      final insights = AiInsights(
        top3Wins: ['win1', 'win2', 'win3'],
        top3Concerns: ['concern1'],
        recommendations: ['rec1', 'rec2'],
        triggerAnalysis: 'No triggers detected',
        generatedAt: now,
      );
      expect(insights.top3Wins, hasLength(3));
      expect(insights.top3Concerns, hasLength(1));
      expect(insights.recommendations, hasLength(2));
      expect(insights.triggerAnalysis, 'No triggers detected');
      expect(insights.generatedAt, now);
    });

    test('generatedAt reflects construction time', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final insights = AiInsights(
        top3Wins: ['a'],
        top3Concerns: ['b'],
        recommendations: ['c'],
        triggerAnalysis: 'd',
        generatedAt: DateTime.now(),
      );
      expect(insights.generatedAt.isAfter(before), isTrue);
    });
  });

  group('CooldownException', () {
    test('remainingSeconds stored', () {
      const ex = CooldownException(remainingSeconds: 120);
      expect(ex.remainingSeconds, 120);
      expect(ex.toString(), contains('120'));
    });
  });

  group('AiInsightNotifier build', () {
    test('initial state is empty and not loading', () async {
      // Unit test without full Riverpod container.
      const state = AiInsightState();
      expect(state.isLoading, isFalse);
      expect(state.insights, isNull);
      expect(state.error, isNull);
    });

    test('copyWith updates fields', () {
      const state = AiInsightState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.insights, isNull);
    });
  });
}
