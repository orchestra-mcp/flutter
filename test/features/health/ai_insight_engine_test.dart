import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/analytics_engine.dart';
import 'package:orchestra/features/health/ai_insight_engine.dart';

void main() {
  group('AiInsightEngine', () {
    late AiInsightEngine engine;
    late HealthContext goodCtx;

    setUp(() {
      engine = AiInsightEngine();
      goodCtx = HealthAnalyticsEngine().compute(
        hydrationScore: 90,
        pomodoroScore: 80,
        nutritionScore: 85,
        sleepScore: 75,
        shutdownScore: 100,
      );
    });

    test('generateInsights returns AiInsights', () async {
      final insights = await engine.generateInsights(goodCtx);
      expect(insights, isA<AiInsights>());
    });

    test('top3Wins is non-empty for good scores', () async {
      final insights = await engine.generateInsights(goodCtx);
      expect(insights.top3Wins, isNotEmpty);
    });

    test('top3Concerns is empty for all-good context', () async {
      final insights = await engine.generateInsights(goodCtx);
      expect(insights.top3Concerns, isEmpty);
    });

    test('triggerAnalysis mentions no triggers for good nutrition', () async {
      final insights = await engine.generateInsights(goodCtx);
      expect(insights.triggerAnalysis, contains('No significant'));
    });

    test('second immediate call throws CooldownException', () async {
      await engine.generateInsights(goodCtx);
      expect(
        () => engine.generateInsights(goodCtx),
        throwsA(isA<CooldownException>()),
      );
    });

    test('CooldownException has positive remainingSeconds', () async {
      await engine.generateInsights(goodCtx);
      try {
        await engine.generateInsights(goodCtx);
      } on CooldownException catch (e) {
        expect(e.remainingSeconds, greaterThan(0));
      }
    });
  });
}
