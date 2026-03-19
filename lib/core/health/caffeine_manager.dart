import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum CaffeineType {
  espresso,
  blackCoffee,
  coldBrew,
  matcha,
  greenTea,
  redBull,
  other,
}

enum CaffeineStatus { noIntake, clean, transitioning, redBullDependent }

class CaffeineEntry {
  const CaffeineEntry({
    required this.type,
    required this.mg,
    required this.timestamp,
  });
  final CaffeineType type;
  final int mg;
  final DateTime timestamp;
}

class CaffeineState {
  const CaffeineState({
    this.totalMg = 0,
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  final int totalMg;
  final List<CaffeineEntry> entries;
  final bool isLoading;
  final String? error;

  /// Approximate mg per drink type.
  static int mgFor(CaffeineType type) {
    switch (type) {
      case CaffeineType.espresso:
        return 63;
      case CaffeineType.blackCoffee:
        return 95;
      case CaffeineType.coldBrew:
        return 200;
      case CaffeineType.matcha:
        return 70;
      case CaffeineType.greenTea:
        return 47;
      case CaffeineType.redBull:
        return 80;
      case CaffeineType.other:
        return 80;
    }
  }

  static CaffeineType typeFromString(String name) {
    switch (name.toLowerCase()) {
      case 'espresso':
        return CaffeineType.espresso;
      case 'black_coffee':
      case 'blackcoffee':
        return CaffeineType.blackCoffee;
      case 'cold_brew':
      case 'coldbrew':
        return CaffeineType.coldBrew;
      case 'matcha':
        return CaffeineType.matcha;
      case 'green_tea':
      case 'greentea':
        return CaffeineType.greenTea;
      case 'red_bull':
      case 'redbull':
        return CaffeineType.redBull;
      default:
        return CaffeineType.other;
    }
  }

  static bool isSugarBased(CaffeineType type) =>
      type == CaffeineType.redBull || type == CaffeineType.other;

  /// Percentage of intake that is "clean" (no added sugar).
  double get cleanTransitionPercent {
    if (entries.isEmpty) return 100;
    final clean = entries.where((e) => !isSugarBased(e.type)).length;
    return (clean / entries.length) * 100;
  }

  CaffeineStatus get status {
    if (entries.isEmpty) return CaffeineStatus.noIntake;
    final redBullCount = entries
        .where((e) => e.type == CaffeineType.redBull)
        .length;
    if (redBullCount >= 2) return CaffeineStatus.redBullDependent;
    if (cleanTransitionPercent >= 80) return CaffeineStatus.clean;
    return CaffeineStatus.transitioning;
  }

  bool get overDailyLimit => totalMg > 400;

  CaffeineState copyWith({
    int? totalMg,
    List<CaffeineEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return CaffeineState(
      totalMg: totalMg ?? this.totalMg,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

class CortisolWindowException implements Exception {
  const CortisolWindowException();
  @override
  String toString() =>
      'Caffeine intake during cortisol window (90-120 min post-wake) is not recommended.';
}

// ---------------------------------------------------------------------------
// Notifier — PowerSync-backed
// ---------------------------------------------------------------------------

class CaffeineNotifier extends Notifier<CaffeineState> {
  DateTime? _wakeTime;

  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  CaffeineState build() {
    // Watch PowerSync for today's caffeine data.
    _watchCaffeine();
    return const CaffeineState(isLoading: true);
  }

  void _watchCaffeine() {
    final stream = _db.watch(
      'SELECT * FROM caffeine_logs ORDER BY created_at ASC',
    );

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      final now = DateTime.now();
      final entries = <CaffeineEntry>[];
      for (final row in results) {
        final loggedStr =
            (row['logged_at'] as String?) ??
            (row['created_at'] as String?) ??
            '';
        final ts = DateTime.tryParse(loggedStr)?.toLocal();
        if (ts == null) continue;
        if (ts.year != now.year || ts.month != now.month || ts.day != now.day)
          continue;

        final typeName = row['drink_type'] as String? ?? 'other';
        final type = CaffeineState.typeFromString(typeName);
        entries.add(
          CaffeineEntry(
            type: type,
            mg:
                (row['caffeine_mg'] as num?)?.toInt() ??
                CaffeineState.mgFor(type),
            timestamp: ts,
          ),
        );
      }

      final totalMg = entries.fold<int>(0, (sum, e) => sum + e.mg);
      state = CaffeineState(totalMg: totalMg, entries: entries);
    });

    ref.onDispose(() => sub?.cancel());
  }

  void setWakeTime(DateTime wakeTime) => _wakeTime = wakeTime;

  bool isCortisolWindow() {
    final wake = _wakeTime;
    if (wake == null) return false;
    final elapsed = DateTime.now().difference(wake).inMinutes;
    return elapsed >= 90 && elapsed <= 120;
  }

  /// Add a caffeine entry for today.
  ///
  /// Writes to local PowerSync SQLite — auto-syncs to PostgreSQL and
  /// propagates to all connected devices.
  Future<void> addCaffeine(
    CaffeineType type, {
    bool ignoreCortisolWindow = false,
  }) async {
    if (!ignoreCortisolWindow && isCortisolWindow()) {
      throw const CortisolWindowException();
    }
    final mg = CaffeineState.mgFor(type);
    final now = DateTime.now();
    final entry = CaffeineEntry(type: type, mg: mg, timestamp: now);

    // Optimistic local state update.
    state = state.copyWith(
      totalMg: state.totalMg + mg,
      entries: [...state.entries, entry],
    );

    // Write to local PowerSync SQLite — auto-syncs to PostgreSQL via the
    // connector's uploadData method, then replicates to all devices.
    final isClean = !CaffeineState.isSugarBased(type);
    await _db.execute(
      'INSERT INTO caffeine_logs(id, user_id, drink_type, caffeine_mg, is_clean, sugar_g, logged_at, created_at, updated_at) '
      'VALUES(?, 0, ?, ?, ?, 0, ?, ?, ?)',
      [
        _uuid.v4(),
        type.name,
        mg,
        isClean ? 1 : 0,
        now.toIso8601String(),
        now.toIso8601String(),
        now.toIso8601String(),
      ],
    );
    debugPrint(
      '[Caffeine] +${mg}mg (${type.name}) → total ${state.totalMg}mg → PowerSync auto-sync',
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  void reset() => state = const CaffeineState();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final caffeineProvider = NotifierProvider<CaffeineNotifier, CaffeineState>(
  CaffeineNotifier.new,
);
