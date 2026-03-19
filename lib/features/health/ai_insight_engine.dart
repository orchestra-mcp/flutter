import 'package:orchestra/core/health/analytics_engine.dart';

/// Thrown when [AiInsightEngine.generateInsights] is called before the
/// 5-minute domain cooldown has expired.
class CooldownException implements Exception {
  const CooldownException({required this.remainingSeconds});
  final int remainingSeconds;

  @override
  String toString() =>
      'CooldownException: wait $remainingSeconds s before next insight.';
}

/// AI-generated health insights based on aggregated health metrics.
class AiInsights {
  const AiInsights({
    required this.top3Wins,
    required this.top3Concerns,
    required this.recommendations,
    required this.triggerAnalysis,
  });

  /// Up to 3 positive health achievements today.
  final List<String> top3Wins;

  /// Up to 3 health concerns to address.
  final List<String> top3Concerns;

  /// Actionable recommendations for the next 24 h.
  final List<String> recommendations;

  /// GERD / IBS flare-risk assessment based on recent nutrition logs.
  final String triggerAnalysis;
}

/// Generates AI health insights from a [HealthContext].
///
/// Uses a 5-minute per-domain cooldown to avoid spamming the AI backend.
class AiInsightEngine {
  AiInsightEngine();

  DateTime? _lastInsightTime;
  static const _cooldownMinutes = 5;

  /// Generates insights for the supplied [context].
  ///
  /// Throws [CooldownException] if called within [_cooldownMinutes] minutes
  /// of the previous call.
  Future<AiInsights> generateInsights(HealthContext context) async {
    _checkCooldown();
    _lastInsightTime = DateTime.now();

    // Production: delegates to FoundationModelsService on iOS/macOS,
    // falls back to the Orchestra tunnel bridge on all other platforms.
    // Stubbed here to keep the feature testable without a live AI backend.
    return AiInsights(
      top3Wins: _buildWins(context),
      top3Concerns: _buildConcerns(context),
      recommendations: _buildRecommendations(context),
      triggerAnalysis: _buildTriggerAnalysis(context),
    );
  }

  /// Generates a standalone GERD/IBS flare-risk assessment.
  Future<String> generateTriggerAnalysis(HealthContext context) async {
    return _buildTriggerAnalysis(context);
  }

  // ---------------------------------------------------------------------------

  void _checkCooldown() {
    final last = _lastInsightTime;
    if (last == null) return;
    final elapsed = DateTime.now().difference(last).inSeconds;
    final cooldownSeconds = _cooldownMinutes * 60;
    if (elapsed < cooldownSeconds) {
      throw CooldownException(remainingSeconds: cooldownSeconds - elapsed);
    }
  }

  List<String> _buildWins(HealthContext ctx) {
    final wins = <String>[];
    if (ctx.hydrationScore >= 75) wins.add('Good hydration today');
    if (ctx.pomodoroScore >= 75) wins.add('Strong focus sessions');
    if (ctx.nutritionScore >= 75) wins.add('Safe nutrition choices');
    if (ctx.sleepScore >= 75) wins.add('Adequate sleep');
    return wins.take(3).toList();
  }

  List<String> _buildConcerns(HealthContext ctx) {
    final concerns = <String>[];
    if (ctx.hydrationScore < 50) concerns.add('Hydration is below 50 %');
    if (ctx.pomodoroScore < 50) concerns.add('Low focus score');
    if (ctx.nutritionScore < 50) concerns.add('Nutrition safety is poor');
    if (ctx.sleepScore < 50) concerns.add('Sleep quality needs improvement');
    if (ctx.shutdownScore < 50) concerns.add('Shutdown compliance is low');
    return concerns.take(3).toList();
  }

  List<String> _buildRecommendations(HealthContext ctx) {
    final recs = <String>[];
    if (ctx.hydrationScore < 75) recs.add('Drink a glass of water now');
    if (ctx.pomodoroScore < 75) recs.add('Start a 25-minute focus session');
    if (ctx.nutritionScore < 75) recs.add('Choose a safe food for your next meal');
    if (ctx.shutdownScore < 75) recs.add('Begin your digital shutdown routine');
    return recs.take(3).toList();
  }

  String _buildTriggerAnalysis(HealthContext ctx) {
    if (ctx.nutritionScore >= 75) {
      return 'No significant GERD/IBS trigger foods detected today.';
    }
    if (ctx.nutritionScore >= 50) {
      return 'Moderate trigger exposure — monitor for symptoms over the next 2 h.';
    }
    return 'High trigger exposure — consider antacids and avoid lying down for 3 h.';
  }
}
