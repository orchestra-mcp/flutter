/// Environment configuration loaded at compile-time via --dart-define-from-file.
///
/// Run local:       flutter run --dart-define-from-file=env/local.json
/// Run staging:     flutter run --dart-define-from-file=env/staging.json
/// Run desktop:     flutter run --dart-define-from-file=env/desktop.json
/// Build prod:      flutter build apk --dart-define-from-file=env/production.json
enum AppEnvironment { local, staging, production }

abstract final class Env {
  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static AppEnvironment get current => switch (_envName) {
    'production' => AppEnvironment.production,
    'staging' => AppEnvironment.staging,
    _ => AppEnvironment.local,
  };

  static bool get isLocal => current == AppEnvironment.local;
  static bool get isStaging => current == AppEnvironment.staging;
  static bool get isProduction => current == AppEnvironment.production;

  // App display name (used in UI)
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Orchestra Dev',
  );

  // REST API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // PowerSync (realtime sync)
  static const String powersyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
    defaultValue: 'http://localhost:8585',
  );

  // WebSocket
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080',
  );

  // Orchestra MCP server (local TCP)
  static const String mcpHost = String.fromEnvironment(
    'MCP_HOST',
    defaultValue: 'localhost',
  );

  static const int mcpPort = int.fromEnvironment(
    'MCP_PORT',
    defaultValue: 50101,
  );

  // Auth
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // Feature flags
  static const bool enableFirebase = bool.fromEnvironment(
    'ENABLE_FIREBASE',
    defaultValue: false,
  );

  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: false,
  );
}
