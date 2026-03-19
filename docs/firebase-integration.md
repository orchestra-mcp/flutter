# Firebase Integration

Firebase is **opt-in** via the `ENABLE_FIREBASE` dart-define flag. It is off by default in local dev.

## Setup

Run `flutterfire configure` once per platform, then add the generated files:

| Platform | File |
|----------|------|
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |
| macOS | `macos/Runner/GoogleService-Info.plist` |

These files are git-ignored — inject them via CI secrets.

## Services

| File | Service | Enabled by |
|------|---------|-----------|
| `firebase_service.dart` | Bootstrap | `ENABLE_FIREBASE=true` |
| `analytics_service.dart` | Analytics | `ENABLE_ANALYTICS=true` |
| `crashlytics_service.dart` | Crash reporting | `ENABLE_CRASHLYTICS=true` |
| `messaging_service.dart` | FCM push | `ENABLE_FIREBASE=true` |
| `performance_service.dart` | HTTP metrics | `ENABLE_FIREBASE=true` |

## Custom Events

| Method | Firebase Event |
|--------|---------------|
| `logLogin(method)` | `login` |
| `logLogout()` | `logout` |
| `logFeatureCreated(id, kind)` | `feature_created` |
| `logProjectOpened(id)` | `project_opened` |
| `logHealthLogged(category)` | `health_logged` |
| `logThemeChanged(name)` | `theme_changed` |
| `logLanguageChanged(locale)` | `language_changed` |
| `logSearchPerformed(q, n)` | `search` + `search_performed` |

## Performance Traces

Add `PerformanceService.dioInterceptor` to your Dio instance. Custom traces:
- `sync_duration` — full sync cycle
- `health_kit_read` — HealthKit/Health Connect reads
- `mcp_tool_<name>` — MCP tool round-trips
