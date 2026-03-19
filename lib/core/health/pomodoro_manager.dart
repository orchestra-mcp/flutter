import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum PomodoroPhase { idle, work, standAlert, shortBreak, longBreak }

extension PomodoroPhaseX on PomodoroPhase {
  int get durationSeconds {
    switch (this) {
      case PomodoroPhase.work:
        return 25 * 60;
      case PomodoroPhase.shortBreak:
        return 5 * 60;
      case PomodoroPhase.longBreak:
        return 15 * 60;
      case PomodoroPhase.standAlert:
        return 60;
      case PomodoroPhase.idle:
        return 0;
    }
  }

  bool get isActive =>
      this == PomodoroPhase.work ||
      this == PomodoroPhase.shortBreak ||
      this == PomodoroPhase.longBreak;

  String get label {
    switch (this) {
      case PomodoroPhase.work:
        return 'Focus';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
      case PomodoroPhase.standAlert:
        return 'Stand Up!';
      case PomodoroPhase.idle:
        return 'Ready';
    }
  }
}

class PomodoroState {
  const PomodoroState({
    this.phase = PomodoroPhase.idle,
    this.secondsRemaining = 25 * 60,
    this.cycleIndex = 0,
    this.completedToday = 0,
    this.dailyTarget = 8,
    this.isRunning = false,
    this.isLoading = false,
    this.error,
  });

  final PomodoroPhase phase;
  final int secondsRemaining;
  final int cycleIndex;
  final int completedToday;
  final int dailyTarget;
  final bool isRunning;
  final bool isLoading;
  final String? error;

  double get progress {
    final total = phase.durationSeconds;
    if (total == 0) return 0;
    return 1 - (secondsRemaining / total);
  }

  String get timeDisplay {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsRemaining,
    int? cycleIndex,
    int? completedToday,
    int? dailyTarget,
    bool? isRunning,
    bool? isLoading,
    String? error,
  }) {
    return PomodoroState(
      phase: phase ?? this.phase,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      cycleIndex: cycleIndex ?? this.cycleIndex,
      completedToday: completedToday ?? this.completedToday,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      isRunning: isRunning ?? this.isRunning,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier — PowerSync-backed
// ---------------------------------------------------------------------------

class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;
  String? _currentSessionId;

  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  PomodoroState build() {
    // Watch PowerSync for today's pomodoro data.
    _watchPomodoro();
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const PomodoroState(isLoading: true);
  }

  void _watchPomodoro() {
    final stream = _db.watch('SELECT * FROM pomodoro_sessions ORDER BY created_at ASC');

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      final now = DateTime.now();
      int completed = 0;
      for (final row in results) {
        final startedStr = (row['started_at'] as String?) ??
            (row['created_at'] as String?) ?? '';
        final ts = DateTime.tryParse(startedStr)?.toLocal();
        if (ts == null) continue;
        if (ts.year != now.year || ts.month != now.month || ts.day != now.day) continue;
        if ((row['completed'] as int?) == 1) completed++;
      }

      state = state.copyWith(
        completedToday: completed,
        isLoading: false,
      );
    });

    ref.onDispose(() => sub?.cancel());
  }

  void cancelTimer() {
    _timer?.cancel();
  }

  /// Start a work phase.
  ///
  /// Writes to local PowerSync SQLite — auto-syncs to PostgreSQL and
  /// propagates to all connected devices.
  Future<void> startWork() async {
    _timer?.cancel();
    final now = DateTime.now();
    final id = _uuid.v4();
    _currentSessionId = id;

    state = state.copyWith(
      phase: PomodoroPhase.work,
      secondsRemaining: PomodoroPhase.work.durationSeconds,
      isRunning: true,
    );
    _startTick();

    // Write to local PowerSync SQLite — auto-syncs to PostgreSQL via the
    // connector's uploadData method, then replicates to all devices.
    await _db.execute(
      'INSERT INTO pomodoro_sessions(id, user_id, started_at, ended_at, duration_min, type, completed, created_at, updated_at) '
      'VALUES(?, 0, ?, ?, ?, ?, 0, ?, ?)',
      [
        id,
        now.toIso8601String(),
        '',
        25,
        PomodoroPhase.work.name,
        now.toIso8601String(),
        now.toIso8601String(),
      ],
    );
    debugPrint('[Pomodoro] started work session $id → PowerSync auto-sync');
  }

  void pauseWork() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resumeWork() {
    if (!state.isRunning && state.phase != PomodoroPhase.idle) {
      state = state.copyWith(isRunning: true);
      _startTick();
    }
  }

  void skipToBreak() {
    _timer?.cancel();
    _advanceToBreak();
  }

  Future<void> refresh() async => ref.invalidateSelf();

  void reset() {
    _timer?.cancel();
    state = const PomodoroState();
  }

  // Internal ------------------------------------------------------------------

  void _startTick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.secondsRemaining <= 1) {
      _timer?.cancel();
      _completePhase();
    } else {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    }
  }

  void _completePhase() {
    HapticFeedback.mediumImpact();

    switch (state.phase) {
      case PomodoroPhase.work:
        final newCompleted = state.completedToday + 1;
        final newCycle = state.cycleIndex + 1;
        state = state.copyWith(
          completedToday: newCompleted,
          cycleIndex: newCycle,
          phase: PomodoroPhase.standAlert,
          secondsRemaining: PomodoroPhase.standAlert.durationSeconds,
          isRunning: true,
        );
        _startTick();
        _endSession();
        break;
      case PomodoroPhase.standAlert:
        _advanceToBreak();
        break;
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        state = state.copyWith(
          phase: PomodoroPhase.idle,
          secondsRemaining: PomodoroPhase.work.durationSeconds,
          isRunning: false,
        );
        break;
      case PomodoroPhase.idle:
        break;
    }
  }

  /// Mark the current session as ended.
  Future<void> _endSession() async {
    final id = _currentSessionId;
    if (id == null) return;
    final now = DateTime.now();

    // Write to local PowerSync SQLite — auto-syncs to PostgreSQL via the
    // connector's uploadData method, then replicates to all devices.
    await _db.execute(
      'UPDATE pomodoro_sessions SET ended_at = ?, completed = 1, updated_at = ? WHERE id = ?',
      [now.toIso8601String(), now.toIso8601String(), id],
    );
    debugPrint('[Pomodoro] ended session $id → PowerSync auto-sync');

    _currentSessionId = null;
  }

  void _advanceToBreak() {
    final phase = (state.cycleIndex % 4 == 0 && state.cycleIndex > 0)
        ? PomodoroPhase.longBreak
        : PomodoroPhase.shortBreak;
    state = state.copyWith(
      phase: phase,
      secondsRemaining: phase.durationSeconds,
      isRunning: true,
    );
    _startTick();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(
  PomodoroNotifier.new,
);
