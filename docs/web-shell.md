# Web App Shell

Adaptive web shell located in `lib/features/web/`.

## Components

### WebAppShell (`web_app_shell.dart`)

`ConsumerWidget` using `LayoutBuilder`. Routes to:
- `WebDesktopShell` when `maxWidth >= 1024`
- `WebMobileShell` when narrower

### WebDesktopShell (`web_desktop_shell.dart`)

Row with `NavigationRail` (16 destinations), `VerticalDivider`, and an expanded router outlet. The rail collapses to 72 dp and extends when the hamburger icon is tapped. Destinations: Dashboard, Projects, Features, Notes, Agents, Skills, Workflows, Docs, Wiki, Delegations, Sessions, Repos, Tunnels, DevTools, Health, Notifications. Active destination uses accent fill indicator and left border.

### WebMobileShell (`web_mobile_shell.dart`)

Reuses the existing `AppShell` with a 5-item `GlassNavBar`: Dashboard, Projects, Library, Health, Notifications.

## Related Files

- `lib/features/web/web_app_shell.dart`
- `lib/features/web/web_desktop_shell.dart`
- `lib/features/web/web_mobile_shell.dart`
- `test/screens/web/web_shell_test.dart`
