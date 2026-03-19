# Platform Web Architecture

Conditional imports and platform stubs isolate web-specific code from native implementations.

## Directory Structure

```
lib/platform/
  web/
    web_storage_service.dart   # sessionStorage / localStorage wrappers
    web_auth_service.dart      # OAuth redirect flow for web
  stub/
    health_stub.dart           # No-op health package stub
    local_auth_stub.dart       # LocalAuthentication stub (always false)
    tray_stub.dart             # No-op TrayManagerService
```

## Web Storage Service

`WebStorageService` wraps the browser Storage APIs:

- `saveSessionToken` / `getSessionToken` / `clearSessionToken` — uses `window.sessionStorage` keyed on `orchestra_access_token`; cleared when the tab closes.
- `saveLocalPref` / `getLocalPref` — uses `window.localStorage` for persisted preferences.

On native platforms the same class falls back to an in-memory map so it compiles everywhere.

## Web Auth Service

`WebAuthService` handles the OAuth redirect flow:

- `signInWithGoogle/GitHub/Discord/Slack()` — sets `window.location.href` to the provider OAuth URL from `/api/auth/{provider}/url`.
- `handleOAuthCallback(code, state)` — called from the `/auth/callback` go_router route; exchanges the code via `POST /api/auth/callback` and stores the returned tokens in sessionStorage.

## Platform Stubs

Each stub provides a no-op implementation of a native-only service so `kIsWeb` guards are not needed at every call site:

| Stub | Native counterpart |
|------|--------------------|
| `HealthStub` | `health` package |
| `LocalAuthStub` | `local_auth` package |
| `TrayManagerService` | system tray integration |
