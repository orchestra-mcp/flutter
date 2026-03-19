# AI Insight Engine

`AiInsightEngine` (`lib/features/health/ai_insight_engine.dart`) generates personalised health insights from a `HealthContext` snapshot. On iOS/macOS it delegates to `FoundationModelsService`; on all other platforms it falls back to the Orchestra tunnel bridge.

## Files

| File | Purpose |
|------|---------|
| `lib/features/health/ai_insight_engine.dart` | `AiInsightEngine`, `AiInsights` model, `CooldownException` |
| `lib/features/health/health_provider.dart` | `HealthNotifier`, `SummaryHealthData`, `healthProvider` |

## AiInsights Model

```dart
class AiInsights {
  final List<String> top3Wins;         // positive achievements
  final List<String> top3Concerns;     // issues to address
  final List<String> recommendations;  // actionable next steps
  final String triggerAnalysis;        // GERD/IBS flare assessment
}
```

## Cooldown

`generateInsights` enforces a **5-minute per-domain cooldown** stored in `SharedPreferences`. Calling it within the cooldown window throws `CooldownException` with `remainingSeconds`.

```dart
try {
  final insights = await engine.generateInsights(ctx);
} on CooldownException catch (e) {
  print('Try again in ${e.remainingSeconds} s');
}
```

## HealthNotifier

`HealthNotifier` (`healthProvider`) holds all five health managers and recomputes `SummaryHealthData` whenever any manager notifies:

| Field | Source |
|-------|--------|
| `hydrationMl` | `HydrationManager.totalMl` |
| `hydrationGoal` | `HydrationManager.dailyGoalMl` |
| `dailyFlowScore` | `PomodoroManager.completedToday / dailyTarget × 100` |
| `todaySteps` | `HealthKitService.getTodaySteps()` |
| `sleepHours` | `HealthKitService.getSleepHours()` |

## Usage

```dart
// Read summary data
final data = ref.watch(healthProvider);

// Generate AI insights
final notifier = ref.read(healthProvider.notifier);
final ctx = notifier.buildHealthContext();
final insights = await notifier.aiInsightEngine.generateInsights(ctx);
```
