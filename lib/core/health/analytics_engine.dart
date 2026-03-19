/// Aggregates 72-hour health logs and produces a weighted health score
/// plus a [HealthContext] for AI prompt generation.

// ─── Health context ───────────────────────────────────────────────────────────

/// Snapshot of health metrics used to build an AI context string.
class HealthContext {
  const HealthContext({
    required this.hydrationScore,
    required this.pomodoroScore,
    required this.nutritionScore,
    required this.sleepScore,
    required this.shutdownScore,
    required this.healthScore,
    required this.summary,
  });

  /// Hydration component (0–100).
  final double hydrationScore;

  /// Pomodoro component (0–100).
  final double pomodoroScore;

  /// Nutrition component (0–100).
  final double nutritionScore;

  /// Sleep component (0–100).
  final double sleepScore;

  /// Shutdown compliance component (0–100).
  final double shutdownScore;

  /// Weighted overall health score (0–100).
  ///
  /// Weights: hydration 25%, pomodoro 25%, nutrition 20%, sleep 20%,
  /// shutdown 10%.
  final double healthScore;

  /// Human-readable summary for injection into AI prompts.
  final String summary;
}

// ─── Analytics engine ─────────────────────────────────────────────────────────

/// Aggregates health data and produces a weighted [HealthContext].
class HealthAnalyticsEngine {
  const HealthAnalyticsEngine();

  // Component weights (must sum to 1.0).
  static const _wHydration = 0.25;
  static const _wPomodoro = 0.25;
  static const _wNutrition = 0.20;
  static const _wSleep = 0.20;
  static const _wShutdown = 0.10;

  /// Computes a [HealthContext] from the supplied component scores.
  ///
  /// All scores are in the range 0–100.
  HealthContext compute({
    required double hydrationScore,
    required double pomodoroScore,
    required double nutritionScore,
    required double sleepScore,
    required double shutdownScore,
  }) {
    final weighted =
        hydrationScore * _wHydration +
        pomodoroScore * _wPomodoro +
        nutritionScore * _wNutrition +
        sleepScore * _wSleep +
        shutdownScore * _wShutdown;

    final score = weighted.clamp(0.0, 100.0);

    final summary = _buildSummary(
      hydration: hydrationScore,
      pomodoro: pomodoroScore,
      nutrition: nutritionScore,
      sleep: sleepScore,
      shutdown: shutdownScore,
      overall: score,
    );

    return HealthContext(
      hydrationScore: hydrationScore,
      pomodoroScore: pomodoroScore,
      nutritionScore: nutritionScore,
      sleepScore: sleepScore,
      shutdownScore: shutdownScore,
      healthScore: score,
      summary: summary,
    );
  }

  String _buildSummary({
    required double hydration,
    required double pomodoro,
    required double nutrition,
    required double sleep,
    required double shutdown,
    required double overall,
  }) {
    final lines = <String>[
      'Overall health score: ${overall.round()}/100',
      'Hydration: ${hydration.round()}/100',
      'Focus (pomodoro): ${pomodoro.round()}/100',
      'Nutrition safety: ${nutrition.round()}/100',
      'Sleep quality: ${sleep.round()}/100',
      'Shutdown compliance: ${shutdown.round()}/100',
    ];
    return lines.join('\n');
  }
}
