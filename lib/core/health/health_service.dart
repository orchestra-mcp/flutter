import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

/// Unified HealthKit (iOS/macOS) and Health Connect (Android) service.
///
/// On unsupported platforms every method returns `null` and the UI
/// displays a "Not available" placeholder.
abstract class HealthService {
  /// Request all required health data permissions.
  Future<bool> requestPermissions();

  /// Returns `true` if all required permissions have been granted.
  Future<bool> hasPermissions();

  /// Steps taken today (midnight → now).
  Future<int?> getSteps(DateTime date);

  /// Latest heart rate reading in bpm.
  Future<int?> getHeartRate(DateTime date);

  /// Total hours of sleep for the night of [date].
  Future<double?> getSleepHours(DateTime date);

  /// Active calories burned today in kcal.
  Future<double?> getActiveCalories(DateTime date);

  /// Latest body weight in kg.
  Future<double?> getLatestWeight();

  /// Latest body-fat percentage (0–100).
  Future<double?> getBodyFat();

  /// Min and max bpm for [date].
  Future<({int min, int max})?> getHeartRateRange(DateTime date);

  /// Latest blood oxygen saturation percentage (0–100).
  Future<double?> getBloodOxygen(DateTime date);

  /// Latest respiratory rate in breaths per minute.
  Future<double?> getRespiratoryRate(DateTime date);
}

// ---------------------------------------------------------------------------
// Real implementation using the `health` package
// ---------------------------------------------------------------------------

/// Uses HealthKit (iOS/macOS) and Health Connect (Android) via the `health`
/// package. Falls back gracefully when data is unavailable.
class HealthServiceImpl implements HealthService {
  HealthServiceImpl();

  final _health = Health();
  bool _permissionsGranted = false;

  /// All health types we'd like to read — filtered per-platform at runtime.
  static const _allTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESPIRATORY_RATE,
  ];

  /// Types that are only available on iOS / Android (not macOS desktop).
  static const _mobileOnlyTypes = {
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.BODY_FAT_PERCENTAGE,
  };

  /// Returns the subset of health types supported on the current platform.
  static List<HealthDataType> get _types {
    if (kIsWeb) return [];
    if (Platform.isMacOS) {
      // macOS HealthKit supports a limited subset — exclude mobile-only types.
      return _allTypes
          .where((t) => !_mobileOnlyTypes.contains(t))
          .toList();
    }
    return _allTypes;
  }

  static List<HealthDataAccess> get _permissions =>
      _types.map((_) => HealthDataAccess.READ).toList();

  /// Whether health is available on this platform at all.
  static bool get _isSupported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

  @override
  Future<bool> requestPermissions() async {
    if (!_isSupported || _types.isEmpty) {
      debugPrint('[HealthService] Platform not supported for health data');
      return false;
    }
    try {
      await _health.configure();

      final result = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      _permissionsGranted = result;
      debugPrint('[HealthService] requestPermissions → $_permissionsGranted');
      return _permissionsGranted;
    } catch (e) {
      debugPrint('[HealthService] requestPermissions error: $e');
      _permissionsGranted = false;
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (!_isSupported || _types.isEmpty) return false;
    try {
      final result = await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );
      _permissionsGranted = result ?? false;
      return _permissionsGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int?> getSteps(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final steps = await _health.getTotalStepsInInterval(midnight, date);
      return steps;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> getHeartRate(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: midnight,
        endTime: date,
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toInt();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getSleepHours(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final bedtime = DateTime(date.year, date.month, date.day - 1, 18);
      final wakeup = DateTime(date.year, date.month, date.day, 12);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: bedtime,
        endTime: wakeup,
      );
      if (data.isEmpty) return null;
      var totalMinutes = 0.0;
      for (final point in data) {
        totalMinutes +=
            point.dateTo.difference(point.dateFrom).inMinutes;
      }
      return totalMinutes / 60.0;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getActiveCalories(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: date,
      );
      if (data.isEmpty) return null;
      var total = 0.0;
      for (final point in data) {
        total += (point.value as NumericHealthValue).numericValue;
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getLatestWeight() async {
    if (!_permissionsGranted) return null;
    try {
      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getBodyFat() async {
    if (!_permissionsGranted) return null;
    try {
      final now = DateTime.now();
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BODY_FAT_PERCENTAGE],
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<({int min, int max})?> getHeartRateRange(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: midnight,
        endTime: date,
      );
      if (data.isEmpty) return null;
      final values = data
          .map((d) =>
              (d.value as NumericHealthValue).numericValue.toInt())
          .toList();
      values.sort();
      return (min: values.first, max: values.last);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getBloodOxygen(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: midnight,
        endTime: date,
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<double?> getRespiratoryRate(DateTime date) async {
    if (!_permissionsGranted) return null;
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.RESPIRATORY_RATE],
        startTime: midnight,
        endTime: date,
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthServiceImpl();
});
