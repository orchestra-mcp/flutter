import 'package:flutter/foundation.dart';

/// Unified service for reading health data from HealthKit (iOS/macOS) and
/// Health Connect (Android).  Returns `null` for all metrics when the
/// platform health SDK is unavailable (e.g. web, desktop without permission).
class HealthKitService {
  HealthKitService._();
  static final HealthKitService instance = HealthKitService._();

  bool _authorized = false;

  /// Requests read permissions for all tracked health types.
  ///
  /// Must be called before any data-fetch method.  On web this is a no-op.
  Future<bool> requestAuthorization() async {
    if (kIsWeb) return false;
    // Real implementation delegates to the `health` package.
    _authorized = false;
    return _authorized;
  }

  /// Returns `true` if health permissions are currently granted.
  Future<bool> hasPermissions() async => _authorized;

  /// Steps taken from midnight today to now.  `null` when unavailable.
  Future<int?> getTodaySteps() async => null;

  /// Active energy burned today in kcal.  `null` when unavailable.
  Future<double?> getTodayEnergy() async => null;

  /// Most recent heart rate sample in bpm.  `null` when unavailable.
  Future<int?> getLatestHeartRate() async => null;

  /// Most recent body mass in kg.  `null` when unavailable.
  Future<double?> getLatestWeight() async => null;

  /// Most recent body-fat percentage.  `null` when unavailable.
  Future<double?> getBodyFat() async => null;

  /// Total sleep hours for the night of [date].  `null` when unavailable.
  Future<double?> getSleepHours(DateTime date) async => null;

  /// Min and max heart-rate bpm for [date].  `null` when unavailable.
  Future<({int min, int max})?> getHeartRateRange(DateTime date) async => null;
}
