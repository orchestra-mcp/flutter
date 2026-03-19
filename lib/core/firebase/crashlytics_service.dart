import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/config/env.dart';

/// Hooks Flutter and platform errors into Crashlytics.
abstract final class CrashlyticsService {
  static FirebaseCrashlytics? _crashlytics;

  /// Called right after Firebase.initializeApp().
  /// Wires error handlers even before collection is enabled.
  static void init() {
    _crashlytics = FirebaseCrashlytics.instance;

    // Flutter framework errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (Env.enableCrashlytics) {
        _crashlytics?.recordFlutterFatalError(details);
      }
    };

    // Platform / isolate errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (Env.enableCrashlytics) {
        _crashlytics?.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  static Future<void> enableCollection() async {
    await _crashlytics?.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  // ─── User context ─────────────────────────────────────────────────────────

  static Future<void> setUser(String userId) async {
    await _crashlytics?.setUserIdentifier(userId);
  }

  static Future<void> clearUser() async {
    await _crashlytics?.setUserIdentifier('');
  }

  static Future<void> setKeys({
    String? theme,
    String? screen,
    String? syncStatus,
  }) async {
    final c = _crashlytics;
    if (c == null) return;
    if (theme != null) await c.setCustomKey('theme', theme);
    if (screen != null) await c.setCustomKey('screen', screen);
    if (syncStatus != null) await c.setCustomKey('sync_status', syncStatus);
  }

  // ─── Error reporting ──────────────────────────────────────────────────────

  /// Reports a handled (non-fatal) error with optional context.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    String? reason,
  }) async {
    if (!Env.enableCrashlytics) return;
    await _crashlytics?.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  static Future<void> log(String message) async {
    await _crashlytics?.log(message);
  }
}
