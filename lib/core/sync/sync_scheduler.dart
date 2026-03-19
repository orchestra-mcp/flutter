import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user-configurable sync interval in minutes.
const _kSyncIntervalKey = 'sync_scheduler_interval_minutes';

/// Default sync interval when no preference is stored.
const int _kDefaultIntervalMinutes = 5;

/// Minimum debounce window — rapid changes within this window
/// are batched into a single sync.
const Duration _kDebounceWindow = Duration(seconds: 3);

// ---------------------------------------------------------------------------
// SyncScheduler
// ---------------------------------------------------------------------------

/// Automatic sync scheduling that triggers [SyncEngineNotifier.fullSync]
/// based on:
///   1. A configurable periodic timer (every N minutes).
///   2. App lifecycle events (sync on resume from background).
///   3. Network connectivity changes (sync when coming back online).
///   4. Debounced manual nudges (for rapid local changes).
///
/// Implements [WidgetsBindingObserver] so it can react to app foreground
/// events without requiring a widget in the tree.
class SyncScheduler with WidgetsBindingObserver {
  SyncScheduler({
    required this.ref,
  });

  final Ref ref;

  Timer? _periodicTimer;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _intervalMinutes = _kDefaultIntervalMinutes;
  bool _started = false;
  bool _hasConnectivity = true;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Start all scheduling mechanisms. Safe to call multiple times.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    // Load persisted interval.
    final prefs = await SharedPreferences.getInstance();
    _intervalMinutes =
        prefs.getInt(_kSyncIntervalKey) ?? _kDefaultIntervalMinutes;

    // 1. Periodic timer.
    _startPeriodicTimer();

    // 2. App lifecycle observer.
    WidgetsBinding.instance.addObserver(this);

    // 3. Connectivity changes.
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // Do an initial sync now.
    _triggerSync();
  }

  /// Stop all scheduling and clean up resources.
  void stop() {
    if (!_started) return;
    _started = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  // ── Configuration ──────────────────────────────────────────────────────

  /// The current sync interval in minutes.
  int get intervalMinutes => _intervalMinutes;

  /// Update the sync interval. Restarts the periodic timer.
  Future<void> setIntervalMinutes(int minutes) async {
    if (minutes < 1) return;
    _intervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSyncIntervalKey, minutes);
    // Restart the timer with the new interval.
    _periodicTimer?.cancel();
    _startPeriodicTimer();
  }

  // ── Periodic timer ─────────────────────────────────────────────────────

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (_) => _triggerSync(),
    );
  }

  // ── App lifecycle ──────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started) {
      // App came back to foreground — sync immediately.
      _triggerSync();
    }
  }

  // ── Connectivity ───────────────────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final nowConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (nowConnected && !_hasConnectivity && _started) {
      // Regained connectivity — sync immediately.
      _triggerSync();
    }
    _hasConnectivity = nowConnected;
  }

  // ── Debounced nudge ────────────────────────────────────────────────────

  /// Call this after a local change to schedule a debounced sync.
  /// Multiple calls within [_kDebounceWindow] collapse into one sync.
  void nudge() {
    if (!_started) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_kDebounceWindow, _triggerSync);
  }

  // ── Trigger ────────────────────────────────────────────────────────────

  void _triggerSync() {
    if (!_started || !_hasConnectivity) return;
    final engine = ref.read(syncEngineNotifierProvider.notifier);
    // Don't await — fire and forget so the scheduler never blocks.
    engine.fullSync();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides the [SyncScheduler] singleton and manages its lifecycle.
///
/// The scheduler starts automatically when first read and stops on dispose.
final syncSchedulerProvider = Provider<SyncScheduler>((ref) {
  final scheduler = SyncScheduler(ref: ref);
  // Auto-start when the provider is first read.
  scheduler.start();
  ref.onDispose(scheduler.stop);
  return scheduler;
});
