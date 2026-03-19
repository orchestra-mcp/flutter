# Web App Shell

## Overview

Adaptive shell for the web platform that switches between a desktop `NavigationRail` layout and a mobile `GlassNavBar` layout based on screen width.

## Files

### `lib/features/web/web_app_shell.dart`

`LayoutBuilder` root: routes to `WebDesktopShell` when `maxWidth >= 1024`, otherwise `WebMobileShell`.

### `lib/features/web/web_desktop_shell.dart`

`Row` with a collapsible `NavigationRail` (72px collapsed, extended when toggled) and a router outlet. 16 navigation destinations with accent-colored active indicators.

### `lib/features/web/web_mobile_shell.dart`

Reuses the existing `AppShell` with a 5-item `GlassNavBar` (Dashboard, Projects, Library, Health, Notifications).
