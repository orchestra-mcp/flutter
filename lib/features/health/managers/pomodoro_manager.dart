import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Phase of the Pomodoro timer.
enum PomodoroPhase { idle, work, standAlert, shortBreak, longBreak }

extension on PomodoroPhase {
  /// Duration in seconds for this phase.
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
}

/// Manages the Pomodoro focus timer.
///
/// Ports the Swift PomodoroManager health-debug class.
class PomodoroManager extends ChangeNotifier {
  PomodoroManager({this.dailyTarget = 8});

  final int dailyTarget;

  PomodoroPhase _phase = PomodoroPhase.idle;
  PomodoroPhase get phase => _phase;

  int _cycleIndex = 0;
  int get cycleIndex => _cycleIndex;

  int _completedToday = 0;
  int get completedToday => _completedToday;

  int _timeRemaining = 0;
  int get timeRemaining => _timeRemaining;

  Timer? _timer;

  /// Starts a 25-minute work session.
  void startWork() {
    _phase = PomodoroPhase.work;
    _timeRemaining = PomodoroPhase.work.durationSeconds;
    _startTick();
    notifyListeners();
  }

  /// Pauses the current session.
  void pauseWork() {
    _timer?.cancel();
    notifyListeners();
  }

  /// Immediately moves to the stand-alert phase.
  void skipToBreak() {
    _timer?.cancel();
    _completePhase();
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        _completePhase();
      }
    });
  }

  void _completePhase() {
    _timer?.cancel();
    if (_phase == PomodoroPhase.work) {
      _completedToday++;
      _cycleIndex++;
      HapticFeedback.mediumImpact();
      _phase = PomodoroPhase.standAlert;
      _timeRemaining = PomodoroPhase.standAlert.durationSeconds;
    } else if (_phase == PomodoroPhase.standAlert) {
      final isLongBreak = _cycleIndex % 4 == 0;
      _phase = isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      _timeRemaining = _phase.durationSeconds;
      _startTick();
    } else {
      _phase = PomodoroPhase.idle;
      _timeRemaining = 0;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
