import 'package:flutter/foundation.dart';

/// Hydration tracking status.
enum HydrationStatus { onTrack, slightlyBehind, dehydrated, goalReached }

/// A single hydration log entry.
class HydrationLog {
  const HydrationLog({required this.ml, required this.timestamp});
  final int ml;
  final DateTime timestamp;
}

/// Manages daily water intake tracking.
///
/// Ports the Swift HydrationManager health-debug class.
class HydrationManager extends ChangeNotifier {
  HydrationManager({this.dailyGoalMl = 2500});

  final int dailyGoalMl;

  int _totalMl = 0;
  int get totalMl => _totalMl;

  final List<HydrationLog> logs = [];

  DateTime? _lastLogTime;

  static const _cooldownSeconds = 30;
  static const _maxDailyMl = 5000;

  /// Logs [ml] of water, subject to a 30-second cooldown and 5000 ml daily cap.
  void logWater(int ml) {
    final now = DateTime.now();
    if (_lastLogTime != null &&
        now.difference(_lastLogTime!).inSeconds < _cooldownSeconds) {
      return;
    }
    final capped = (_totalMl + ml).clamp(0, _maxDailyMl);
    final actual = capped - _totalMl;
    if (actual <= 0) return;
    _totalMl = capped;
    logs.add(HydrationLog(ml: actual, timestamp: now));
    _lastLogTime = now;
    notifyListeners();
  }

  /// Computed hydration status relative to goal.
  HydrationStatus get status {
    final ratio = _totalMl / dailyGoalMl;
    if (ratio >= 1.0) return HydrationStatus.goalReached;
    if (ratio >= 0.75) return HydrationStatus.onTrack;
    if (ratio >= 0.5) return HydrationStatus.slightlyBehind;
    return HydrationStatus.dehydrated;
  }

  /// Human-readable status message.
  String get statusMessage {
    switch (status) {
      case HydrationStatus.goalReached:
        return 'Goal reached! Great work.';
      case HydrationStatus.onTrack:
        return 'On track — keep it up.';
      case HydrationStatus.slightlyBehind:
        return 'Slightly behind — try to drink more.';
      case HydrationStatus.dehydrated:
        return 'Dehydrated — drink water now.';
    }
  }

  /// Whether to recommend extra water for gout prevention.
  bool get goutFlushRecommendation => _totalMl < dailyGoalMl * 0.5;
}
