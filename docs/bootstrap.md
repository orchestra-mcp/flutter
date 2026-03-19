# App Bootstrap

Entry point wiring: Firebase, Riverpod, GoRouter, theme, locale, and RTL direction.

## Entrypoints

| File | Flavor | Notes |
|------|--------|-------|
| `lib/main_local.dart` | local | `ENABLE_FIREBASE=false`, no bg handler |
| `lib/main_staging.dart` | staging | Firebase + push background handler |
| `lib/main_production.dart` | production | Firebase + push background handler |

All entrypoints follow the same boot sequence:

```
WidgetsFlutterBinding.ensureInitialized()
  → if kIsWeb: usePathUrlStrategy()
  → initFlavor()
  → FirebaseService.init()        // no-op when ENABLE_FIREBASE=false
  → runApp(ProviderScope(child: OrchestraApp()))
```

## OrchestraApp

`ConsumerWidget` that composes:
- **Theme** — `themeProvider` → `AppThemeBuilder.build(theme)`
- **Router** — `routerProvider` → `GoRouter` stub (replaced by FEAT-OYK)
- **Locale** — `localeProvider` → `MaterialApp.router.locale`
- **RTL** — `builder` wraps child in `Directionality(rtl)` when `locale == ar`
- **Analytics** — `OrchestraAnalyticsObserver` in `GoRouter.observers`

## Router Stub

`lib/core/router/router_provider.dart` provides a `GoRouter` with a single `/` placeholder route. This will be replaced by the full auth-aware router in FEAT-OYK.

## Platform Utilities

`lib/core/utils/platform_utils.dart`:

```dart
bool isDesktop  // macOS | Windows | Linux, not web
bool isMobile   // Android | iOS, not web
bool isWeb      // kIsWeb
bool isApple    // iOS | macOS, not web
```

## Date Utilities

`lib/core/utils/date_utils.dart`:

```dart
formatRelative(DateTime dt) // "2h ago" | "yesterday" | "Mar 12"
formatISO(DateTime dt)      // "2025-01-01T12:00:00.000Z"
parseISO(String s)          // DateTime (local), falls back to DateTime.now()
```
