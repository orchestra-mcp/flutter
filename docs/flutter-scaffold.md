# Flutter App Scaffold

## Overview

The Orchestra Flutter app is a cross-platform client targeting Android, iOS, macOS, Windows, Linux, and Web. Built with Flutter 3.41.4 / Dart 3.11.1.

## Running the App

### Local (default)
```bash
flutter run --dart-define-from-file=env/local.json
```

### Staging
```bash
flutter run --dart-define-from-file=env/staging.json
```

### Production
```bash
flutter build apk --dart-define-from-file=env/production.json
flutter build ios --dart-define-from-file=env/production.json
flutter build macos --dart-define-from-file=env/production.json
flutter build web --dart-define-from-file=env/production.json
```

## Multi-Environment Setup

Uses `flutter_flavor` + `--dart-define-from-file` for compile-time environment injection.

| File | Environment | API |
|------|-------------|-----|
| `env/local.json` | Local dev | `localhost:8080` |
| `env/staging.json` | Staging | `api-staging.orchestramcp.com` |
| `env/production.json` | Production | `api.orchestramcp.com` |

Environment values are read via `lib/core/config/env.dart` using `String.fromEnvironment`.

## Entrypoints

| File | Use |
|------|-----|
| `lib/main_local.dart` | Default / local flavor |
| `lib/main_staging.dart` | Staging flavor |
| `lib/main_production.dart` | Production flavor |

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | 3.3.1 | State management |
| go_router | 17.1.0 | Declarative routing |
| drift | 2.31.0 | SQLite ORM |
| dio | 5.9.2 | HTTP client |
| firebase_core | 4.5.0 | Firebase (optional) |
| flutter_flavor | 3.1.4 | Multi-env banner |

## Localization

- EN and AR supported (RTL via `GlobalWidgetsLocalizations`)
- ARB files at `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- Generated via `flutter gen-l10n` (triggered by `generate: true` in pubspec)
