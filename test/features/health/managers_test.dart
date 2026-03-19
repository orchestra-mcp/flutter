import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/health/managers/caffeine_manager.dart';
import 'package:orchestra/features/health/managers/hydration_manager.dart';
import 'package:orchestra/features/health/managers/pomodoro_manager.dart';

void main() {
  group('HydrationManager', () {
    test('starts at zero', () {
      final m = HydrationManager();
      expect(m.totalMl, 0);
      expect(m.logs, isEmpty);
    });

    test('logWater accumulates ml', () {
      final m = HydrationManager();
      m.logWater(250);
      expect(m.totalMl, 250);
      expect(m.logs.length, 1);
    });

    test('status is dehydrated below 50% of goal', () {
      final m = HydrationManager(dailyGoalMl: 2000);
      m.logWater(100);
      expect(m.status, HydrationStatus.dehydrated);
    });

    test('status is goalReached at 100%', () {
      final m = HydrationManager(dailyGoalMl: 500);
      m.logWater(500);
      expect(m.status, HydrationStatus.goalReached);
    });

    test('goutFlushRecommendation is true below 50%', () {
      final m = HydrationManager(dailyGoalMl: 2000);
      m.logWater(100);
      expect(m.goutFlushRecommendation, isTrue);
    });
  });

  group('CaffeineManager', () {
    test('starts with noIntake status', () {
      final m = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(m.status, CaffeineStatus.noIntake);
    });

    test('isSugarBased returns true for redBull only', () {
      final m = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(m.isSugarBased(CaffeineType.redBull), isTrue);
      expect(m.isSugarBased(CaffeineType.espresso), isFalse);
    });

    test('logCaffeine outside cortisol window succeeds', () {
      final m = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
      m.logCaffeine(CaffeineType.espresso);
      expect(m.logs.length, 1);
    });

    test('logCaffeine in cortisol window throws', () {
      final m = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(minutes: 95)),
      );
      expect(
        () => m.logCaffeine(CaffeineType.espresso),
        throwsA(isA<CortisolWindowException>()),
      );
    });

    test('cleanTransitionPercent is 100 for no logs', () {
      final m = CaffeineManager(
        wakeTime: DateTime.now().subtract(const Duration(hours: 4)),
      );
      expect(m.cleanTransitionPercent, 100.0);
    });
  });

  group('PomodoroManager', () {
    test('starts idle at zero', () {
      final m = PomodoroManager();
      expect(m.phase, PomodoroPhase.idle);
      expect(m.completedToday, 0);
      expect(m.cycleIndex, 0);
    });

    test('startWork moves to work phase', () {
      final m = PomodoroManager();
      m.startWork();
      expect(m.phase, PomodoroPhase.work);
      expect(m.timeRemaining, 25 * 60);
      m.dispose();
    });

    test('pauseWork stops without state change', () {
      final m = PomodoroManager();
      m.startWork();
      m.pauseWork();
      expect(m.phase, PomodoroPhase.work);
      m.dispose();
    });

    test('PomodoroPhase enum has 5 values', () {
      expect(PomodoroPhase.values.length, 5);
    });
  });
}
