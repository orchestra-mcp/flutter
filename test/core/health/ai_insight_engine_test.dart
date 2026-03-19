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

  group('AiInsights.placeholder', () {
    test('produces non-empty wins and concerns', () {
      final insights = AiInsights.placeholder();
      expect(insights.top3Wins, isNotEmpty);
      expect(insights.top3Concerns, isNotEmpty);
      expect(insights.recommendations, isNotEmpty);
      expect(insights.triggerAnalysis, isNotEmpty);
    });

    test('generatedAt is recent', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final insights = AiInsights.placeholder();
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
  });
}
