import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/firebase/analytics_service.dart';
import 'package:orchestra/core/firebase/crashlytics_service.dart';
import 'package:orchestra/core/firebase/messaging_service.dart';
import 'package:orchestra/core/firebase/performance_service.dart';

/// Initialises Firebase and all sub-services.
/// Only runs when [Env.enableFirebase] is true.
abstract final class FirebaseService {
  static bool _initialised = false;

  static Future<void> init() async {
    if (!Env.enableFirebase) return;
    if (_initialised) return;

    await Firebase.initializeApp();
    _initialised = true;

    // Wire up sub-services in order
    CrashlyticsService.init();

    if (Env.enableAnalytics) {
      await AnalyticsService.init();
    }

    if (Env.enableCrashlytics) {
      await CrashlyticsService.enableCollection();
    }

    await MessagingService.init();
    PerformanceService.init();

    if (kDebugMode) {
      debugPrint('[FirebaseService] Initialised (env: ${Env.current.name})');
    }
  }

  static bool get isReady => _initialised;
}
