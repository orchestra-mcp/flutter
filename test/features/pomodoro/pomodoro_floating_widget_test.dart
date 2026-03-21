import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/features/pomodoro/pomodoro_floating_widget.dart';

void main() {
  group('PomodoroFloatingController', () {
    test('isVisible is false initially', () {
      expect(PomodoroFloatingController.isVisible, isFalse);
    });

    test('hide is safe to call when not visible', () {
      // Should not throw
      PomodoroFloatingController.hide();
      expect(PomodoroFloatingController.isVisible, isFalse);
    });
  });

  group('PomodoroState (used by floating widget)', () {
    test('timeDisplay formats MM:SS correctly', () {
      const s = PomodoroState(secondsRemaining: 25 * 60);
      expect(s.timeDisplay, '25:00');
    });

    test('timeDisplay pads single digits', () {
      const s = PomodoroState(secondsRemaining: 65);
      expect(s.timeDisplay, '01:05');
    });

    test('timeDisplay shows 00:00 at zero', () {
      const s = PomodoroState(secondsRemaining: 0);
      expect(s.timeDisplay, '00:00');
    });

    test('progress is 0 when idle', () {
      const s = PomodoroState(phase: PomodoroPhase.idle);
      expect(s.progress, 0.0);
    });

    test('progress is 0 at start of work phase', () {
      const s = PomodoroState(
        phase: PomodoroPhase.work,
        secondsRemaining: 25 * 60,
      );
      expect(s.progress, 0.0);
    });

    test('progress is 0.5 at halfway through work phase', () {
      const s = PomodoroState(
        phase: PomodoroPhase.work,
        secondsRemaining: (25 * 60) ~/ 2,
      );
      expect(s.progress, closeTo(0.5, 0.01));
    });

    test('progress is near 1.0 at end of work phase', () {
      const s = PomodoroState(
        phase: PomodoroPhase.work,
        secondsRemaining: 1,
      );
      expect(s.progress, greaterThan(0.99));
    });
  });

  group('PomodoroPhase', () {
    test('work duration is 25 minutes', () {
      expect(PomodoroPhase.work.durationSeconds, 25 * 60);
    });

    test('shortBreak duration is 5 minutes', () {
      expect(PomodoroPhase.shortBreak.durationSeconds, 5 * 60);
    });

    test('longBreak duration is 15 minutes', () {
      expect(PomodoroPhase.longBreak.durationSeconds, 15 * 60);
    });

    test('standAlert duration is 60 seconds', () {
      expect(PomodoroPhase.standAlert.durationSeconds, 60);
    });

    test('idle duration is 0', () {
      expect(PomodoroPhase.idle.durationSeconds, 0);
    });

    test('isActive is true for work, shortBreak, longBreak', () {
      expect(PomodoroPhase.work.isActive, isTrue);
      expect(PomodoroPhase.shortBreak.isActive, isTrue);
      expect(PomodoroPhase.longBreak.isActive, isTrue);
    });

    test('isActive is false for idle and standAlert', () {
      expect(PomodoroPhase.idle.isActive, isFalse);
      expect(PomodoroPhase.standAlert.isActive, isFalse);
    });

    test('each phase has a non-empty label', () {
      for (final phase in PomodoroPhase.values) {
        expect(phase.label, isNotEmpty);
      }
    });
  });

  group('PomodoroState.copyWith', () {
    test('preserves defaults', () {
      const original = PomodoroState();
      final copy = original.copyWith();
      expect(copy.phase, original.phase);
      expect(copy.secondsRemaining, original.secondsRemaining);
      expect(copy.isRunning, original.isRunning);
      expect(copy.completedToday, original.completedToday);
    });

    test('updates specified fields', () {
      const original = PomodoroState();
      final copy = original.copyWith(
        phase: PomodoroPhase.work,
        isRunning: true,
        completedToday: 3,
      );
      expect(copy.phase, PomodoroPhase.work);
      expect(copy.isRunning, isTrue);
      expect(copy.completedToday, 3);
      // Unchanged
      expect(copy.dailyTarget, original.dailyTarget);
    });
  });
}
