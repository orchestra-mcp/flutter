import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';

/// Health profile (baseline settings: wake time, sleep target, goals).
final healthProfileProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getHealthProfile();
});

/// Composite health summary (scores, streaks, daily status).
final healthSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getHealthSummary();
});

/// Today's hydration status (total_ml, goal_ml, percentage).
final hydrationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getHydrationStatus();
});

/// Water log entries for a given date (defaults to today on the backend).
final waterLogsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
      (ref, date) => ref.watch(apiClientProvider).listWaterLogs(date: date),
    );

/// Meal log entries for a given date.
final mealLogsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
      (ref, date) => ref.watch(apiClientProvider).listMealLogs(date: date),
    );

/// Caffeine log entries for a given date.
final caffeineLogsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
      (ref, date) => ref.watch(apiClientProvider).listCaffeineLogs(date: date),
    );

/// Caffeine cleanliness score.
final caffeineScoreProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getCaffeineScore();
});

/// Pomodoro sessions for a given date.
final pomodoroSessionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>(
      (ref, date) =>
          ref.watch(apiClientProvider).listPomodoroSessions(date: date),
    );

/// Shutdown ritual status.
final shutdownStatusProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getShutdownStatus();
});

/// Health snapshots between two dates.
final snapshotsProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String? from, String? to})
    >(
      (ref, range) => ref
          .watch(apiClientProvider)
          .listSnapshots(from: range.from, to: range.to),
    );
