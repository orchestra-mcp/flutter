import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks daily water intake in millilitres.
class HydrationManager extends Notifier<int> {
  static const int _goalMl = 2000;

  @override
  int build() => 0;

  int get goalMl => _goalMl;

  /// Logs [ml] millilitres of water consumed.
  void log(int ml) => state = (state + ml).clamp(0, _goalMl * 2);

  /// Resets intake for a new day.
  void reset() => state = 0;
}

final hydrationProvider = NotifierProvider<HydrationManager, int>(
  HydrationManager.new,
);
