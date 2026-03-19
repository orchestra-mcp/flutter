import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _NotificationIds {
  static const int hydration = 1000;
  static const int pomodoroBreak = 2000;
  static const int pomodoroStart = 2001;
  static const int shutdownLead = 3000;
  static const int shutdownMain = 3001;
  static const int weight = 4000;
  static const int meal = 5000;
  static const int coffee = 6000;
  static const int movement = 7000;
  static const int heartHigh = 8000;
  static const int heartLow = 8001;
  static const int hygiene = 9000;
  static const int gerd = 10000;
}

class _Channels {
  static const String hydration = 'health_hydration';
  static const String pomodoro = 'health_pomodoro';
  static const String shutdown = 'health_shutdown';
  static const String weight = 'health_weight';
  static const String meal = 'health_meal';
  static const String coffee = 'health_coffee';
  static const String movement = 'health_movement';
  static const String heart = 'health_heart';
  static const String hygiene = 'health_hygiene';
  static const String gerd = 'health_gerd';
}

/// Service for scheduling and managing local health-related notifications.
///
/// Handles hydration reminders, pomodoro alerts, shutdown routines, weight
/// check-ins, meal logging, coffee cutoff, movement breaks, heart rate alerts,
/// hygiene reminders, and GERD warnings.
///
/// Usage:
/// ```dart
/// final service = HealthNotificationService.instance;
/// await service.initialize();
/// await service.scheduleHydrationReminder(intervalMinutes: 45);
/// await service.schedulePomodoroBreak(afterMinutes: 25);
/// await service.scheduleShutdownReminder(shutdownTime: TimeOfDay(hour: 22, minute: 0));
/// await service.cancelAll();
/// ```
class HealthNotificationService {
  HealthNotificationService._();

  /// Constructor for testing — allows subclasses to override scheduling methods.
  @visibleForTesting
  HealthNotificationService.testable();

  /// Singleton instance.
  static final HealthNotificationService instance =
      HealthNotificationService._();

  /// Route path from the last tapped notification, consumed by the router.
  static String? pendingDeepLink;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Whether the notification service has been initialized.
  bool get isInitialized => _initialized;

  /// Initialize the notification service.
  ///
  /// Must be called once before scheduling any notifications. Requests
  /// notification permissions on platforms that require them.
  ///
  /// Returns `true` if permissions were granted.
  Future<bool> initialize() async {
    if (_initialized) return true;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    final granted = await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createAndroidChannels();

    _initialized = granted ?? false;
    debugPrint('[HealthNotif] initialized, granted=$_initialized');
    return _initialized;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      pendingDeepLink = payload;
      debugPrint('[HealthNotif] deep link stored: $payload');
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channels = <AndroidNotificationChannel>[
      const AndroidNotificationChannel(
        _Channels.hydration,
        'Hydration Reminders',
        description: 'Reminders to drink water throughout the day',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _Channels.pomodoro,
        'Pomodoro Alerts',
        description: 'Break and focus session notifications',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _Channels.shutdown,
        'Shutdown Routine',
        description: 'Evening wind-down routine reminders',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _Channels.weight,
        'Weight Check-In',
        description: 'Daily weight logging reminders',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _Channels.meal,
        'Meal Logging',
        description: 'Reminders to log meals',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _Channels.coffee,
        'Coffee Cutoff',
        description: 'Caffeine cutoff time alerts',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _Channels.movement,
        'Movement Reminders',
        description: 'Stand up and stretch reminders',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _Channels.heart,
        'Heart Rate Alerts',
        description: 'Heart rate threshold warnings',
        importance: Importance.max,
      ),
      const AndroidNotificationChannel(
        _Channels.hygiene,
        'Hygiene Check-In',
        description: 'Personal hygiene reminders',
        importance: Importance.low,
      ),
      const AndroidNotificationChannel(
        _Channels.gerd,
        'GERD Warning',
        description: 'GERD shutdown warning alerts',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
    debugPrint('[HealthNotif] ${channels.length} Android channels created');
  }

  // ---------------------------------------------------------------------------
  // Hydration
  // ---------------------------------------------------------------------------

  /// Schedules a recurring hydration reminder every [intervalMinutes] minutes.
  ///
  /// Call [cancelHydrationReminders] to stop the recurring schedule.
  Future<void> scheduleHydrationReminder({
    int intervalMinutes = 45,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    await cancelHydrationReminders();
    debugPrint(
        '[HealthNotif] scheduling hydration every ${intervalMinutes}m');

    await _plugin.periodicallyShowWithDuration(
      id: _NotificationIds.hydration,
      title: 'Time to hydrate',
      body: 'Drink a glass of water to stay on track.',
      repeatDurationInterval: Duration(minutes: intervalMinutes),
      notificationDetails: _notificationDetails(
        _Channels.hydration,
        'Hydration Reminders',
        importance: Importance.high,
      ),
      payload: '/health/hydration',
    );
  }

  /// Cancels all pending hydration reminders.
  Future<void> cancelHydrationReminders() async {
    await _plugin.cancel(id: _NotificationIds.hydration);
  }

  // ---------------------------------------------------------------------------
  // Pomodoro
  // ---------------------------------------------------------------------------

  /// Schedules a one-shot notification for a pomodoro break.
  ///
  /// Fires [afterMinutes] minutes from now. [isLongBreak] controls whether
  /// the notification says "short break" or "long break".
  Future<void> schedulePomodoroBreak({
    required int afterMinutes,
    bool isLongBreak = false,
  }) async {
    final scheduledDate = _fromNow(afterMinutes);
    final title = isLongBreak ? 'Long break time' : 'Short break time';
    debugPrint(
        '[HealthNotif] pomodoro break in ${afterMinutes}m (long=$isLongBreak)');

    await _plugin.zonedSchedule(
      id: _NotificationIds.pomodoroBreak,
      title: title,
      body: 'Stand up, stretch, and rest your eyes.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(
        _Channels.pomodoro,
        'Pomodoro Alerts',
        importance: Importance.high,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/health/pomodoro',
    );
  }

  /// Schedules a notification for when the pomodoro work session should start.
  ///
  /// Fires [afterMinutes] minutes from now.
  Future<void> schedulePomodoroWorkStart({
    required int afterMinutes,
  }) async {
    final scheduledDate = _fromNow(afterMinutes);
    debugPrint('[HealthNotif] pomodoro work start in ${afterMinutes}m');

    await _plugin.zonedSchedule(
      id: _NotificationIds.pomodoroStart,
      title: 'Break is over',
      body: 'Time to focus! Start your next pomodoro.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(
        _Channels.pomodoro,
        'Pomodoro Alerts',
        importance: Importance.high,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/health/pomodoro',
    );
  }

  /// Cancels all pending pomodoro-related notifications.
  Future<void> cancelPomodoroNotifications() async {
    await _plugin.cancel(id: _NotificationIds.pomodoroBreak);
    await _plugin.cancel(id: _NotificationIds.pomodoroStart);
  }

  // ---------------------------------------------------------------------------
  // Shutdown
  // ---------------------------------------------------------------------------

  /// Schedules daily shutdown reminders.
  ///
  /// Fires a lead notification [leadMinutes] before [shutdownTime] and a main
  /// notification at [shutdownTime]. Both repeat daily.
  Future<void> scheduleShutdownReminder({
    required TimeOfDay shutdownTime,
    int leadMinutes = 30,
  }) async {
    await cancelShutdownReminders();

    final adjustedLead = _adjustTime(
      shutdownTime.hour,
      shutdownTime.minute - leadMinutes,
    );
    final leadDate = _nextInstanceOfTime(adjustedLead.$1, adjustedLead.$2);

    debugPrint(
        '[HealthNotif] shutdown lead at ${adjustedLead.$1}:${adjustedLead.$2}, '
        'main at ${shutdownTime.hour}:${shutdownTime.minute}');

    await _plugin.zonedSchedule(
      id: _NotificationIds.shutdownLead,
      title: 'Shutdown approaching',
      body: 'Your shutdown routine starts in $leadMinutes minutes.',
      scheduledDate: leadDate,
      notificationDetails: _notificationDetails(
        _Channels.shutdown,
        'Shutdown Routine',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/health/shutdown',
    );

    final mainDate =
        _nextInstanceOfTime(shutdownTime.hour, shutdownTime.minute);

    await _plugin.zonedSchedule(
      id: _NotificationIds.shutdownMain,
      title: 'Time to shut down',
      body: 'Begin your evening wind-down routine now.',
      scheduledDate: mainDate,
      notificationDetails: _notificationDetails(
        _Channels.shutdown,
        'Shutdown Routine',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/health/shutdown',
    );
  }

  /// Cancels all pending shutdown reminders.
  Future<void> cancelShutdownReminders() async {
    await _plugin.cancel(id: _NotificationIds.shutdownLead);
    await _plugin.cancel(id: _NotificationIds.shutdownMain);
  }

  // ---------------------------------------------------------------------------
  // Weight
  // ---------------------------------------------------------------------------

  /// Schedules a daily weight check-in reminder at the given time.
  Future<void> scheduleWeightCheckIn({
    required int hour,
    required int minute,
  }) async {
    await cancelWeightReminders();
    final date = _nextInstanceOfTime(hour, minute);
    debugPrint('[HealthNotif] weight check-in at $hour:$minute daily');

    await _plugin.zonedSchedule(
      id: _NotificationIds.weight,
      title: 'Weight check-in',
      body: 'Step on the scale and log your weight.',
      scheduledDate: date,
      notificationDetails: _notificationDetails(
        _Channels.weight,
        'Weight Check-In',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/health/weight',
    );
  }

  /// Cancels pending weight check-in reminders.
  Future<void> cancelWeightReminders() async {
    await _plugin.cancel(id: _NotificationIds.weight);
  }

  // ---------------------------------------------------------------------------
  // Meal
  // ---------------------------------------------------------------------------

  /// Shows an immediate meal logging reminder.
  Future<void> scheduleMealReminder() async {
    debugPrint('[HealthNotif] showing meal reminder now');

    await _plugin.show(
      id: _NotificationIds.meal,
      title: 'Log your meal',
      body: 'Record what you ate to keep your nutrition on track.',
      notificationDetails: _notificationDetails(
        _Channels.meal,
        'Meal Logging',
      ),
      payload: '/health/meal',
    );
  }

  /// Cancels pending meal reminders.
  Future<void> cancelMealReminders() async {
    await _plugin.cancel(id: _NotificationIds.meal);
  }

  // ---------------------------------------------------------------------------
  // Coffee
  // ---------------------------------------------------------------------------

  /// Schedules a daily coffee cutoff alert at the given time.
  Future<void> scheduleCoffeeCutoff({
    required int hour,
    required int minute,
  }) async {
    await cancelCoffeeReminders();
    final date = _nextInstanceOfTime(hour, minute);
    debugPrint('[HealthNotif] coffee cutoff at $hour:$minute daily');

    await _plugin.zonedSchedule(
      id: _NotificationIds.coffee,
      title: 'Coffee cutoff',
      body: 'No more caffeine after this point for better sleep.',
      scheduledDate: date,
      notificationDetails: _notificationDetails(
        _Channels.coffee,
        'Coffee Cutoff',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/health/coffee',
    );
  }

  /// Cancels pending coffee cutoff reminders.
  Future<void> cancelCoffeeReminders() async {
    await _plugin.cancel(id: _NotificationIds.coffee);
  }

  // ---------------------------------------------------------------------------
  // Movement
  // ---------------------------------------------------------------------------

  /// Schedules periodic movement/stretch reminders.
  Future<void> scheduleMovementReminder({int intervalMinutes = 60}) async {
    await cancelMovementReminders();
    debugPrint('[HealthNotif] movement every ${intervalMinutes}m');

    await _plugin.periodicallyShowWithDuration(
      id: _NotificationIds.movement,
      title: 'Time to move',
      body: 'Stand up, stretch, and take a short walk.',
      repeatDurationInterval: Duration(minutes: intervalMinutes),
      notificationDetails: _notificationDetails(
        _Channels.movement,
        'Movement Reminders',
      ),
      payload: '/health/movement',
    );
  }

  /// Cancels pending movement reminders.
  Future<void> cancelMovementReminders() async {
    await _plugin.cancel(id: _NotificationIds.movement);
  }

  // ---------------------------------------------------------------------------
  // Heart Rate
  // ---------------------------------------------------------------------------

  /// Shows an immediate heart rate threshold alert.
  Future<void> showHeartRateAlert({
    required bool isHigh,
    required int bpm,
  }) async {
    final id =
        isHigh ? _NotificationIds.heartHigh : _NotificationIds.heartLow;
    final title =
        isHigh ? 'High heart rate detected' : 'Low heart rate detected';
    final body =
        'Your heart rate is $bpm bpm. Consider resting and monitoring.';
    debugPrint(
        '[HealthNotif] heart rate alert: ${isHigh ? "high" : "low"} $bpm bpm');

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(
        _Channels.heart,
        'Heart Rate Alerts',
        importance: Importance.max,
      ),
      payload: '/health/heart',
    );
  }

  /// Cancels pending heart rate alerts.
  Future<void> cancelHeartRateAlerts() async {
    await _plugin.cancel(id: _NotificationIds.heartHigh);
    await _plugin.cancel(id: _NotificationIds.heartLow);
  }

  // ---------------------------------------------------------------------------
  // Hygiene
  // ---------------------------------------------------------------------------

  /// Schedules a hygiene check-in reminder [delayDays] days from now.
  Future<void> scheduleHygieneReminder({required int delayDays}) async {
    await cancelHygieneReminders();
    final scheduledDate = _fromNow(delayDays * 24 * 60);
    debugPrint('[HealthNotif] hygiene reminder in $delayDays days');

    await _plugin.zonedSchedule(
      id: _NotificationIds.hygiene,
      title: 'Hygiene check-in',
      body: 'Time for your personal hygiene routine.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(
        _Channels.hygiene,
        'Hygiene Check-In',
        importance: Importance.low,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '/health/hygiene',
    );
  }

  /// Cancels pending hygiene reminders.
  Future<void> cancelHygieneReminders() async {
    await _plugin.cancel(id: _NotificationIds.hygiene);
  }

  // ---------------------------------------------------------------------------
  // GERD
  // ---------------------------------------------------------------------------

  /// Schedules a daily GERD shutdown warning [leadMinutes] before [shutdownTime].
  Future<void> scheduleGerdWarning({
    required TimeOfDay shutdownTime,
    int leadMinutes = 30,
  }) async {
    await cancelGerdWarning();

    final adjusted = _adjustTime(
      shutdownTime.hour,
      shutdownTime.minute - leadMinutes,
    );
    final date = _nextInstanceOfTime(adjusted.$1, adjusted.$2);
    debugPrint(
        '[HealthNotif] GERD warning at ${adjusted.$1}:${adjusted.$2} daily');

    await _plugin.zonedSchedule(
      id: _NotificationIds.gerd,
      title: 'GERD warning',
      body: 'Stop eating now to avoid reflux before bed.',
      scheduledDate: date,
      notificationDetails: _notificationDetails(
        _Channels.gerd,
        'GERD Warning',
        importance: Importance.high,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/health/gerd',
    );
  }

  /// Cancels pending GERD warnings.
  Future<void> cancelGerdWarning() async {
    await _plugin.cancel(id: _NotificationIds.gerd);
  }

  // ---------------------------------------------------------------------------
  // Global
  // ---------------------------------------------------------------------------

  /// Cancels all pending health notifications across all channels.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[HealthNotif] all notifications cancelled');
  }

  /// Disposes the notification service and cancels all pending notifications.
  Future<void> dispose() async {
    await cancelAll();
    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  AndroidNotificationDetails _androidDetails(
    String channelId,
    String channelName, {
    Importance importance = Importance.defaultImportance,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelName,
      importance: importance,
      priority: importance == Importance.max || importance == Importance.high
          ? Priority.high
          : Priority.defaultPriority,
      groupKey: channelId,
    );
  }

  NotificationDetails _notificationDetails(
    String channelId,
    String channelName, {
    Importance importance = Importance.defaultImportance,
  }) {
    return NotificationDetails(
      android: _androidDetails(channelId, channelName, importance: importance),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _fromNow(int minutes) {
    return tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
  }

  (int, int) _adjustTime(int hour, int minute) {
    var h = hour;
    var m = minute;
    while (m < 0) {
      m += 60;
      h -= 1;
    }
    while (m >= 60) {
      m -= 60;
      h += 1;
    }
    h = h % 24;
    if (h < 0) h += 24;
    return (h, m);
  }
}
