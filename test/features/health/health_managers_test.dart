import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/health/caffeine_manager.dart';
import 'package:orchestra/features/health/hydration_manager.dart';
import 'package:orchestra/features/health/pomodoro_manager.dart';

void main() {
  group('HydrationManager', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('starts at 0 ml', () {
      expect(container.read(hydrationProvider), 0);
    });

    test('log adds millilitres', () {
      container.read(hydrationProvider.notifier).log(250);
      expect(container.read(hydrationProvider), 250);
    });

    test('reset returns to 0', () {
      container.read(hydrationProvider.notifier).log(500);
      container.read(hydrationProvider.notifier).reset();
      expect(container.read(hydrationProvider), 0);
    });

    test('goal is 2000 ml', () {
      expect(container.read(hydrationProvider.notifier).goalMl, 2000);
    });
  });

  group('CaffeineManager', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('starts at 0 mg', () {
      expect(container.read(caffeineProvider), 0);
    });

    test('log adds milligrams', () {
      container.read(caffeineProvider.notifier).log(100);
      expect(container.read(caffeineProvider), 100);
    });

    test('isOverLimit is false under 400 mg', () {
      container.read(caffeineProvider.notifier).log(300);
      expect(container.read(caffeineProvider.notifier).isOverLimit, isFalse);
    });

    test('isOverLimit is true over 400 mg', () {
      container.read(caffeineProvider.notifier).log(450);
      expect(container.read(caffeineProvider.notifier).isOverLimit, isTrue);
    });
  });

  group('PomodoroManager', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial state is idle with 25 minutes remaining', () {
      final state = container.read(pomodoroProvider);
      expect(state.phase, PomodoroPhase.idle);
      expect(state.remainingSeconds, 25 * 60);
      expect(state.isRunning, isFalse);
      expect(state.completedSessions, 0);
    });

    test('reset returns to initial state', () {
      container.read(pomodoroProvider.notifier).start();
      container.read(pomodoroProvider.notifier).reset();
      final state = container.read(pomodoroProvider);
      expect(state.phase, PomodoroPhase.idle);
      expect(state.isRunning, isFalse);
    });
  });
}
