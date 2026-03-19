# Web Platform Architecture — Stubs and Storage

## Overview

Platform-conditional code for web builds using stubs and web-specific implementations.

## Files

### `lib/platform/web/web_storage_service.dart`

Wraps browser `sessionStorage` and `localStorage` APIs. Stores the access token under `orchestra_access_token` in `sessionStorage`.

### `lib/platform/web/web_auth_service.dart`

OAuth redirect flow for web. Redirects to provider OAuth URLs for Google, GitHub, Discord, and Slack. Handles the callback code exchange.

### `lib/platform/stub/tray_stub.dart`

No-op `TrayManagerService` for web — `init`, `showMenu`, `hide` are all async no-ops.

### `lib/platform/stub/health_stub.dart`

No-op `HealthStub` returning `false`/`null` for all health queries on web.

### `lib/platform/stub/local_auth_stub.dart`

No-op `LocalAuthStub` — `authenticate()` always returns `false` on web.

## Usage

Use `kIsWeb` guards before calling any platform-specific service. Conditional imports select the correct implementation at compile time.
