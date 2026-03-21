import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/providers/health_provider.dart';
import 'package:orchestra/features/health/health_notification_service.dart';

/// Reads the user's health profile settings and schedules or cancels
/// notifications accordingly.
///
/// This is a plain service class (not a widget). It bridges the gap between
/// the profile map returned by `healthProfileProvider` and the concrete
/// scheduling calls on [HealthNotificationService].
///
/// Typical usage through Riverpod:
///
/// ```dart
/// // One-shot sync (e.g. on app startup):
/// ref.read(notificationSyncProvider);
///
/// // Auto-sync whenever the health profile changes:
/// ref.watch(notificationSyncProvider);
/// ```
class NotificationScheduler {
  NotificationScheduler(this._service);

  final HealthNotificationService _service;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Cancels every pending health notification and re-schedules them based on
  /// the values in [profile].
  ///
  /// This is the single entry-point that the Riverpod sync provider calls
  /// whenever the health profile changes.
  Future<void> syncFromProfile(Map<String, dynamic> profile) async {
    debugPrint('[NotifScheduler] Syncing notifications from profile');

    // Wipe the slate so removed/disabled alerts do not linger.
    await _service.cancelAll();

    // Schedule each category independently.
    await _scheduleWeight(profile);
    await _scheduleHygiene(profile);
    _logPomodoroAlerts(profile);
    await _scheduleMeal(profile);
    await _scheduleCoffee(profile);
    await _scheduleHydration(profile);
    await _scheduleMovement(profile);
    await _scheduleShutdown(profile);
    await _scheduleGerd(profile);

    debugPrint('[NotifScheduler] Sync complete');
  }

  // ---------------------------------------------------------------------------
  // Private schedulers
  // ---------------------------------------------------------------------------

  /// Weight check reminder -- fires daily at the configured hour/minute.
  Future<void> _scheduleWeight(Map<String, dynamic> profile) async {
    if (!_bool(profile, 'weightAlertEnabled')) return;

    final hour = _int(profile, 'weightAlertHour', 8);
    final minute = _int(profile, 'weightAlertMinute', 0);

    await _service.scheduleWeightCheckIn(hour: hour, minute: minute);
    debugPrint(
      '[NotifScheduler] Weight alert at $hour:${minute.toString().padLeft(2, '0')}',
    );
  }

  /// Hygiene reminder -- fires after the configured delay in days.
  Future<void> _scheduleHygiene(Map<String, dynamic> profile) async {
    if (!_bool(profile, 'hygieneAlertEnabled')) return;

    final delayDays = _int(profile, 'hygieneAlertDelayDays', 1);

    await _service.scheduleHygieneReminder(delayDays: delayDays);
    debugPrint('[NotifScheduler] Hygiene alert in $delayDays day(s)');
  }

  /// Pomodoro start/end alerts are managed by the PomodoroManager at runtime,
  /// not by this scheduler. We only log whether they are enabled so the
  /// manager knows to fire lead-time notifications.
  void _logPomodoroAlerts(Map<String, dynamic> profile) {
    final startEnabled = _bool(profile, 'pomodoroStartAlertEnabled');
    final endEnabled = _bool(profile, 'pomodoroEndAlertEnabled');

    if (startEnabled) {
      final leadMin = _int(profile, 'pomodoroStartLeadMinutes', 5);
      debugPrint(
        '[NotifScheduler] Pomodoro start alert enabled -- '
        '$leadMin min lead',
      );
    }

    if (endEnabled) {
      final leadMin = _int(profile, 'pomodoroEndLeadMinutes', 5);
      debugPrint(
        '[NotifScheduler] Pomodoro end alert enabled -- '
        '$leadMin min lead',
      );
    }
  }

  /// Meal reminder -- enables meal logging notifications.
  Future<void> _scheduleMeal(Map<String, dynamic> profile) async {
    if (!_bool(profile, 'mealReminderEnabled')) return;

    debugPrint('[NotifScheduler] Meal reminders enabled');
    // Meal reminders are triggered contextually (e.g., after meal times),
    // not on a fixed schedule. The flag is read by the health screen.
  }

  /// Coffee cutoff alert -- fires daily at the configured hour/minute.
  Future<void> _scheduleCoffee(Map<String, dynamic> profile) async {
    if (!_bool(profile, 'coffeeAlertEnabled')) return;

    final hour = _int(profile, 'coffeeAlertHour', 14);
    final minute = _int(profile, 'coffeeAlertMinute', 0);

    await _service.scheduleCoffeeCutoff(hour: hour, minute: minute);
    debugPrint(
      '[NotifScheduler] Coffee cutoff at $hour:${minute.toString().padLeft(2, '0')}',
    );
  }

  /// Hydration reminders -- periodic with the configured gap.
  Future<void> _scheduleHydration(Map<String, dynamic> profile) async {
    if (!_bool(profile, 'hydrationAlertEnabled')) return;

    final gapMinutes = _int(profile, 'hydrationAlertGapMinutes', 60);

    await _service.scheduleHydrationReminder(intervalMinutes: gapMinutes);

    debugPrint(
      '[NotifScheduler] Hydration reminders enabled -- '
      'every $gapMinutes min',
    );
  }

  /// Movement reminders -- periodic with the configured interval.
  Future<void> _scheduleMovement(Map<String, dynamic> profile) async {
    if (!_bool(profile, 'movementAlertEnabled')) return;

    final intervalMinutes = _int(profile, 'movementAlertIntervalMinutes', 60);

    await _service.scheduleMovementReminder(intervalMinutes: intervalMinutes);
    debugPrint('[NotifScheduler] Movement every $intervalMinutes min');
  }

  /// Shutdown routine reminder -- computed from bedtime minus the window.
  ///
  /// For example, bedtime 23:00 with a 2-hour window means the shutdown
  /// notification fires at 21:00.
  Future<void> _scheduleShutdown(Map<String, dynamic> profile) async {
    final bedtimeHour = _int(profile, 'sleepBedtimeHour', 23);
    final bedtimeMinute = _int(profile, 'sleepBedtimeMinute', 0);
    final windowHours = _int(profile, 'shutdownWindowHours', 2);

    final shutdownTime = _subtractHours(
      TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute),
      windowHours,
    );

    await _service.scheduleShutdownReminder(shutdownTime: shutdownTime);

    debugPrint(
      '[NotifScheduler] Shutdown reminder at '
      '${shutdownTime.hour}:${shutdownTime.minute.toString().padLeft(2, '0')} '
      '($windowHours hr before bedtime)',
    );
  }

  /// GERD pre-shutdown warning -- fires [gerdShutdownLeadMinutes] before the
  /// computed shutdown time so the user can stop eating.
  Future<void> _scheduleGerd(Map<String, dynamic> profile) async {
    final bedtimeHour = _int(profile, 'sleepBedtimeHour', 23);
    final bedtimeMinute = _int(profile, 'sleepBedtimeMinute', 0);
    final windowHours = _int(profile, 'shutdownWindowHours', 2);
    final gerdLead = _int(profile, 'gerdShutdownLeadMinutes', 30);

    final shutdownTime = _subtractHours(
      TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute),
      windowHours,
    );

    final gerdTime = _subtractMinutes(shutdownTime, gerdLead);

    await _service.scheduleGerdWarning(
      shutdownTime: shutdownTime,
      leadMinutes: gerdLead,
    );

    debugPrint(
      '[NotifScheduler] GERD warning at '
      '${gerdTime.hour}:${gerdTime.minute.toString().padLeft(2, '0')} '
      '($gerdLead min before shutdown)',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Reads an [int] from [profile], falling back to [fallback].
  int _int(Map<String, dynamic> profile, String key, int fallback) {
    final value = profile[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  /// Reads a [bool] from [profile], defaulting to `false`.
  bool _bool(Map<String, dynamic> profile, String key) {
    final value = profile[key];
    if (value is bool) return value;
    return false;
  }

  /// Returns a [TimeOfDay] that is [hours] earlier than [time], wrapping
  /// around midnight when necessary.
  TimeOfDay _subtractHours(TimeOfDay time, int hours) {
    final totalMinutes = time.hour * 60 + time.minute - hours * 60;
    final wrapped = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;
    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
  }

  /// Returns a [TimeOfDay] that is [minutes] earlier than [time], wrapping
  /// around midnight when necessary.
  TimeOfDay _subtractMinutes(TimeOfDay time, int minutes) {
    final totalMinutes = time.hour * 60 + time.minute - minutes;
    final wrapped = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;
    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
  }
}

// =============================================================================
// Riverpod providers
// =============================================================================

/// Provides a [NotificationScheduler] backed by the singleton
/// [HealthNotificationService].
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(HealthNotificationService.instance);
});

/// Automatically syncs notification schedules whenever the health profile
/// changes.
///
/// Watching this provider from a top-level widget (e.g. the app shell) ensures
/// that notifications stay in sync with the user's latest settings without
/// requiring manual refresh calls.
final notificationSyncProvider = FutureProvider<void>((ref) async {
  final scheduler = ref.read(notificationSchedulerProvider);
  final rows = await ref.read(healthProfileProvider.future);
  if (rows.isEmpty) return;
  await scheduler.syncFromProfile(rows.first);
});
