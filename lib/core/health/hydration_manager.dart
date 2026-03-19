import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum HydrationStatus { onTrack, slightlyBehind, dehydrated, goalReached }

class HydrationEntry {
  const HydrationEntry({
    required this.ml,
    required this.timestamp,
  });
  final int ml;
  final DateTime timestamp;
}

class HydrationState {
  const HydrationState({
    this.totalMl = 0,
    this.goalMl = 2500,
    this.entries = const [],
    this.lastLoggedAt,
    this.isLoading = false,
    this.error,
  });

  final int totalMl;
  final int goalMl;
  final List<HydrationEntry> entries;
  final DateTime? lastLoggedAt;
  final bool isLoading;
  final String? error;

  double get progressFraction => (totalMl / goalMl).clamp(0.0, 1.0);

  HydrationStatus get status {
    final pct = progressFraction;
    if (pct >= 1.0) return HydrationStatus.goalReached;
    if (pct >= 0.6) return HydrationStatus.onTrack;
    if (pct >= 0.3) return HydrationStatus.slightlyBehind;
    return HydrationStatus.dehydrated;
  }

  String get statusMessage {
    switch (status) {
      case HydrationStatus.goalReached:
        return 'Great job! Daily goal reached.';
      case HydrationStatus.onTrack:
        return 'On track — keep it up.';
      case HydrationStatus.slightlyBehind:
        return 'Slightly behind — have a glass now.';
      case HydrationStatus.dehydrated:
        return 'Drink water soon — you\'re dehydrated.';
    }
  }

  bool get goutFlushRecommendation => totalMl < 1500;

  HydrationState copyWith({
    int? totalMl,
    int? goalMl,
    List<HydrationEntry>? entries,
    DateTime? lastLoggedAt,
    bool? isLoading,
    String? error,
  }) {
    return HydrationState(
      totalMl: totalMl ?? this.totalMl,
      goalMl: goalMl ?? this.goalMl,
      entries: entries ?? this.entries,
      lastLoggedAt: lastLoggedAt ?? this.lastLoggedAt,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier — PowerSync-backed
// ---------------------------------------------------------------------------

class HydrationNotifier extends Notifier<HydrationState> {
  static const _cooldownSeconds = 30;
  static const _maxDailyMl = 5000;
  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  HydrationState build() {
    // Watch PowerSync for today's hydration data.
    _watchHydration();
    return const HydrationState(isLoading: true);
  }

  void _watchHydration() {
    // Watch ALL water_logs — filter by today's date in Dart to avoid
    // SQL timestamp format mismatches between local writes and PowerSync sync.
    final stream = _db.watch('SELECT * FROM water_logs ORDER BY created_at ASC');

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      final now = DateTime.now();
      final entries = <HydrationEntry>[];

      debugPrint('[Hydration] watch fired: ${results.length} total rows');

      for (final row in results) {
        final loggedStr = (row['logged_at'] as String?) ??
            (row['created_at'] as String?) ?? '';
        final ml = (row['amount_ml'] as num?)?.toInt() ?? 0;
        final ts = DateTime.tryParse(loggedStr)?.toLocal();

        debugPrint('[Hydration]   row: amount_ml=$ml logged_at=$loggedStr parsed=${ts?.toLocal()} id=${row['id']}');

        if (ts == null) continue;

        // Filter: only include today's entries.
        if (ts.year != now.year ||
            ts.month != now.month ||
            ts.day != now.day) continue;

        entries.add(HydrationEntry(ml: ml, timestamp: ts));
      }

      final totalMl = entries.fold<int>(0, (sum, e) => sum + e.ml);
      debugPrint('[Hydration] today entries: ${entries.length}, total: ${totalMl}ml');

      state = HydrationState(
        totalMl: totalMl,
        goalMl: state.goalMl,
        entries: entries,
        lastLoggedAt: entries.isNotEmpty ? entries.last.timestamp : null,
      );
    });

    ref.onDispose(() => sub?.cancel());
  }

  /// Add [ml] to today's hydration.
  ///
  /// Writes to local PowerSync SQLite — auto-syncs to PostgreSQL and
  /// propagates to all connected devices.
  Future<void> addWater(int ml) async {
    assert(ml > 0, 'ml must be positive');
    final now = DateTime.now();
    final last = state.lastLoggedAt;
    if (last != null && now.difference(last).inSeconds < _cooldownSeconds) {
      debugPrint('[Hydration] cooldown active — ignoring addWater($ml)');
      return;
    }

    final newTotal = (state.totalMl + ml).clamp(0, _maxDailyMl);

    // Optimistic local state update.
    state = state.copyWith(
      totalMl: newTotal,
      entries: [...state.entries, HydrationEntry(ml: ml, timestamp: now)],
      lastLoggedAt: now,
    );

    // Write to local PowerSync SQLite — auto-syncs to PostgreSQL via the
    // connector's uploadData method, then replicates to all devices.
    await _db.execute(
      'INSERT INTO water_logs(id, user_id, amount_ml, logged_at, source, is_gout_flush, created_at, updated_at) '
      'VALUES(?, 0, ?, ?, ?, 0, ?, ?)',
      [_uuid.v4(), ml, now.toIso8601String(), 'manual', now.toIso8601String(), now.toIso8601String()],
    );
    debugPrint('[Hydration] +$ml ml → total $newTotal ml → PowerSync auto-sync');
  }

  /// Refresh data — re-triggers the PowerSync watch.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Reset daily hydration data.
  void reset() {
    state = const HydrationState();
  }

  /// Update the daily goal.
  void setGoal(int ml) {
    state = state.copyWith(goalMl: ml);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final hydrationProvider =
    NotifierProvider<HydrationNotifier, HydrationState>(
  HydrationNotifier.new,
);
