import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/health/analytics_engine.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/features/health/ai_insight_engine.dart';

// ─── Summary model ────────────────────────────────────────────────────────────

/// Flattened health snapshot consumed by the health summary card.
class SummaryHealthData {
  const SummaryHealthData({
    this.todaySteps = 0,
    this.hydrationMl = 0,
    this.hydrationGoal = 2500,
    this.sleepHours = 0.0,
    this.dailyFlowScore = 0.0,
    this.healthContext,
    this.isLoading = false,
    this.error,
  });

  final int todaySteps;
  final int hydrationMl;
  final int hydrationGoal;
  final double sleepHours;
  final double dailyFlowScore;
  final HealthContext? healthContext;
  final bool isLoading;
  final String? error;

  /// Convenience getter for the overall health score (0–100).
  double get healthScore => healthContext?.healthScore ?? 0;
}

// ─── Health notifier ──────────────────────────────────────────────────────────

/// Holds a unified [SummaryHealthData] aggregated from API and local managers.
///
/// Watches ALL 5 health dimension providers so any mutation in hydration,
/// caffeine, nutrition, pomodoro, or shutdown immediately recomputes the
/// aggregated health score and triggers rebuilds in all consumers.
class HealthNotifier extends Notifier<SummaryHealthData> {
  final HealthAnalyticsEngine analyticsEngine = const HealthAnalyticsEngine();
  final AiInsightEngine aiInsightEngine = AiInsightEngine();

  @override
  SummaryHealthData build() {
    // Watch ALL health dimension providers for reactive updates.
    final hydration = ref.watch(hydrationProvider);
    final pomodoro = ref.watch(pomodoroProvider);
    final nutrition = ref.watch(nutritionProvider);
    // Watch caffeine so changes trigger a rebuild even though caffeine
    // doesn't contribute a direct score yet.
    ref.watch(caffeineProvider);
    final shutdown = ref.watch(shutdownProvider);

    // Compute component scores from live provider state.
    final hydrationScore =
        (hydration.totalMl / hydration.goalMl).clamp(0.0, 1.0) * 100;
    final pomodoroScore =
        (pomodoro.completedToday / pomodoro.dailyTarget).clamp(0.0, 1.0) * 100;
    final nutritionScore = nutrition.safetyScore;
    // TODO(health): Wire to sleep provider when available.
    const sleepScore = 75.0;
    final shutdownScore =
        shutdown.completedTasks.isEmpty && shutdown.plannedTasks.isEmpty
        ? 100.0
        : shutdown.plannedTasks.isEmpty
        ? 100.0
        : (shutdown.completedTasks.length / shutdown.plannedTasks.length).clamp(
                0.0,
                1.0,
              ) *
              100;

    final ctx = analyticsEngine.compute(
      hydrationScore: hydrationScore,
      pomodoroScore: pomodoroScore,
      nutritionScore: nutritionScore,
      sleepScore: sleepScore,
      shutdownScore: shutdownScore,
    );

    final flowScore = ctx.healthScore;

    // Also load full summary from API in the background.
    _loadSummary();

    return SummaryHealthData(
      hydrationMl: hydration.totalMl,
      hydrationGoal: hydration.goalMl,
      dailyFlowScore: flowScore,
      healthContext: ctx,
    );
  }

  Future<void> _loadSummary() async {
    try {
      final api = ref.read(apiClientProvider);
      final summary = await api.getHealthSummary();
      final steps = (summary['today_steps'] as num?)?.toInt() ?? 0;
      final sleepHours = (summary['sleep_hours'] as num?)?.toDouble() ?? 0.0;

      if (steps > 0 || sleepHours > 0) {
        state = SummaryHealthData(
          todaySteps: steps,
          hydrationMl: state.hydrationMl,
          hydrationGoal: state.hydrationGoal,
          sleepHours: sleepHours,
          dailyFlowScore: state.dailyFlowScore,
          healthContext: state.healthContext,
        );
      }
    } catch (e) {
      debugPrint('[HealthSummary] API load failed: $e');
    }
  }

  /// Generates a [HealthContext] from the current reactive state.
  ///
  /// Since [build()] already watches all providers and computes the context,
  /// this just returns the cached value — no stale reads.
  HealthContext buildHealthContext() {
    return state.healthContext ??
        analyticsEngine.compute(
          hydrationScore: 0,
          pomodoroScore: 0,
          nutritionScore: 100,
          sleepScore: 75,
          shutdownScore: 100,
        );
  }
}

final healthProvider = NotifierProvider<HealthNotifier, SummaryHealthData>(
  HealthNotifier.new,
);
