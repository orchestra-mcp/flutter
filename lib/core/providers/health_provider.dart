import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';

/// Health profile (baseline settings: wake time, sleep target, goals).
/// Backed by PowerSync db.watch() — auto-updates when data changes on any device.
final healthProfileProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db
      .watch('SELECT * FROM health_profiles ORDER BY updated_at DESC')
      .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
});

/// Composite health summary (scores, streaks, daily status).
/// Kept as FutureProvider — computed server-side, no local PowerSync table.
final healthSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getHealthSummary();
});

/// Today's hydration status — water logs (null date = all).
/// Backed by PowerSync water_logs table.
final hydrationStatusProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final db = ref.watch(powersyncDatabaseProvider);
      return db
          .watch('SELECT * FROM water_logs ORDER BY logged_at DESC')
          .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
    });

/// Water log entries for a given date (null = all).
/// Backed by PowerSync db.watch() — reactive to writes from any device.
final waterLogsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, date) {
      final db = ref.watch(powersyncDatabaseProvider);
      if (date != null && date.isNotEmpty) {
        return db
            .watch(
              'SELECT * FROM water_logs WHERE logged_at LIKE ? ORDER BY logged_at DESC',
              parameters: ['$date%'],
            )
            .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      return db
          .watch('SELECT * FROM water_logs ORDER BY logged_at DESC')
          .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
    });

/// Meal log entries for a given date.
final mealLogsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, date) {
      final db = ref.watch(powersyncDatabaseProvider);
      if (date != null && date.isNotEmpty) {
        return db
            .watch(
              'SELECT * FROM meal_logs WHERE logged_at LIKE ? ORDER BY logged_at DESC',
              parameters: ['$date%'],
            )
            .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      return db
          .watch('SELECT * FROM meal_logs ORDER BY logged_at DESC')
          .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
    });

/// Caffeine log entries for a given date.
final caffeineLogsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, date) {
      final db = ref.watch(powersyncDatabaseProvider);
      if (date != null && date.isNotEmpty) {
        return db
            .watch(
              'SELECT * FROM caffeine_logs WHERE logged_at LIKE ? ORDER BY logged_at DESC',
              parameters: ['$date%'],
            )
            .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      return db
          .watch('SELECT * FROM caffeine_logs ORDER BY logged_at DESC')
          .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
    });

/// Caffeine cleanliness score.
/// Kept as FutureProvider — server-computed score, no direct table.
final caffeineScoreProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getCaffeineScore();
});

/// Pomodoro sessions for a given date.
final pomodoroSessionsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, date) {
      final db = ref.watch(powersyncDatabaseProvider);
      if (date != null && date.isNotEmpty) {
        return db
            .watch(
              'SELECT * FROM pomodoro_sessions WHERE started_at LIKE ? ORDER BY started_at DESC',
              parameters: ['$date%'],
            )
            .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
      }
      return db
          .watch('SELECT * FROM pomodoro_sessions ORDER BY started_at DESC')
          .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
    });

/// Shutdown / sleep config status.
/// Backed by PowerSync sleep_configs table.
final shutdownStatusProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final db = ref.watch(powersyncDatabaseProvider);
      return db
          .watch('SELECT * FROM sleep_configs ORDER BY updated_at DESC')
          .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
    });

/// Health snapshots between two dates.
final snapshotsProvider = StreamProvider.family<List<Map<String, dynamic>>,
    ({String? from, String? to})>((ref, range) {
  final db = ref.watch(powersyncDatabaseProvider);
  if (range.from != null && range.to != null) {
    return db
        .watch(
          'SELECT * FROM health_snapshots WHERE snapshot_date >= ? AND snapshot_date <= ? ORDER BY snapshot_date DESC',
          parameters: [range.from!, range.to!],
        )
        .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
  }
  return db
      .watch('SELECT * FROM health_snapshots ORDER BY snapshot_date DESC')
      .map((r) => r.map((e) => Map<String, dynamic>.from(e)).toList());
});
