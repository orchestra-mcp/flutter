import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/health/health_notification_service.dart';
import 'package:orchestra/features/health/notification_scheduler.dart';

/// A fake [HealthNotificationService] that records calls instead of firing
/// real notifications.
class FakeHealthNotificationService extends HealthNotificationService {
  FakeHealthNotificationService() : super.testable();

  final List<String> calls = [];

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }

  @override
  Future<void> scheduleHydrationReminder({
    int intervalMinutes = 45,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    calls.add('hydration:$intervalMinutes');
  }

  @override
  Future<void> scheduleShutdownReminder({
    required TimeOfDay shutdownTime,
    int leadMinutes = 30,
  }) async {
    calls.add('shutdown:${shutdownTime.hour}:${shutdownTime.minute}');
  }

  @override
  Future<void> scheduleGerdWarning({
    required TimeOfDay shutdownTime,
    int leadMinutes = 30,
  }) async {
    calls.add('gerd:${shutdownTime.hour}:${shutdownTime.minute}:$leadMinutes');
  }

  @override
  Future<void> scheduleWeightCheckIn({
    required int hour,
    required int minute,
  }) async {
    calls.add('weight:$hour:$minute');
  }

  @override
  Future<void> scheduleHygieneReminder({required int delayDays}) async {
    calls.add('hygiene:$delayDays');
  }

  @override
  Future<void> scheduleCoffeeCutoff({
    required int hour,
    required int minute,
  }) async {
    calls.add('coffee:$hour:$minute');
  }

  @override
  Future<void> scheduleMovementReminder({int intervalMinutes = 60}) async {
    calls.add('movement:$intervalMinutes');
  }
}

void main() {
  group('NotificationScheduler', () {
    late FakeHealthNotificationService fakeService;
    late NotificationScheduler scheduler;

    setUp(() {
      fakeService = FakeHealthNotificationService();
      scheduler = NotificationScheduler(fakeService);
    });

    test('cancels all notifications before syncing', () async {
      await scheduler.syncFromProfile({});
      expect(fakeService.calls.first, 'cancelAll');
    });

    test('schedules hydration when enabled', () async {
      await scheduler.syncFromProfile({
        'hydrationAlertEnabled': true,
        'hydrationAlertGapMinutes': 90,
      });

      expect(fakeService.calls, contains('hydration:90'));
    });

    test('does not schedule hydration when disabled', () async {
      await scheduler.syncFromProfile({
        'hydrationAlertEnabled': false,
      });

      expect(
        fakeService.calls.where((c) => c.startsWith('hydration')),
        isEmpty,
      );
    });

    test('schedules weight check-in when enabled', () async {
      await scheduler.syncFromProfile({
        'weightAlertEnabled': true,
        'weightAlertHour': 7,
        'weightAlertMinute': 15,
      });

      expect(fakeService.calls, contains('weight:7:15'));
    });

    test('schedules hygiene reminder when enabled', () async {
      await scheduler.syncFromProfile({
        'hygieneAlertEnabled': true,
        'hygieneAlertDelayDays': 3,
      });

      expect(fakeService.calls, contains('hygiene:3'));
    });

    test('schedules coffee cutoff when enabled', () async {
      await scheduler.syncFromProfile({
        'coffeeAlertEnabled': true,
        'coffeeAlertHour': 14,
        'coffeeAlertMinute': 30,
      });

      expect(fakeService.calls, contains('coffee:14:30'));
    });

    test('schedules movement when enabled', () async {
      await scheduler.syncFromProfile({
        'movementAlertEnabled': true,
        'movementAlertIntervalMinutes': 45,
      });

      expect(fakeService.calls, contains('movement:45'));
    });

    test('schedules shutdown from bedtime minus window', () async {
      await scheduler.syncFromProfile({
        'sleepBedtimeHour': 23,
        'sleepBedtimeMinute': 0,
        'shutdownWindowHours': 2,
      });

      // 23:00 - 2 hours = 21:00
      expect(fakeService.calls, contains('shutdown:21:0'));
    });

    test('schedules shutdown wrapping around midnight', () async {
      await scheduler.syncFromProfile({
        'sleepBedtimeHour': 1,
        'sleepBedtimeMinute': 0,
        'shutdownWindowHours': 3,
      });

      // 01:00 - 3 hours = 22:00
      expect(fakeService.calls, contains('shutdown:22:0'));
    });

    test('schedules GERD warning before shutdown', () async {
      await scheduler.syncFromProfile({
        'sleepBedtimeHour': 23,
        'sleepBedtimeMinute': 0,
        'shutdownWindowHours': 2,
        'gerdShutdownLeadMinutes': 30,
      });

      // Shutdown at 21:00, GERD at 30 min before = scheduleGerdWarning called
      expect(
        fakeService.calls.where((c) => c.startsWith('gerd:')),
        isNotEmpty,
      );
    });

    test('uses defaults when profile is empty', () async {
      await scheduler.syncFromProfile({});

      // Should still schedule shutdown with defaults (23:00 - 2h = 21:00)
      expect(fakeService.calls, contains('shutdown:21:0'));
      // Should not schedule disabled alerts
      expect(
        fakeService.calls.where((c) => c.startsWith('hydration')),
        isEmpty,
      );
      expect(
        fakeService.calls.where((c) => c.startsWith('weight')),
        isEmpty,
      );
    });

    test('schedules all enabled categories in one sync', () async {
      await scheduler.syncFromProfile({
        'weightAlertEnabled': true,
        'weightAlertHour': 8,
        'weightAlertMinute': 0,
        'hygieneAlertEnabled': true,
        'hygieneAlertDelayDays': 2,
        'coffeeAlertEnabled': true,
        'coffeeAlertHour': 15,
        'coffeeAlertMinute': 0,
        'hydrationAlertEnabled': true,
        'hydrationAlertGapMinutes': 60,
        'movementAlertEnabled': true,
        'movementAlertIntervalMinutes': 60,
        'sleepBedtimeHour': 22,
        'sleepBedtimeMinute': 30,
        'shutdownWindowHours': 2,
        'gerdShutdownLeadMinutes': 20,
      });

      expect(fakeService.calls, contains('cancelAll'));
      expect(fakeService.calls, contains('weight:8:0'));
      expect(fakeService.calls, contains('hygiene:2'));
      expect(fakeService.calls, contains('coffee:15:0'));
      expect(fakeService.calls, contains('hydration:60'));
      expect(fakeService.calls, contains('movement:60'));
      expect(fakeService.calls.where((c) => c.startsWith('shutdown')), isNotEmpty);
      expect(fakeService.calls.where((c) => c.startsWith('gerd')), isNotEmpty);
    });
  });
}
