import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Context aggregated from the last 72 hours of health data.
class HealthContext {
  const HealthContext({
    this.hydrationMl = 0,
    this.hydrationGoalMl = 2500,
    this.caffeineMg = 0,
    this.nutritionSafetyScore = 100.0,
    this.completedPomodoros = 0,
    this.sleepHours = 0.0,
    this.shutdownCompliant = true,
    this.recentTriggerFoods = const [],
  });

  final int hydrationMl;
  final int hydrationGoalMl;
  final int caffeineMg;
  final double nutritionSafetyScore;
  final int completedPomodoros;
  final double sleepHours;
  final bool shutdownCompliant;
  final List<String> recentTriggerFoods;
}

/// AI-generated health insights.
class AiInsights {
  const AiInsights({
    required this.top3Wins,
    required this.top3Concerns,
    required this.recommendations,
    required this.triggerAnalysis,
    required this.generatedAt,
  });

  final List<String> top3Wins;
  final List<String> top3Concerns;
  final List<String> recommendations;
  final String triggerAnalysis;
  final DateTime generatedAt;

  factory AiInsights.placeholder(AppLocalizations l10n) => AiInsights(
        top3Wins: [
          l10n.insightConsistentHydration,
          l10n.insightPomodoroStreaks,
          l10n.insightCleanCaffeine,
        ],
        top3Concerns: [
          l10n.insightCortisolCaffeine,
          l10n.insightSleepBelow7h,
          l10n.insightShutdownViolatedNights,
        ],
        recommendations: [
          l10n.insightDrinkWaterPomodoro,
          l10n.insightMoveCaffeine,
          l10n.insightStartShutdownRitual,
        ],
        triggerAnalysis: l10n.insightNoTriggersDetected,
        generatedAt: DateTime.now(),
      );
}

/// Thrown when insights were generated less than 5 minutes ago.
class CooldownException implements Exception {
  const CooldownException({required this.remainingSeconds});
  final int remainingSeconds;
  @override
  String toString() =>
      'CooldownException: $remainingSeconds seconds remaining before next insight.';
}

// ---------------------------------------------------------------------------
// Insight state
// ---------------------------------------------------------------------------

class AiInsightState {
  const AiInsightState({
    this.insights,
    this.isLoading = false,
    this.error,
  });

  final AiInsights? insights;
  final bool isLoading;
  final String? error;

  AiInsightState copyWith({
    AiInsights? insights,
    bool? isLoading,
    String? error,
  }) {
    return AiInsightState(
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AiInsightNotifier extends AsyncNotifier<AiInsightState> {
  static const _cooldownMinutes = 5;
  DateTime? _lastGeneratedAt;

  @override
  Future<AiInsightState> build() async => const AiInsightState();

  /// Generate insights from the given [context].
  ///
  /// Throws [CooldownException] if called within 5 minutes of the last call.
  Future<void> generateInsights(HealthContext context, AppLocalizations l10n) async {
    // Cooldown check.
    final last = _lastGeneratedAt;
    if (last != null) {
      final elapsed = DateTime.now().difference(last).inSeconds;
      final cooldownSecs = _cooldownMinutes * 60;
      if (elapsed < cooldownSecs) {
        throw CooldownException(remainingSeconds: cooldownSecs - elapsed);
      }
    }

    state = const AsyncValue.data(AiInsightState(isLoading: true));

    try {
      // Placeholder: real implementation calls FoundationModelsService on
      // iOS/macOS or TunnelSmartAction on other platforms.
      await Future<void>.delayed(const Duration(seconds: 1));

      final insights = _buildPlaceholderInsights(context, l10n);
      _lastGeneratedAt = DateTime.now();
      state = AsyncValue.data(AiInsightState(insights: insights));
    } catch (e, st) {
      debugPrint('[AiInsightEngine] error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  AiInsights _buildPlaceholderInsights(HealthContext ctx, AppLocalizations l10n) {
    final wins = <String>[];
    final concerns = <String>[];
    final recs = <String>[];

    if (ctx.hydrationMl >= ctx.hydrationGoalMl) {
      wins.add(l10n.insightDailyHydrationGoalReached);
    } else {
      concerns.add(l10n.insightHydrationAtPercent(
          (ctx.hydrationMl / ctx.hydrationGoalMl * 100).toInt()));
      recs.add(l10n.insightDrinkMoreMl(ctx.hydrationGoalMl - ctx.hydrationMl));
    }

    if (ctx.completedPomodoros >= 4) {
      wins.add(l10n.insightPomodorosCompleted(ctx.completedPomodoros));
    } else {
      concerns.add(l10n.insightOnlyFocusSessions(ctx.completedPomodoros));
      recs.add(l10n.insightAimForPomodoros);
    }

    if (ctx.nutritionSafetyScore >= 75) {
      wins.add(l10n.insightNutritionSafetyScore(ctx.nutritionSafetyScore.toInt()));
    } else {
      concerns.add(l10n.insightNutritionBelowThreshold(ctx.nutritionSafetyScore.toInt()));
    }

    if (ctx.shutdownCompliant) {
      wins.add(l10n.insightShutdownCompleted);
    } else {
      concerns.add(l10n.insightShutdownViolatedLastNight);
      recs.add(l10n.insightStartShutdownHours(ctx.hydrationGoalMl > 0 ? '4' : '2'));
    }

    final triggerAnalysis = ctx.recentTriggerFoods.isEmpty
        ? l10n.insightNoTriggerFoods72h
        : l10n.insightTriggerFoodsDetected(ctx.recentTriggerFoods.join(', '));

    return AiInsights(
      top3Wins: wins.take(3).toList(),
      top3Concerns: concerns.take(3).toList(),
      recommendations: recs.take(3).toList(),
      triggerAnalysis: triggerAnalysis,
      generatedAt: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final aiInsightProvider =
    AsyncNotifierProvider<AiInsightNotifier, AiInsightState>(
  AiInsightNotifier.new,
);
