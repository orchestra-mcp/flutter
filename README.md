# Orchestra

Cross-platform AI agent client built with Flutter. Supports Android, iOS, macOS, Windows, Linux, and Web.

## Prerequisites

- Flutter SDK 3.41+ / Dart 3.11+
- [Orchestra MCP](https://github.com/orchestra-mcp/framework) binary (desktop platforms)
- Xcode 16+ (iOS/macOS)
- Android Studio / JDK 17 (Android)
- Visual Studio 2022 with C++ workload (Windows)
- GTK 3 dev libraries (Linux)

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run locally (connects to localhost MCP)
flutter run --dart-define-from-file=env/local.json

# Run with staging backend
flutter run --dart-define-from-file=env/staging.json

# Run web
flutter run -d chrome --dart-define-from-file=env/local.json
```

## Build

```bash
# Android
flutter build apk --release --dart-define-from-file=env/production.json
flutter build appbundle --release --dart-define-from-file=env/production.json

# iOS
flutter build ipa --release --dart-define-from-file=env/production.json

# macOS
flutter build macos --release --dart-define-from-file=env/production.json

# Linux
flutter build linux --release --dart-define-from-file=env/production.json

# Windows
flutter build windows --release --dart-define-from-file=env/production.json

# Web
flutter build web --release --web-renderer canvaskit --dart-define-from-file=env/production.json
```

## Project Structure

```
lib/
  core/           # Shared infrastructure
    api/          # Dio HTTP client, interceptors
    database/     # Drift ORM, SQLite schema
    mcp/          # MCP TCP client, protocol
    router/       # GoRouter configuration
    startup/      # Startup gate (binary/workspace checks)
    theme/        # Material 3 theme, glass components
    utils/        # Platform detection, helpers
  screens/        # Feature screens
    auth/         # Login, register, magic link
    installer/    # Orchestra binary installer
    marketing/    # Landing pages (web)
    onboarding/   # First-run onboarding
    settings/     # App settings
    summary/      # Dashboard / summary
    welcome/      # Workspace picker (desktop)
    setup_desktop/ # Desktop required gate (mobile)
env/              # Environment configs (local/staging/production)
deploy/           # Deployment scripts, Caddyfile, Dockerfile
docs/             # Architecture documentation
scripts/          # Build and test scripts
```

## Environment Configuration

Environment variables are injected at compile time via `--dart-define-from-file`:

| File | Use |
|------|-----|
| `env/local.json` | Local development (localhost) |
| `env/staging.json` | Staging server |
| `env/production.json` | Production release |

## Scripts

```bash
# Run tests with coverage
./scripts/flutter-test.sh --test --coverage

# Run analyzer
./scripts/flutter-test.sh --analyze

# Check formatting
./scripts/flutter-test.sh --format

# Build all platforms (auto-detects OS)
./scripts/flutter-build.sh

# Build specific platform
./scripts/flutter-build.sh android
./scripts/flutter-build.sh web --docker
```

## Deployment

### Web (SSH + Caddy)
```bash
./deploy/deploy.sh
# or with custom host:
SERVER_HOST=prod.orchestra-mcp.dev ./deploy/deploy.sh
```

### Web (Docker)
```bash
docker build -f deploy/Dockerfile.web -t orchestra-web .
docker run -p 8080:80 orchestra-web
```

### iOS (Fastlane)
```bash
cd ios && bundle exec fastlane deploy_testflight
```

### Android (Fastlane)
```bash
cd android && bundle exec fastlane deploy_internal
```

## CI/CD

GitHub Actions workflows in `.github/workflows/`:

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `flutter-ci.yml` | Push/PR to master | Analyze, format check, tests |
| `flutter-build.yml` | Manual dispatch | Build all 6 platforms |
| `flutter-release.yml` | Tag `app-v*` | Full release pipeline |

## Documentation

| Document | Description |
|----------|-------------|
| [flutter-scaffold.md](docs/flutter-scaffold.md) | App scaffold and project setup |
| [auth.md](docs/auth.md) | Authentication architecture |
| [auth-screens.md](docs/auth-screens.md) | Auth screen implementations |
| [auth-register-screens.md](docs/auth-register-screens.md) | Registration flow |
| [login.md](docs/login.md) | Login flow |
| [login-screen.md](docs/login-screen.md) | Login screen implementation |
| [magic-login.md](docs/magic-login.md) | Magic link authentication |
| [router.md](docs/router.md) | GoRouter configuration |
| [bootstrap.md](docs/bootstrap.md) | App bootstrap sequence |
| [api-client.md](docs/api-client.md) | Dio API client setup |
| [database-schema.md](docs/database-schema.md) | Drift database schema |
| [sync-engine.md](docs/sync-engine.md) | Sync engine architecture |
| [websocket.md](docs/websocket.md) | WebSocket integration |
| [theme-system.md](docs/theme-system.md) | Material 3 theme system |
| [glass-components.md](docs/glass-components.md) | Glass UI components |
| [i18n.md](docs/i18n.md) | Internationalization |
| [settings.md](docs/settings.md) | Settings architecture |
| [settings-screen.md](docs/settings-screen.md) | Settings screen |
| [summary-screen.md](docs/summary-screen.md) | Summary/dashboard screen |
| [notifications-screen.md](docs/notifications-screen.md) | Notifications screen |
| [onboarding.md](docs/onboarding.md) | Onboarding flow |
| [installer.md](docs/installer.md) | Binary installer |
| [health.md](docs/health.md) | Health tracking |
| [health-service.md](docs/health-service.md) | Health service layer |
| [health-managers.md](docs/health-managers.md) | Health data managers |
| [health-kit-service.md](docs/health-kit-service.md) | HealthKit integration |
| [nutrition-shutdown.md](docs/nutrition-shutdown.md) | Nutrition shutdown feature |
| [ai-insight-engine.md](docs/ai-insight-engine.md) | AI insight engine |
| [firebase-integration.md](docs/firebase-integration.md) | Firebase setup |
| [tray.md](docs/tray.md) | System tray architecture |
| [tray-integration.md](docs/tray-integration.md) | Tray integration details |
| [marketing-pages.md](docs/marketing-pages.md) | Marketing/landing pages |
| [web-app-shell.md](docs/web-app-shell.md) | Web app shell |
| [web-platform-stubs.md](docs/web-platform-stubs.md) | Web platform stubs |
| [web-routes.md](docs/web-routes.md) | Web-specific routes |
| [web-shell.md](docs/web-shell.md) | Web shell wrapper |
| [platform-web.md](docs/platform-web.md) | Web platform specifics |

## License

Proprietary. All rights reserved.
