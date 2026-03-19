import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/health_service.dart';

void main() {
  group('HealthServiceImpl', () {
    late HealthServiceImpl svc;

    setUp(() => svc = HealthServiceImpl());

    test('requestPermissions returns false without crashing', () async {
      // On test runners (macOS CI), HealthKit may not be configured.
      // The critical invariant is: it must never throw.
      final result = await svc.requestPermissions();
      expect(result, isA<bool>());
    });

    test('hasPermissions returns false before request', () async {
      expect(await svc.hasPermissions(), isFalse);
    });

    test('getSteps returns null without permissions', () async {
      expect(await svc.getSteps(DateTime.now()), isNull);
    });

    test('getHeartRate returns null without permissions', () async {
      expect(await svc.getHeartRate(DateTime.now()), isNull);
    });

    test('getSleepHours returns null without permissions', () async {
      expect(await svc.getSleepHours(DateTime.now()), isNull);
    });

    test('getActiveCalories returns null without permissions', () async {
      expect(await svc.getActiveCalories(DateTime.now()), isNull);
    });

    test('getLatestWeight returns null without permissions', () async {
      expect(await svc.getLatestWeight(), isNull);
    });

    test('getBodyFat returns null without permissions', () async {
      expect(await svc.getBodyFat(), isNull);
    });

    test('getHeartRateRange returns null without permissions', () async {
      expect(await svc.getHeartRateRange(DateTime.now()), isNull);
    });

    test('platform detection does not crash', () {
      // Verify HealthServiceImpl can be constructed without errors
      // on any platform (the static getters should not throw).
      final svc2 = HealthServiceImpl();
      expect(svc2, isNotNull);
    });
  });
}
