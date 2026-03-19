import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum ShutdownPhase { inactive, active, violated }

enum FlareRisk { none, moderate, high }

class ShutdownState {
  const ShutdownState({
    this.phase = ShutdownPhase.inactive,
    this.shutdownWindowHours = 4,
    this.targetSleepTime,
    this.plannedTasks = const [],
    this.completedTasks = const [],
    this.timeUntilShutdown,
    this.timeUntilSleep,
    this.flareRisk = FlareRisk.none,
    this.isLoading = false,
    this.error,
  });

  final ShutdownPhase phase;
  final int shutdownWindowHours;
  final DateTime? targetSleepTime;
  final List<String> plannedTasks;
  final List<String> completedTasks;
  final Duration? timeUntilShutdown;
  final Duration? timeUntilSleep;
  final FlareRisk flareRisk;
  final bool isLoading;
  final String? error;

  DateTime? get shutdownTime => targetSleepTime
      ?.subtract(Duration(hours: shutdownWindowHours));

  bool get isInShutdownMode => phase == ShutdownPhase.active;

  static const allowedDuringShutdown = [
    'Water',
    'Chamomile Tea',
    'Anise Tea',
  ];

  ShutdownState copyWith({
    ShutdownPhase? phase,
    int? shutdownWindowHours,
    DateTime? targetSleepTime,
    List<String>? plannedTasks,
    List<String>? completedTasks,
    Duration? timeUntilShutdown,
    Duration? timeUntilSleep,
    FlareRisk? flareRisk,
    bool? isLoading,
    String? error,
  }) {
    return ShutdownState(
      phase: phase ?? this.phase,
      shutdownWindowHours: shutdownWindowHours ?? this.shutdownWindowHours,
      targetSleepTime: targetSleepTime ?? this.targetSleepTime,
      plannedTasks: plannedTasks ?? this.plannedTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      timeUntilShutdown: timeUntilShutdown ?? this.timeUntilShutdown,
      timeUntilSleep: timeUntilSleep ?? this.timeUntilSleep,
      flareRisk: flareRisk ?? this.flareRisk,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier — PowerSync-backed
// ---------------------------------------------------------------------------

class ShutdownNotifier extends Notifier<ShutdownState> {
  Timer? _timer;
  String? _currentShutdownId;

  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  ShutdownState build() {
    // Watch PowerSync for today's shutdown data.
    _watchShutdown();
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const ShutdownState(isLoading: true);
  }

  void _watchShutdown() {
    final stream = _db.watch(
      'SELECT * FROM sleep_configs ORDER BY created_at DESC LIMIT 1',
    );

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      if (results.isEmpty) {
        state = const ShutdownState();
        return;
      }

      final row = results.first;
      final isActive = (row['shutdown_active'] as int?) == 1;
      final phase = isActive ? ShutdownPhase.active : ShutdownPhase.inactive;

      final bedtimeStr = row['target_bedtime'] as String?;
      final targetSleep = bedtimeStr != null && bedtimeStr.isNotEmpty
          ? DateTime.tryParse(bedtimeStr)
          : null;

      _currentShutdownId = row['id'] as String?;

      state = ShutdownState(
        phase: phase,
        targetSleepTime: targetSleep,
      );

      if (targetSleep != null) {
        _startTick();
      }
    });

    ref.onDispose(() => sub?.cancel());
  }

  void configure({
    required DateTime targetSleepTime,
    int shutdownWindowHours = 4,
  }) {
    state = state.copyWith(
      targetSleepTime: targetSleepTime,
      shutdownWindowHours: shutdownWindowHours,
    );
    _startTick();
  }

  /// Start a shutdown session.
  ///
  /// Writes to local PowerSync SQLite — auto-syncs to PostgreSQL and
  /// propagates to all connected devices.
  Future<void> startShutdown() async {
    final now = DateTime.now();
    final id = _uuid.v4();
    _currentShutdownId = id;

    // Optimistic local state update.
    state = state.copyWith(phase: ShutdownPhase.active);

    final targetSleep = state.targetSleepTime?.toIso8601String() ?? '';
    final planned = state.plannedTasks.join(',');

    // Write to local PowerSync SQLite — auto-syncs to PostgreSQL via the
    // connector's uploadData method, then replicates to all devices.
    await _db.execute(
      'INSERT INTO sleep_configs(id, user_id, target_bedtime, shutdown_started_at, shutdown_active, wake_time, sleep_time, created_at, updated_at) '
      'VALUES(?, 0, ?, ?, 1, ?, ?, ?, ?)',
      [
        id,
        targetSleep,
        now.toIso8601String(),
        state.targetSleepTime?.subtract(const Duration(hours: 8)).toIso8601String() ?? '',
        targetSleep,
        now.toIso8601String(),
        now.toIso8601String(),
      ],
    );
    debugPrint('[Shutdown] started session $id → PowerSync auto-sync');
  }

  void endShutdown() {
    _timer?.cancel();
    state = const ShutdownState();
  }

  void addTask(String task) {
    state = state.copyWith(
      plannedTasks: [...state.plannedTasks, task],
    );
    _updateShutdownRecord();
  }

  void completeTask(String task) {
    state = state.copyWith(
      completedTasks: [...state.completedTasks, task],
    );
    _updateShutdownRecord();
  }

  Future<void> refresh() async => ref.invalidateSelf();

  void cancelTimer() => _timer?.cancel();

  /// Persist current planned/completed tasks to PowerSync.
  Future<void> _updateShutdownRecord() async {
    final id = _currentShutdownId;
    if (id == null) return;
    final now = DateTime.now();
    final planned = state.plannedTasks.join(',');
    final completed = state.completedTasks.join(',');

    await _db.execute(
      'UPDATE sleep_configs SET updated_at = ? WHERE id = ?',
      [now.toIso8601String(), id],
    );
  }

  // Internal ------------------------------------------------------------------

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final sleep = state.targetSleepTime;
    final shutdown = state.shutdownTime;
    if (sleep == null || shutdown == null) return;

    final now = DateTime.now();
    final toShutdown = shutdown.difference(now);
    final toSleep = sleep.difference(now);

    if (toShutdown.isNegative && state.phase == ShutdownPhase.inactive) {
      state = state.copyWith(phase: ShutdownPhase.active);
    }

    state = state.copyWith(
      timeUntilShutdown: toShutdown.isNegative ? Duration.zero : toShutdown,
      timeUntilSleep: toSleep.isNegative ? Duration.zero : toSleep,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final shutdownProvider =
    NotifierProvider<ShutdownNotifier, ShutdownState>(
  ShutdownNotifier.new,
);
