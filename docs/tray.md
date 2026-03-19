# System Tray Integration

## Overview

`TrayService` manages the system-tray icon and context menu on macOS, Windows, and Linux. All methods are no-ops on web and mobile, guarded by `isDesktop`.

## Files

### `lib/core/tray/tray_service.dart`

Singleton (`TrayService.instance`) with the following API:

| Method | Description |
|--------|-------------|
| `init()` | Sets the initial stopped icon and builds the context menu. Call once on app start. |
| `updateIcon(TrayIconState)` | Swaps the tray icon to reflect orchestrator subprocess status. |
| `showMenu()` | Rebuilds and re-applies the context menu (e.g. after workspace list changes). |
| `hide()` | Removes the tray icon. |

#### `TrayIconState` enum

| Value | Asset | Meaning |
|-------|-------|---------|
| `running` | `tray_running.png` | Orchestrator subprocess is active |
| `starting` | `tray_starting.png` | Subprocess is launching |
| `stopped` | `tray_stopped.png` | Subprocess is not running |
| `error` | `tray_error.png` | Subprocess exited with error |

#### Menu structure

```
Show / Hide Orchestra
─────────────────────
Start Orchestra
Restart
Stop
─────────────────────
Workspace ▶  [list with active checkmark]
─────────────────────
Sync Now
─────────────────────
Settings
Quit
```

### `lib/screens/tray/workspace_switcher.dart`

`WorkspaceSwitcher` — `ConsumerWidget` that renders the workspace list sub-panel. Each row shows the workspace initial, name, and a checkmark for the active workspace. Calls `onSwitch(id)` on tap.

## Usage

```dart
// App startup (main.dart or AppDelegate equivalent):
await TrayService.instance.init();

// When orchestrator state changes:
await TrayService.instance.updateIcon(TrayIconState.running);
```
