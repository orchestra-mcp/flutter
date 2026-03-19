import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks daily caffeine intake in milligrams.
class CaffeineManager extends Notifier<int> {
  static const int _safeLimit = 400; // mg per day

  @override
  int build() => 0;

  int get safeLimitMg => _safeLimit;

  bool get isOverLimit => state > _safeLimit;

  /// Logs [mg] milligrams of caffeine consumed.
  void log(int mg) => state = (state + mg).clamp(0, 9999);

  /// Resets intake for a new day.
  void reset() => state = 0;
}

final caffeineProvider = NotifierProvider<CaffeineManager, int>(
  CaffeineManager.new,
);
