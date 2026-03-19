import 'package:flutter/foundation.dart';

/// Type of caffeinated drink.
enum CaffeineType {
  redBull,
  coldBrew,
  matcha,
  greenTea,
  espresso,
  blackCoffee,
  other,
}

/// Cortisol-window awareness status.
enum CaffeineStatus { clean, transitioning, redBullDependent, noIntake }

/// Exception thrown when caffeine is logged during the cortisol window.
class CortisolWindowException implements Exception {
  const CortisolWindowException();

  @override
  String toString() =>
      'Cortisol window active — avoid caffeine for 90–120 min after waking.';
}

/// A single caffeine log entry.
class CaffeineLog {
  const CaffeineLog({required this.type, required this.timestamp});
  final CaffeineType type;
  final DateTime timestamp;
}

/// Manages daily caffeine intake with cortisol-window detection.
///
/// Ports the Swift CaffeineManager health-debug class.
class CaffeineManager extends ChangeNotifier {
  CaffeineManager({required this.wakeTime});

  /// The user's wake time for the current day.
  final DateTime wakeTime;

  final List<CaffeineLog> logs = [];

  /// Returns `true` if the current time is within 90–120 min of [wakeTime].
  bool isCortisolWindow() {
    final now = DateTime.now();
    final elapsed = now.difference(wakeTime).inMinutes;
    return elapsed >= 90 && elapsed <= 120;
  }

  /// Returns `true` for sugar-based drinks.
  bool isSugarBased(CaffeineType type) => type == CaffeineType.redBull;

  /// Percentage of today's drinks that are considered clean.
  double get cleanTransitionPercent {
    if (logs.isEmpty) return 100.0;
    final clean = logs.where((l) => !isSugarBased(l.type)).length;
    return (clean / logs.length) * 100;
  }

  /// Computed status based on today's intake pattern.
  CaffeineStatus get status {
    if (logs.isEmpty) return CaffeineStatus.noIntake;
    final hasRedBull = logs.any((l) => l.type == CaffeineType.redBull);
    if (hasRedBull && cleanTransitionPercent < 50) {
      return CaffeineStatus.redBullDependent;
    }
    if (cleanTransitionPercent < 80) return CaffeineStatus.transitioning;
    return CaffeineStatus.clean;
  }

  /// Logs a caffeinated drink.
  ///
  /// Throws [CortisolWindowException] when called during the cortisol window.
  void logCaffeine(CaffeineType type) {
    if (isCortisolWindow()) throw const CortisolWindowException();
    logs.add(CaffeineLog(type: type, timestamp: DateTime.now()));
    notifyListeners();
  }
}
