import 'package:flutter/foundation.dart' show kIsWeb;

/// Throws [UnsupportedError] when [feature] is invoked on the web platform.
///
/// Use this guard at the entry point of any service that has no web
/// implementation (e.g. HealthKit, system-tray, TCP socket to the local
/// orchestrator daemon).
///
/// ```dart
/// class TrayManagerService {
///   void show() {
///     webPlatformGuard('TrayManagerService.show');
///     // native-only code below
///   }
/// }
/// ```
void webPlatformGuard(String feature) {
  if (kIsWeb) {
    throw UnsupportedError(
      '$feature is not supported on the web platform. '
      'Guard call sites with `if (!kIsWeb)` before invoking this feature.',
    );
  }
}

/// Stub implementation of a health-data service for the web platform.
///
/// All methods are no-ops / return null so that provider graphs that
/// unconditionally wire up health-related providers do not crash on web.
class HealthServiceStub {
  const HealthServiceStub();

  /// Always returns false on web — health permissions cannot be requested.
  Future<bool> requestPermissions() async => false;

  /// Always returns null on web — no health data is available.
  Future<List<Map<String, dynamic>>?> fetchSteps({
    required DateTime start,
    required DateTime end,
  }) async => null;

  /// Always returns null on web.
  Future<Map<String, dynamic>?> fetchHeartRate({
    required DateTime start,
    required DateTime end,
  }) async => null;
}

/// Stub for the system-tray manager — no tray icon exists on web.
class TrayManagerStub {
  const TrayManagerStub();

  /// No-op on web.
  Future<void> setIcon(String assetPath) async {}

  /// No-op on web.
  Future<void> setToolTip(String tooltip) async {}

  /// No-op on web.
  Future<void> destroy() async {}
}

/// Stub for local biometric authentication — always returns false on web.
class LocalAuthStub {
  const LocalAuthStub();

  /// Returns false — biometrics are not available in the browser.
  Future<bool> canCheckBiometrics() async => false;

  /// Returns false — authentication always fails on web.
  Future<bool> authenticate({required String localizedReason}) async => false;
}
