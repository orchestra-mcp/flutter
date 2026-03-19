import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PomodoroPhase { work, shortBreak, longBreak, idle }

class PomodoroState {
  const PomodoroState({
    required this.phase,
    required this.remainingSeconds,
    required this.completedSessions,
    required this.isRunning,
  });

  final PomodoroPhase phase;
  final int remainingSeconds;
  final int completedSessions;
  final bool isRunning;

  static const initial = PomodoroState(
    phase: PomodoroPhase.idle,
    remainingSeconds: 25 * 60,
    completedSessions: 0,
    isRunning: false,
  );

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? remainingSeconds,
    int? completedSessions,
    bool? isRunning,
  }) =>
      PomodoroState(
        phase: phase ?? this.phase,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        completedSessions: completedSessions ?? this.completedSessions,
        isRunning: isRunning ?? this.isRunning,
      );
}

/// Pomodoro timer manager.
///
/// Work: 25 min | Short break: 5 min | Long break (every 4 sessions): 15 min.
class PomodoroManager extends Notifier<PomodoroState> {
  static const _workSeconds = 25 * 60;
  static const _shortBreakSeconds = 5 * 60;
  static const _longBreakSeconds = 15 * 60;

  Timer? _timer;

  @override
  PomodoroState build() => PomodoroState.initial;

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(
      phase: PomodoroPhase.work,
      remainingSeconds: _workSeconds,
      isRunning: true,
    );
    _tick();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.isRunning || state.phase == PomodoroPhase.idle) return;
    state = state.copyWith(isRunning: true);
    _tick();
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroState.initial;
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        _onPhaseComplete();
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    final sessions = state.completedSessions +
        (state.phase == PomodoroPhase.work ? 1 : 0);
    final isLongBreak = sessions % 4 == 0;
    final nextPhase = state.phase == PomodoroPhase.work
        ? (isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak)
        : PomodoroPhase.idle;
    final nextSeconds = nextPhase == PomodoroPhase.shortBreak
        ? _shortBreakSeconds
        : nextPhase == PomodoroPhase.longBreak
            ? _longBreakSeconds
            : _workSeconds;
    state = PomodoroState(
      phase: nextPhase,
      remainingSeconds: nextSeconds,
      completedSessions: sessions,
      isRunning: false,
    );
  }
}

final pomodoroProvider = NotifierProvider<PomodoroManager, PomodoroState>(
  PomodoroManager.new,
);
