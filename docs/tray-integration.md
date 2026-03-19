# System Tray Integration

`TrayManagerService` (`lib/features/desktop/tray_manager_service.dart`) is a singleton that manages the system tray icon and context menu on desktop platforms.

## TrayIconState

| State | Meaning |
|-------|---------|
| `running` | Orchestrator subprocess active |
| `starting` | Subprocess launching |
| `stopped` | Subprocess not running |
| `error` | Subprocess crashed |

## API

- `init()` — initialise the tray icon on app start
- `updateIcon(TrayIconState)` — swap the icon asset
- `buildMenu({workspaceNames, activeWorkspaceId, onShowHide, onQuit})` — rebuild context menu
- `dispose()` — clean up on app exit

## Menu Structure

Show/Hide Orchestra → Start / Restart / Stop → Workspace submenu (active marked with checkmark) → Sync Now → Settings → Quit

## Related Files

- `lib/features/desktop/tray_manager_service.dart`
- `test/screens/desktop/tray_manager_test.dart`
